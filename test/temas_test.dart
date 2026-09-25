import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_pendiente/core/constants/app_config.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/providers/preferences_providers.dart';
import 'package:mi_pendiente/core/theme/app_theme.dart';
import 'package:mi_pendiente/core/theme/tema_app.dart';
import 'package:mi_pendiente/features/ajustes/presentation/providers/ajustes_provider.dart';
import 'package:mi_pendiente/features/ajustes/presentation/screens/ajustes_screen.dart';
import 'package:mi_pendiente/features/ajustes/presentation/screens/selector_temas_screen.dart';
import 'package:mi_pendiente/features/ajustes/presentation/widgets/selector_temas_grid.dart';
import 'package:mi_pendiente/features/racha/domain/entities/racha.dart';
import 'package:mi_pendiente/features/racha/domain/repositories/racha_repository.dart';
import 'package:mi_pendiente/features/racha/presentation/providers/racha_provider.dart';

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
  group('Fase 10: TemaApp y TemasDisponibles', () {
    test('TemasDisponibles.todos contiene temas bien configurados', () {
      const todos = TemasDisponibles.todos;
      expect(todos.length, greaterThanOrEqualTo(6));

      final ids = todos.map((t) => t.id).toList();
      expect(ids, containsAll(['clasico', 'esmeralda', 'lavanda', 'atardecer', 'aurora', 'dorado', 'fondo_personalizado']));
    });

    test('obtenerPorId retorna el tema correspondiente o clasico por defecto', () {
      final esmeralda = TemasDisponibles.obtenerPorId('esmeralda');
      expect(esmeralda.id, 'esmeralda');
      expect(esmeralda.nombre, 'Esmeralda Fresco');

      final desconocido = TemasDisponibles.obtenerPorId('no_existe');
      expect(desconocido.id, 'clasico');
    });

    test('Temas libres están desbloqueados sin requerir racha', () {
      final clasico = TemasDisponibles.obtenerPorId('clasico');
      final esmeralda = TemasDisponibles.obtenerPorId('esmeralda');
      final lavanda = TemasDisponibles.obtenerPorId('lavanda');

      expect(clasico.estaDesbloqueado(0, const []), isTrue);
      expect(esmeralda.estaDesbloqueado(0, const []), isTrue);
      expect(lavanda.estaDesbloqueado(0, const []), isTrue);
    });

    test('Temas exclusivos se desbloquean al alcanzar los días de racha exactos o por logro', () {
      AppConfig.todoDesbloqueado = false;
      addTearDown(() => AppConfig.todoDesbloqueado = true);

      final atardecer = TemasDisponibles.obtenerPorId('atardecer');
      final aurora = TemasDisponibles.obtenerPorId('aurora');
      final dorado = TemasDisponibles.obtenerPorId('dorado');

      // Atardecer (7 días)
      expect(atardecer.estaDesbloqueado(6, const []), isFalse);
      expect(atardecer.estaDesbloqueado(7, const []), isTrue);
      expect(atardecer.estaDesbloqueado(0, ['dias7']), isTrue);
      expect(atardecer.estaDesbloqueado(0, ['tema_atardecer']), isTrue);

      // Aurora (30 días)
      expect(aurora.estaDesbloqueado(29, const []), isFalse);
      expect(aurora.estaDesbloqueado(30, const []), isTrue);
      expect(aurora.estaDesbloqueado(0, ['dias30']), isTrue);
      expect(aurora.estaDesbloqueado(0, ['tema_aurora']), isTrue);

      // Dorado (100 días)
      expect(dorado.estaDesbloqueado(99, const []), isFalse);
      expect(dorado.estaDesbloqueado(100, const []), isTrue);
      expect(dorado.estaDesbloqueado(0, ['dias100']), isTrue);
      expect(dorado.estaDesbloqueado(0, ['tema_dorado']), isTrue);
    });
  });

  group('Fase 10: AppTheme.crearThemeData dinámico', () {
    testWidgets('crearThemeData genera ThemeData consistente en modo claro', (tester) async {
      final tema = TemasDisponibles.obtenerPorId('esmeralda');
      final themeData = AppTheme.crearThemeData(tema, false);

      expect(themeData.brightness, Brightness.light);
      expect(themeData.colorScheme.primary, tema.colorPrimario);
      expect(themeData.useMaterial3, isTrue);
    });

    testWidgets('crearThemeData genera ThemeData consistente en modo oscuro', (tester) async {
      final tema = TemasDisponibles.obtenerPorId('lavanda');
      final themeData = AppTheme.crearThemeData(tema, true);

      expect(themeData.brightness, Brightness.dark);
      expect(themeData.primaryColor, tema.colorSecundario);
      expect(themeData.colorScheme.primary, tema.colorSecundario);
      expect(themeData.useMaterial3, isTrue);
    });

    testWidgets('AppTheme.lightTheme y darkTheme retrocompatibles funcionan', (tester) async {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
    });
  });

  group('Fase 10: AjustesNotifier - cambiarTema y persistencia', () {
    test('cambiarTema actualiza el estado y persiste en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'tema_id': 'clasico'});
      final prefs = await SharedPreferences.getInstance();

      final notifier = AjustesNotifier(prefs);
      expect(notifier.state.temaId, 'clasico');

      await notifier.cambiarTema('esmeralda');
      expect(notifier.state.temaId, 'esmeralda');
      expect(prefs.getString('tema_id'), 'esmeralda');
    });

    test('AjustesState.copyWith soporta temaId', () {
      const state = AjustesState();
      expect(state.temaId, 'clasico');

      final modificado = state.copyWith(temaId: 'aurora');
      expect(modificado.temaId, 'aurora');
      expect(modificado.notificaciones, state.notificaciones);
    });
  });

  group('Fase 10: Widgets - SelectorTemasGrid y SelectorTemasScreen', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'tema_id': 'clasico',
      });
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('SelectorTemasGrid renderiza las 6 tarjetas de temas', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeRachaRepository(
        const Racha(
          diasActuales: 10,
          mejorRacha: 10,
          ultimaFechaCompletado: null,
          logrosDesbloqueados: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            rachaRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SelectorTemasGrid(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Azul Clásico'), findsOneWidget);
      expect(find.text('Esmeralda Fresco'), findsOneWidget);
      expect(find.text('Lavanda Cósmica'), findsOneWidget);
      expect(find.text('Atardecer Cálido'), findsOneWidget);
      expect(find.text('Aurora Boreal'), findsOneWidget);
      expect(find.text('Racha Dorada'), findsOneWidget);
    });

    testWidgets('Tocar un tema desbloqueado cambia el tema activo', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeRachaRepository(
        const Racha(
          diasActuales: 0,
          mejorRacha: 0,
          ultimaFechaCompletado: null,
          logrosDesbloqueados: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            rachaRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SelectorTemasGrid(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap en Esmeralda Fresco (tema desbloqueado sin racha)
      await tester.tap(find.text('Esmeralda Fresco'));
      await tester.pumpAndSettle();

      expect(prefs.getString('tema_id'), 'esmeralda');
    });

    testWidgets('Tocar un tema bloqueado muestra diálogo explicativo con días faltantes', (tester) async {
      AppConfig.todoDesbloqueado = false;
      addTearDown(() => AppConfig.todoDesbloqueado = true);

      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeRachaRepository(
        const Racha(
          diasActuales: 3,
          mejorRacha: 3,
          ultimaFechaCompletado: null,
          logrosDesbloqueados: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            rachaRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SelectorTemasGrid(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Atardecer Cálido requiere 7 días, racha es 3
      await tester.tap(find.text('Atardecer Cálido'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('7 días de racha'), findsOneWidget);
      expect(find.text('Entendido 💪'), findsOneWidget);

      // Cerrar diálogo
      await tester.tap(find.text('Entendido 💪'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('SelectorTemasScreen muestra el banner de racha y el título', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeRachaRepository(
        const Racha(
          diasActuales: 15,
          mejorRacha: 15,
          ultimaFechaCompletado: null,
          logrosDesbloqueados: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            rachaRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: SelectorTemasScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Temas y Colores 🎨'), findsOneWidget);
      expect(find.text('Tu Racha: 15 días'), findsOneWidget);
      expect(find.text('Elige tu paleta favorita'), findsOneWidget);
    });

    testWidgets('AjustesScreen muestra la tarjeta de Paleta de colores y temas', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AjustesScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Paleta de colores y temas'), findsOneWidget);
      expect(find.text('Azul Clásico'), findsOneWidget);
    });
  });
}
