import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import '../entities/pendiente.dart';
import '../repositories/pendiente_repository.dart';
import '../services/notification_scheduler.dart';

class AlternarCompletado {
  const AlternarCompletado(this._repo, this._alarmas, this._reloj);

  final PendienteRepository _repo;
  final NotificationScheduler _alarmas;
  final Reloj _reloj;

  Future<Result<Pendiente>> call(Pendiente pendiente, [bool? forzarValor]) async {
    final completandoAhora = forzarValor ?? !pendiente.estaCompletado;

    final actualizado = pendiente.copyWith(
      estaCompletado: completandoAhora,
      fechaCompletado: completandoAhora ? _reloj.ahora() : null,
      limpiarFechaCompletado: !completandoAhora,
    );

    final guardado = await _repo.actualizarPendiente(actualizado);
    if (guardado case Fallo(:final failure)) {
      return Fallo(failure);
    }

    // Regla: una tarea completada no debe sonar; al restaurarla, vuelve a sonar
    // solo si su hora sigue en el futuro.
    if (completandoAhora) {
      if (actualizado.notificacionId != null) {
        await _alarmas.cancelarRecordatorio(actualizado.notificacionId!);
      }
      await _alarmas.cancelarRecordatorioPorIdString(actualizado.id);
    } else if (actualizado.tieneRecordatorio &&
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
