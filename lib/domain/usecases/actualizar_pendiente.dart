import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/services/reloj.dart';
import '../entities/pendiente.dart';
import '../repositories/pendiente_repository.dart';
import '../services/notification_scheduler.dart';

class ActualizarPendiente {
  const ActualizarPendiente(this._repo, this._alarmas, this._reloj);

  final PendienteRepository _repo;
  final NotificationScheduler _alarmas;
  final Reloj _reloj;

  Future<Result<Pendiente>> call(Pendiente pendiente) async {
    if (pendiente.titulo.trim().isEmpty) {
      return const Fallo(FallaValidacion('El título no puede estar vacío'));
    }

    final res = await _repo.actualizarPendiente(pendiente);
    if (res case Fallo(:final failure)) {
      return Fallo(failure);
    }

    if (pendiente.tieneRecordatorio &&
        !pendiente.estaCompletado &&
        pendiente.momentoDeAviso.isAfter(_reloj.ahora())) {
      if (pendiente.notificacionId != null) {
        await _alarmas.programarRecordatorio(
          notificacionId: pendiente.notificacionId!,
          titulo: pendiente.titulo,
          cuerpo: pendiente.descripcion ?? 'Tienes un pendiente programado',
          cuando: pendiente.momentoDeAviso,
        );
      } else {
        await _alarmas.programarRecordatorioPendiente(pendiente);
      }
    } else {
      if (pendiente.notificacionId != null) {
        await _alarmas.cancelarRecordatorio(pendiente.notificacionId!);
      }
      await _alarmas.cancelarRecordatorioPorIdString(pendiente.id);
    }

    return Exito(pendiente);
  }
}
