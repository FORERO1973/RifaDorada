import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/theme.dart';
import '../services/offline_queue_service.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isOnline = true;
  StreamSubscription? _connectivitySub;
  VoidCallback? _queueListener;
  bool get _active => !kIsWeb; // Only active on mobile

  @override
  void initState() {
    super.initState();
    if (!_active) return;
    _checkInitial();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && !_isOnline) {
        OfflineQueueService().processQueue();
      }
      if (mounted) setState(() => _isOnline = online);
    });
    _queueListener = _onQueueChanged;
    OfflineQueueService().pendingCountNotifier.addListener(_queueListener!);
  }

  void _onQueueChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkInitial() async {
    if (!_active) return;
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _isOnline = results.any((r) => r != ConnectivityResult.none));
    }
  }

  @override
  void dispose() {
    if (!_active) { super.dispose(); return; }
    _connectivitySub?.cancel();
    if (_queueListener != null) {
      OfflineQueueService().pendingCountNotifier.removeListener(_queueListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return widget.child;

    final pending = OfflineQueueService().pendingCount;
    return Column(
      children: [
        if (!_isOnline)
          MaterialBanner(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            backgroundColor: Colors.orange.shade800,
            content: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sin conexión — los cambios se guardarán localmente',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            actions: const [SizedBox.shrink()],
          ),
        if (pending > 0 && _isOnline)
          MaterialBanner(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            content: Row(
              children: [
                const Icon(Icons.sync_rounded, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  '$pending operación(es) pendiente(s) de sincronizar',
                  style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => OfflineQueueService().processQueue(),
                child: const Text('Sincronizar ahora', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
