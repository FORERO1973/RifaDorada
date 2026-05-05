enum EstadoPago { pendiente, pagado }

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
  });

  factory Participante.fromMap(Map<String, dynamic> map, String id) {
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
          : EstadoPago.pendiente,
      fechaRegistro: (map['fechaRegistro'] != null)
          ? DateTime.parse(map['fechaRegistro'])
          : DateTime.now(),
      totalPagado: (map['totalPagado'] ?? 0).toDouble(),
      notas: map['notas'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rifaId': rifaId,
      'nombre': nombre,
      'whatsapp': whatsapp,
      'ciudad': ciudad,
      'documento': documento,
      'numeros': numeros,
      'estadoPago': estadoPago == EstadoPago.pagado ? 'pagado' : 'pendiente',
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'totalPagado': totalPagado,
      'notas': notas,
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
    );
  }

  bool get estaPagado => estadoPago == EstadoPago.pagado;

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