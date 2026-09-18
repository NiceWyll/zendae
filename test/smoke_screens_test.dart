import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_pendiente/core/providers/notification_providers.dart';
import 'package:mi_pendiente/core/providers/preferences_providers.dart';
import 'package:mi_pendiente/core/theme/app_theme.dart';
import 'package:mi_pendiente/domain/entities/pendiente.dart';
import 'package:mi_pendiente/domain/entities/prioridad.dart';
import 'package:mi_pendiente/domain/entities/hora_del_dia.dart';
import 'package:mi_pendiente/presentation/screens/splash_screen.dart';
import 'package:mi_pendiente/presentation/screens/home_shell_screen.dart';
import 'package:mi_pendiente/presentation/screens/hoy_screen.dart';
import 'package:mi_pendiente/presentation/screens/semana_screen.dart';
import 'package:mi_pendiente/presentation/screens/mes_screen.dart';
import 'package:mi_pendiente/presentation/screens/nuevo_pendiente_screen.dart';
import 'package:mi_pendiente/presentation/screens/detalle_pendiente_screen.dart';
import 'package:mi_pendiente/presentation/screens/completados_screen.dart';
import 'package:mi_pendiente/presentation/screens/ajustes_screen.dart';
import 'package:mi_pendiente/presentation/providers/pendientes_provider.dart';
import 'helpers/test_fakes.dart';

late SharedPreferences testPrefs;

Widget _crearAppDePrueba(Widget child, {List<Pendiente> pendientes = const []}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(testPrefs),
      notificationSchedulerProvider.overrideWithValue(FakeNotificationScheduler()),
      pendienteRepositoryProvider.overrideWithValue(FakeRepository(List.from(pendientes))),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      locale: const Locale('es', 'ES'),
      home: child,
    ),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    testPrefs = await SharedPreferences.getInstance();
  });

  final pendienteEjemplo = Pendiente(
    id: 'test-123',
    titulo: 'Pendiente de prueba',
    descripcion: 'Descripción detallada de prueba',
    fecha: DateTime.now(),
    hora: const HoraDelDia(hora: 14, minuto: 30),
    prioridad: Prioridad.alta,
    tieneRecordatorio: true,
  );

  group('Smoke Tests - Verificación de Renderizado de Pantallas (Fase 0)', () {
    testWidgets('1. SplashScreen renderiza sin excepciones', (tester) async {
      await tester.pumpWidget(_crearAppDePrueba(const SplashScreen()));
      expect(find.byType(SplashScreen), findsOneWidget);
      // Avanzar timer del splash para no dejar timers pendientes
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('2. HomeShellScreen renderiza sin excepciones', (tester) async {
      await tester.pumpWidget(_crearAppDePrueba(const HomeShellScreen(), pendientes: [pendienteEjemplo]));
      await tester.pumpAndSettle();
      expect(find.byType(HomeShellScreen), findsOneWidget);
    });

    testWidgets('3. HoyScreen renderiza sin excepciones', (tester) async {
      await tester.pumpWidget(_crearAppDePrueba(const Scaffold(body: HoyScreen()), pendientes: [pendienteEjemplo]));
      await tester.pumpAndSettle();
      expect(find.byType(HoyScreen), findsOneWidget);
    });

    testWidgets('4. SemanaScreen renderiza sin excepciones', (tester) async {
      await tester.pumpWidget(_crearAppDePrueba(const Scaffold(body: SemanaScreen()), pendientes: [pendienteEjemplo]));
      await tester.pumpAndSettle();
      expect(find.byType(SemanaScreen), findsOneWidget);
    });

    testWidgets('5. MesScreen renderiza sin excepciones', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_crearAppDePrueba(const Scaffold(body: MesScreen()), pendientes: [pendienteEjemplo]));
      await tester.pumpAndSettle();
      expect(find.byType(MesScreen), findsOneWidget);
    });

    testWidgets('6. NuevoPendienteScreen renderiza sin excepciones', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_crearAppDePrueba(const NuevoPendienteScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(NuevoPendienteScreen), findsOneWidget);
    });

    testWidgets('7. DetallePendienteScreen renderiza sin excepciones', (tester) async {
      await tester.pumpWidget(_crearAppDePrueba(
        DetallePendienteScreen(pendienteId: pendienteEjemplo.id),
        pendientes: [pendienteEjemplo],
      ));
      await tester.pumpAndSettle();
      expect(find.byType(DetallePendienteScreen), findsOneWidget);
    });

    testWidgets('8. CompletadosScreen renderiza sin excepciones', (tester) async {
      final completado = pendienteEjemplo.copyWith(estaCompletado: true, fechaCompletado: DateTime.now());
      await tester.pumpWidget(_crearAppDePrueba(const Scaffold(body: CompletadosScreen()), pendientes: [completado]));
      await tester.pumpAndSettle();
      expect(find.byType(CompletadosScreen), findsOneWidget);
    });

    testWidgets('9. AjustesScreen renderiza sin excepciones', (tester) async {
      await tester.pumpWidget(_crearAppDePrueba(const Scaffold(body: AjustesScreen())));
      await tester.pumpAndSettle();
      expect(find.byType(AjustesScreen), findsOneWidget);
    });
  });
}
