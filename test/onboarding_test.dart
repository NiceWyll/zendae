import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_pendiente/core/providers/notification_providers.dart';
import 'package:mi_pendiente/core/providers/preferences_providers.dart';
import 'package:mi_pendiente/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/pendientes_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'helpers/test_fakes.dart';

void main() {
  group('OnboardingScreen Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget crearApp({Widget? child}) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationSchedulerProvider.overrideWithValue(FakeNotificationScheduler()),
          pendienteRepositoryProvider.overrideWithValue(FakeRepository([])),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es', 'ES')],
          locale: const Locale('es', 'ES'),
          home: child ?? const OnboardingScreen(),
        ),
      );
    }

    testWidgets('Renderiza primera página de onboarding con Organiza tu día', (tester) async {
      await tester.pumpWidget(crearApp());
      await tester.pumpAndSettle();

      expect(find.text('Organiza tu día'), findsOneWidget);
      expect(find.text('Omitir'), findsOneWidget);
      expect(find.text('Siguiente'), findsOneWidget);
    });

    testWidgets('Navega entre páginas con el botón Siguiente y muestra Comenzar al final', (tester) async {
      await tester.pumpWidget(crearApp());
      await tester.pumpAndSettle();

      // Página 1
      expect(find.text('Organiza tu día'), findsOneWidget);

      // Ir a Página 2
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Cuida tu racha'), findsOneWidget);

      // Ir a Página 3
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Asistente con IA'), findsOneWidget);
      expect(find.text('Comenzar'), findsOneWidget);

      // Tocar Comenzar
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      expect(prefs.getBool('ha_visto_onboarding'), isTrue);
    });

    testWidgets('Botón Omitir completa el onboarding inmediatamente', (tester) async {
      await tester.pumpWidget(crearApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();

      expect(prefs.getBool('ha_visto_onboarding'), isTrue);
    });
  });
}
