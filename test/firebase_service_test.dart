import 'package:flutter_test/flutter_test.dart';
import 'package:rifa_dorada/services/firebase_service.dart';
import 'package:rifa_dorada/models/participante.dart';

void main() {
  setUp(() async {
    final service = FirebaseService.instance;
    await service.initialize();
  });

  test('Local data atomic registration prevents double booking', () async {
    final service = FirebaseService.instance;

    // Check that we are indeed in local data mode for the test environment
    expect(service.useLocalData, isTrue);

    // 1. Register first participant successfully with numbers '50' and '51'
    final part1 = Participante(
      id: '',
      rifaId: 'rifa_1',
      nombre: 'Carlos',
      whatsapp: '3001111111',
      ciudad: 'Bogotá',
      numeros: ['50', '51'],
      fechaRegistro: DateTime.now(),
    );

    final id1 = await service.registrarParticipante(part1);
    expect(id1, isNotEmpty);

    // 2. Try to register second participant with a number already taken ('50')
    final part2 = Participante(
      id: '',
      rifaId: 'rifa_1',
      nombre: 'Andres',
      whatsapp: '3002222222',
      ciudad: 'Medellín',
      numeros: ['50', '52'], // '50' is already taken!
      fechaRegistro: DateTime.now(),
    );

    // This must throw an exception because '50' is already reserved
    expect(
      () => service.registrarParticipante(part2),
      throwsA(isA<Exception>().having(
        (e) => e.toString(),
        'message',
        contains('ya se encuentra ocupado'),
      )),
    );
  });
}
