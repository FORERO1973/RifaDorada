class AppConfig {
  final String organizacion;
  final String responsable;
  final String telefono;
  final String email;
  final String numeroCuenta;
  final String metodoPago;

  AppConfig({
    this.organizacion = '',
    this.responsable = '',
    this.telefono = '',
    this.email = '',
    this.numeroCuenta = '',
    this.metodoPago = 'nequi',
  });

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      organizacion: map['organizacion'] ?? '',
      responsable: map['responsable'] ?? '',
      telefono: map['telefono'] ?? '',
      email: map['email'] ?? '',
      numeroCuenta: map['numeroCuenta'] ?? '',
      metodoPago: map['metodoPago'] ?? 'nequi',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizacion': organizacion,
      'responsable': responsable,
      'telefono': telefono,
      'email': email,
      'numeroCuenta': numeroCuenta,
      'metodoPago': metodoPago,
    };
  }

  AppConfig copyWith({
    String? organizacion,
    String? responsable,
    String? telefono,
    String? email,
    String? numeroCuenta,
    String? metodoPago,
  }) {
    return AppConfig(
      organizacion: organizacion ?? this.organizacion,
      responsable: responsable ?? this.responsable,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      numeroCuenta: numeroCuenta ?? this.numeroCuenta,
      metodoPago: metodoPago ?? this.metodoPago,
    );
  }
}
