import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mi_pendiente/core/error/failure.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import 'package:mi_pendiente/features/pendientes/data/datasources/app_database.dart';
import 'package:mi_pendiente/features/pendientes/data/repositories/pendiente_repository_impl.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/hora_del_dia.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/prioridad.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/repeticion.dart';
import 'package:mi_pendiente/features/pendientes/domain/repositories/pendiente_repository.dart';
import 'package:mi_pendiente/features/pendientes/domain/services/notification_scheduler.dart';
import 'package:mi_pendiente/features/pendientes/domain/usecases/actualizar_pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/usecases/alternar_completado.dart';
import 'package:mi_pendiente/features/pendientes/domain/usecases/crear_pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/usecases/eliminar_pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/usecases/posponer_para_manana.dart';

class MockPendienteRepository extends Mock implements PendienteRepository {}
class MockNotificationScheduler extends Mock implements NotificationScheduler {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Pendiente(
        id: 'fallback-id',
        titulo: 'Fallback',
        fecha: DateTime(2026, 9, 18),
        hora: const HoraDelDia(hora: 10, minuto: 0),
      ),
    );
    registerFallbackValue(DateTime(2026, 9, 18));
  });

  group('Fase 7: Pruebas con Mocktail de Reglas de Negocio', () {
    late MockPendienteRepository mockRepo;
    late MockNotificationScheduler mockAlarmas;
    final momentoFijo = DateTime(2026, 9, 18, 10, 0);
    late Reloj relojFijo;

    setUp(() {
      mockRepo = MockPendienteRepository();
      mockAlarmas = MockNotificationScheduler();
      relojFijo = RelojFijo(momentoFijo);
    });

    test('AlternarCompletado: completar una tarea cancela su recordatorio y sella fecha', () async {
      final tarea = Pendiente(
        id: 'task-42',
        titulo: 'Enviar reporte',
        fecha: DateTime(2026, 9, 18),
        hora: const HoraDelDia(hora: 12, minuto: 0),
        tieneRecordatorio: true,
        notificacionId: 42,
        estaCompletado: false,
      );

      when(() => mockRepo.actualizarPendiente(any()))
          .thenAnswer((invocation) async => const Exito(null));
      when(() => mockAlarmas.cancelarRecordatorio(any()))
          .thenAnswer((_) async {});
      when(() => mockAlarmas.cancelarRecordatorioPorIdString(any()))
          .thenAnswer((_) async {});

      final caso = AlternarCompletado(mockRepo, mockAlarmas, relojFijo);
      final resultado = await caso(tarea, true);

      expect(resultado.esExito, isTrue);
      expect(resultado.valorO!.estaCompletado, isTrue);
      expect(resultado.valorO!.fechaCompletado, momentoFijo);

      verify(() => mockAlarmas.cancelarRecordatorio(42)).called(1);
      verify(() => mockAlarmas.cancelarRecordatorioPorIdString('task-42')).called(1);
      verifyNever(() => mockAlarmas.programarRecordatorio(
            notificacionId: any(named: 'notificacionId'),
            titulo: any(named: 'titulo'),
            cuerpo: any(named: 'cuerpo'),
            cuando: any(named: 'cuando'),
          ));
    });

    test('AlternarCompletado: al desmarcar una tarea del pasado NO reprograma alarma (bug protegido)', () async {
      // Tarea cuya fecha/hora es antes de momentoFijo
      final tareaPasada = Pendiente(
        id: 'task-ayer',
        titulo: 'Reunión de ayer',
        fecha: DateTime(2026, 9, 17),
        hora: const HoraDelDia(hora: 9, minuto: 0),
        minutosAntes: 10,
        tieneRecordatorio: true,
        notificacionId: 101,
        estaCompletado: true,
        fechaCompletado: DateTime(2026, 9, 17, 9, 30),
      );

      when(() => mockRepo.actualizarPendiente(any()))
          .thenAnswer((_) async => const Exito(null));

      final caso = AlternarCompletado(mockRepo, mockAlarmas, relojFijo);
      final resultado = await caso(tareaPasada, false);

      expect(resultado.esExito, isTrue);
      expect(resultado.valorO!.estaCompletado, isFalse);
      expect(resultado.valorO!.fechaCompletado, isNull);

      // Regla de oro: como la hora de aviso está en el pasado, NUNCA debe reprogramar alarma
      verifyNever(() => mockAlarmas.programarRecordatorio(
            notificacionId: any(named: 'notificacionId'),
            titulo: any(named: 'titulo'),
            cuerpo: any(named: 'cuerpo'),
            cuando: any(named: 'cuando'),
          ));
      verifyNever(() => mockAlarmas.programarRecordatorioPendiente(any()));
    });

    test('AlternarCompletado: al desmarcar una tarea del futuro SÍ reprograma alarma', () async {
      // Tarea con fecha/hora futura respecto a momentoFijo (2026-09-18 10:00)
      final tareaFutura = Pendiente(
        id: 'task-futura',
        titulo: 'Dentista a la tarde',
        fecha: DateTime(2026, 9, 18),
        hora: const HoraDelDia(hora: 16, minuto: 0),
        minutosAntes: 15,
        tieneRecordatorio: true,
        notificacionId: 202,
        estaCompletado: true,
      );

      when(() => mockRepo.actualizarPendiente(any()))
          .thenAnswer((_) async => const Exito(null));
      when(() => mockAlarmas.programarRecordatorio(
            notificacionId: any(named: 'notificacionId'),
            titulo: any(named: 'titulo'),
            cuerpo: any(named: 'cuerpo'),
            cuando: any(named: 'cuando'),
          )).thenAnswer((_) async {});

      final caso = AlternarCompletado(mockRepo, mockAlarmas, relojFijo);
      final resultado = await caso(tareaFutura, false);

      expect(resultado.esExito, isTrue);
      verify(() => mockAlarmas.programarRecordatorio(
            notificacionId: 202,
            titulo: 'Dentista a la tarde',
            cuerpo: any(named: 'cuerpo'),
            cuando: DateTime(2026, 9, 18, 15, 45),
          )).called(1);
    });

    test('PosponerParaManana: suma exactamente 1 día con reloj congelado y reprograma alarma', () async {
      final tarea = Pendiente(
        id: 'task-posponer',
        titulo: 'Pagar tarjeta',
        fecha: DateTime(2026, 9, 18),
        hora: const HoraDelDia(hora: 18, minuto: 0),
        tieneRecordatorio: true,
        notificacionId: 303,
        estaCompletado: false,
      );

      when(() => mockRepo.actualizarPendiente(any()))
          .thenAnswer((_) async => const Exito(null));
      when(() => mockAlarmas.programarRecordatorio(
            notificacionId: any(named: 'notificacionId'),
            titulo: any(named: 'titulo'),
            cuerpo: any(named: 'cuerpo'),
            cuando: any(named: 'cuando'),
          )).thenAnswer((_) async {});

      final caso = PosponerParaManana(mockRepo, mockAlarmas, relojFijo);
      final resultado = await caso(tarea);

      expect(resultado.esExito, isTrue);
      expect(resultado.valorO!.fecha, DateTime(2026, 9, 19));
      verify(() => mockRepo.actualizarPendiente(any(that: predicate<Pendiente>((p) => p.fecha == DateTime(2026, 9, 19))))).called(1);
      verify(() => mockAlarmas.programarRecordatorio(
            notificacionId: 303,
            titulo: 'Pagar tarjeta',
            cuerpo: any(named: 'cuerpo'),
            cuando: any(named: 'cuando'),
          )).called(1);
    });

    test('PosponerParaManana: rechaza posponer si la tarea ya está completada', () async {
      final tarea = Pendiente(
        id: 'task-completa',
        titulo: 'Ya realizada',
        fecha: DateTime(2026, 9, 18),
        hora: const HoraDelDia(hora: 8, minuto: 0),
        estaCompletado: true,
      );

      final caso = PosponerParaManana(mockRepo, mockAlarmas, relojFijo);
      final resultado = await caso(tarea);

      expect(resultado.esFallo, isTrue);
      expect(resultado.failureO, isA<FallaValidacion>());
      verifyNever(() => mockRepo.actualizarPendiente(any()));
    });

    test('CrearPendiente: rechaza título vacío sin tocar repositorio ni alarmas', () async {
      final tareaInvalida = Pendiente(
        id: '',
        titulo: '   ',
        fecha: DateTime(2026, 9, 18),
        hora: const HoraDelDia(hora: 10, minuto: 0),
      );

      final caso = CrearPendiente(mockRepo, mockAlarmas, relojFijo, () => 'uuid-1');
      final resultado = await caso(tareaInvalida);

      expect(resultado.esFallo, isTrue);
      expect(resultado.failureO, isA<FallaValidacion>());
      verifyNever(() => mockRepo.insertarPendiente(any()));
      verifyNever(() => mockAlarmas.programarRecordatorio(
            notificacionId: any(named: 'notificacionId'),
            titulo: any(named: 'titulo'),
            cuerpo: any(named: 'cuerpo'),
            cuando: any(named: 'cuando'),
          ));
    });

    test('CrearPendiente: genera UUID y notificacionId, guardando y programando alarma', () async {
      final nuevaTarea = Pendiente(
        id: '',
        titulo: 'Cita con cliente',
        descripcion: 'Presentar propuesta',
        fecha: DateTime(2026, 9, 19),
        hora: const HoraDelDia(hora: 11, minuto: 0),
        minutosAntes: 10,
        tieneRecordatorio: true,
      );

      when(() => mockRepo.insertarPendiente(any()))
          .thenAnswer((_) async => const Exito(null));
      when(() => mockAlarmas.programarRecordatorio(
            notificacionId: any(named: 'notificacionId'),
            titulo: any(named: 'titulo'),
            cuerpo: any(named: 'cuerpo'),
            cuando: any(named: 'cuando'),
          )).thenAnswer((_) async {});

      final caso = CrearPendiente(mockRepo, mockAlarmas, relojFijo, () => 'gen-uuid-99');
      final resultado = await caso(nuevaTarea);

      expect(resultado.esExito, isTrue);
      final guardada = resultado.valorO!;
      expect(guardada.id, 'gen-uuid-99');
      expect(guardada.notificacionId, isNotNull);

      verify(() => mockRepo.insertarPendiente(guardada)).called(1);
      verify(() => mockAlarmas.programarRecordatorio(
            notificacionId: guardada.notificacionId!,
            titulo: 'Cita con cliente',
            cuerpo: 'Presentar propuesta',
            cuando: DateTime(2026, 9, 19, 10, 50),
          )).called(1);
    });

    test('ActualizarPendiente: cancela alarma cuando se desactiva el recordatorio', () async {
      final tareaSinRecordatorio = Pendiente(
        id: 'task-edit',
        titulo: 'Comprar insumos',
        fecha: DateTime(2026, 9, 20),
        hora: const HoraDelDia(hora: 14, minuto: 0),
        tieneRecordatorio: false,
        notificacionId: 505,
      );

      when(() => mockRepo.actualizarPendiente(any()))
          .thenAnswer((_) async => const Exito(null));
      when(() => mockAlarmas.cancelarRecordatorio(any()))
          .thenAnswer((_) async {});
      when(() => mockAlarmas.cancelarRecordatorioPorIdString(any()))
          .thenAnswer((_) async {});

      final caso = ActualizarPendiente(mockRepo, mockAlarmas, relojFijo);
      final resultado = await caso(tareaSinRecordatorio);

      expect(resultado.esExito, isTrue);
      verify(() => mockAlarmas.cancelarRecordatorio(505)).called(1);
      verify(() => mockAlarmas.cancelarRecordatorioPorIdString('task-edit')).called(1);
    });

    test('EliminarPendiente: elimina del repositorio y cancela alarma', () async {
      when(() => mockRepo.eliminarPendiente(any()))
          .thenAnswer((_) async => const Exito(null));
      when(() => mockAlarmas.cancelarRecordatorio(any()))
          .thenAnswer((_) async {});
      when(() => mockAlarmas.cancelarRecordatorioPorIdString(any()))
          .thenAnswer((_) async {});

      final caso = EliminarPendiente(mockRepo, mockAlarmas);
      final res = await caso('task-to-delete', 707);

      expect(res.esExito, isTrue);
      verify(() => mockRepo.eliminarPendiente('task-to-delete')).called(1);
      verify(() => mockAlarmas.cancelarRecordatorio(707)).called(1);
      verify(() => mockAlarmas.cancelarRecordatorioPorIdString('task-to-delete')).called(1);
    });
  });

  group('Fase 7: SQLite Real en Memoria (sqflite_common_ffi)', () {
    late Database rawDb;
    late AppDatabase appDb;
    late PendienteRepositoryImpl repo;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      rawDb = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE pendientes (
                id TEXT PRIMARY KEY,
                titulo TEXT NOT NULL,
                descripcion TEXT,
                fecha TEXT NOT NULL,
                hora_hour INTEGER NOT NULL,
                hora_minute INTEGER NOT NULL,
                prioridad TEXT NOT NULL,
                tiene_recordatorio INTEGER NOT NULL,
                minutos_antes INTEGER NOT NULL,
                repetir TEXT NOT NULL,
                esta_completado INTEGER NOT NULL,
                fecha_completado TEXT,
                notificacion_id INTEGER,
                clase_id TEXT
              )
            ''');
          },
        ),
      );

      appDb = AppDatabase(db: rawDb);
      repo = PendienteRepositoryImpl(appDatabase: appDb);
    });

    tearDown(() async {
      await rawDb.close();
    });

    test('CRUD completo en SQLite en memoria', () async {
      final p = Pendiente(
        id: 'sql-1',
        titulo: 'Revisión SQL en memoria',
        descripcion: 'Verificar FFI',
        fecha: DateTime(2026, 9, 18),
        hora: const HoraDelDia(hora: 15, minuto: 30),
        prioridad: Prioridad.alta,
        tieneRecordatorio: true,
        minutosAntes: 10,
        repetir: Repeticion.diario,
        estaCompletado: false,
        notificacionId: 999,
      );

      // 1. Insertar
      final insertRes = await repo.insertarPendiente(p);
      expect(insertRes.esExito, isTrue);

      // 2. Obtener
      final getRes = await repo.getPendientes();
      expect(getRes.esExito, isTrue);
      expect(getRes.valorO!.length, 1);
      final saved = getRes.valorO!.first;
      expect(saved.titulo, 'Revisión SQL en memoria');
      expect(saved.notificacionId, 999);
      expect(saved.prioridad, Prioridad.alta);
      expect(saved.repetir, Repeticion.diario);

      // 3. Consultar por fecha
      final porFecha = await repo.getPendientesPorFecha(DateTime(2026, 9, 18));
      expect(porFecha.valorO!.length, 1);

      // 4. Actualizar
      final updated = saved.copyWith(titulo: 'Título Modificado');
      final updRes = await repo.actualizarPendiente(updated);
      expect(updRes.esExito, isTrue);

      // 5. Alternar completado
      await repo.alternarCompletado('sql-1', true);
      final completados = await repo.getPendientesCompletados();
      expect(completados.valorO!.length, 1);

      // 6. Eliminar completados
      await repo.eliminarCompletados();
      final afterDelete = await repo.getPendientes();
      expect(afterDelete.valorO!.isEmpty, isTrue);
    });

    test('Devuelve Fallo(FallaBaseDeDatos) ante fallo de SQLite (e.g. tabla cerrada o inválida)', () async {
      await rawDb.close(); // Cerramos la base deliberadamente para provocar DatabaseException
      final res = await repo.getPendientes();
      expect(res.esFallo, isTrue);
      expect(res.failureO, isA<FallaBaseDeDatos>());
    });
  });
}
