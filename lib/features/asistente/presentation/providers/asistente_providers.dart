import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/providers/clock_providers.dart';
import 'package:mi_pendiente/core/providers/preferences_providers.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/usecase_providers.dart';
import '../../data/datasources/asistente_local_datasource.dart';
import '../../data/datasources/ia_datasource.dart';
import '../../data/repositories/asistente_repository_impl.dart';
import '../../domain/entities/limite_chat.dart';
import '../../domain/entities/mensaje_chat.dart';
import '../../domain/repositories/asistente_repository.dart';
import '../../domain/usecases/enviar_mensaje_chat.dart';
import '../../domain/usecases/interpretar_mensaje.dart';
import '../../domain/usecases/verificar_limite_chat.dart';

class InMemoryAsistenteRepository implements AsistenteRepository {
  LimiteChat _limite = LimiteChat(mensajesUsadosHoy: 0, fecha: DateTime.now());
  final List<MensajeChat> _historial = [];

  @override
  Future<Result<LimiteChat>> obtenerLimite() async => Exito(_limite);

  @override
  Future<Result<void>> registrarMensajeEnviado() async {
    _limite = _limite.copyWith(mensajesUsadosHoy: _limite.mensajesUsadosHoy + 1);
    return const Exito(null);
  }

  @override
  Future<Result<List<MensajeChat>>> obtenerHistorial() async => Exito(List.from(_historial));

  @override
  Future<Result<void>> guardarMensaje(MensajeChat mensaje) async {
    _historial.add(mensaje);
    return const Exito(null);
  }

  @override
  Future<Result<void>> limpiarHistorial() async {
    _historial.clear();
    return const Exito(null);
  }
}

final iaDatasourceProvider = Provider<IaDatasource>((ref) {
  return const NlpIaDatasource();
});

final asistenteRepositoryProvider = Provider<AsistenteRepository>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    final reloj = ref.watch(relojProvider);
    return AsistenteRepositoryImpl(
      localDatasource: AsistenteLocalDatasource(prefs: prefs),
      reloj: reloj,
    );
  } catch (_) {
    return InMemoryAsistenteRepository();
  }
});

final interpretarMensajeProvider = Provider<InterpretarMensaje>((ref) {
  return InterpretarMensaje(
    ref.watch(iaDatasourceProvider),
    ref.watch(relojProvider),
  );
});

final verificarLimiteChatProvider = Provider<VerificarLimiteChat>((ref) {
  return VerificarLimiteChat(ref.watch(asistenteRepositoryProvider));
});

final enviarMensajeChatProvider = Provider<EnviarMensajeChat>((ref) {
  return EnviarMensajeChat(
    repo: ref.watch(asistenteRepositoryProvider),
    interpretar: ref.watch(interpretarMensajeProvider),
    crearPendiente: ref.watch(crearPendienteProvider),
    actualizarPendiente: ref.watch(actualizarPendienteProvider),
    eliminarPendiente: ref.watch(eliminarPendienteProvider),
    reloj: ref.watch(relojProvider),
    generarUuid: ref.watch(uuidProvider),
  );
});
