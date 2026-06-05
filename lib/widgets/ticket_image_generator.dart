import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class TicketImageGenerator {
  static Future<bool> sendTicketImage({
    required String chatbotUrl,
    required String whatsapp,
    required String rifaNombre,
    required List<String> numeros,
    required String participanteNombre,
    required String ciudad,
    required double precioNumero,
    required String? loteria,
    required String? fechaSorteo,
    required String participanteId,
  }) async {
    try {
      final cleanUrl = chatbotUrl.endsWith('/')
          ? chatbotUrl.substring(0, chatbotUrl.length - 1)
          : chatbotUrl;

      final url = '$cleanUrl/v1/web/ticket';
      debugPrint('[TICKET] Enviando a: $url');

      final body = jsonEncode({
        'whatsapp': whatsapp,
        'rifaNombre': rifaNombre,
        'numeros': numeros,
        'participanteNombre': participanteNombre,
        'ciudad': ciudad,
        'precioNumero': precioNumero,
        'loteria': loteria,
        'fechaSorteo': fechaSorteo,
        'participanteId': participanteId,
      });

      debugPrint('[TICKET] Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (AppConstants.botApiKey.isNotEmpty) 'X-API-Key': AppConstants.botApiKey,
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      debugPrint('[TICKET] Status: ${response.statusCode}');
      debugPrint('[TICKET] Response: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('[TICKET] ✅ Ticket enviado exitosamente a $whatsapp');
        return true;
      }
      debugPrint('[TICKET] ❌ Error: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      debugPrint('[TICKET] ❌ Error enviando ticket: $e');
      return false;
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
