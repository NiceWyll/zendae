import 'package:mi_pendiente/core/error/result.dart';
import '../entities/limite_chat.dart';
import '../entities/mensaje_chat.dart';

abstract class AsistenteRepository {
  Future<Result<LimiteChat>> obtenerLimite();
  Future<Result<void>> registrarMensajeEnviado();
  Future<Result<List<MensajeChat>>> obtenerHistorial();
  Future<Result<void>> guardarMensaje(MensajeChat mensaje);
  Future<Result<void>> limpiarHistorial();
}
