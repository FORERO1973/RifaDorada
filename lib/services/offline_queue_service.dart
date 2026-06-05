import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._();

  static const _queueKey = 'bot_offline_queue';
  SharedPreferences? _prefs;
  final List<Map<String, dynamic>> _queue = [];
  int _processing = 0;

  final ValueNotifier<int> pendingCountNotifier = ValueNotifier(0);

  int get pendingCount => _queue.length;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    if (_prefs == null) return;
    final raw = _prefs!.getString(_queueKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      _queue.addAll(list.cast<Map<String, dynamic>>());
      pendingCountNotifier.value = _queue.length;
    } catch (_) {}
  }

  Future<void> _saveToDisk() async {
    if (_prefs == null) return;
    await _prefs!.setString(_queueKey, jsonEncode(_queue));
    pendingCountNotifier.value = _queue.length;
  }

  Future<http.Response> enqueueOrSend({
    required String url,
    required String method,
    required Map<String, String> headers,
    dynamic body,
    int maxRetries = 5,
  }) async {
    if (_processing > 0) {
      return _queueIt(url, method, headers, body, maxRetries);
    }

    final online = await _isOnline();
    if (!online) {
      return _queueIt(url, method, headers, body, maxRetries);
    }

    try {
      final response = await _doHttp(url, method, headers, body);
      if (response.statusCode >= 200 && response.statusCode < 500) {
        return response;
      }
      return _queueIt(url, method, headers, body, maxRetries);
    } catch (_) {
      return _queueIt(url, method, headers, body, maxRetries);
    }
  }

  Future<http.Response> _queueIt(
    String url,
    String method,
    Map<String, String> headers,
    dynamic body,
    int maxRetries,
  ) async {
    final item = {
      'id': _generateId(),
      'url': url,
      'method': method,
      'headers': headers,
      'body': body is String ? body : jsonEncode(body),
      'createdAt': DateTime.now().toIso8601String(),
      'retries': 0,
      'maxRetries': maxRetries,
    };
    _queue.add(item);
    await _saveToDisk();
    debugPrint('[OFFLINE_QUEUE] Encolado: $url (pendientes: ${_queue.length})');
    return http.Response('{"status":"queued","message":"Sin conexión, se encoló automáticamente"}', 202);
  }

  Future<void> processQueue() async {
    if (_queue.isEmpty || _processing > 0) return;
    _processing = 1;

    final items = List<Map<String, dynamic>>.from(_queue);
    for (final item in items) {
      final online = await _isOnline();
      if (!online) break;

      final url = item['url'] as String;
      final method = item['method'] as String? ?? 'POST';
      final headers = Map<String, String>.from(item['headers'] as Map? ?? {});
      final body = item['body'] as String?;

      try {
        final response = await _doHttp(url, method, headers, body);
        if (response.statusCode >= 200 && response.statusCode < 500) {
          _queue.removeWhere((e) => e['id'] == item['id']);
          debugPrint('[OFFLINE_QUEUE] Sincronizado: $url');
        } else {
          item['retries'] = (item['retries'] as int? ?? 0) + 1;
          if (item['retries'] >= (item['maxRetries'] as int? ?? 5)) {
            _queue.removeWhere((e) => e['id'] == item['id']);
            debugPrint('[OFFLINE_QUEUE] Descartado tras ${item['retries']} intentos: $url');
          }
        }
      } catch (_) {
        item['retries'] = (item['retries'] as int? ?? 0) + 1;
        if (item['retries'] >= (item['maxRetries'] as int? ?? 5)) {
          _queue.removeWhere((e) => e['id'] == item['id']);
        }
        break;
      }
      await _saveToDisk();
    }

    _processing = 0;
    await _saveToDisk();
  }

  Future<http.Response> _doHttp(
    String url, String method, Map<String, String> headers, String? body,
  ) async {
    final uri = Uri.parse(url);
    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      case 'POST':
        return await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 15));
      case 'PUT':
        return await http.put(uri, headers: headers, body: body).timeout(const Duration(seconds: 15));
      case 'DELETE':
        return await http.delete(uri, headers: headers).timeout(const Duration(seconds: 15));
      default:
        return await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 15));
    }
  }

  Future<bool> _isOnline() async {
    try {
      final result = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 3));
      return result.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  String _generateId() {
    final r = Random();
    return '${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(99999)}';
  }
}
