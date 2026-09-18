import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/error/result.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../data/datasources/app_database.dart';
import '../../data/repositories/pendiente_repository_impl.dart';
import '../../domain/entities/pendiente.dart';
import '../../domain/repositories/pendiente_repository.dart';
import '../../domain/services/notification_scheduler.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return ref.watch(databaseProvider);
});

final pendienteRepositoryProvider = Provider<PendienteRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PendienteRepositoryImpl(appDatabase: db);
});

class PendientesState {
  final List<Pendiente> pendientes;
  final bool isLoading;
  final String? errorMessage;
  final DateTime fechaSeleccionada;

  PendientesState({
    this.pendientes = const [],
    this.isLoading = true,
    this.errorMessage,
    DateTime? fechaSeleccionada,
  }) : fechaSeleccionada = fechaSeleccionada ?? DateTime.now();

  PendientesState copyWith({
    List<Pendiente>? pendientes,
    bool? isLoading,
    String? errorMessage,
    DateTime? fechaSeleccionada,
  }) {
    return PendientesState(
      pendientes: pendientes ?? this.pendientes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      fechaSeleccionada: fechaSeleccionada ?? this.fechaSeleccionada,
    );
  }
}

class PendientesNotifier extends StateNotifier<PendientesState> {
  final PendienteRepository repository;
  final NotificationScheduler notifications;

  PendientesNotifier(this.repository, this.notifications) : super(PendientesState()) {
    cargarPendientes();
  }

  Future<void> cargarPendientes() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await repository.getPendientes();
    switch (result) {
      case Exito(:final valor):
        state = state.copyWith(pendientes: valor, isLoading: false);
      case Fallo(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.mensaje);
    }
  }

  void seleccionarFecha(DateTime fecha) {
    state = state.copyWith(fechaSeleccionada: fecha);
  }

  Future<void> alternarCompletado(String id, bool valor) async {
    final res = await repository.alternarCompletado(id, valor);
    if (res case Fallo(:final failure)) {
      state = state.copyWith(errorMessage: failure.mensaje);
      return;
    }
    if (valor) {
      await notifications.cancelarRecordatorioPorIdString(id);
    } else {
      final task = state.pendientes.where((p) => p.id == id).firstOrNull;
      if (task != null && task.tieneRecordatorio) {
        await notifications.programarRecordatorioPendiente(task);
      }
    }
    await cargarPendientes();
  }

  Future<void> crearPendiente(Pendiente pendiente) async {
    final res = await repository.insertarPendiente(pendiente);
    if (res case Fallo(:final failure)) {
      state = state.copyWith(errorMessage: failure.mensaje);
      return;
    }
    if (pendiente.tieneRecordatorio) {
      await notifications.programarRecordatorioPendiente(pendiente);
    }
    await cargarPendientes();
  }

  Future<void> actualizarPendiente(Pendiente pendiente) async {
    final res = await repository.actualizarPendiente(pendiente);
    if (res case Fallo(:final failure)) {
      state = state.copyWith(errorMessage: failure.mensaje);
      return;
    }
    if (pendiente.tieneRecordatorio && !pendiente.estaCompletado) {
      await notifications.programarRecordatorioPendiente(pendiente);
    } else {
      await notifications.cancelarRecordatorioPorIdString(pendiente.id);
    }
    await cargarPendientes();
  }

  Future<void> eliminarPendiente(String id) async {
    final res = await repository.eliminarPendiente(id);
    if (res case Fallo(:final failure)) {
      state = state.copyWith(errorMessage: failure.mensaje);
      return;
    }
    await notifications.cancelarRecordatorioPorIdString(id);
    await cargarPendientes();
  }

  Future<void> posponerParaManana(String id) async {
    final task = state.pendientes.firstWhere((p) => p.id == id);
    final manana = task.fecha.add(const Duration(days: 1));
    final updated = task.copyWith(fecha: manana);
    final res = await repository.actualizarPendiente(updated);
    if (res case Fallo(:final failure)) {
      state = state.copyWith(errorMessage: failure.mensaje);
      return;
    }
    if (updated.tieneRecordatorio && !updated.estaCompletado) {
      await notifications.programarRecordatorioPendiente(updated);
    }
    await cargarPendientes();
  }

  Future<void> restaurarCompletado(String id) async {
    final res = await repository.alternarCompletado(id, false);
    if (res case Fallo(:final failure)) {
      state = state.copyWith(errorMessage: failure.mensaje);
      return;
    }
    final task = state.pendientes.where((p) => p.id == id).firstOrNull;
    if (task != null && task.tieneRecordatorio) {
      await notifications.programarRecordatorioPendiente(task);
    }
    await cargarPendientes();
  }

  Future<void> eliminarTodosCompletados() async {
    final res = await repository.eliminarCompletados();
    if (res case Fallo(:final failure)) {
      state = state.copyWith(errorMessage: failure.mensaje);
      return;
    }
    await cargarPendientes();
  }
}

final pendientesProvider = StateNotifierProvider<PendientesNotifier, PendientesState>((ref) {
  final repository = ref.watch(pendienteRepositoryProvider);
  final notifications = ref.watch(notificationSchedulerProvider);
  return PendientesNotifier(repository, notifications);
});
