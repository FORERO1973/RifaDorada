enum UserRol { superAdmin, orgAdmin, vendedor }

class UserModel {
  final String uid;
  final String email;
  final String nombre;
  final String? telefono;
  final UserRol rol;
  final String? organizacionId;
  final bool activo;
  final DateTime fechaCreacion;
  final DateTime? ultimoAcceso;

  UserModel({
    required this.uid,
    required this.email,
    required this.nombre,
    this.telefono,
    required this.rol,
    this.organizacionId,
    this.activo = true,
    required this.fechaCreacion,
    this.ultimoAcceso,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      nombre: map['nombre'] ?? '',
      telefono: map['telefono'],
      rol: _parseRol(map['rol']),
      organizacionId: map['organizacionId'],
      activo: map['activo'] ?? true,
      fechaCreacion: map['fechaCreacion'] != null
          ? DateTime.parse(map['fechaCreacion'])
          : DateTime.now(),
      ultimoAcceso: map['ultimoAcceso'] != null
          ? DateTime.parse(map['ultimoAcceso'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nombre': nombre,
      'telefono': telefono,
      'rol': rol.name,
      'organizacionId': organizacionId,
      'activo': activo,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'ultimoAcceso': ultimoAcceso?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? nombre,
    String? telefono,
    UserRol? rol,
    String? organizacionId,
    bool? activo,
    DateTime? fechaCreacion,
    DateTime? ultimoAcceso,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      rol: rol ?? this.rol,
      organizacionId: organizacionId ?? this.organizacionId,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      ultimoAcceso: ultimoAcceso ?? this.ultimoAcceso,
    );
  }

  bool get esAdmin => rol == UserRol.orgAdmin || rol == UserRol.superAdmin;
  bool get esVendedor => rol == UserRol.vendedor;
  bool get esSuperAdmin => rol == UserRol.superAdmin;
  bool get puedeGestionarPagos => esAdmin;
  bool get puedeEliminar => esAdmin;
  bool get puedeCrearRifas => esAdmin;

  static UserRol _parseRol(String? rol) {
    switch (rol) {
      case 'superAdmin':
        return UserRol.superAdmin;
      case 'orgAdmin':
        return UserRol.orgAdmin;
      case 'vendedor':
        return UserRol.vendedor;
      default:
        return UserRol.vendedor;
    }
  }
}
