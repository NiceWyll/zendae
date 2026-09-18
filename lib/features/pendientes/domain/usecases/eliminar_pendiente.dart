import 'package:mi_pendiente/core/error/result.dart';
import '../repositories/pendiente_repository.dart';
import '../services/notification_scheduler.dart';

class EliminarPendiente {
  const EliminarPendiente(this._repo, this._alarmas);

  final PendienteRepository _repo;
  final NotificationScheduler _alarmas;

  Future<Result<void>> call(String id, [int? notificacionId]) async {
    final res = await _repo.eliminarPendiente(id);
    if (res case Fallo(:final failure)) {
      return Fallo(failure);
    }

    if (notificacionId != null) {
      await _alarmas.cancelarRecordatorio(notificacionId);
    }
    await _alarmas.cancelarRecordatorioPorIdString(id);

    return const Exito(null);
  }
}
