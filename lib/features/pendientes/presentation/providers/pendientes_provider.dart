import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/providers/clock_providers.dart';
import 'package:mi_pendiente/core/providers/database_providers.dart';
import 'package:mi_pendiente/core/utils/date_time_utils.dart';
import '../../data/datasources/app_database.dart';
import '../../data/repositories/pendiente_repository_impl.dart';
import '../../domain/entities/pendiente.dart';
import '../../domain/repositories/pendiente_repository.dart';
import 'usecase_providers.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return ref.watch(databaseProvider);
});

final pendienteRepositoryProvider = Provider<PendienteRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PendienteRepositoryImpl(appDatabase: db);
});

final mensajeErrorProvider = StateProvider<String?>((ref) => null);

final fechaSeleccionadaProvider = StateProvider<DateTime>((ref) => DateTime.now());

class PendientesNotifier extends AsyncNotifier<List<Pendiente>> {
  @override
  Future<List<Pendiente>> build() async {
    final repository = ref.watch(pendienteRepositoryProvider);
    final resultado = await repository.getPendientes();
    return switch (resultado) {
      Exito(:final valor) => valor,
      Fallo(:final failure) => throw failure,
    };
  }

  void seleccionarFecha(DateTime fecha) {
    ref.read(fechaSeleccionadaProvider.notifier).state = fecha;
  }

  Future<void> alternarCompletado(String id, [bool? forzarValor]) async {
    final currentList = state.valueOrNull ?? [];
    final task = currentList.where((p) => p.id == id).firstOrNull;
    if (task == null) return;

    final caso = ref.read(alternarCompletadoProvider);
    final resultado = await caso(task, forzarValor);

    switch (resultado) {
      case Exito(:final valor):
        state = AsyncData([
          for (final p in state.valueOrNull ?? <Pendiente>[])
            if (p.id == valor.id) valor else p,
        ]);
      case Fallo(:final failure):
        ref.read(mensajeErrorProvider.notifier).state = failure.mensaje;
    }
  }

  Future<void> crearPendiente(Pendiente pendiente) async {
    final caso = ref.read(crearPendienteProvider);
    final resultado = await caso(pendiente);

    switch (resultado) {
      case Exito(:final valor):
        state = AsyncData([
          ...?state.valueOrNull,
          valor,
        ]);
      case Fallo(:final failure):
        ref.read(mensajeErrorProvider.notifier).state = failure.mensaje;
    }
  }

  Future<void> actualizarPendiente(Pendiente pendiente) async {
    final caso = ref.read(actualizarPendienteProvider);
    final resultado = await caso(pendiente);

    switch (resultado) {
      case Exito(:final valor):
        state = AsyncData([
          for (final p in state.valueOrNull ?? <Pendiente>[])
            if (p.id == valor.id) valor else p,
        ]);
      case Fallo(:final failure):
        ref.read(mensajeErrorProvider.notifier).state = failure.mensaje;
    }
  }

  Future<void> eliminarPendiente(String id) async {
    final currentList = state.valueOrNull ?? [];
    final task = currentList.where((p) => p.id == id).firstOrNull;
    final caso = ref.read(eliminarPendienteProvider);
    final resultado = await caso(id, task?.notificacionId);

    switch (resultado) {
      case Exito():
        state = AsyncData([
          for (final p in state.valueOrNull ?? <Pendiente>[])
            if (p.id != id) p,
        ]);
      case Fallo(:final failure):
        ref.read(mensajeErrorProvider.notifier).state = failure.mensaje;
    }
  }

  Future<void> posponerParaManana(String id) async {
    final currentList = state.valueOrNull ?? [];
    final task = currentList.where((p) => p.id == id).firstOrNull;
    if (task == null) return;

    final caso = ref.read(posponerParaMananaProvider);
    final resultado = await caso(task);

    switch (resultado) {
      case Exito(:final valor):
        state = AsyncData([
          for (final p in state.valueOrNull ?? <Pendiente>[])
            if (p.id == valor.id) valor else p,
        ]);
      case Fallo(:final failure):
        ref.read(mensajeErrorProvider.notifier).state = failure.mensaje;
    }
  }

  Future<void> restaurarCompletado(String id) async {
    await alternarCompletado(id, false);
  }

  Future<void> eliminarTodosCompletados() async {
    final repo = ref.read(pendienteRepositoryProvider);
    final res = await repo.eliminarCompletados();
    switch (res) {
      case Exito():
        state = AsyncData([
          for (final p in state.valueOrNull ?? <Pendiente>[])
            if (!p.estaCompletado) p,
        ]);
      case Fallo(:final failure):
        ref.read(mensajeErrorProvider.notifier).state = failure.mensaje;
    }
  }
}

final pendientesProvider =
    AsyncNotifierProvider<PendientesNotifier, List<Pendiente>>(
        PendientesNotifier.new);

final pendientesPorFechaProvider =
    Provider.family<AsyncValue<List<Pendiente>>, DateTime>((ref, fecha) {
  return ref.watch(pendientesProvider).whenData(
        (lista) => lista.where((p) => DateTimeUtils.isSameDay(p.fecha, fecha)).toList(),
      );
});

final pendientesDeHoyProvider = Provider<AsyncValue<List<Pendiente>>>((ref) {
  final hoy = ref.watch(relojProvider).ahora();
  return ref.watch(pendientesPorFechaProvider(hoy));
});

final pendientesCompletadosProvider = Provider<AsyncValue<List<Pendiente>>>((ref) {
  return ref.watch(pendientesProvider).whenData(
        (lista) => lista.where((p) => p.estaCompletado).toList(),
      );
});
