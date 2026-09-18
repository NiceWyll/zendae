import 'package:mi_pendiente/core/error/failure.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import '../../domain/entities/limite_chat.dart';
import '../../domain/entities/mensaje_chat.dart';
import '../../domain/repositories/asistente_repository.dart';
import '../datasources/asistente_local_datasource.dart';

class AsistenteRepositoryImpl implements AsistenteRepository {
  final AsistenteLocalDatasource localDatasource;
  final Reloj reloj;

  const AsistenteRepositoryImpl({
    required this.localDatasource,
    required this.reloj,
  });

  @override
  Future<Result<LimiteChat>> obtenerLimite() async {
    try {
      final limite = await localDatasource.obtenerLimite(reloj.ahora());
      return Exito(limite);
    } catch (e) {
      return Fallo(FallaPreferencias('Error al obtener límite de chat: $e'));
    }
  }

  @override
  Future<Result<void>> registrarMensajeEnviado() async {
    try {
      await localDatasource.registrarMensajeEnviado(reloj.ahora());
      return const Exito(null);
    } catch (e) {
      return Fallo(FallaPreferencias('Error al registrar mensaje: $e'));
    }
  }

  @override
  Future<Result<List<MensajeChat>>> obtenerHistorial() async {
    try {
      final mensajes = await localDatasource.obtenerHistorial();
      return Exito(mensajes);
    } catch (e) {
      return Fallo(FallaPreferencias('Error al obtener historial: $e'));
    }
  }

  @override
  Future<Result<void>> guardarMensaje(MensajeChat mensaje) async {
    try {
      await localDatasource.guardarMensaje(mensaje);
      return const Exito(null);
    } catch (e) {
      return Fallo(FallaPreferencias('Error al guardar mensaje: $e'));
    }
  }

  @override
  Future<Result<void>> limpiarHistorial() async {
    try {
      await localDatasource.limpiarHistorial();
      return const Exito(null);
    } catch (e) {
      return Fallo(FallaPreferencias('Error al limpiar historial: $e'));
    }
  }
}
