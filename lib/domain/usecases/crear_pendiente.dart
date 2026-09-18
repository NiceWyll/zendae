import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/services/reloj.dart';
import '../entities/pendiente.dart';
import '../repositories/pendiente_repository.dart';
import '../services/notification_scheduler.dart';

class CrearPendiente {
  const CrearPendiente(
    this._repo,
    this._alarmas,
    this._reloj,
    this._generarUuid,
  );

  final PendienteRepository _repo;
  final NotificationScheduler _alarmas;
  final Reloj _reloj;
  final String Function() _generarUuid;

  Future<Result<Pendiente>> call(Pendiente pendiente) async {
    if (pendiente.titulo.trim().isEmpty) {
      return const Fallo(FallaValidacion('El título no puede estar vacío'));
    }

    final id = pendiente.id.trim().isEmpty ? _generarUuid() : pendiente.id;
    final notifId = (pendiente.tieneRecordatorio && pendiente.notificacionId == null)
        ? _reloj.ahora().microsecondsSinceEpoch.remainder(1 << 31)
        : pendiente.notificacionId;

    final conIds = pendiente.copyWith(
      id: id,
      notificacionId: notifId,
    );

    final res = await _repo.insertarPendiente(conIds);
    if (res case Fallo(:final failure)) {
      return Fallo(failure);
    }

    if (conIds.tieneRecordatorio &&
        conIds.momentoDeAviso.isAfter(_reloj.ahora())) {
      if (conIds.notificacionId != null) {
        await _alarmas.programarRecordatorio(
          notificacionId: conIds.notificacionId!,
          titulo: conIds.titulo,
          cuerpo: conIds.descripcion ?? 'Tienes un pendiente programado',
          cuando: conIds.momentoDeAviso,
        );
      } else {
        await _alarmas.programarRecordatorioPendiente(conIds);
      }
    }

    return Exito(conIds);
  }
}
