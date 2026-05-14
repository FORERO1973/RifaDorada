import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../models/rifa.dart';
import '../models/participante.dart';
import '../models/numero.dart';
import '../models/app_config.dart';
import '../config/constants.dart';

class FirebaseService {
  static FirebaseService? _instance;
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  bool _isInitialized = false;
  
  bool _useLocalData = true;
  final List<Rifa> _localRifas = [];
  final Map<String, List<Participante>> _localParticipantes = {};
  final Map<String, Map<String, Numero>> _localNumeros = {};

  FirebaseService._();

  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  bool get isInitialized => _isInitialized;
  bool get useLocalData => _useLocalData;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      _useLocalData = false;
      _isInitialized = true;
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      debugPrint('Using local data mode');
      _useLocalData = true;
      _isInitialized = true;
      _initializeLocalData();
    }
  }

  void _initializeLocalData() {
    if (_localRifas.isEmpty) {
      _localRifas.addAll([
        Rifa(
          id: 'rifa_1',
          nombre: 'Rifa Navidad',
          descripcion: 'Rifa especial de Navidad con grandes premios',
          precioNumero: 10000,
          cantidadNumeros: 100,
          tipoRifa: '2 cifras',
          activa: true,
          fechaCreacion: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Rifa(
          id: 'rifa_2',
          nombre: 'Rifa Auto Nuevo',
          descripcion: 'Gana un carro 0km',
          precioNumero: 50000,
          cantidadNumeros: 1000,
          tipoRifa: '3 cifras',
          activa: true,
          fechaCreacion: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ]);

      _localNumeros['rifa_1'] = {};
      for (int i = 0; i < 100; i++) {
        final numStr = i.toString().padLeft(2, '0');
        _localNumeros['rifa_1']![numStr] = Numero(
          numero: numStr,
          estado: EstadoNumero.disponible,
          rifaId: 'rifa_1',
        );
      }
      
      _localNumeros['rifa_2'] = {};
      for (int i = 0; i < 1000; i++) {
        final numStr = i.toString().padLeft(3, '0');
        _localNumeros['rifa_2']![numStr] = Numero(
          numero: numStr,
          estado: EstadoNumero.disponible,
          rifaId: 'rifa_2',
        );
      }

      _localParticipantes['rifa_1'] = [
        Participante(
          id: 'p1',
          rifaId: 'rifa_1',
          nombre: 'Juan Pérez',
          whatsapp: '3001234567',
          ciudad: 'Bogotá',
          documento: '12345678',
          numeros: ['25', '47', '89'],
          estadoPago: EstadoPago.pagado,
          fechaRegistro: DateTime.now().subtract(const Duration(days: 3)),
          totalPagado: 30000,
        ),
        Participante(
          id: 'p2',
          rifaId: 'rifa_1',
          nombre: 'María García',
          whatsapp: '3209876543',
          ciudad: 'Medellín',
          documento: '98765432',
          numeros: ['12'],
          estadoPago: EstadoPago.pendiente,
          fechaRegistro: DateTime.now().subtract(const Duration(days: 1)),
          totalPagado: 0,
        ),
      ];

      _localParticipantes['rifa_2'] = [];
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Stream<List<Rifa>> getRifas() {
    if (_useLocalData) {
      return Stream.value(_localRifas);
    }
    
    return _firestore!.collection('rifas')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rifa.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<Rifa?> getRifa(String id) async {
    if (_useLocalData) {
      try {
        return _localRifas.firstWhere((r) => r.id == id);
      } catch (e) {
        return null;
      }
    }
    
    final doc = await _firestore!.collection('rifas').doc(id).get();
    if (doc.exists) {
      return Rifa.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<String> crearRifa(Rifa rifa) async {
    final id = _generateId();
    
    if (_useLocalData) {
      final nuevaRifa = rifa.copyWith(id: id);
      _localRifas.insert(0, nuevaRifa);
      
      _localNumeros[id] = {};
      final digitos = rifa.tipoRifa == '3 cifras' ? 3 : 2;
      for (int i = 0; i < rifa.cantidadNumeros; i++) {
        final numStr = i.toString().padLeft(digitos, '0');
        _localNumeros[id]![numStr] = Numero(
          numero: numStr,
          estado: EstadoNumero.disponible,
          rifaId: id,
        );
      }
      _localParticipantes[id] = [];
      
      return id;
    }
    
    await _firestore!.collection('rifas').doc(id).set(rifa.toMap());
    _syncRifasToChatbot();
    return id;
  }

  Future<void> actualizarRifa(Rifa rifa) async {
    if (_useLocalData) {
      final index = _localRifas.indexWhere((r) => r.id == rifa.id);
      if (index != -1) {
        _localRifas[index] = rifa;
      }
      return;
    }
    
    await _firestore!.collection('rifas').doc(rifa.id).update(rifa.toMap());
    _syncRifasToChatbot();
  }

  Future<void> eliminarRifa(String id) async {
    if (_useLocalData) {
      _localRifas.removeWhere((r) => r.id == id);
      _localNumeros.remove(id);
      _localParticipantes.remove(id);
      return;
    }
    
    await _firestore!.collection('rifas').doc(id).delete();
    _syncRifasToChatbot();
  }

  Stream<List<Participante>> getParticipantes(String rifaId) {
    if (_useLocalData) {
      return Stream.value(_localParticipantes[rifaId] ?? []);
    }
    
    return _firestore!.collection('participantes')
        .where('rifaId', isEqualTo: rifaId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Participante.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<List<Participante>> getParticipantesOnce(String rifaId) async {
    if (_useLocalData) {
      return _localParticipantes[rifaId] ?? [];
    }
    
    final snapshot = await _firestore!.collection('participantes')
        .where('rifaId', isEqualTo: rifaId)
        .get();
    
    final results = snapshot.docs
        .map((doc) => Participante.fromMap(doc.data(), doc.id))
        .toList();
    
    results.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
    return results;
  }

  Future<String> registrarParticipante(Participante participante) async {
    final id = _generateId();
    
    if (_useLocalData) {
      final nuevoParticipante = participante.copyWith(id: id);
      _localParticipantes[participante.rifaId] ??= [];
      _localParticipantes[participante.rifaId]!.insert(0, nuevoParticipante);
      
      for (final num in participante.numeros) {
        if (_localNumeros[participante.rifaId]!.containsKey(num)) {
          _localNumeros[participante.rifaId]![num] = Numero(
            numero: num,
            estado: participante.estadoPago == EstadoPago.pagado 
                ? EstadoNumero.pagado 
                : EstadoNumero.reservado,
            participanteId: id,
            rifaId: participante.rifaId,
          );
        }
      }
      
      return id;
    }
    
    await _firestore!.collection('participantes').doc(id).set(participante.toMap());
    _syncParticipantesToChatbot(participante.rifaId);
    final rifa = await getRifa(participante.rifaId);
    final total = rifa != null ? rifa.precioNumero * participante.numeros.length : 0.0;
    _notifySaleToChatbot(participante.rifaId, participante.numeros, participante, total);
    return id;
  }

  Future<void> actualizarParticipante(Participante participante) async {
    if (_useLocalData) {
      final lista = _localParticipantes[participante.rifaId];
      if (lista != null) {
        final index = lista.indexWhere((p) => p.id == participante.id);
        if (index != -1) {
          lista[index] = participante;
        }
      }
      return;
    }
    
    await _firestore!.collection('participantes')
        .doc(participante.id)
        .update(participante.toMap());
    _syncParticipantesToChatbot(participante.rifaId);
  }

  Future<void> eliminarParticipante(String id, String rifaId, List<String> numeros) async {
    if (_useLocalData) {
      _localParticipantes[rifaId]?.removeWhere((p) => p.id == id);
      
      for (final num in numeros) {
        if (_localNumeros[rifaId]!.containsKey(num)) {
          _localNumeros[rifaId]![num] = Numero(
            numero: num,
            estado: EstadoNumero.disponible,
            rifaId: rifaId,
          );
        }
      }
      return;
    }
    
    final batch = _firestore!.batch();
    batch.delete(_firestore!.collection('participantes').doc(id));
    for (final num in numeros) {
      final numRef = _firestore!.collection('rifas').doc(rifaId).collection('numeros').doc(num);
      batch.set(numRef, {
        'estado': 'disponible',
        'participanteId': '',
        'rifaId': rifaId,
      });
    }
    await batch.commit();
  }

  Future<Map<String, Numero>> getNumeros(String rifaId) async {
    if (_useLocalData) {
      return _localNumeros[rifaId] ?? {};
    }
    
    final snapshot = await _firestore!.collection('rifas').doc(rifaId).collection('numeros').get();
    final Map<String, Numero> numeros = {};
    for (final doc in snapshot.docs) {
      numeros[doc.id] = Numero.fromMap(doc.data(), doc.id);
    }
    return numeros;
  }

  Stream<Map<String, Numero>> getNumerosStream(String rifaId) {
    if (_useLocalData) {
      return Stream.value(_localNumeros[rifaId] ?? {});
    }
    
    return _firestore!.collection('rifas').doc(rifaId).collection('numeros')
        .snapshots()
        .map((snapshot) {
          final Map<String, Numero> numeros = {};
          for (final doc in snapshot.docs) {
            numeros[doc.id] = Numero.fromMap(doc.data(), doc.id);
          }
          return numeros;
        });
  }

  Future<void> actualizarNumero(String rifaId, String numero, Numero numObj) async {
    if (_useLocalData) {
      if (_localNumeros[rifaId] != null) {
        _localNumeros[rifaId]![numero] = numObj;
      }
      return;
    }
    
    await _firestore!.collection('rifas').doc(rifaId).collection('numeros')
        .doc(numero)
        .set(numObj.toMap());
  }

  Future<void> reservarNumeros(String rifaId, List<String> numeros, String participanteId) async {
    if (_useLocalData) {
      for (final num in numeros) {
        if (_localNumeros[rifaId]!.containsKey(num)) {
          _localNumeros[rifaId]![num] = Numero(
            numero: num,
            estado: EstadoNumero.reservado,
            participanteId: participanteId,
            rifaId: rifaId,
          );
        }
      }
      return;
    }
    
    final batch = _firestore!.batch();
    for (final num in numeros) {
      final docRef = _firestore!.collection('rifas').doc(rifaId).collection('numeros').doc(num);
      batch.set(docRef, {
        'estado': 'reservado',
        'participanteId': participanteId,
        'rifaId': rifaId,
      });
    }
    await batch.commit();
  }

  Future<bool> loginAdmin(String email, String password) async {
    if (_useLocalData) {
      return email == 'admin@rifadorada.com' && password == 'admin123';
    }
    
    try {
      await _auth!.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    if (!_useLocalData) {
      await _auth!.signOut();
    }
  }

  bool isLoggedIn() {
    if (_useLocalData) {
      return false;
    }
    return _auth?.currentUser != null;
  }

  Map<String, dynamic> getEstadisticas(String rifaId, double precioNumero) {
    if (_useLocalData) {
      final participantes = _localParticipantes[rifaId] ?? [];
      final numerosMap = _localNumeros[rifaId] ?? {};
      
      final vendidos = numerosMap.values.where((n) => n.estaOcupado || n.estaPagado).length;
      final disponibles = numerosMap.values.where((n) => n.estaDisponible).length;
      final totalVendido = participantes
          .where((p) => p.estaPagado)
          .fold(0.0, (acc, p) => acc + p.totalPagado);
      final pendientePago = participantes
          .where((p) => !p.estaPagado)
          .fold(0.0, (acc, p) => acc + (p.numeros.length * precioNumero));
      
      return {
        'totalVendidos': vendidos,
        'totalDisponibles': disponibles,
        'totalVendido': totalVendido,
        'pendientePago': pendientePago,
        'participantesPagados': participantes.where((p) => p.estaPagado).length,
        'participantesPendientes': participantes.where((p) => !p.estaPagado).length,
      };
    }
    
    return {
      'totalVendidos': 0,
      'totalDisponibles': 0,
      'totalVendido': 0.0,
      'pendientePago': 0.0,
      'participantesPagados': 0,
      'participantesPendientes': 0,
    };
  }

  Future<String> exportarDatosCSV(String rifaId, String nombreRifa) async {
    List<Participante> participantes;
    if (_useLocalData) {
      participantes = _localParticipantes[rifaId] ?? [];
    } else {
      final snapshot = await _firestore!
          .collection('participantes')
          .where('rifaId', isEqualTo: rifaId)
          .get();
      participantes = snapshot.docs
          .map((doc) => Participante.fromMap(doc.data(), doc.id))
          .toList();
    }

    if (participantes.isEmpty) return '';

    final buffer = StringBuffer();
    // Añadir BOM para que Excel reconozca caracteres especiales (tildes, ñ) en español
    buffer.write('\uFEFF');
    // Encabezados con nombres profesionales
    buffer.writeln('Nombre,WhatsApp,Ciudad,Documento,Números,Estado de Pago,Total,Fecha de Registro');
    
    for (final p in participantes) {
      final estado = p.estadoPago == EstadoPago.pagado ? 'Pagado' : 'Pendiente';
      final fecha = DateFormat('dd/MM/yyyy HH:mm').format(p.fechaRegistro);
      
      buffer.writeln(
        '"${p.nombre}","${p.whatsapp}","${p.ciudad}","${p.documento ?? ''}","${p.numerosString}","$estado","${p.totalPagado}","$fecha"'
      );
    }
    
    return buffer.toString();
  }

  Future<void> _syncRifasToChatbot() async {
    if (_useLocalData) return;
    try {
      final rifas = await _firestore!.collection('rifas')
          .where('activa', isEqualTo: true)
          .get();
      final rifasData = rifas.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['nombre'] ?? '',
          'description': data['descripcion'] ?? '',
          'ticketPrice': (data['precioNumero'] ?? 0).toDouble(),
          'totalTickets': data['cantidadNumeros'] ?? 0,
          'deadline': data['fechaSorteo'] != null 
              ? data['fechaSorteo'] 
              : null,
          'active': data['activa'] ?? true,
          'soldTickets': <int>[],
        };
      }).toList();

      await http.post(
        Uri.parse('${AppConstants.chatbotApi}/sync/rifas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rifas': rifasData}),
      );
      debugPrint('[SYNC] Rifas enviadas al chatbot');
    } catch (e) {
      debugPrint('[SYNC] Error enviando rifas al chatbot: $e');
    }
  }

  Future<void> _syncParticipantesToChatbot(String rifaId) async {
    if (_useLocalData) return;
    try {
      final snapshot = await _firestore!.collection('participantes')
          .where('rifaId', isEqualTo: rifaId)
          .get();
      final participantesData = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'rifaId': data['rifaId'] ?? '',
          'nombre': data['nombre'] ?? '',
          'whatsapp': data['whatsapp'] ?? '',
          'ciudad': data['ciudad'] ?? '',
          'numeros': List<String>.from(data['numeros'] ?? []),
          'estadoPago': data['estadoPago'] ?? 'pendiente',
          'totalPagado': (data['totalPagado'] ?? 0).toDouble(),
          'fechaRegistro': data['fechaRegistro'] ?? DateTime.now().toIso8601String(),
        };
      }).toList();

      await http.post(
        Uri.parse('${AppConstants.chatbotApi}/sync/participantes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'participantes': participantesData}),
      );
      debugPrint('[SYNC] Participantes de rifa $rifaId enviados al chatbot');
    } catch (e) {
      debugPrint('[SYNC] Error enviando participantes al chatbot: $e');
    }
  }

  Future<void> _notifySaleToChatbot(String rifaId, List<String> numeros, Participante participante, double total) async {
    try {
      final estadoPago = participante.estadoPago == EstadoPago.pagado ? 'pagado' : 'pendiente';
      final restante = total - participante.totalPagado;
      final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      final config = await getAppConfig();
      final cuenta = (config?.numeroCuenta ?? '').trim();
      final metodo = config?.metodoPago ?? 'nequi';
      final labelCuenta = cuenta.isNotEmpty ? '$cuenta (*${metodo.toUpperCase()}*)' : '—';

      final estadoIcono = estadoPago == 'pagado' ? '✅' : '⏳';
      final estadoTexto = estadoPago == 'pagado' ? 'PAGADO' : 'PENDIENTE';
      final mensajeTicket = [
        '🎫 *RIFADORADA — TICKET*',
        '━━━━━━━━━━━━━━━━━━━━━━━',
        '🏆 *Rifa:* ${participante.rifaId}',
        '📅 ${fecha}',
        '',
        '👤 *${participante.nombre}*',
        '📱 ${participante.whatsappFormateado}',
        '📍 ${participante.ciudad}',
        '',
        '🎯 *Números:* ${numeros.join(', ')}',
        '',
        '━━ 💰 PAGO ━━',
        '*Total:* \$${total.toStringAsFixed(0)} COP',
        '*Pagado:* \$${participante.totalPagado.toStringAsFixed(0)} COP',
        if (restante > 0) '*Restante:* \$${restante.toStringAsFixed(0)} COP',
        '*Estado:* ${estadoIcono} ${estadoTexto}',
        '',
        '━━ 📌 ━━',
        '1. Transfiere a $labelCuenta',
        '2. Envía el comprobante por este chat',
        '3. ¡Listo! Ya participas',
        '',
        '📞 _¿Dudas? Escribe y te ayudamos_',
        '',
        '🍀 *¡Mucha suerte!*',
      ].join('\n');

      await http.post(
        Uri.parse('${AppConstants.chatbotApi}/send/wa'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'number': participante.whatsappFormateado,
          'message': mensajeTicket,
        }),
      );
      debugPrint('[SYNC] Ticket enviado al cliente por WhatsApp');
    } catch (e) {
      debugPrint('[SYNC] Error enviando ticket al chatbot: $e');
    }
  }

  Future<bool> enviarTicketConImagen(String whatsapp, String message, String? imageBase64) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.chatbotApi}/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'number': whatsapp,
          'message': message,
          'imageBase64': imageBase64,
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('[SYNC] Ticket con imagen enviado al cliente');
        return true;
      }
      debugPrint('[SYNC] Error: chatbot respondió ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('[SYNC] Error enviando ticket con imagen: $e');
      return false;
    }
  }

  Future<void> _notifyAbonoToChatbot({
    required String rifaId,
    required String whatsapp,
    required double monto,
    required String metodoPago,
    required String nombre,
    required List<String> numeros,
    required double total,
    required double totalPagado,
    required List<Map<String, dynamic>> abonos,
  }) async {
    try {
      await http.post(
        Uri.parse('${AppConstants.chatbotApi}/sync/abono'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'whatsapp': whatsapp,
          'rifaId': rifaId,
          'monto': monto,
          'metodoPago': metodoPago,
          'nombre': nombre,
          'numeros': numeros,
          'total': total,
          'totalPagado': totalPagado,
          'abonos': abonos,
        }),
      );
      debugPrint('[SYNC] Abono notificado al chatbot');
    } catch (e) {
      debugPrint('[SYNC] Error notificando abono al chatbot: $e');
    }
  }

  Future<void> syncAllToChatbot() async {
    await _syncRifasToChatbot();
    if (_useLocalData) {
      for (final rifa in _localRifas) {
        await _syncParticipantesToChatbot(rifa.id);
      }
    } else {
      final rifaDocs = await _firestore!.collection('rifas').get();
      for (final doc in rifaDocs.docs) {
        await _syncParticipantesToChatbot(doc.id);
      }
    }
  }

  Future<void> notificarAbonoAlChatbot({
    required String rifaId,
    required String whatsapp,
    required double monto,
    required String metodoPago,
    required String nombre,
    required List<String> numeros,
    required double total,
    required double totalPagado,
    required List<Map<String, dynamic>> abonos,
  }) async {
    await _notifyAbonoToChatbot(
      rifaId: rifaId,
      whatsapp: whatsapp,
      monto: monto,
      metodoPago: metodoPago,
      nombre: nombre,
      numeros: numeros,
      total: total,
      totalPagado: totalPagado,
      abonos: abonos,
    );
    await _syncParticipantesToChatbot(rifaId);
  }

  Future<void> reenviarTicket(String rifaId, String whatsapp) async {
    try {
      await http.post(
        Uri.parse('${AppConstants.chatbotApi}/send/ticket'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'whatsapp': whatsapp,
          'rifaId': rifaId,
        }),
      );
      debugPrint('[SYNC] Ticket reenviado al chatbot');
    } catch (e) {
      debugPrint('[SYNC] Error reenviando ticket al chatbot: $e');
    }
  }

  Future<void> enviarMensajePersonalizado(String whatsapp, String mensaje) async {
    try {
      await http.post(
        Uri.parse('${AppConstants.chatbotApi}/send/custom'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'whatsapp': whatsapp,
          'message': mensaje,
        }),
      );
      debugPrint('[SYNC] Mensaje personalizado enviado');
    } catch (e) {
      debugPrint('[SYNC] Error enviando mensaje personalizado: $e');
    }
  }

  Future<AppConfig?> getAppConfig() async {
    if (_useLocalData) return null;
    try {
      final doc = await _firestore!.collection('config').doc('app').get();
      if (doc.exists) {
        return AppConfig.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('[CONFIG] Error obteniendo configuración: $e');
      return null;
    }
  }

  Future<void> updateAppConfig(AppConfig config) async {
    if (_useLocalData) return;
    try {
      await _firestore!.collection('config').doc('app').set(config.toMap());
      debugPrint('[CONFIG] Configuración guardada');
    } catch (e) {
      debugPrint('[CONFIG] Error guardando configuración: $e');
      rethrow;
    }
  }
}