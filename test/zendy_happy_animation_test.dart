import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mi_pendiente/core/constants/app_config.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/features/racha/domain/entities/racha.dart';
import 'package:mi_pendiente/features/racha/domain/repositories/racha_repository.dart';
import 'package:mi_pendiente/features/racha/presentation/providers/racha_provider.dart';
import 'package:mi_pendiente/features/racha/presentation/screens/mis_logros_screen.dart';
import 'package:mi_pendiente/features/racha/presentation/widgets/zendy_personaje_widget.dart';

class _FakeRachaRepo implements RachaRepository {
  final Racha racha;
  _FakeRachaRepo(this.racha);

  @override
  Future<Result<Racha>> obtenerRacha() async => Exito(racha);

  @override
  Future<Result<void>> guardarRacha(Racha r) async => const Exito(null);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Zendy Animación Feliz y Bloqueos Android', () {
    test('Verificación de Bloqueos en Android vs iOS', () {
      // Por defecto en entorno no iOS, debe estar bloqueado
      AppConfig.todoDesbloqueado = false;
      expect(AppConfig.todoDesbloqueado, isFalse,
          reason: 'En Android el APK tiene todo bloqueado para desbloqueo por racha');

      AppConfig.todoDesbloqueado = true;
      expect(AppConfig.todoDesbloqueado, isTrue,
          reason: 'En iOS para pruebas está desbloqueado');

      // Restaurar
      AppConfig.todoDesbloqueado = false;
    });

    testWidgets('ZendyPersonajeWidget soporta reaccionarFeliz y tap interactivo', (tester) async {
      final key = GlobalKey<ZendyPersonajeWidgetState>();
      bool tapDisparado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ZendyPersonajeWidget(
                key: key,
                size: 100,
                onTap: () => tapDisparado = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ZendyPersonajeWidget), findsOneWidget);

      // Tocar a Zendy
      await tester.tap(find.byType(ZendyPersonajeWidget));
      await tester.pump();
      expect(tapDisparado, isTrue);

      // Invocar reaccionarFeliz y avanzar la animación
      key.currentState?.reaccionarFeliz();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('MisLogrosScreen muestra Zendy grande interactivo con bocadillo feliz', (tester) async {
      final repo = _FakeRachaRepo(
        const Racha(
          diasActuales: 4,
          mejorRacha: 10,
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
            home: MisLogrosScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar el bocadillo inicial
      expect(find.text('¡Tócame para alegrarme! ✨'), findsOneWidget);

      // Tocar el Zendy grande dentro de la pantalla
      final zendyFinder = find.byType(ZendyPersonajeWidget);
      expect(zendyFinder, findsOneWidget);

      await tester.tap(zendyFinder);
      await tester.pump();

      // El bocadillo se actualiza a una frase alegre
      expect(find.text('¡Tócame para alegrarme! ✨'), findsNothing);
    });
  });
}
