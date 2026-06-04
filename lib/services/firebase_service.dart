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

Map<String, String> _botHeaders() => {
  'Content-Type': 'application/json',
  if (AppConstants.botApiKey.isNotEmpty) 'X-API-Key': AppConstants.botApiKey,
};

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

  Stream<List<Rifa>> getRifas({String? organizacionId}) {
    if (_useLocalData) {
      return Stream.value(_localRifas);
    }

    var query = _firestore!.collection('rifas')
        .orderBy('fechaCreacion', descending: true);
    
    if (organizacionId != null) {
      query = query.where('organizacionId', isEqualTo: organizacionId);
    }

    return query.snapshots()
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

    // Pre-create all number documents so the subcollection is fully populated.
    // This prevents race conditions where concurrent transactions could both
    // create the same number document (Firestore read-before-write gap).
    final batch = _firestore!.batch();
    final digitos = rifa.tipoRifa == '3 cifras' ? 3 : 2;
    for (int i = 0; i < rifa.cantidadNumeros; i++) {
      final numStr = i.toString().padLeft(digitos, '0');
      final numRef = _firestore!.collection('rifas').doc(id).collection('numeros').doc(numStr);
      batch.set(numRef, {
        'estado': 'disponible',
        'participanteId': '',
        'rifaId': id,
      });
    }
    await batch.commit();

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

  Stream<List<Participante>> getParticipantes(String rifaId, {String? vendedorId}) {
    if (_useLocalData) {
      return Stream.value(_localParticipantes[rifaId] ?? []);
    }

    var query = _firestore!.collection('participantes')
        .where('rifaId', isEqualTo: rifaId);

    if (vendedorId != null) {
      query = query.where('vendedorId', isEqualTo: vendedorId);
    }

    return query.snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Participante.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<List<Participante>> getParticipantesOnce(String rifaId, {String? vendedorId}) async {
    if (_useLocalData) {
      return _localParticipantes[rifaId] ?? [];
    }

    var query = _firestore!.collection('participantes')
        .where('rifaId', isEqualTo: rifaId);

    if (vendedorId != null) {
      query = query.where('vendedorId', isEqualTo: vendedorId);
    }

    final snapshot = await query.get();
    
    final results = snapshot.docs
        .map((doc) => Participante.fromMap(doc.data(), doc.id))
        .toList();
    
    results.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
    return results;
  }

  Future<List<Participante>> getAllParticipantes(List<String> rifaIds) async {
    if (_useLocalData || rifaIds.isEmpty) return [];
    try {
      final List<Participante> all = [];
      for (final id in rifaIds) {
        try {
          final snapshot = await _firestore!
              .collection('participantes')
              .where('rifaId', isEqualTo: id)
              .get();
          all.addAll(snapshot.docs
              .map((doc) => Participante.fromMap(doc.data(), doc.id)));
        } catch (_) {}
      }
      all.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
      return all;
    } catch (e) {
      debugPrint('[FIREBASE] Error getting all participantes: $e');
      return [];
    }
  }

  Future<String> registrarParticipante(Participante participante) async {
    final id = _generateId();
    
    if (_useLocalData) {
      // Check local numbers first to prevent race condition/double reservation
      for (final num in participante.numeros) {
        if (_localNumeros[participante.rifaId] != null &&
            _localNumeros[participante.rifaId]!.containsKey(num)) {
          final numObj = _localNumeros[participante.rifaId]![num]!;
          if (numObj.estaOcupado) {
            throw Exception('El número $num ya se encuentra ocupado.');
          }
        }
      }

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
    
    final participanteConId = participante.copyWith(id: id);

    // Atomic transaction for Firestore
    await _firestore!.runTransaction((transaction) async {
      // 1. Read and check all requested numbers
      for (final num in participante.numeros) {
        final docRef = _firestore!
            .collection('rifas')
            .doc(participante.rifaId)
            .collection('numeros')
            .doc(num);
        
        final docSnapshot = await transaction.get(docRef);
        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          final estado = data?['estado'] as String?;
          if (estado == 'reservado' || estado == 'pagado' || estado == 'ocupado') {
            throw Exception('El número $num ya se encuentra ocupado por otra compra simultánea.');
          }
        }
      }

      // 2. Set participant document
      final partRef = _firestore!.collection('participantes').doc(id);
      transaction.set(partRef, participanteConId.toMap());

      // 3. Update the state of all requested numbers
      for (final num in participante.numeros) {
        final docRef = _firestore!
            .collection('rifas')
            .doc(participante.rifaId)
            .collection('numeros')
            .doc(num);
        
        transaction.set(docRef, {
          'estado': participante.estadoPago == EstadoPago.pagado ? 'pagado' : 'reservado',
          'participanteId': id,
          'rifaId': participante.rifaId,
        });
      }
    });

    // Sync and notify outside the transaction block
    _syncParticipantesToChatbot(participante.rifaId);
    final rifa = await getRifa(participante.rifaId);
    final total = rifa != null ? rifa.precioNumero * participante.numeros.length : 0.0;
    _notifySaleToChatbot(participante.rifaId, participante.numeros, participanteConId, total);
    
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

    // Reconcile: ensure numbers referenced by participants exist in the subcollection.
    // This fixes data from before numbers were pre-created on rifa creation.
    final participantes = await _firestore!
        .collection('participantes')
        .where('rifaId', isEqualTo: rifaId)
        .get();
    bool needsRepair = false;
    final batch = _firestore!.batch();
    for (final doc in participantes.docs) {
      final data = doc.data();
      final nums = data['numeros'] as List? ?? [];
      for (final num in nums) {
        final numStr = num.toString();
        if (!numeros.containsKey(numStr)) {
          needsRepair = true;
          final numRef = _firestore!.collection('rifas').doc(rifaId).collection('numeros').doc(numStr);
          batch.set(numRef, {
            'estado': 'reservado',
            'participanteId': doc.id,
            'rifaId': rifaId,
          });
          numeros[numStr] = Numero(
            numero: numStr,
            estado: EstadoNumero.reservado,
            participanteId: doc.id,
            rifaId: rifaId,
          );
        }
      }
    }
    if (needsRepair) {
      await batch.commit();
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

  Future<Map<String, dynamic>> getFirebaseRifaStats(String rifaId, double precioNumero) async {
    if (_useLocalData) {
      return getEstadisticas(rifaId, precioNumero);
    }

    try {
      int pagados = 0, reservados = 0, disponibles = 0;
      try {
        final numerosSnapshot = await _firestore!
            .collection('rifas').doc(rifaId).collection('numeros').get();
        for (final doc in numerosSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final estado = data['estado'] as String?;
          if (estado == 'pagado') {
            pagados++;
          } else if (estado == 'reservado') {
            reservados++;
          } else {
            disponibles++;
          }
        }
      } catch (_) {}

      final participantesSnapshot = await _firestore!
          .collection('participantes')
          .where('rifaId', isEqualTo: rifaId)
          .get();

      int pPagados = 0, pAbonados = 0, pPendientes = 0;
      double totalRecaudado = 0;
      double pendientePago = 0;
      for (final doc in participantesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final estado = data['estadoPago'] as String?;
        final pagado = (data['totalPagado'] as num?)?.toDouble() ?? 0;
        totalRecaudado += pagado;
        if (estado == 'pagado') { pPagados++; }
        else if (estado == 'abonado') {
          pAbonados++;
          pendientePago += ((data['numeros'] as List?)?.length ?? 0) * precioNumero - pagado;
        }
        else {
          pPendientes++;
          pendientePago += ((data['numeros'] as List?)?.length ?? 0) * precioNumero;
        }
      }

      final vendidos = pagados + reservados;

      return {
        'totalVendidos': vendidos,
        'totalDisponibles': disponibles,
        'totalVendido': totalRecaudado,
        'pendientePago': pendientePago,
        'participantesPagados': pPagados,
        'participantesPendientes': pPendientes,
        'participantesAbonados': pAbonados,
        'numerosPagados': pagados,
        'numerosReservados': reservados,
      };
    } catch (e) {
      debugPrint('[FIREBASE] Error getting stats: $e');
      return {
        'totalVendidos': 0, 'totalDisponibles': 0,
        'totalVendido': 0.0, 'pendientePago': 0.0,
        'participantesPagados': 0, 'participantesPendientes': 0,
        'participantesAbonados': 0, 'numerosPagados': 0, 'numerosReservados': 0,
      };
    }
  }

  Future<Map<String, dynamic>> getFirebaseVendedorStats({String? organizacionId, String? rifaId}) async {
    if (_useLocalData) return {};
    try {
      Query query = _firestore!
          .collection('participantes');
      if (rifaId != null) {
        query = query.where('rifaId', isEqualTo: rifaId);
      }
      final snapshot = await query.get();

      // Collect unique rifaIds to fetch prices
      final Set<String> rifaIds = {};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final rid = data['rifaId'] as String?;
        if (rid != null) rifaIds.add(rid);
      }

      // Fetch rifa prices
      final Map<String, double> rifaPrices = {};
      for (final rid in rifaIds) {
        try {
          final rifaDoc = await _firestore!.collection('rifas').doc(rid).get();
          if (rifaDoc.exists) {
            final rifaData = rifaDoc.data();
            rifaPrices[rid] = (rifaData?['precioNumero'] as num?)?.toDouble() ?? 0;
          }
        } catch (_) {}
      }

      final Map<String, Map<String, dynamic>> vendedores = {};
      final Map<String, String> adminUidMap = {};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final vid = (data['vendedorId'] as String?)?.isNotEmpty == true ? data['vendedorId'] : 'admin';
        final creadoPor = data['creadoPor'] as String?;
        final estadoPago = data['estadoPago'] as String? ?? 'pendiente';
        final totalPagado = (data['totalPagado'] as num?)?.toDouble() ?? 0;
        final numCount = (data['numeros'] as List?)?.length ?? 0;
        final precio = rifaPrices[data['rifaId'] as String?] ?? 0;
        final valorTotal = numCount * precio;
        final pendiente = estadoPago == 'pagado' ? 0.0 : valorTotal - totalPagado;

        if (!vendedores.containsKey(vid)) {
          vendedores[vid] = {
            'vendedorId': vid,
            'nombre': vid,
            'totalParticipantes': 0,
            'totalRecaudado': 0.0,
            'totalPendiente': 0.0,
            'numerosVendidos': 0,
            'pagados': 0,
            'abonados': 0,
            'pendientes': 0,
          };
          if (vid == 'admin' && creadoPor != null) {
            adminUidMap[vid] = creadoPor;
          }
        }
        vendedores[vid]!['totalParticipantes'] = (vendedores[vid]!['totalParticipantes'] as int) + 1;
        vendedores[vid]!['totalRecaudado'] = (vendedores[vid]!['totalRecaudado'] as double) + totalPagado;
        vendedores[vid]!['totalPendiente'] = (vendedores[vid]!['totalPendiente'] as double) + pendiente;
        vendedores[vid]!['numerosVendidos'] = (vendedores[vid]!['numerosVendidos'] as int) + numCount;

        if (estadoPago == 'pagado') {
          vendedores[vid]!['pagados'] = (vendedores[vid]!['pagados'] as int) + 1;
        } else if (estadoPago == 'abonado') {
          vendedores[vid]!['abonados'] = (vendedores[vid]!['abonados'] as int) + 1;
        } else {
          vendedores[vid]!['pendientes'] = (vendedores[vid]!['pendientes'] as int) + 1;
        }
      }

      // Collect all UIDs to fetch: vendedor IDs + admin creadoPor
      final Set<String> uidsToFetch = {};
      for (final vid in vendedores.keys) {
        if (vid == 'admin') {
          final adminUid = adminUidMap['admin'];
          if (adminUid != null) uidsToFetch.add(adminUid);
        } else {
          uidsToFetch.add(vid);
        }
      }

      // Fetch user names
      final Map<String, String> uidToName = {};
      for (final uid in uidsToFetch) {
        try {
          final userDoc = await _firestore!.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            final userName = userData?['nombre'] as String?;
            if (userName != null) uidToName[uid] = userName;
          }
        } catch (_) {}
      }

      // Apply resolved names
      for (final entry in vendedores.entries) {
        final vid = entry.key;
        if (vid == 'admin') {
          final adminUid = adminUidMap['admin'];
          if (adminUid != null && uidToName.containsKey(adminUid)) {
            entry.value['nombre'] = uidToName[adminUid]!;
          } else {
            entry.value['nombre'] = 'Admin';
          }
        } else if (uidToName.containsKey(vid)) {
          entry.value['nombre'] = uidToName[vid]!;
        }
      }

      return {'vendedores': vendedores.values.toList()};
    } catch (e) {
      debugPrint('[FIREBASE] Error getting vendedor stats: $e');
      return {'vendedores': <Map<String, dynamic>>[]};
    }
  }

  Future<Map<String, dynamic>> getPaymentMethodStats(String rifaId) async {
    if (_useLocalData) return {};
    try {
      final snapshot = await _firestore!
          .collection('participantes')
          .where('rifaId', isEqualTo: rifaId)
          .get();

      final Map<String, int> methods = {};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final estadoPago = data['estadoPago'] as String?;
        if (estadoPago == 'pagado' || estadoPago == 'abonado') {
          final metodo = data['metodoPago'] as String? ?? 'efectivo';
          methods[metodo] = (methods[metodo] ?? 0) + 1;
        }

        final abonos = data['abonos'];
        if (abonos is Map) {
          for (final abonoEntry in abonos.entries) {
            final abono = abonoEntry.value as Map?;
            if (abono != null) {
              final metodo = abono['metodoPago'] as String? ?? 'efectivo';
              methods[metodo] = (methods[metodo] ?? 0) + 1;
            }
          }
        } else if (abonos is List) {
          for (final abono in abonos) {
            final metodo = (abono as Map)['metodoPago'] as String? ?? 'efectivo';
            methods[metodo] = (methods[metodo] ?? 0) + 1;
          }
        }
      }
      return {'methods': methods};
    } catch (e) {
      debugPrint('[FIREBASE] Error getting payment stats: $e');
      return {'methods': <String, int>{}};
    }
  }

  Future<Map<String, dynamic>> getPaymentMethodStatsGlobal(List<String> rifaIds) async {
    if (_useLocalData || rifaIds.isEmpty) return {};
    try {
      final Map<String, int> methods = {};
      for (final rifaId in rifaIds) {
        try {
          final snapshot = await _firestore!
              .collection('participantes')
              .where('rifaId', isEqualTo: rifaId)
              .get();
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;

            final estadoPago = data['estadoPago'] as String?;
            if (estadoPago == 'pagado' || estadoPago == 'abonado') {
              final metodo = data['metodoPago'] as String? ?? 'efectivo';
              methods[metodo] = (methods[metodo] ?? 0) + 1;
            }

            final abonos = data['abonos'];
            if (abonos is Map) {
              for (final abonoEntry in abonos.entries) {
                final abono = abonoEntry.value as Map?;
                if (abono != null) {
                  final metodo = abono['metodoPago'] as String? ?? 'efectivo';
                  methods[metodo] = (methods[metodo] ?? 0) + 1;
                }
              }
            } else if (abonos is List) {
              for (final abono in abonos) {
                final metodo = (abono as Map)['metodoPago'] as String? ?? 'efectivo';
                methods[metodo] = (methods[metodo] ?? 0) + 1;
              }
            }
          }
        } catch (_) {}
      }
      return {'methods': methods};
    } catch (e) {
      debugPrint('[FIREBASE] Error getting global payment stats: $e');
      return {'methods': <String, int>{}};
    }
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

  Future<String> exportarDatosCSV(String rifaId, String nombreRifa, {String? vendedorId}) async {
    List<Participante> participantes;
    Rifa? rifa;
    if (_useLocalData) {
      participantes = _localParticipantes[rifaId] ?? [];
      try { rifa = _localRifas.firstWhere((r) => r.id == rifaId); } catch (_) {}
    } else {
      Query<Map<String, dynamic>> query = _firestore!
          .collection('participantes')
          .where('rifaId', isEqualTo: rifaId);
      if (vendedorId != null) {
        query = query.where('creadoPor', isEqualTo: vendedorId);
      }
      final snapshot = await query.get();
      participantes = snapshot.docs
          .map((doc) => Participante.fromMap(doc.data(), doc.id))
          .toList();
      rifa = await getRifa(rifaId);
    }

    if (participantes.isEmpty) return '';

    participantes.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
    final precio = rifa?.precioNumero ?? 0;
    final pagados = participantes.where((p) => p.estaPagado);
    final abonados = participantes.where((p) => p.estaAbonado && !p.estaPagado);
    final pendientes = participantes.where((p) => !p.estaAbonado && !p.estaPagado);
    final totalRecaudado = pagados.fold(0.0, (s, p) => s + p.totalPagado) +
        abonados.fold(0.0, (s, p) => s + p.totalPagado);
    final totalPendiente = pendientes.fold(0.0, (s, p) => s + p.numeros.length * precio)
        + abonados.fold(0.0, (s, p) => s + (p.numeros.length * precio - p.totalPagado));

    final vendidos = participantes.fold(0, (s, p) => s + p.numeros.length);
    final disponibles = (rifa?.cantidadNumeros ?? 0) - vendidos;
    final pct = (rifa?.cantidadNumeros ?? 0) > 0
        ? (vendidos * 100 / rifa!.cantidadNumeros).toStringAsFixed(0)
        : '0';

    final buffer = StringBuffer();
    buffer.write('\uFEFF');
    buffer.writeln('"REPORTE DE RIFA: $nombreRifa"');
    buffer.writeln('"Generado:", "${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}"');
    buffer.writeln('"Números vendidos:", "$vendidos / ${rifa?.cantidadNumeros ?? 0} ($pct%)"');
    buffer.writeln('"Números disponibles:", "$disponibles"');
    buffer.writeln('"Total participantes:", "${participantes.length}"');
    buffer.writeln('"Pagados:", "${pagados.length}"');
    buffer.writeln('"Abonados:", "${abonados.length}"');
    buffer.writeln('"Pendientes:", "${pendientes.length}"');
    buffer.writeln('"Total recaudado:", "${totalRecaudado.toStringAsFixed(0)}"');
    buffer.writeln('"Saldo pendiente:", "${totalPendiente.toStringAsFixed(0)}"');
    buffer.writeln('"Potencial total:", "${(totalRecaudado + totalPendiente).toStringAsFixed(0)}"');
    buffer.writeln('');
    buffer.writeln('Nombre,WhatsApp,Ciudad,Documento,Números,Estado,Total Pagado,Valor Total,Abonos,Fecha Registro');
    
    for (final p in participantes) {
      final estado = p.estadoPago == EstadoPago.pagado ? 'Pagado' 
          : p.estadoPago == EstadoPago.abonado ? 'Abonado' : 'Pendiente';
      final totalValor = p.numeros.length * precio;
      final fecha = DateFormat('dd/MM/yyyy HH:mm').format(p.fechaRegistro);
      final abonosCount = p.abonos.length;
      
      String sanitize(dynamic v) {
        final s = v.toString();
        if (s.startsWith('=') || s.startsWith('+') || s.startsWith('-') || s.startsWith('@') || s.startsWith('|')) {
          return "'$s";
        }
        return s;
      }
      buffer.writeln(
        '"${sanitize(p.nombre)}","${sanitize(p.whatsapp)}","${sanitize(p.ciudad)}","${sanitize(p.documento ?? '')}","${sanitize(p.numerosString)}","$estado","${p.totalPagado.toStringAsFixed(0)}","${totalValor.toStringAsFixed(0)}","$abonosCount","$fecha"'
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
          'organizacionId': data['organizacionId'] ?? '',
          'name': data['nombre'] ?? '',
          'description': data['descripcion'] ?? '',
          'ticketPrice': (data['precioNumero'] ?? 0).toDouble(),
          'totalTickets': data['cantidadNumeros'] ?? 0,
          'deadline': data['fechaSorteo'],
          'active': data['activa'] ?? true,
          'soldTickets': <int>[],
        };
      }).toList();

      await http.post(
        Uri.parse('${AppConstants.chatbotApi}/sync/rifas'),
        headers: _botHeaders(),
        body: jsonEncode({'rifas': rifasData}),
      );
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
          'organizacionId': data['organizacionId'] ?? '',
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
        headers: _botHeaders(),
        body: jsonEncode({'participantes': participantesData}),
      );
      debugPrint('[SYNC] Participantes de rifa $rifaId enviados al chatbot');
    } catch (e) {
      debugPrint('[SYNC] Error enviando participantes al chatbot: $e');
    }
  }

  Future<void> _notifySaleToChatbot(String rifaId, List<String> numeros, Participante participante, double total) async {
    if (participante.botNotified) return;

    try {
      final estadoPago = participante.estadoPago == EstadoPago.pagado ? 'pagado' : 'pendiente';
      final restante = total - participante.totalPagado;
      final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      final config = await getAppConfig(organizacionId: participante.organizacionId);
      final cuenta = (config?.numeroCuenta ?? '').trim();
      final metodo = config?.metodoPago ?? 'nequi';
      final labelCuenta = cuenta.isNotEmpty ? '$cuenta (*${metodo.toUpperCase()}*)' : '—';

      final estadoIcono = estadoPago == 'pagado' ? '✅' : '⏳';
      final estadoTexto = estadoPago == 'pagado' ? 'PAGADO' : 'PENDIENTE';
      final mensajeTicket = [
        '🎫 *RIFADORADA — TICKET*',
        '━━━━━━━━━━━━━━━━━━━━━━━',
        '🏆 *Rifa:* ${participante.rifaId}',
        '📅 $fecha',
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
        '*Estado:* $estadoIcono $estadoTexto',
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

      // Retry up to 3 times
      int retries = 0;
      while (retries < 3) {
        try {
          final response = await http.post(
            Uri.parse('${AppConstants.chatbotApi}/send/wa'),
            headers: _botHeaders(),
            body: jsonEncode({
              'number': participante.whatsappFormateado,
              'message': mensajeTicket,
              'organizacionId': participante.organizacionId ?? '',
            }),
          );
          if (response.statusCode == 200) {
            debugPrint('[SYNC] Ticket enviado al cliente por WhatsApp');
            // Mark as notified
            await _firestore!
                .collection('participantes')
                .doc(participante.id)
                .update({'bot_notified': true});
            break;
          }
          debugPrint('[SYNC] Chatbot respondió ${response.statusCode}, reintento ${retries + 1}');
        } catch (e) {
          debugPrint('[SYNC] Error en intento ${retries + 1}: $e');
        }
        retries++;
        if (retries < 3) await Future.delayed(Duration(seconds: 1 << retries));
      }
    } catch (e) {
      debugPrint('[SYNC] Error en _notifySaleToChatbot: $e');
    }
  }

  Future<bool> enviarTicketConImagen(String whatsapp, String message, String? imageBase64) async {
    try {
      final sizeKB = (imageBase64?.length ?? 0) / 1024;
      debugPrint('[SYNC] Enviando ticket con imagen a $whatsapp (base64: ${sizeKB.toStringAsFixed(1)} KB)');

      final response = await http.post(
        Uri.parse('${AppConstants.chatbotApi}/messages'),
        headers: _botHeaders(),
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
      debugPrint('[SYNC] Error: chatbot respondió ${response.statusCode} - ${response.body}');
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
    String? organizacionId,
  }) async {
    try {
      await http.post(
        Uri.parse('${AppConstants.chatbotApi}/sync/abono'),
        headers: _botHeaders(),
        body: jsonEncode({
          'whatsapp': whatsapp,
          'rifaId': rifaId,
          'organizacionId': organizacionId ?? '',
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
    String? organizacionId,
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
      organizacionId: organizacionId,
    );
    await _syncParticipantesToChatbot(rifaId);
  }

  Future<void> reenviarTicket(String rifaId, String whatsapp, {String? organizacionId}) async {
    try {
      await http.post(
        Uri.parse('${AppConstants.chatbotApi}/send/ticket'),
        headers: _botHeaders(),
        body: jsonEncode({
          'whatsapp': whatsapp,
          'rifaId': rifaId,
          'organizacionId': organizacionId ?? '',
        }),
      );
      debugPrint('[SYNC] Ticket reenviado al chatbot');
    } catch (e) {
      debugPrint('[SYNC] Error reenviando ticket al chatbot: $e');
    }
  }

  Future<void> enviarMensajePersonalizado(String whatsapp, String mensaje, {String? organizacionId}) async {
    try {
      await http.post(
        Uri.parse('${AppConstants.chatbotApi}/send/custom'),
        headers: _botHeaders(),
        body: jsonEncode({
          'whatsapp': whatsapp,
          'message': mensaje,
          if (organizacionId != null) 'organizacionId': organizacionId,
        }),
      );
      debugPrint('[SYNC] Mensaje personalizado enviado');
    } catch (e) {
      debugPrint('[SYNC] Error enviando mensaje personalizado: $e');
    }
  }

  Future<AppConfig?> getAppConfig({String? organizacionId}) async {
    if (_useLocalData) return null;
    try {
      if (organizacionId != null) {
        final doc = await _firestore!.collection('organizaciones').doc(organizacionId).get();
        if (doc.exists) {
          final data = doc.data()!;
          return AppConfig(
            organizacion: data['nombre'] ?? '',
            responsable: data['responsable'] ?? '',
            telefono: data['telefono'] ?? '',
            email: data['email'] ?? '',
            numeroCuenta: data['numeroCuenta'] ?? '',
            metodoPago: data['metodoPago'] ?? 'nequi',
          );
        }
      }

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

  Future<void> updateAppConfig(AppConfig config, {String? organizacionId}) async {
    if (_useLocalData) return;
    try {
      if (organizacionId != null) {
        await _firestore!.collection('organizaciones').doc(organizacionId).update({
          'nombre': config.organizacion,
          'responsable': config.responsable,
          'telefono': config.telefono,
          'email': config.email,
          'numeroCuenta': config.numeroCuenta,
          'metodoPago': config.metodoPago,
        });
      } else {
        await _firestore!.collection('config').doc('app').set(config.toMap());
      }
      debugPrint('[CONFIG] Configuración guardada');
    } catch (e) {
      debugPrint('[CONFIG] Error guardando configuración: $e');
      rethrow;
    }
  }
}