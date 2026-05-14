import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  static const String appName = 'RifaDorada';
  static const String appVersion = '1.0.0';
  
  static const String currencySymbol = '\$';
  static const String currencyCode = 'COP';
  static const String countryCode = '+57';
  static const String timezone = 'America/Bogota';

  static const String _defaultChatbotUrl = 'http://192.168.200.106:3008';
  static const String _chatbotUrlKey = 'chatbot_url';

  static String _chatbotUrl = _defaultChatbotUrl;

  static String get chatbotUrl => _chatbotUrl;
  static String get chatbotApi => '$_chatbotUrl/v1';

  static Future<void> loadChatbotUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _chatbotUrl = prefs.getString(_chatbotUrlKey) ?? _defaultChatbotUrl;
    } catch (e) {
      _chatbotUrl = _defaultChatbotUrl;
    }
  }

  static Future<void> setChatbotUrl(String url) async {
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    _chatbotUrl = cleanUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chatbotUrlKey, cleanUrl);
    } catch (e) {
      debugPrint('Error saving chatbot URL: $e');
    }
  }
  static const int maxNumeros100 = 100;
  static const int maxNumeros1000 = 1000;
  
  static const List<String> ciudadesColombia = [
    'Bogotá',
    'Medellín',
    'Cali',
    'Barranquilla',
    'Cartagena',
    'Cúcuta',
    'Bucaramanga',
    'Pereira',
    'Manizales',
    'Ibagué',
    'Pasto',
    'Neiva',
    'Villavicencio',
    'Montería',
    'Valledupar',
    'Santa Marta',
    'Armenia',
    'Sincelejo',
    'Popayán',
    'Tunja',
    'Riohacha',
    'Quibdó',
    'San Andrés',
    'Otra',
  ];

  static const List<int> cantidadesNumeros = [10, 20, 50, 100, 200, 500, 1000];
  
  static const List<String> tiposRifa = ['2 cifras', '3 cifras'];

  static String formatCurrencyCOP(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  static String formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    if (!cleaned.startsWith('57')) {
      cleaned = '57$cleaned';
    }
    return cleaned;
  }

  static String generateWhatsAppMessage({
    required String nombre,
    required List<String> numeros,
    required double total,
    required String nombreRifa,
  }) {
    final numerosStr = numeros.join(', ');
    return 'Hola $nombre, tus números para la rifa "$nombreRifa" son: $numerosStr. Total: ${formatCurrencyCOP(total)}. Gracias por participar. 🎉';
  }
}