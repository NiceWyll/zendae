import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import '../entities/prioridad.dart';
import '../repositories/pendiente_repository.dart';
import '../services/notification_scheduler.dart';

class ProgramarResumenMatutino {
  const ProgramarResumenMatutino(
    this._repo,
    this._alarmas,
    this._reloj,
  );

  final PendienteRepository _repo;
  final NotificationScheduler _alarmas;
  final Reloj _reloj;

  static const int notificacionIdResumen = 8888;

  Future<Result<void>> call({
    required bool habilitado,
    required int hora,
    required int minuto,
  }) async {
    if (!habilitado) {
      await _alarmas.cancelarRecordatorio(notificacionIdResumen);
      return const Exito(null);
    }

    final hoy = _reloj.ahora();
    final res = await _repo.getPendientesPorFecha(hoy);

    final tareas = switch (res) {
      Exito(:final valor) => valor.where((p) => !p.estaCompletado).toList(),
      Fallo() => [],
    };

    final totalTareas = tareas.length;
    final tareasAlta = tareas.where((p) => p.prioridad == Prioridad.alta).length;

    final String titulo;
    final String cuerpo;

    if (totalTareas > 0) {
      titulo = '🌅 ¡Buenos días! Tu Plan de Hoy';
      final detalleAlta = tareasAlta > 0
          ? ' ($tareasAlta ${tareasAlta == 1 ? 'de alta prioridad' : 'de alta prioridad'})'
          : '';
      final sufijo = totalTareas == 1 ? '1 pendiente' : '$totalTareas pendientes';
      cuerpo = 'Tienes $sufijo para hoy$detalleAlta. ¡Empieza con foco!';
    } else {
      titulo = '🌅 ¡Día despejado!';
      cuerpo = 'No tienes pendientes programados para hoy. ¡Aprovecha tu día!';
    }

    await _alarmas.programarResumenDiario(
      notificacionId: notificacionIdResumen,
      titulo: titulo,
      cuerpo: cuerpo,
      hora: hora,
      minuto: minuto,
    );

    return const Exito(null);
  }
}
