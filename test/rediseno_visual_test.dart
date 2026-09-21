import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_pendiente/core/constants/app_typography.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/providers/notification_providers.dart';
import 'package:mi_pendiente/core/providers/preferences_providers.dart';
import 'package:mi_pendiente/core/widgets/empty_state_widget.dart';
import 'package:mi_pendiente/core/widgets/task_card.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/hora_del_dia.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/prioridad.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/pendientes_provider.dart';
import 'package:mi_pendiente/features/racha/domain/entities/racha.dart';
import 'package:mi_pendiente/features/racha/domain/repositories/racha_repository.dart';
import 'package:mi_pendiente/features/racha/presentation/providers/racha_provider.dart';
import 'package:mi_pendiente/shell/splash_screen.dart';
import 'helpers/test_fakes.dart';

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
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es_ES', null);
  });

  group('Fase 11: AppTypography - Jerarquía Visual', () {
    testWidgets('AppTypography define estilos consistentes y armonizados', (tester) async {
      expect(AppTypography.displayLarge.fontSize, 30);
      expect(AppTypography.displayLarge.fontWeight, FontWeight.w800);

      expect(AppTypography.headlineMedium.fontSize, 24);
      expect(AppTypography.headlineMedium.fontWeight, FontWeight.w700);

      expect(AppTypography.titleLarge.fontSize, 18);
      expect(AppTypography.titleLarge.fontWeight, FontWeight.w700);

      expect(AppTypography.titleMedium.fontSize, 15.5);
      expect(AppTypography.titleMedium.fontWeight, FontWeight.w600);

      expect(AppTypography.bodyLarge.fontSize, 15);
      expect(AppTypography.bodyRegular.fontSize, 14);
      expect(AppTypography.bodySecondary.fontSize, 13);
      expect(AppTypography.statNumber.fontSize, 24);
      expect(AppTypography.timeLabel.fontSize, 13.5);
      expect(AppTypography.tagText.fontSize, 11.5);
      expect(AppTypography.buttonLarge.fontSize, 15.5);
    });
  });

  group('Fase 11: EmptyStateWidget - Estados Vacíos Ilustrados', () {
    testWidgets('renderiza icono, título, mensaje y botón CTA opcional', (tester) async {
      bool botonPresionado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icono: Icons.task_alt_rounded,
              titulo: '¡Todo al día!',
              mensaje: 'No tienes tareas pendientes para hoy.',
              textoBoton: 'Crear pendiente',
              alPresionarBoton: () {
                botonPresionado = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.task_alt_rounded), findsOneWidget);
      expect(find.text('¡Todo al día!'), findsOneWidget);
      expect(find.text('No tienes tareas pendientes para hoy.'), findsOneWidget);
      expect(find.text('Crear pendiente'), findsOneWidget);

      await tester.tap(find.text('Crear pendiente'));
      await tester.pumpAndSettle();

      expect(botonPresionado, isTrue);
    });

    testWidgets('no renderiza botón si alPresionarBoton o textoBoton es nulo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icono: Icons.checklist_rounded,
              titulo: 'Sin tareas',
              mensaje: 'Mensaje sin acción',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('Fase 11: TaskCard - Rediseño con Hero, acento y animación', () {
    final tareaEjemplo = Pendiente(
      id: 'task-hero-1',
      titulo: 'Diseñar nueva interfaz',
      fecha: DateTime(2026, 9, 18),
      hora: const HoraDelDia(hora: 10, minuto: 30),
      prioridad: Prioridad.alta,
      estaCompletado: false,
    );

    testWidgets('renderiza tarjeta con Hero, título, hora y checkbox', (tester) async {
      bool tapCard = false;
      bool toggleVal = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              pendiente: tareaEjemplo,
              onTap: () => tapCard = true,
              onToggleComplete: (val) => toggleVal = val,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica widget Hero con tag correspondiente
      final heroFinder = find.byType(Hero);
      expect(heroFinder, findsOneWidget);
      final heroWidget = tester.widget<Hero>(heroFinder);
      expect(heroWidget.tag, 'task_card_task-hero-1');

      // Verifica título y hora
      expect(find.text('Diseñar nueva interfaz'), findsOneWidget);
      expect(find.text('10:30 AM'), findsOneWidget);

      // Tap en la tarjeta
      await tester.tap(find.text('Diseñar nueva interfaz'));
      expect(tapCard, isTrue);

      // Tap en el checkbox
      await tester.tap(find.byType(AnimatedContainer));
      expect(toggleVal, isTrue);
    });

    testWidgets('muestra checkmark cuando el pendiente está completado', (tester) async {
      final completado = tareaEjemplo.copyWith(estaCompletado: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              pendiente: completado,
              onTap: () {},
              onToggleComplete: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });

  group('Fase 11: SplashScreen - Identidad visual oficial', () {
    testWidgets('SplashScreen renderiza título y subtítulo oficial', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final fakeRepo = FakeRachaRepository(
        const Racha(
          diasActuales: 7,
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
            notificationSchedulerProvider.overrideWithValue(FakeNotificationScheduler()),
            pendienteRepositoryProvider.overrideWithValue(FakeRepository([])),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('es', 'ES'),
            ],
            locale: Locale('es', 'ES'),
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Zendae'), findsOneWidget);
      expect(find.text('Organiza tu día, semana y mes'), findsOneWidget);

      // Avanzar timers para liberar recursos del splash
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 600));
    });
  });
}
