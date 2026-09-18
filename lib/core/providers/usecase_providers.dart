import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/actualizar_pendiente.dart';
import '../../domain/usecases/alternar_completado.dart';
import '../../domain/usecases/crear_pendiente.dart';
import '../../domain/usecases/eliminar_pendiente.dart';
import '../../domain/usecases/posponer_para_manana.dart';
import '../../presentation/providers/pendientes_provider.dart';
import 'clock_providers.dart';
import 'notification_providers.dart';

final alternarCompletadoProvider = Provider<AlternarCompletado>((ref) {
  return AlternarCompletado(
    ref.watch(pendienteRepositoryProvider),
    ref.watch(notificationSchedulerProvider),
    ref.watch(relojProvider),
  );
});

final posponerParaMananaProvider = Provider<PosponerParaManana>((ref) {
  return PosponerParaManana(
    ref.watch(pendienteRepositoryProvider),
    ref.watch(notificationSchedulerProvider),
    ref.watch(relojProvider),
  );
});

final crearPendienteProvider = Provider<CrearPendiente>((ref) {
  return CrearPendiente(
    ref.watch(pendienteRepositoryProvider),
    ref.watch(notificationSchedulerProvider),
    ref.watch(relojProvider),
    ref.watch(uuidProvider),
  );
});

final actualizarPendienteProvider = Provider<ActualizarPendiente>((ref) {
  return ActualizarPendiente(
    ref.watch(pendienteRepositoryProvider),
    ref.watch(notificationSchedulerProvider),
    ref.watch(relojProvider),
  );
});

final eliminarPendienteProvider = Provider<EliminarPendiente>((ref) {
  return EliminarPendiente(
    ref.watch(pendienteRepositoryProvider),
    ref.watch(notificationSchedulerProvider),
  );
});
