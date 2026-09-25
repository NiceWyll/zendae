import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/providers/clock_providers.dart';
import 'package:mi_pendiente/core/services/tts_service.dart';
import 'package:mi_pendiente/features/horario/presentation/providers/horario_provider.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/pendientes_provider.dart';
import '../../domain/entities/limite_chat.dart';
import '../../domain/entities/mensaje_chat.dart';
import 'asistente_providers.dart';

class ChatState {
  final List<MensajeChat> mensajes;
  final LimiteChat limite;
  final bool estaEscribiendo;
  final String? error;

  const ChatState({
    required this.mensajes,
    required this.limite,
    this.estaEscribiendo = false,
    this.error,
  });

  ChatState copyWith({
    List<MensajeChat>? mensajes,
    LimiteChat? limite,
    bool? estaEscribiendo,
    String? error,
  }) {
    return ChatState(
      mensajes: mensajes ?? this.mensajes,
      limite: limite ?? this.limite,
      estaEscribiendo: estaEscribiendo ?? this.estaEscribiendo,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  List<Pendiente>? _candidatosEliminacion;

  ChatNotifier(this.ref)
      : super(
          ChatState(
            mensajes: const [],
            limite: LimiteChat(
              mensajesUsadosHoy: 0,
              fecha: DateTime.now(),
            ),
          ),
        ) {
    _cargarEstadoInicial();
  }

  Future<void> _cargarEstadoInicial() async {
    final repo = ref.read(asistenteRepositoryProvider);
    final reloj = ref.read(relojProvider);

    final limiteRes = await repo.obtenerLimite();
    final limite = switch (limiteRes) {
      Exito(:final valor) => valor,
      Fallo() => LimiteChat(mensajesUsadosHoy: 0, fecha: reloj.ahora()),
    };

    final historialRes = await repo.obtenerHistorial();
    List<MensajeChat> mensajes = switch (historialRes) {
      Exito(:final valor) => List<MensajeChat>.from(valor),
      Fallo() => [],
    };

    if (mensajes.isEmpty) {
      final bienvenida = MensajeChat(
        id: 'bienvenida',
        texto: '¡Hola! 👋 Soy tu asistente IA de Zendae ✨.\n\n'
            'Puedo programar, modificar o borrar recordatorios y decirte tu resumen del día.\n\n'
            'Prueba diciendo:\n'
            '• "¿Qué tengo hoy?"\n'
            '• "Recuérdame llamar al dentista mañana a las 3pm"\n'
            '• "Cambia la tarea del doctor para las 5pm"\n'
            '• "Borra la de mañana"',
        esUsuario: false,
        fecha: reloj.ahora(),
      );
      mensajes = [bienvenida];
    }

    state = state.copyWith(
      mensajes: mensajes,
      limite: limite,
    );
  }

  Future<void> enviarMensaje(String texto) async {
    final limpio = texto.trim();
    if (limpio.isEmpty) return;

    final reloj = ref.read(relojProvider);
    final uuid = ref.read(uuidProvider);

    // 1. Mensaje visual optimista para el usuario
    final mensajeUsuario = MensajeChat(
      id: uuid(),
      texto: limpio,
      esUsuario: true,
      fecha: reloj.ahora(),
    );

    state = state.copyWith(
      mensajes: [...state.mensajes, mensajeUsuario],
      estaEscribiendo: true,
      error: null,
    );

    // Obtener contexto actual de tareas y clases
    final pendientesActuales = ref.read(pendientesProvider).valueOrNull ?? [];
    final clasesActuales = ref.read(clasesProvider).valueOrNull ?? [];

    // 2. Enviar a través del caso de uso
    final caso = ref.read(enviarMensajeChatProvider);
    final res = await caso(
      limpio,
      pendientesExistentes: pendientesActuales,
      clasesExistentes: clasesActuales,
      candidatosPendientesEliminacion: _candidatosEliminacion,
      onCandidatosActualizados: (c) => _candidatosEliminacion = c,
    );

    final repo = ref.read(asistenteRepositoryProvider);
    final limiteActualizado = await repo.obtenerLimite();
    final nuevoLimite = switch (limiteActualizado) {
      Exito(:final valor) => valor,
      Fallo() => state.limite,
    };

    switch (res) {
      case Exito(:final valor):
        state = state.copyWith(
          mensajes: [...state.mensajes, valor],
          limite: nuevoLimite,
          estaEscribiendo: false,
        );

        // Si es un resumen o pide lectura en voz alta (Requisito 6)
        if (valor.debeLeerEnVozAlta) {
          TtsService.instance.hablar(valor.texto);
        }

        // Refrescar lista de tareas en toda la app
        ref.invalidate(pendientesProvider);

      case Fallo(:final failure):
        final mensajeError = MensajeChat(
          id: uuid(),
          texto: 'Error: ${failure.mensaje}',
          esUsuario: false,
          fecha: reloj.ahora(),
          esError: true,
        );
        state = state.copyWith(
          mensajes: [...state.mensajes, mensajeError],
          limite: nuevoLimite,
          estaEscribiendo: false,
        );
    }
  }

  Future<void> limpiarConversacion() async {
    final repo = ref.read(asistenteRepositoryProvider);
    final reloj = ref.read(relojProvider);
    await repo.limpiarHistorial();

    final bienvenida = MensajeChat(
      id: 'bienvenida',
      texto: 'Conversación reiniciada ✨. ¿Qué nuevo pendiente te gustaría programar?',
      esUsuario: false,
      fecha: reloj.ahora(),
    );

    state = state.copyWith(
      mensajes: [bienvenida],
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
