class Organizacion {
  final String id;
  final String nombre;
  final String? nit;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? logo;
  final bool activa;
  final DateTime fechaCreacion;
  final String creadoPor;
  final String metodoPago;
  final String numeroCuenta;

  Organizacion({
    required this.id,
    required this.nombre,
    this.nit,
    this.telefono,
    this.email,
    this.direccion,
    this.logo,
    this.activa = true,
    required this.fechaCreacion,
    required this.creadoPor,
    this.metodoPago = 'nequi',
    this.numeroCuenta = '',
  });

  factory Organizacion.fromMap(Map<String, dynamic> map, String id) {
    return Organizacion(
      id: id,
      nombre: map['nombre'] ?? '',
      nit: map['nit'],
      telefono: map['telefono'],
      email: map['email'],
      direccion: map['direccion'],
      logo: map['logo'],
      activa: map['activa'] ?? true,
      fechaCreacion: map['fechaCreacion'] != null
          ? DateTime.parse(map['fechaCreacion'])
          : DateTime.now(),
      creadoPor: map['creadoPor'] ?? '',
      metodoPago: map['metodoPago'] ?? 'nequi',
      numeroCuenta: map['numeroCuenta'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'nit': nit,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'logo': logo,
      'activa': activa,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'creadoPor': creadoPor,
      'metodoPago': metodoPago,
      'numeroCuenta': numeroCuenta,
    };
  }

  Organizacion copyWith({
    String? id,
    String? nombre,
    String? nit,
    String? telefono,
    String? email,
    String? direccion,
    String? logo,
    bool? activa,
    DateTime? fechaCreacion,
    String? creadoPor,
    String? metodoPago,
    String? numeroCuenta,
  }) {
    return Organizacion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      nit: nit ?? this.nit,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      logo: logo ?? this.logo,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      creadoPor: creadoPor ?? this.creadoPor,
      metodoPago: metodoPago ?? this.metodoPago,
      numeroCuenta: numeroCuenta ?? this.numeroCuenta,
    );
  }
}
