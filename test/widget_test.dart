import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_pendiente/app.dart';
import 'package:mi_pendiente/features/pendientes/presentation/screens/nuevo_pendiente_screen.dart';
import 'package:mi_pendiente/core/providers/preferences_providers.dart';
import 'package:mi_pendiente/core/providers/notification_providers.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/pendientes_provider.dart';
import 'helpers/test_fakes.dart';

void main() {
  late SharedPreferences testPrefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    testPrefs = await SharedPreferences.getInstance();
  });

  testWidgets('MiPendienteApp inicia correctamente', (WidgetTester tester) async {
    await testPrefs.setBool('ha_visto_onboarding', true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(testPrefs),
          notificationSchedulerProvider.overrideWithValue(FakeNotificationScheduler()),
          pendienteRepositoryProvider.overrideWithValue(FakeRepository()),
        ],
        child: const MiPendienteApp(),
      ),
    );

    // Verifica que el título inicial aparezca en el Splash
    expect(find.text('Zendae'), findsOneWidget);
    expect(find.text('Organiza tu día, semana y mes'), findsOneWidget);

    // Avanza el tiempo pasando el Timer del splash
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 600));

    // Verifica que se muestre la cabecera en el Shell
    expect(find.text('Mis pendientes'), findsOneWidget);
  });

  testWidgets('Selector de hora estilo alarma abre correctamente y elimina chips fijos', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(testPrefs),
          notificationSchedulerProvider.overrideWithValue(FakeNotificationScheduler()),
          pendienteRepositoryProvider.overrideWithValue(FakeRepository()),
        ],
        child: const MaterialApp(
          home: NuevoPendienteScreen(),
        ),
      ),
    );

    // Verifica que exista la fila de Hora
    expect(find.text('Hora'), findsOneWidget);
    expect(find.text('10:30 AM'), findsOneWidget);

    // Toca el selector de Hora
    await tester.tap(find.text('Hora'));
    await tester.pumpAndSettle();

    // Verifica que se abra el BottomSheet estilo alarma
    expect(find.text('Ajustar Hora'), findsOneWidget);
    expect(find.text('Desliza las ruedas y elige AM o PM'), findsOneWidget);
    expect(find.text('HORA (1-12)'), findsOneWidget);
    expect(find.text('MINUTOS (0-59)'), findsOneWidget);
    expect(find.text('AM'), findsNWidgets(2));
    expect(find.text('PM'), findsOneWidget);
    expect(find.text('Confirmar hora'), findsOneWidget);

    // Verifica que los cuadros fijos anteriores (chips) NO existan
    expect(find.text('08:00'), findsNothing);
    expect(find.text('09:00'), findsNothing);
    expect(find.text(':15'), findsNothing);
    expect(find.text(':45'), findsNothing);

    // Verifica que existan las ruedas CupertinoPicker para horas y minutos
    expect(find.byType(CupertinoPicker), findsNWidgets(2));

    // Pulsa el botón "Confirmar hora"
    await tester.tap(find.text('Confirmar hora'));
    await tester.pumpAndSettle();

    // El modal se cierra correctamente
    expect(find.text('Ajustar Hora'), findsNothing);
  });
}
