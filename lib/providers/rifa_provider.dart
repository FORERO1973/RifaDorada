import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/rifa.dart';
import '../models/participante.dart';
import '../models/numero.dart';
import '../services/firebase_service.dart';

class RifaProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;

  List<Rifa> _rifas = [];
  List<Rifa> get rifas => _rifas;

  // Forzado a true para facilitar pruebas y gestión de UI durante el desarrollo
  bool get isAdmin => true; 


  Rifa? _rifaSeleccionada;
  Rifa? get rifaSeleccionada => _rifaSeleccionada;

  List<Participante> _participantes = [];
  List<Participante> get participantes => _participantes;

  Map<String, Numero> _numeros = {};
  Map<String, Numero> get numeros => _numeros;

  final Set<String> _numerosSeleccionados = {};
  Set<String> get numerosSeleccionados => _numerosSeleccionados;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadRifas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _firebaseService.getRifas().listen((rifas) {
        _rifas = rifas;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setRifaSeleccionada(Rifa rifa) {
    _rifaSeleccionada = rifa;
    _numerosSeleccionados.clear();
    notifyListeners();
  }

  void clearRifaSeleccionada() {
    _rifaSeleccionada = null;
    _numerosSeleccionados.clear();
    _participantes.clear();
    _numeros = {};
    notifyListeners();
  }

  Future<void> loadNumeros(String rifaId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _numeros = await _firebaseService.getNumeros(rifaId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadNumerosStream(String rifaId) {
    _firebaseService.getNumerosStream(rifaId).listen((numeros) {
      _numeros = numeros;
      notifyListeners();
    });
  }

  void toggleNumeroSeleccion(String numero) {
    if (_numerosSeleccionados.contains(numero)) {
      _numerosSeleccionados.remove(numero);
    } else {
      final numActual = _numeros[numero];
      if (numActual == null || numActual.estaDisponible) {
        _numerosSeleccionados.add(numero);
      }
    }
    notifyListeners();
  }

  void clearSeleccion() {
    _numerosSeleccionados.clear();
    notifyListeners();
  }

  bool isNumeroSeleccionado(String numero) {
    return _numerosSeleccionados.contains(numero);
  }

  bool isNumeroDisponible(String numero) {
    final numActual = _numeros[numero];
    return numActual == null || numActual.estaDisponible;
  }

  bool isNumeroOcupado(String numero) {
    final numActual = _numeros[numero];
    return numActual != null && numActual.estaOcupado;
  }

  double get totalSeleccion {
    if (_rifaSeleccionada == null) return 0;
    return _numerosSeleccionados.length * _rifaSeleccionada!.precioNumero;
  }

  int get cantidadNumerosSeleccionados => _numerosSeleccionados.length;

  Future<void> loadParticipantes(String rifaId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final participantes = await _firebaseService.getParticipantesOnce(rifaId);
      _participantes = participantes;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> crearRifa(Rifa rifa) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await _firebaseService.crearRifa(rifa);
      await loadRifas();
      return id;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> actualizarRifa(Rifa rifa) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.actualizarRifa(rifa);
      await loadRifas();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setNumeroGanador(String rifaId, String numero) async {
    _isLoading = true;
    notifyListeners();

    try {
      final rifa = _rifas.firstWhere((r) => r.id == rifaId);
      final updatedRifa = rifa.copyWith(numeroGanador: numero, activa: false);
      await _firebaseService.actualizarRifa(updatedRifa);
      await loadRifas();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> eliminarRifa(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.eliminarRifa(id);
      await loadRifas();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> registrarParticipante({
    required String nombre,
    required String whatsapp,
    required String ciudad,
    String? documento,
  }) async {
    if (_rifaSeleccionada == null) {
      throw Exception('No hay rifa seleccionada');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final participante = Participante(
        id: '',
        rifaId: _rifaSeleccionada!.id,
        nombre: nombre,
        whatsapp: whatsapp,
        ciudad: ciudad,
        documento: documento,
        numeros: _numerosSeleccionados.toList(),
        estadoPago: EstadoPago.pendiente,
        fechaRegistro: DateTime.now(),
        totalPagado: 0,
        botNotified: false, // Iniciar en false para que el bot lo detecte
      );

      final id = await _firebaseService.registrarParticipante(participante);

      await _firebaseService.reservarNumeros(
        _rifaSeleccionada!.id,
        _numerosSeleccionados.toList(),
        id,
      );

      await loadNumeros(_rifaSeleccionada!.id);
      clearSeleccion();

      return id;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> registrarAbono({
    required String participanteId,
    required double monto,
    String? nota,
    String metodoPago = 'efectivo',
  }) async {
    if (_rifaSeleccionada == null) return;

    try {
      final participante = _participantes.firstWhere(
        (p) => p.id == participanteId,
      );

      final abonoId = DateTime.now().millisecondsSinceEpoch.toString();
      final abono = Abono(
        id: abonoId,
        fecha: DateTime.now(),
        monto: monto,
        nota: nota,
        metodoPago: metodoPago,
      );

      final historialId = DateTime.now().millisecondsSinceEpoch.toString();
      final historial = HistorialCambio(
        id: historialId,
        fecha: DateTime.now(),
        tipo: 'abono',
        descripcion: 'Abono registrado: \$${monto.toStringAsFixed(0)}',
        valorAnterior: participante.totalPagado,
        valorNuevo: participante.totalPagado + monto,
      );

      final nuevosAbonos = [...participante.abonos, abono];
      final nuevoHistorial = [...participante.historial, historial];
      final nuevoTotalPagado = participante.totalPagado + monto;
      final precioTotal = participante.numeros.length * _rifaSeleccionada!.precioNumero;

      EstadoPago nuevoEstado;
      if (nuevoTotalPagado >= precioTotal) {
        nuevoEstado = EstadoPago.pagado;
      } else if (nuevoTotalPagado > 0) {
        nuevoEstado = EstadoPago.abonado;
      } else {
        nuevoEstado = EstadoPago.pendiente;
      }

      final nuevoParticipante = participante.copyWith(
        abonos: nuevosAbonos,
        historial: nuevoHistorial,
        totalPagado: nuevoTotalPagado,
        estadoPago: nuevoEstado,
      );

      await _firebaseService.actualizarParticipante(nuevoParticipante);

      final abonosMap = nuevosAbonos.map((a) => {
        'fecha': a.fecha.toIso8601String(),
        'monto': a.monto,
        'metodoPago': a.metodoPago,
      }).toList();

      await _firebaseService.notificarAbonoAlChatbot(
        rifaId: _rifaSeleccionada!.id,
        whatsapp: participante.whatsappFormateado,
        monto: monto,
        metodoPago: metodoPago,
        nombre: participante.nombre,
        numeros: participante.numeros,
        total: precioTotal.toDouble(),
        totalPagado: nuevoTotalPagado,
        abonos: abonosMap,
      );

      if (nuevoEstado == EstadoPago.pagado && participante.estadoPago != EstadoPago.pagado) {
        for (final num in participante.numeros) {
          final numeroObj = _numeros[num]?.copyWith(estado: EstadoNumero.pagado);
          if (numeroObj != null) {
            await _firebaseService.actualizarNumero(_rifaSeleccionada!.id, num, numeroObj);
          }
        }
      }

      await loadParticipantes(_rifaSeleccionada!.id);
      await loadNumeros(_rifaSeleccionada!.id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> marcarPago(String participanteId, bool pagado, {String? rifaId, double? precioNumero}) async {
    try {
      final rid = rifaId ?? _rifaSeleccionada?.id;
      if (rid == null) return;

      if (rifaId != null && _rifaSeleccionada?.id != rifaId) {
        await loadParticipantes(rifaId);
        await loadNumeros(rifaId);
      }

      final participante = _participantes.firstWhere(
        (p) => p.id == participanteId,
      );

      final pNumero = precioNumero ?? _rifaSeleccionada?.precioNumero ?? 0;
      final historialId = DateTime.now().millisecondsSinceEpoch.toString();
      final historial = HistorialCambio(
        id: historialId,
        fecha: DateTime.now(),
        tipo: 'estado',
        descripcion:pagado ? 'Marcado como PAGADO' : 'Marcado como PENDIENTE',
        valorAnterior: participante.estadoPago.name,
        valorNuevo: pagado ? 'pagado' : 'pendiente',
      );

      final precioTotal = participante.numeros.length * pNumero;
      final nuevoParticipante = participante.copyWith(
        estadoPago: pagado ? EstadoPago.pagado : EstadoPago.pendiente,
        totalPagado: pagado ? precioTotal : 0,
        historial: [...participante.historial, historial],
      );

      await _firebaseService.actualizarParticipante(nuevoParticipante);
      
      for (final num in participante.numeros) {
        final numeroObj = _numeros[num]?.copyWith(
          estado: pagado ? EstadoNumero.pagado : EstadoNumero.reservado,
        );
        if (numeroObj != null) {
          await _firebaseService.actualizarNumero(rid, num, numeroObj);
        }
      }

      await loadParticipantes(rid);
      await loadNumeros(rid);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> eliminarParticipante(String id, List<String> numeros, {String? rifaId}) async {
    final rid = rifaId ?? _rifaSeleccionada?.id;
    if (rid == null) return;

    try {
      await _firebaseService.eliminarParticipante(id, rid, numeros);
      await loadParticipantes(rid);
      await loadNumeros(rid);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

Map<String, dynamic> getEstadisticas() {
    if (_rifaSeleccionada == null) {
      return {
        'totalVendidos': 0,
        'totalDisponibles': 0,
        'totalVendido': 0.0,
        'pendientePago': 0.0,
        'participantesPagados': 0,
        'participantesPendientes': 0,
      };
    }

    final vendidos = _numeros.values.where((n) => n.estaOcupado || n.estaPagado || n.estaReservado).length;
    // Cálculo corregido basado en la cantidad total de la rifa
    final disponibles = _rifaSeleccionada!.cantidadNumeros - vendidos;
    final pagadosCount = _numeros.values.where((n) => n.estaPagado).length;
    final reservadosCount = _numeros.values.where((n) => n.estaReservado).length;
    
    final totalVendido = pagadosCount * _rifaSeleccionada!.precioNumero;
    final pendientePago = reservadosCount * _rifaSeleccionada!.precioNumero;

    return {
      'totalVendidos': vendidos,
      'totalDisponibles': disponibles,
      'totalVendido': totalVendido,
      'pendientePago': pendientePago,
      'numerosPagados': pagadosCount,
      'numerosReservados': reservadosCount,
    };
  }

  Map<String, dynamic> getEstadisticasForRifa(String rifaId, double precioNumero) {
    // Si es la rifa seleccionada, usamos los datos en tiempo real
    if (_rifaSeleccionada?.id == rifaId) {
      return getEstadisticas();
    }
    
    // Si no, recurrimos al servicio (aunque lo ideal sería tener todos cargados)
    return _firebaseService.getEstadisticas(rifaId, precioNumero);
  }


  Future<void> exportarDatosCSV() async {
    if (_rifaSeleccionada == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final csvContent = await _firebaseService.exportarDatosCSV(
        _rifaSeleccionada!.id,
        _rifaSeleccionada!.nombre,
      );

      if (csvContent.isEmpty) {
        _error = 'No hay participantes registrados en esta rifa para exportar.';
        return;
      }

      final directory = await getTemporaryDirectory();
      // Nombre de archivo más profesional con fecha
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'Reporte_${_rifaSeleccionada!.nombre.replaceAll(' ', '_')}_$dateStr.csv';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsString(csvContent, encoding: utf8);

      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'text/csv')],
        subject: 'Reporte de Rifa: ${_rifaSeleccionada!.nombre}',
      );
    } catch (e) {
      _error = 'Error crítico al exportar: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
