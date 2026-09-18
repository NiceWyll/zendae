import 'package:mi_pendiente/core/error/failure.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import '../entities/pendiente.dart';
import '../repositories/pendiente_repository.dart';
import '../services/notification_scheduler.dart';

class PosponerParaManana {
  const PosponerParaManana(this._repo, this._alarmas, this._reloj);

  final PendienteRepository _repo;
  final NotificationScheduler _alarmas;
  final Reloj _reloj;

  Future<Result<Pendiente>> call(Pendiente pendiente) async {
    if (pendiente.estaCompletado) {
      return const Fallo(FallaValidacion('No se puede posponer un pendiente ya completado'));
    }

    final manana = pendiente.fecha.add(const Duration(days: 1));
    final actualizado = pendiente.copyWith(fecha: manana);

    final res = await _repo.actualizarPendiente(actualizado);
    if (res case Fallo(:final failure)) {
      return Fallo(failure);
    }

    if (actualizado.tieneRecordatorio &&
        actualizado.momentoDeAviso.isAfter(_reloj.ahora())) {
      if (actualizado.notificacionId != null) {
        await _alarmas.programarRecordatorio(
          notificacionId: actualizado.notificacionId!,
          titulo: actualizado.titulo,
          cuerpo: actualizado.descripcion ?? 'Tienes un pendiente programado',
          cuando: actualizado.momentoDeAviso,
        );
      } else {
        await _alarmas.programarRecordatorioPendiente(actualizado);
      }
    }

    return Exito(actualizado);
  }
}
