import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rifa.dart';
import '../models/participante.dart';
import '../models/numero.dart';

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
  }

  Future<void> eliminarRifa(String id) async {
    if (_useLocalData) {
      _localRifas.removeWhere((r) => r.id == id);
      _localNumeros.remove(id);
      _localParticipantes.remove(id);
      return;
    }
    
    await _firestore!.collection('rifas').doc(id).delete();
  }

  Stream<List<Participante>> getParticipantes(String rifaId) {
    if (_useLocalData) {
      return Stream.value(_localParticipantes[rifaId] ?? []);
    }
    
    return _firestore!.collection('participantes')
        .where('rifaId', isEqualTo: rifaId)
        .orderBy('fechaRegistro', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Participante.fromMap(doc.data(), doc.id))
            .toList());
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
    
    await _firestore!.collection('participantes').doc(id).delete();
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
      
      final vendidos = numerosMap.values.where((n) => n.estaOcupado).length;
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
    if (_useLocalData) {
      final participantes = _localParticipantes[rifaId] ?? [];
      final buffer = StringBuffer();
      
      buffer.writeln('Nombre,Whatsapp,Ciudad,Documento,Numeros,EstadoPago,Total,Fecha');
      
      for (final p in participantes) {
        buffer.writeln(
          '"${p.nombre}","${p.whatsapp}","${p.ciudad}","${p.documento ?? ''}","${p.numerosString}","${p.estadoPago == EstadoPago.pagado ? 'Pagado' : 'Pendiente'}","${p.totalPagado}","${p.fechaRegistro.toIso8601String()}"'
        );
      }
      
      return buffer.toString();
    }
    
    return '';
  }
}