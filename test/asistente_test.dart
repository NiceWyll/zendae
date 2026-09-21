import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/hora_del_dia.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/prioridad.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/repeticion.dart';
import 'package:mi_pendiente/features/pendientes/domain/repositories/pendiente_repository.dart';
import 'package:mi_pendiente/features/pendientes/domain/services/notification_scheduler.dart';
import 'package:mi_pendiente/features/pendientes/domain/usecases/crear_pendiente.dart';
import 'package:mi_pendiente/features/racha/domain/entities/racha.dart';
import 'package:mi_pendiente/features/racha/domain/repositories/racha_repository.dart';
import 'package:mi_pendiente/features/racha/presentation/providers/racha_provider.dart';
import 'package:mi_pendiente/features/asistente/data/datasources/ia_datasource.dart';
import 'package:mi_pendiente/features/asistente/domain/entities/limite_chat.dart';
import 'package:mi_pendiente/features/asistente/domain/entities/mensaje_chat.dart';
import 'package:mi_pendiente/features/asistente/domain/usecases/enviar_mensaje_chat.dart';
import 'package:mi_pendiente/features/asistente/domain/usecases/interpretar_mensaje.dart';
import 'package:mi_pendiente/features/asistente/domain/usecases/verificar_limite_chat.dart';
import 'package:mi_pendiente/features/asistente/presentation/providers/asistente_providers.dart';
import 'package:mi_pendiente/features/asistente/presentation/screens/chat_screen.dart';
import 'package:mi_pendiente/features/asistente/presentation/widgets/boton_microfono.dart';

class MockPendienteRepository extends Mock implements PendienteRepository {}
class MockNotificationScheduler extends Mock implements NotificationScheduler {}

class FakeRachaRepository implements RachaRepository {
  Racha racha;
  FakeRachaRepository(this.racha);

  @override
  Future<Result<Racha>> obtenerRacha() async => Exito(racha);

  @override
  Future<Result<void>> guardarRacha(Racha racha) async {
    this.racha = racha;
    return const Exito(null);
  }
}

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

  final relojFijo = RelojFijo(DateTime(2026, 9, 18, 10, 0));

  group('Fase 9: Entidad LimiteChat', () {
    test('calcula correctamente restantes y puedeEnviar', () {
      final limite = LimiteChat(
        mensajesUsadosHoy: 5,
        mensajesMaximosPorDia: 20,
        fecha: relojFijo.ahora(),
      );
      expect(limite.puedeEnviar, isTrue);
      expect(limite.restantes, 15);

      final agotado = LimiteChat(
        mensajesUsadosHoy: 20,
        mensajesMaximosPorDia: 20,
        fecha: relojFijo.ahora(),
      );
      expect(agotado.puedeEnviar, isFalse);
      expect(agotado.restantes, 0);
    });
  });

  group('Fase 9: Motor de Lenguaje Natural (NlpIaDatasource)', () {
    const nlp = NlpIaDatasource();

    test('interpreta tarea con fecha relativa, hora 12h y prioridad', () async {
      final res = await nlp.interpretarTexto(
        'Recuérdame llamar al médico mañana a las 3pm con prioridad alta',
        relojFijo.ahora(),
      );

      expect(res.esConversacional, isFalse);
      expect(res.pendiente, isNotNull);
      final p = res.pendiente!;

      expect(p.titulo, 'Llamar al médico');
      expect(p.fecha.day, 19); // Mañana
      expect(p.hora.hora, 15);
      expect(p.hora.minuto, 0);
      expect(p.prioridad, Prioridad.alta);
    });

    test('interpreta tarea con hora 24h y repetición diaria', () async {
      final res = await nlp.interpretarTexto(
        'Hacer ejercicio hoy a las 07:30 todos los días',
        relojFijo.ahora(),
      );

      expect(res.esConversacional, isFalse);
      expect(res.pendiente, isNotNull);
      final p = res.pendiente!;

      expect(p.titulo, 'Hacer ejercicio');
      expect(p.fecha.day, 18); // Hoy
      expect(p.hora.hora, 7);
      expect(p.hora.minuto, 30);
      expect(p.repetir, Repeticion.diario);
    });

    test('reconoce saludos y consultas conversacionales sin crear tareas erróneas', () async {
      final res = await nlp.interpretarTexto('Hola qué puedes hacer?', relojFijo.ahora());

      expect(res.esConversacional, isTrue);
      expect(res.pendiente, isNull);
      expect(res.respuestaTexto, contains('Soy tu Asistente IA'));
    });
  });

  group('Fase 9: Casos de Uso del Asistente', () {
    late InMemoryAsistenteRepository repoAsistente;
    late MockPendienteRepository mockRepo;
    late MockNotificationScheduler mockAlarmas;
    late CrearPendiente casoCrear;
    late InterpretarMensaje casoInterpretar;

    setUp(() {
      repoAsistente = InMemoryAsistenteRepository();
      mockRepo = MockPendienteRepository();
      mockAlarmas = MockNotificationScheduler();
      casoCrear = CrearPendiente(mockRepo, mockAlarmas, relojFijo, () => 'uuid-test');
      casoInterpretar = InterpretarMensaje(const NlpIaDatasource(), relojFijo);

      when(() => mockRepo.insertarPendiente(any())).thenAnswer((_) async {
        return const Exito(null);
      });
      when(() => mockAlarmas.programarRecordatorio(
        notificacionId: any(named: 'notificacionId'),
        titulo: any(named: 'titulo'),
        cuerpo: any(named: 'cuerpo'),
        cuando: any(named: 'cuando'),
      )).thenAnswer((_) async {});
    });

    test('VerificarLimiteChat devuelve el cupo del repositorio', () async {
      final caso = VerificarLimiteChat(repoAsistente);
      final res = await caso();
      expect(res, isA<Exito<LimiteChat>>());
      expect((res as Exito<LimiteChat>).valor.mensajesMaximosPorDia, 20);
    });

    test('EnviarMensajeChat crea pendiente vía CrearPendiente y descuenta cuota', () async {
      final casoEnviar = EnviarMensajeChat(
        repo: repoAsistente,
        interpretar: casoInterpretar,
        crearPendiente: casoCrear,
        reloj: relojFijo,
        generarUuid: () => 'uuid-123',
      );

      final res = await casoEnviar('Recuérdame comprar pan mañana a las 8am');
      expect(res, isA<Exito<MensajeChat>>());
      final mensaje = (res as Exito<MensajeChat>).valor;

      expect(mensaje.esUsuario, isFalse);
      expect(mensaje.pendienteCreadoId, 'uuid-test');
      expect(mensaje.tituloPendienteCreado, 'Comprar pan');

      // Verifica que CrearPendiente fue invocado
      verify(() => mockRepo.insertarPendiente(any())).called(1);

      // Verifica que la cuota aumentó en 1
      final limite = await repoAsistente.obtenerLimite();
      expect((limite as Exito<LimiteChat>).valor.mensajesUsadosHoy, 1);
    });

    test('EnviarMensajeChat rechaza amablemente si el límite diario está agotado', () async {
      // Agotar los 20 mensajes
      for (int i = 0; i < 20; i++) {
        await repoAsistente.registrarMensajeEnviado();
      }

      final casoEnviar = EnviarMensajeChat(
        repo: repoAsistente,
        interpretar: casoInterpretar,
        crearPendiente: casoCrear,
        reloj: relojFijo,
        generarUuid: () => 'uuid-123',
      );

      final res = await casoEnviar('Cualquier tarea');
      expect(res, isA<Exito<MensajeChat>>());
      final mensaje = (res as Exito<MensajeChat>).valor;

      expect(mensaje.esError, isTrue);
      expect(mensaje.texto, contains('Has alcanzado el límite diario'));
      verifyNever(() => mockRepo.insertarPendiente(any()));
    });
  });

  group('Fase 9: Desbloqueo de Voz Condicionado a Racha (BotonMicrofono)', () {
    testWidgets('muestra candado cuando la racha es menor a 15 días', (tester) async {
      final repoRacha = FakeRachaRepository(
        const Racha(
          diasActuales: 10, // Menor a 15
          mejorRacha: 10,
          ultimaFechaCompletado: null,
          logrosDesbloqueados: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rachaRepositoryProvider.overrideWithValue(repoRacha),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BotonMicrofono(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

      // Al tocar el botón bloqueado muestra el diálogo motivacional
      await tester.tap(find.byType(BotonMicrofono));
      await tester.pumpAndSettle();

      expect(find.text('Asistente por Voz'), findsOneWidget);
      expect(find.textContaining('Llevas 10 de 15 días'), findsOneWidget);
    });

    testWidgets('muestra micrófono activo cuando la racha es >= 15 días', (tester) async {
      final repoRacha = FakeRachaRepository(
        const Racha(
          diasActuales: 16, // Desbloqueado!
          mejorRacha: 16,
          ultimaFechaCompletado: null,
          logrosDesbloqueados: ['dias15'],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rachaRepositoryProvider.overrideWithValue(repoRacha),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BotonMicrofono(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    });
  });

  group('Fase 9: Pantalla ChatScreen', () {
    testWidgets('ChatScreen renderiza barra de límite, mensaje de bienvenida y campo de texto', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Asistente IA'), findsOneWidget);
      expect(find.text('En línea'), findsOneWidget);
      expect(find.textContaining('Cupo diario:'), findsOneWidget);
      expect(find.textContaining('Soy tu asistente IA de Zendae'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(BotonMicrofono), findsOneWidget);
    });
  });
}
