class Rifa {
  final String id;
  final String nombre;
  final String descripcion;
  final double precioNumero;
  final int cantidadNumeros;
  final String tipoRifa;
  final bool activa;
  final DateTime fechaCreacion;
  final DateTime? fechaSorteo;
  final String? numeroGanador;
  
  final String? loteria;
  final String? diaSorteo;
  final List<String> imagenes;
  final String? responsable;
  final String? contactoResponsable;
  final String? organizacion;
  final String? organizacionId;
  final String? creadoPor;
  final String? vendedorId;

  Rifa({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioNumero,
    required this.cantidadNumeros,
    required this.tipoRifa,
    this.activa = true,
    required this.fechaCreacion,
    this.fechaSorteo,
    this.numeroGanador,
    this.loteria,
    this.diaSorteo,
    this.imagenes = const [],
    this.responsable,
    this.contactoResponsable,
    this.organizacion,
    this.organizacionId,
    this.creadoPor,
    this.vendedorId,
  });

  factory Rifa.fromMap(Map<String, dynamic> map, String id) {
    return Rifa(
      id: id,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      precioNumero: (map['precioNumero'] ?? 0).toDouble(),
      cantidadNumeros: map['cantidadNumeros'] ?? 0,
      tipoRifa: map['tipoRifa'] ?? '2 cifras',
      activa: map['activa'] ?? true,
      fechaCreacion: (map['fechaCreacion'] != null)
          ? DateTime.parse(map['fechaCreacion'])
          : DateTime.now(),
      fechaSorteo: map['fechaSorteo'] != null
          ? DateTime.parse(map['fechaSorteo'])
          : null,
      numeroGanador: map['numeroGanador'],
      loteria: map['loteria'],
      diaSorteo: map['diaSorteo'],
      imagenes: List<String>.from(map['imagenes'] ?? []),
      responsable: map['responsable'],
      contactoResponsable: map['contactoResponsable'],
      organizacion: map['organizacion'],
      organizacionId: map['organizacionId'],
      creadoPor: map['creadoPor'],
      vendedorId: map['vendedorId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precioNumero': precioNumero,
      'cantidadNumeros': cantidadNumeros,
      'tipoRifa': tipoRifa,
      'activa': activa,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaSorteo': fechaSorteo?.toIso8601String(),
      'numeroGanador': numeroGanador,
      'loteria': loteria,
      'diaSorteo': diaSorteo,
      'imagenes': imagenes,
      'responsable': responsable,
      'contactoResponsable': contactoResponsable,
      'organizacion': organizacion,
      'organizacionId': organizacionId,
      'creadoPor': creadoPor,
      'vendedorId': vendedorId,
    };
  }

  Rifa copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    double? precioNumero,
    int? cantidadNumeros,
    String? tipoRifa,
    bool? activa,
    DateTime? fechaCreacion,
    DateTime? fechaSorteo,
    String? numeroGanador,
    String? loteria,
    String? diaSorteo,
    List<String>? imagenes,
    String? responsable,
    String? contactoResponsable,
    String? organizacion,
    String? organizacionId,
    String? creadoPor,
    String? vendedorId,
  }) {
    return Rifa(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioNumero: precioNumero ?? this.precioNumero,
      cantidadNumeros: cantidadNumeros ?? this.cantidadNumeros,
      tipoRifa: tipoRifa ?? this.tipoRifa,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaSorteo: fechaSorteo ?? this.fechaSorteo,
      numeroGanador: numeroGanador ?? this.numeroGanador,
      loteria: loteria ?? this.loteria,
      diaSorteo: diaSorteo ?? this.diaSorteo,
      imagenes: imagenes ?? this.imagenes,
      responsable: responsable ?? this.responsable,
      contactoResponsable: contactoResponsable ?? this.contactoResponsable,
      organizacion: organizacion ?? this.organizacion,
      organizacionId: organizacionId ?? this.organizacionId,
      creadoPor: creadoPor ?? this.creadoPor,
      vendedorId: vendedorId ?? this.vendedorId,
    );
  }

  String get numeroDigitos {
    return tipoRifa == '3 cifras' ? '3' : '2';
  }

  String formatNumero(int numero) {
    final digitos = int.parse(numeroDigitos);
    return numero.toString().padLeft(digitos, '0');
  }

  String get infoLoterias {
    if (loteria != null && diaSorteo != null) {
      return '$loteria - $diaSorteo';
    } else if (loteria != null) {
      return loteria!;
    } else if (diaSorteo != null) {
      return diaSorteo!;
    }
    return '';
  }
}

class LoteriasColombia {
  static const List<String> principales = [
    'Baloto',
    'Chance MegaMillions',
    'Lotería de Bogotá',
    'Lotería de Medellín',
    'Lotería de Cali',
    'Lotería del Valle',
    'Lotería de Manizales',
    'Lotería de Bucaramanga',
    'Lotería de Cúcuta',
    'Lotería de Cartagena',
    'Lotería de Boyacá',
    'Lotería de Crisca',
    'Lotería del Quindío',
    'Lotería de Risaralda',
    'Lotería de Santander',
    'Lotería de Tolima',
    'Lotería del Huila',
    'Lotería del Cesar',
    'Lotería de la Cruz Roja',
    'Otra',
  ];

  static const List<String> diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
    'Diario',
  ];
}