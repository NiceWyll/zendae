import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/hora_del_dia.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/prioridad.dart';
import 'package:mi_pendiente/features/pendientes/domain/repositories/pendiente_repository.dart';
import 'package:mi_pendiente/features/pendientes/domain/services/notification_scheduler.dart';
import 'package:mi_pendiente/features/pendientes/domain/usecases/programar_resumen_matutino.dart';

class MockPendienteRepository extends Mock implements PendienteRepository {}
class MockNotificationScheduler extends Mock implements NotificationScheduler {}

void main() {
  group('Resumen Matutino Diario ("Tu Plan de Hoy")', () {
    late MockPendienteRepository mockRepo;
    late MockNotificationScheduler mockAlarmas;
    final momentoFijo = DateTime(2026, 9, 20, 7, 0);
    late Reloj relojFijo;
    late ProgramarResumenMatutino caso;

    setUp(() {
      mockRepo = MockPendienteRepository();
      mockAlarmas = MockNotificationScheduler();
      relojFijo = RelojFijo(momentoFijo);
      caso = ProgramarResumenMatutino(mockRepo, mockAlarmas, relojFijo);
    });

    test('Programa resumen matutino con conteo de tareas y alta prioridad', () async {
      final tareasHoy = [
        Pendiente(
          id: '1',
          titulo: 'Reunión importante',
          fecha: DateTime(2026, 9, 20),
          hora: const HoraDelDia(hora: 9, minuto: 0),
          prioridad: Prioridad.alta,
          estaCompletado: false,
        ),
        Pendiente(
          id: '2',
          titulo: 'Comprar café',
          fecha: DateTime(2026, 9, 20),
          hora: const HoraDelDia(hora: 11, minuto: 30),
          prioridad: Prioridad.media,
          estaCompletado: false,
        ),
        Pendiente(
          id: '3',
          titulo: 'Tarea ya hecha',
          fecha: DateTime(2026, 9, 20),
          hora: const HoraDelDia(hora: 8, minuto: 0),
          prioridad: Prioridad.baja,
          estaCompletado: true, // No debe contarse
        ),
      ];

      when(() => mockRepo.getPendientesPorFecha(any()))
          .thenAnswer((_) async => Exito(tareasHoy));

      when(() => mockAlarmas.programarResumenDiario(
            notificacionId: any(named: 'notificacionId'),
            titulo: any(named: 'titulo'),
            cuerpo: any(named: 'cuerpo'),
            hora: any(named: 'hora'),
            minuto: any(named: 'minuto'),
          )).thenAnswer((_) async {});

      final res = await caso(
        habilitado: true,
        hora: 8,
        minuto: 0,
      );

      expect(res, isA<Exito<void>>());

      verify(() => mockAlarmas.programarResumenDiario(
            notificacionId: ProgramarResumenMatutino.notificacionIdResumen,
            titulo: '🌅 ¡Buenos días! Tu Plan de Hoy',
            cuerpo: 'Tienes 2 pendientes para hoy (1 de alta prioridad). ¡Empieza con foco!',
            hora: 8,
            minuto: 0,
          )).called(1);
    });

    test('Programa resumen matutino con día despejado cuando no hay tareas', () async {
      when(() => mockRepo.getPendientesPorFecha(any()))
          .thenAnswer((_) async => const Exito([]));

      when(() => mockAlarmas.programarResumenDiario(
            notificacionId: any(named: 'notificacionId'),
            titulo: any(named: 'titulo'),
            cuerpo: any(named: 'cuerpo'),
            hora: any(named: 'hora'),
            minuto: any(named: 'minuto'),
          )).thenAnswer((_) async {});

      final res = await caso(
        habilitado: true,
        hora: 8,
        minuto: 30,
      );

      expect(res, isA<Exito<void>>());

      verify(() => mockAlarmas.programarResumenDiario(
            notificacionId: ProgramarResumenMatutino.notificacionIdResumen,
            titulo: '🌅 ¡Día despejado!',
            cuerpo: 'No tienes pendientes programados para hoy. ¡Aprovecha tu día!',
            hora: 8,
            minuto: 30,
          )).called(1);
    });

    test('Cancela la notificación del resumen si habilitado es false', () async {
      when(() => mockAlarmas.cancelarRecordatorio(any()))
          .thenAnswer((_) async {});

      final res = await caso(
        habilitado: false,
        hora: 8,
        minuto: 0,
      );

      expect(res, isA<Exito<void>>());

      verify(() => mockAlarmas.cancelarRecordatorio(
            ProgramarResumenMatutino.notificacionIdResumen,
          )).called(1);

      verifyNever(() => mockAlarmas.programarResumenDiario(
            notificacionId: any(named: 'notificacionId'),
            titulo: any(named: 'titulo'),
            cuerpo: any(named: 'cuerpo'),
            hora: any(named: 'hora'),
            minuto: any(named: 'minuto'),
          ));
    });
  });
}
