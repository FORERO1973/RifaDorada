import 'package:flutter/foundation.dart';
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
      _firebaseService.getParticipantes(rifaId).listen((participantes) {
        _participantes = participantes;
        _isLoading = false;
        notifyListeners();
      });
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

  Future<void> marcarPago(String participanteId, bool pagado) async {
    try {
      final participante = _participantes.firstWhere(
        (p) => p.id == participanteId,
      );
      final nuevoParticipante = participante.copyWith(
        estadoPago: pagado ? EstadoPago.pagado : EstadoPago.pendiente,
        totalPagado: pagado
            ? (participante.numeros.length * _rifaSeleccionada!.precioNumero)
            : 0,
      );

      await _firebaseService.actualizarParticipante(nuevoParticipante);
      
      // Actualizar estado de los números
      for (final num in participante.numeros) {
        final numeroObj = _numeros[num]?.copyWith(
          estado: pagado ? EstadoNumero.pagado : EstadoNumero.reservado,
        );
        if (numeroObj != null) {
          await _firebaseService.actualizarNumero(_rifaSeleccionada!.id, num, numeroObj);
        }
      }

      await loadParticipantes(_rifaSeleccionada!.id);
      await loadNumeros(_rifaSeleccionada!.id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> eliminarParticipante(String id, List<String> numeros) async {
    if (_rifaSeleccionada == null) return;

    try {
      await _firebaseService.eliminarParticipante(
        id,
        _rifaSeleccionada!.id,
        numeros,
      );
      await loadParticipantes(_rifaSeleccionada!.id);
      await loadNumeros(_rifaSeleccionada!.id);
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

    final vendidos = _numeros.values.where((n) => n.estaOcupado).length;
    final disponibles = _numeros.values.where((n) => n.estaDisponible).length;
    
    double totalVendido = 0;
    double pendientePago = 0;
    int pagadosCount = 0;
    int pendientesCount = 0;

    for (var p in _participantes) {
      if (p.estaPagado) {
        totalVendido += p.totalPagado;
        pagadosCount++;
      } else {
        pendientePago += (p.numeros.length * _rifaSeleccionada!.precioNumero);
        pendientesCount++;
      }
    }

    return {
      'totalVendidos': vendidos,
      'totalDisponibles': disponibles,
      'totalVendido': totalVendido,
      'pendientePago': pendientePago,
      'participantesPagados': pagadosCount,
      'participantesPendientes': pendientesCount,
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


  Future<String> exportarDatosCSV() async {
    if (_rifaSeleccionada == null) return '';

    return await _firebaseService.exportarDatosCSV(
      _rifaSeleccionada!.id,
      _rifaSeleccionada!.nombre,
    );
  }
}
