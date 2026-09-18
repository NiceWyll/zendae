import 'package:flutter_test/flutter_test.dart';
import 'package:mi_pendiente/core/error/failure.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import 'package:mi_pendiente/data/datasources/seed_data.dart';
import 'package:mi_pendiente/domain/entities/hora_del_dia.dart';
import 'package:mi_pendiente/domain/entities/pendiente.dart';
import 'package:mi_pendiente/domain/entities/prioridad.dart';
import 'package:mi_pendiente/domain/entities/repeticion.dart';
import 'package:mi_pendiente/data/models/pendiente_model.dart';
import 'package:mi_pendiente/domain/usecases/actualizar_pendiente.dart';
import 'package:mi_pendiente/domain/usecases/alternar_completado.dart';
import 'package:mi_pendiente/domain/usecases/crear_pendiente.dart';
import 'package:mi_pendiente/domain/usecases/eliminar_pendiente.dart';
import 'package:mi_pendiente/domain/usecases/posponer_para_manana.dart';
import 'package:mi_pendiente/presentation/mappers/prioridad_ui.dart';
import 'helpers/test_fakes.dart';

void main() {
  group('Pendiente Entity y Model Tests (Fases 1 y 3)', () {
    test('Creación de pendiente y conversión toMap / fromMap incluyendo notificacion_id', () {
      final now = DateTime(2026, 9, 15);
      final p = Pendiente(
        id: 'test-1',
        titulo: 'Reunión de prueba',
        descripcion: 'Detalle de prueba',
        fecha: now,
        hora: const HoraDelDia(hora: 14, minuto: 30),
        prioridad: Prioridad.alta,
        tieneRecordatorio: true,
        minutosAntes: 15,
        repetir: Repeticion.noRepetir,
        estaCompletado: false,
        notificacionId: 887766,
      );

      final map = PendienteModel.toMap(p);
      expect(map['id'], 'test-1');
      expect(map['titulo'], 'Reunión de prueba');
      expect(map['prioridad'], 'alta');
      expect(map['tiene_recordatorio'], 1);
      expect(map['esta_completado'], 0);
      expect(map['notificacion_id'], 887766);

      final revived = PendienteModel.fromMap(map);
      expect(revived.id, p.id);
      expect(revived.titulo, p.titulo);
      expect(revived.hora.hora, 14);
      expect(revived.hora.minuto, 30);
      expect(revived.prioridad, Prioridad.alta);
      expect(revived.estaCompletado, false);
      expect(revived.notificacionId, 887766);
    });

    test('copyWith preserva valores y actualiza campos solicitados', () {
      final p = Pendiente(
        id: '1',
        titulo: 'Tarea Original',
        fecha: DateTime(2026, 9, 10),
        hora: const HoraDelDia(hora: 9, minuto: 0),
        prioridad: Prioridad.baja,
      );

      final completada = p.copyWith(
        estaCompletado: true,
        fechaCompletado: DateTime(2026, 9, 10, 10, 0),
        notificacionId: 12345,
      );

      expect(completada.estaCompletado, true);
      expect(completada.titulo, 'Tarea Original');
      expect(completada.prioridad, Prioridad.baja);
      expect(completada.fechaCompletado != null, true);
      expect(completada.notificacionId, 12345);
    });

    test('Prioridad labels y colores', () {
      expect(Prioridad.alta.label, 'Alta');
      expect(Prioridad.media.label, 'Media');
      expect(Prioridad.baja.label, 'Baja');
    });

    test('HoraDelDia parsea y formatea como HH:mm', () {
      final h = HoraDelDia.desdeTexto('08:05');
      expect(h.hora, 8);
      expect(h.minuto, 5);
      expect(h.comoTexto, '08:05');
    });

    test('Repeticion convierte correctamente a enum y texto', () {
      expect(Repeticion.desdeTexto('Diario'), Repeticion.diario);
      expect(Repeticion.diario.comoTexto, 'Diario');
      expect(Repeticion.desdeTexto('desconocido'), Repeticion.noRepetir);
    });

    test('Result y Failure funcionan con patrón sellado', () {
      const Result<int> exito = Exito(42);
      const Result<int> fallo = Fallo(FallaBaseDeDatos('Error BD'));

      expect(exito.esExito, isTrue);
      expect(exito.esFallo, isFalse);
      expect(exito.datosO(0), 42);

      expect(fallo.esExito, isFalse);
      expect(fallo.esFallo, isTrue);
      expect(fallo.errorO(null)?.mensaje, 'Error BD');
    });

    test('SeedData contiene tareas iniciales predefinidas', () {
      final seeds = SeedData.obtenerPendientesIniciales();
      expect(seeds.isNotEmpty, isTrue);
      expect(seeds.any((p) => p.titulo == 'Revisar correos'), isTrue);
      expect(seeds.any((p) => p.notificacionId != null), isTrue);
    });

    test('FakeRepository implementa operaciones con Result<T>', () async {
      final repo = FakeRepository();
      final p = Pendiente(
        id: 'fake-1',
        titulo: 'Tarea Test',
        fecha: DateTime.now(),
        hora: const HoraDelDia(hora: 10, minuto: 0),
      );

      final insertRes = await repo.insertarPendiente(p);
      expect(insertRes.esExito, isTrue);

      final listRes = await repo.getPendientes();
      expect(listRes.esExito, isTrue);
      expect(listRes.datosO([]).length, 1);

      final porIdRes = await repo.getPendientePorId('fake-1');
      expect(porIdRes.datosO(null)?.titulo, 'Tarea Test');

      final altRes = await repo.alternarCompletado('fake-1', true);
      expect(altRes.esExito, isTrue);

      final compRes = await repo.getPendientesCompletados();
      expect(compRes.datosO([]).length, 1);

      final delRes = await repo.eliminarPendiente('fake-1');
      expect(delRes.esExito, isTrue);

      final emptyList = await repo.getPendientes();
      expect(emptyList.datosO([]).isEmpty, isTrue);
    });
  });

  group('Casos de Uso de Negocio (Fase 4)', () {
    final momentoFijo = DateTime(2026, 9, 20, 10, 0);
    final reloj = RelojFijo(momentoFijo);

    test('CrearPendiente valida que el título no esté vacío', () async {
      final repo = FakeRepository();
      final alarmas = FakeNotificationScheduler();
      final casoDeUso = CrearPendiente(repo, alarmas, reloj, () => 'uuid-123');

      final vacio = Pendiente(
        id: '',
        titulo: '   ',
        fecha: momentoFijo,
        hora: const HoraDelDia(hora: 11, minuto: 0),
      );

      final res = await casoDeUso(vacio);
      expect(res.esFallo, isTrue);
      expect(res.failureO, isA<FallaValidacion>());
    });

    test('CrearPendiente asigna UUID y notificacionId si tiene recordatorio', () async {
      final repo = FakeRepository();
      final alarmas = FakeNotificationScheduler();
      final casoDeUso = CrearPendiente(repo, alarmas, reloj, () => 'uuid-123');

      final tarea = Pendiente(
        id: '',
        titulo: 'Comprar pan',
        fecha: momentoFijo,
        hora: const HoraDelDia(hora: 11, minuto: 0),
        tieneRecordatorio: true,
      );

      final res = await casoDeUso(tarea);
      expect(res.esExito, isTrue);
      final creado = res.valorO!;
      expect(creado.id, 'uuid-123');
      expect(creado.notificacionId != null, isTrue);
    });

    test('AlternarCompletado sella fecha al completar y limpia al desmarcar', () async {
      final repo = FakeRepository();
      final alarmas = FakeNotificationScheduler();
      final casoDeUso = AlternarCompletado(repo, alarmas, reloj);

      final tarea = Pendiente(
        id: '1',
        titulo: 'Hacer deporte',
        fecha: momentoFijo,
        hora: const HoraDelDia(hora: 12, minuto: 0),
        estaCompletado: false,
      );
      await repo.insertarPendiente(tarea);

      final completadaRes = await casoDeUso(tarea);
      expect(completadaRes.esExito, isTrue);
      expect(completadaRes.valorO!.estaCompletado, isTrue);
      expect(completadaRes.valorO!.fechaCompletado, momentoFijo);

      final desmarcadaRes = await casoDeUso(completadaRes.valorO!);
      expect(desmarcadaRes.esExito, isTrue);
      expect(desmarcadaRes.valorO!.estaCompletado, isFalse);
      expect(desmarcadaRes.valorO!.fechaCompletado, isNull);
    });

    test('PosponerParaManana suma 1 día y rechaza completadas', () async {
      final repo = FakeRepository();
      final alarmas = FakeNotificationScheduler();
      final casoDeUso = PosponerParaManana(repo, alarmas, reloj);

      final tarea = Pendiente(
        id: '2',
        titulo: 'Estudiar Flutter',
        fecha: DateTime(2026, 9, 20),
        hora: const HoraDelDia(hora: 14, minuto: 0),
      );
      await repo.insertarPendiente(tarea);

      final res = await casoDeUso(tarea);
      expect(res.esExito, isTrue);
      expect(res.valorO!.fecha, DateTime(2026, 9, 21));

      // Intento de posponer una completada
      final completada = tarea.copyWith(estaCompletado: true);
      final resComp = await casoDeUso(completada);
      expect(resComp.esFallo, isTrue);
      expect(resComp.failureO, isA<FallaValidacion>());
    });

    test('ActualizarPendiente modifica los datos y valida título no vacío', () async {
      final repo = FakeRepository();
      final alarmas = FakeNotificationScheduler();
      final casoDeUso = ActualizarPendiente(repo, alarmas, reloj);

      final tarea = Pendiente(
        id: '2b',
        titulo: 'Título anterior',
        fecha: DateTime(2026, 9, 20),
        hora: const HoraDelDia(hora: 14, minuto: 0),
      );
      await repo.insertarPendiente(tarea);

      final res = await casoDeUso(tarea.copyWith(titulo: 'Título nuevo'));
      expect(res.esExito, isTrue);
      expect(res.valorO!.titulo, 'Título nuevo');

      final vacio = await casoDeUso(tarea.copyWith(titulo: '   '));
      expect(vacio.esFallo, isTrue);
      expect(vacio.failureO, isA<FallaValidacion>());
    });

    test('EliminarPendiente borra de repositorio', () async {
      final repo = FakeRepository();
      final alarmas = FakeNotificationScheduler();
      final casoDeUso = EliminarPendiente(repo, alarmas);

      final tarea = Pendiente(
        id: '3',
        titulo: 'Eliminarme',
        fecha: momentoFijo,
        hora: const HoraDelDia(hora: 9, minuto: 0),
      );
      await repo.insertarPendiente(tarea);

      final res = await casoDeUso(tarea.id, tarea.notificacionId);
      expect(res.esExito, isTrue);

      final list = await repo.getPendientes();
      expect(list.valorO!.isEmpty, isTrue);
    });
  });
}
