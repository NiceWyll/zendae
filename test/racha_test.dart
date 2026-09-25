import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import 'package:mi_pendiente/features/pendientes/data/datasources/app_database.dart';
import 'package:mi_pendiente/features/racha/data/repositories/racha_repository_impl.dart';
import 'package:mi_pendiente/features/racha/domain/entities/hito_racha.dart';
import 'package:mi_pendiente/features/racha/domain/entities/racha.dart';
import 'package:mi_pendiente/features/racha/domain/repositories/racha_repository.dart';
import 'package:mi_pendiente/features/racha/domain/usecases/actualizar_racha.dart';
import 'package:mi_pendiente/features/racha/domain/usecases/obtener_racha.dart';
import 'package:mi_pendiente/features/racha/presentation/providers/racha_provider.dart';
import 'package:mi_pendiente/features/racha/presentation/screens/mis_logros_screen.dart';
import 'package:mi_pendiente/features/racha/presentation/widgets/banner_racha.dart';

class FakeRachaRepository implements RachaRepository {
  Racha rachaActual;

  FakeRachaRepository([this.rachaActual = const Racha.inicial()]);

  @override
  Future<Result<Racha>> obtenerRacha() async => Exito(rachaActual);

  @override
  Future<Result<void>> guardarRacha(Racha racha) async {
    rachaActual = racha;
    return const Exito(null);
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Fase 8: Entidad Racha y Hitos', () {
    test('Racha.inicial tiene 0 días y ningún logro', () {
      const inicial = Racha.inicial();
      expect(inicial.diasActuales, 0);
      expect(inicial.mejorRacha, 0);
      expect(inicial.ultimaFechaCompletado, isNull);
      expect(inicial.logrosDesbloqueados, isEmpty);
      expect(inicial.proximoHito, HitoRacha.dias3);
      expect(inicial.progresoHaciaProximoHito, 0.0);
    });

    test('progresoHaciaProximoHito calcula porcentajes coherentes', () {
      final racha2 = const Racha.inicial().copyWith(diasActuales: 2);
      expect(racha2.proximoHito, HitoRacha.dias3);
      expect(racha2.progresoHaciaProximoHito, closeTo(2 / 3, 0.01));

      final racha3 = const Racha.inicial().copyWith(diasActuales: 3);
      expect(racha3.proximoHito, HitoRacha.dias7);
      expect(racha3.progresoHaciaProximoHito, 0.0); // recién empieza el tramo 3->7

      final racha5 = const Racha.inicial().copyWith(diasActuales: 5);
      expect(racha5.proximoHito, HitoRacha.dias7);
      expect(racha5.progresoHaciaProximoHito, closeTo(2 / 4, 0.01)); // 2 días de 4 en el rango
    });
  });

  group('Fase 8: Reglas de Negocio con ActualizarRacha', () {
    test('primera tarea completada inicia la racha en 1', () async {
      final repo = FakeRachaRepository();
      final reloj = RelojFijo(DateTime(2026, 9, 18, 10, 0));
      final caso = ActualizarRacha(repo, reloj);

      final res = await caso();
      expect(res, isA<Exito<Racha>>());
      final racha = (res as Exito<Racha>).valor;

      expect(racha.diasActuales, 1);
      expect(racha.mejorRacha, 1);
      expect(racha.ultimaFechaCompletado, DateTime(2026, 9, 18, 10, 0));
    });

    test('completar otra tarea el mismo día no incrementa más de 1 vez', () async {
      final repo = FakeRachaRepository(
        Racha(
          diasActuales: 1,
          mejorRacha: 1,
          ultimaFechaCompletado: DateTime(2026, 9, 18, 8, 30),
          logrosDesbloqueados: const [],
        ),
      );
      final reloj = RelojFijo(DateTime(2026, 9, 18, 16, 0)); // mismo día por la tarde
      final caso = ActualizarRacha(repo, reloj);

      final res = await caso();
      final racha = (res as Exito<Racha>).valor;

      expect(racha.diasActuales, 1);
      expect(racha.mejorRacha, 1);
    });

    test('completar tarea en día consecutivo incrementa +1 y actualiza récord', () async {
      final repo = FakeRachaRepository(
        Racha(
          diasActuales: 2,
          mejorRacha: 2,
          ultimaFechaCompletado: DateTime(2026, 9, 17, 20, 0),
          logrosDesbloqueados: const [],
        ),
      );
      final reloj = RelojFijo(DateTime(2026, 9, 18, 9, 0));
      final caso = ActualizarRacha(repo, reloj);

      final res = await caso();
      final racha = (res as Exito<Racha>).valor;

      expect(racha.diasActuales, 3);
      expect(racha.mejorRacha, 3);
      // Al llegar a 3 días se desbloquea HitoRacha.dias3
      expect(racha.logrosDesbloqueados, contains('dias3'));
    });

    test('interrupción de >1 día reinicia racha a 1 pero conserva mejorRacha y logros', () async {
      final repo = FakeRachaRepository(
        Racha(
          diasActuales: 5,
          mejorRacha: 10,
          ultimaFechaCompletado: DateTime(2026, 9, 15, 12, 0), // hace 3 días
          logrosDesbloqueados: const ['dias3'],
        ),
      );
      final reloj = RelojFijo(DateTime(2026, 9, 18, 10, 0));
      final caso = ActualizarRacha(repo, reloj);

      final res = await caso();
      final racha = (res as Exito<Racha>).valor;

      expect(racha.diasActuales, 1);
      expect(racha.mejorRacha, 10); // Conserva el récord histórico
      expect(racha.logrosDesbloqueados, contains('dias3')); // Conserva logros previos
    });

    test('desbloquea hitos clave para Fases 9 y 10 (30 y 50 días)', () async {
      final repo = FakeRachaRepository(
        Racha(
          diasActuales: 29,
          mejorRacha: 29,
          ultimaFechaCompletado: DateTime(2026, 9, 17, 10, 0),
          logrosDesbloqueados: const ['dias3', 'dias7', 'dias15'],
        ),
      );
      final reloj = RelojFijo(DateTime(2026, 9, 18, 10, 0));
      final caso = ActualizarRacha(repo, reloj);

      final res30 = await caso();
      final racha30 = (res30 as Exito<Racha>).valor;
      expect(racha30.diasActuales, 30);
      expect(racha30.logrosDesbloqueados, contains('dias30')); // Recompensa Tema Aurora
    });

    test('días neutros sin clases ni pendientes no rompen la racha al volver', () async {
      // Usuario completó el viernes (18 de sept), sábado y domingo fueron días neutros
      // El lunes (21 de sept) completa una tarea: la racha debe continuar (5 -> 6)
      final repo = FakeRachaRepository(
        Racha(
          diasActuales: 5,
          mejorRacha: 5,
          ultimaFechaCompletado: DateTime(2026, 9, 18, 14, 0),
          logrosDesbloqueados: const ['dias3'],
        ),
      );
      final reloj = RelojFijo(DateTime(2026, 9, 21, 9, 0));
      // Validador que indica que los días intermedios (19 y 20) no tuvieron clases ni pendientes
      final caso = ActualizarRacha(repo, reloj, (fecha) async => false);

      final res = await caso();
      final racha = (res as Exito<Racha>).valor;

      expect(racha.diasActuales, 6);
      expect(racha.mejorRacha, 6);
    });
  });

  group('Fase 8: ObtenerRacha y detección de inactividad', () {
    test('resetea diasActuales a 0 si pasó más de un día completo sin completar tareas', () async {
      final repo = FakeRachaRepository(
        Racha(
          diasActuales: 4,
          mejorRacha: 4,
          ultimaFechaCompletado: DateTime(2026, 9, 15, 10, 0), // pasaron 3 días
          logrosDesbloqueados: const ['dias3'],
        ),
      );
      final reloj = RelojFijo(DateTime(2026, 9, 18, 10, 0));
      final caso = ObtenerRacha(repo, reloj);

      final res = await caso();
      final racha = (res as Exito<Racha>).valor;

      expect(racha.diasActuales, 0); // racha rota por inactividad
      expect(racha.mejorRacha, 4);   // récord intacto
      expect(repo.rachaActual.diasActuales, 0); // persistido en repositorio
    });

    test('mantiene diasActuales si la última tarea fue ayer (aún a tiempo de sumar hoy)', () async {
      final repo = FakeRachaRepository(
        Racha(
          diasActuales: 4,
          mejorRacha: 4,
          ultimaFechaCompletado: DateTime(2026, 9, 17, 21, 0), // ayer por la noche
          logrosDesbloqueados: const ['dias3'],
        ),
      );
      final reloj = RelojFijo(DateTime(2026, 9, 18, 9, 0)); // hoy por la mañana
      final caso = ObtenerRacha(repo, reloj);

      final res = await caso();
      final racha = (res as Exito<Racha>).valor;

      expect(racha.diasActuales, 4); // todavía mantiene su racha
    });
  });

  group('Fase 8: SQLite Real en Memoria (RachaRepositoryImpl)', () {
    late Database db;
    late AppDatabase appDb;
    late RachaRepositoryImpl repo;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 3,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE racha (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              dias_actuales INTEGER NOT NULL,
              mejor_racha INTEGER NOT NULL,
              ultima_fecha TEXT,
              logros TEXT NOT NULL
            );
          ''');
        },
      );
      appDb = AppDatabase(db: db);
      repo = RachaRepositoryImpl(appDatabase: appDb);
    });

    tearDown(() async {
      await db.close();
    });

    test('devuelve Racha.inicial cuando la tabla está vacía', () async {
      final res = await repo.obtenerRacha();
      expect(res, isA<Exito<Racha>>());
      final racha = (res as Exito<Racha>).valor;
      expect(racha.diasActuales, 0);
      expect(racha.mejorRacha, 0);
    });

    test('persiste y recupera Racha correctamente en SQLite', () async {
      final rachaGuardar = Racha(
        diasActuales: 7,
        mejorRacha: 12,
        ultimaFechaCompletado: DateTime(2026, 9, 18, 11, 45),
        logrosDesbloqueados: const ['dias3', 'dias7'],
      );

      final saveRes = await repo.guardarRacha(rachaGuardar);
      expect(saveRes, isA<Exito<void>>());

      final getRes = await repo.obtenerRacha();
      expect(getRes, isA<Exito<Racha>>());
      final recuperada = (getRes as Exito<Racha>).valor;

      expect(recuperada.diasActuales, 7);
      expect(recuperada.mejorRacha, 12);
      expect(recuperada.ultimaFechaCompletado?.year, 2026);
      expect(recuperada.ultimaFechaCompletado?.month, 9);
      expect(recuperada.ultimaFechaCompletado?.day, 18);
      expect(recuperada.logrosDesbloqueados, equals(['dias3', 'dias7']));
    });
  });

  group('Fase 8: Widgets de Racha y Pantalla Mis Logros', () {
    testWidgets('BannerRachaChip muestra fuego y días de racha', (tester) async {
      final repo = FakeRachaRepository(
        const Racha(
          diasActuales: 5,
          mejorRacha: 10,
          ultimaFechaCompletado: null,
          logrosDesbloqueados: ['dias3'],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rachaRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BannerRachaChip(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('días'), findsOneWidget);
    });

    testWidgets('BannerRachaMotivacional muestra mensaje motivador', (tester) async {
      final repo = FakeRachaRepository(
        const Racha(
          diasActuales: 0,
          mejorRacha: 5,
          ultimaFechaCompletado: null,
          logrosDesbloqueados: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rachaRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BannerRachaMotivacional(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Empecemos de nuevo 💪'), findsOneWidget);
    });

    testWidgets('MisLogrosScreen renderiza hitos y récord', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeRachaRepository(
        const Racha(
          diasActuales: 7,
          mejorRacha: 14,
          ultimaFechaCompletado: null,
          logrosDesbloqueados: ['dias3', 'dias7'],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rachaRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: MisLogrosScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Mis Logros y Racha 🔥'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Récord: 14 días'), findsOneWidget);
      expect(find.text('Hábito Inicial'), findsOneWidget);
      expect(find.text('Primera Semana'), findsOneWidget);
      expect(find.text('Tema "Atardecer" desbloqueado'), findsOneWidget);
      expect(find.text('Constancia'), findsOneWidget);

      // Cambiar al rango Leyenda
      await tester.tap(find.text('Leyenda'));
      await tester.pumpAndSettle();
      expect(find.text('Centenario Legendario'), findsOneWidget);
    });
  });
}
