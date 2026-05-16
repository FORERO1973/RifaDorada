enum EstadoPago { pendiente, pagado, abonado }

class Abono {
  final String id;
  final DateTime fecha;
  final double monto;
  final String? nota;
  final String metodoPago;

  Abono({
    required this.id,
    required this.fecha,
    required this.monto,
    this.nota,
    this.metodoPago = 'efectivo',
  });

  factory Abono.fromMap(Map<String, dynamic> map, String id) {
    return Abono(
      id: id,
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha']) : DateTime.now(),
      monto: (map['monto'] ?? 0).toDouble(),
      nota: map['nota'],
      metodoPago: map['metodoPago'] ?? 'efectivo',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha.toIso8601String(),
      'monto': monto,
      'nota': nota,
      'metodoPago': metodoPago,
    };
  }
}

class HistorialCambio {
  final String id;
  final DateTime fecha;
  final String tipo; // 'estado', 'abono', 'numero', 'nota'
  final String descripcion;
  final dynamic valorAnterior;
  final dynamic valorNuevo;

  HistorialCambio({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.descripcion,
    this.valorAnterior,
    this.valorNuevo,
  });

  factory HistorialCambio.fromMap(Map<String, dynamic> map, String id) {
    return HistorialCambio(
      id: id,
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha']) : DateTime.now(),
      tipo: map['tipo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      valorAnterior: map['valorAnterior'],
      valorNuevo: map['valorNuevo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha.toIso8601String(),
      'tipo': tipo,
      'descripcion': descripcion,
      'valorAnterior': valorAnterior,
      'valorNuevo': valorNuevo,
    };
  }
}

class Participante {
  final String id;
  final String rifaId;
  final String nombre;
  final String whatsapp;
  final String ciudad;
  final String? documento;
  final List<String> numeros;
  final EstadoPago estadoPago;
  final DateTime fechaRegistro;
  final double totalPagado;
  final String? notas;
  final List<Abono> abonos;
  final List<HistorialCambio> historial;
  final bool botNotified;
  final String? organizacionId;
  final String? creadoPor;
  final String? vendedorId;

  Participante({
    required this.id,
    required this.rifaId,
    required this.nombre,
    required this.whatsapp,
    required this.ciudad,
    this.documento,
    required this.numeros,
    this.estadoPago = EstadoPago.pendiente,
    required this.fechaRegistro,
    this.totalPagado = 0,
    this.notas,
    this.abonos = const [],
    this.historial = const [],
    this.botNotified = false,
    this.organizacionId,
    this.creadoPor,
    this.vendedorId,
  });

  factory Participante.fromMap(Map<String, dynamic> map, String id) {
    List<Abono> abonosList = [];
    if (map['abonos'] != null) {
      final abonosMap = map['abonos'] as Map<String, dynamic>;
      abonosList = abonosMap.entries
          .map((e) => Abono.fromMap(e.value as Map<String, dynamic>, e.key))
          .toList();
      abonosList.sort((a, b) => b.fecha.compareTo(a.fecha));
    }

    List<HistorialCambio> historialList = [];
    if (map['historial'] != null) {
      final historialMap = map['historial'] as Map<String, dynamic>;
      historialList = historialMap.entries
          .map((e) => HistorialCambio.fromMap(e.value as Map<String, dynamic>, e.key))
          .toList();
      historialList.sort((a, b) => b.fecha.compareTo(a.fecha));
    }

    return Participante(
      id: id,
      rifaId: map['rifaId'] ?? '',
      nombre: map['nombre'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      ciudad: map['ciudad'] ?? '',
      documento: map['documento'],
      numeros: List<String>.from(map['numeros'] ?? []),
      estadoPago: map['estadoPago'] == 'pagado'
          ? EstadoPago.pagado
          : map['estadoPago'] == 'abonado'
              ? EstadoPago.abonado
              : EstadoPago.pendiente,
      fechaRegistro: (map['fechaRegistro'] != null)
          ? DateTime.parse(map['fechaRegistro'])
          : DateTime.now(),
      totalPagado: (map['totalPagado'] ?? 0).toDouble(),
      notas: map['notas'],
      abonos: abonosList,
      historial: historialList,
      botNotified: map['bot_notified'] ?? false,
      organizacionId: map['organizacionId'],
      creadoPor: map['creadoPor'],
      vendedorId: map['vendedorId'],
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> abonosMap = {};
    for (var abono in abonos) {
      abonosMap[abono.id] = abono.toMap();
    }

    Map<String, dynamic> historialMap = {};
    for (var cambio in historial) {
      historialMap[cambio.id] = cambio.toMap();
    }

    return {
      'rifaId': rifaId,
      'nombre': nombre,
      'whatsapp': whatsapp,
      'ciudad': ciudad,
      'documento': documento,
      'numeros': numeros,
      'estadoPago': estadoPago == EstadoPago.pagado
          ? 'pagado'
          : estadoPago == EstadoPago.abonado
              ? 'abonado'
              : 'pendiente',
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'totalPagado': totalPagado,
      'notas': notas,
      'abonos': abonosMap,
      'historial': historialMap,
      'bot_notified': botNotified,
      'organizacionId': organizacionId,
      'creadoPor': creadoPor,
      'vendedorId': vendedorId,
    };
  }

  Participante copyWith({
    String? id,
    String? rifaId,
    String? nombre,
    String? whatsapp,
    String? ciudad,
    String? documento,
    List<String>? numeros,
    EstadoPago? estadoPago,
    DateTime? fechaRegistro,
    double? totalPagado,
    String? notas,
    List<Abono>? abonos,
    List<HistorialCambio>? historial,
    bool? botNotified,
    String? organizacionId,
    String? creadoPor,
    String? vendedorId,
  }) {
    return Participante(
      id: id ?? this.id,
      rifaId: rifaId ?? this.rifaId,
      nombre: nombre ?? this.nombre,
      whatsapp: whatsapp ?? this.whatsapp,
      ciudad: ciudad ?? this.ciudad,
      documento: documento ?? this.documento,
      numeros: numeros ?? this.numeros,
      estadoPago: estadoPago ?? this.estadoPago,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      totalPagado: totalPagado ?? this.totalPagado,
      notas: notas ?? this.notas,
      abonos: abonos ?? this.abonos,
      historial: historial ?? this.historial,
      botNotified: botNotified ?? this.botNotified,
      organizacionId: organizacionId ?? this.organizacionId,
      creadoPor: creadoPor ?? this.creadoPor,
      vendedorId: vendedorId ?? this.vendedorId,
    );
  }

  bool get estaPagado => estadoPago == EstadoPago.pagado;
  bool get tieneAbonos => abonos.isNotEmpty;
  bool get estaAbonado => estadoPago == EstadoPago.abonado || totalPagado > 0;

  String get numerosString => numeros.join(', ');

  String get whatsappFormateado {
    String cleaned = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    if (!cleaned.startsWith('57')) {
      cleaned = '57$cleaned';
    }
    return cleaned;
  }
}