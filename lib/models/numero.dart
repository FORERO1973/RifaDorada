enum EstadoNumero { disponible, reservado, pagado, seleccionado }

class Numero {
  final String numero;
  final EstadoNumero estado;
  final String? participanteId;
  final String? rifaId;

  Numero({
    required this.numero,
    this.estado = EstadoNumero.disponible,
    this.participanteId,
    this.rifaId,
  });

  factory Numero.fromMap(Map<String, dynamic> map, String numero) {
    EstadoNumero estado;
    switch (map['estado']) {
      case 'pagado':
        estado = EstadoNumero.pagado;
        break;
      case 'reservado':
      case 'ocupado': // Backward compatibility
        estado = EstadoNumero.reservado;
        break;
      default:
        estado = EstadoNumero.disponible;
    }
    return Numero(
      numero: numero,
      estado: estado,
      participanteId: map['participanteId'],
      rifaId: map['rifaId'],
    );
  }

  Map<String, dynamic> toMap() {
    String estadoStr;
    switch (estado) {
      case EstadoNumero.pagado:
        estadoStr = 'pagado';
        break;
      case EstadoNumero.reservado:
        estadoStr = 'reservado';
        break;
      default:
        estadoStr = 'disponible';
    }
    return {
      'estado': estadoStr,
      'participanteId': participanteId,
      'rifaId': rifaId,
    };
  }

  Numero copyWith({
    String? numero,
    EstadoNumero? estado,
    String? participanteId,
    String? rifaId,
  }) {
    return Numero(
      numero: numero ?? this.numero,
      estado: estado ?? this.estado,
      participanteId: participanteId ?? this.participanteId,
      rifaId: rifaId ?? this.rifaId,
    );
  }

  bool get estaDisponible => estado == EstadoNumero.disponible;
  bool get estaReservado => estado == EstadoNumero.reservado;
  bool get estaPagado => estado == EstadoNumero.pagado;
  bool get estaOcupado => estado == EstadoNumero.reservado || estado == EstadoNumero.pagado;
  bool get estaSeleccionado => estado == EstadoNumero.seleccionado;
}