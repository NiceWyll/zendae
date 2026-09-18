import 'package:mi_pendiente/core/error/result.dart';
import '../entities/limite_chat.dart';
import '../repositories/asistente_repository.dart';

class VerificarLimiteChat {
  final AsistenteRepository _repo;

  const VerificarLimiteChat(this._repo);

  Future<Result<LimiteChat>> call() async {
    return _repo.obtenerLimite();
  }
}
