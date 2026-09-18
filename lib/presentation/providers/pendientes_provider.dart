import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final list = await repository.getPendientes();
      state = state.copyWith(pendientes: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void seleccionarFecha(DateTime fecha) {
    state = state.copyWith(fechaSeleccionada: fecha);
  }

  Future<void> alternarCompletado(String id, bool valor) async {
    await repository.alternarCompletado(id, valor);
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
    await repository.insertarPendiente(pendiente);
    if (pendiente.tieneRecordatorio) {
      await notifications.programarRecordatorioPendiente(pendiente);
    }
    await cargarPendientes();
  }

  Future<void> actualizarPendiente(Pendiente pendiente) async {
    await repository.actualizarPendiente(pendiente);
    if (pendiente.tieneRecordatorio && !pendiente.estaCompletado) {
      await notifications.programarRecordatorioPendiente(pendiente);
    } else {
      await notifications.cancelarRecordatorioPorIdString(pendiente.id);
    }
    await cargarPendientes();
  }

  Future<void> eliminarPendiente(String id) async {
    await repository.eliminarPendiente(id);
    await notifications.cancelarRecordatorioPorIdString(id);
    await cargarPendientes();
  }

  Future<void> posponerParaManana(String id) async {
    final task = state.pendientes.firstWhere((p) => p.id == id);
    final manana = task.fecha.add(const Duration(days: 1));
    final updated = task.copyWith(fecha: manana);
    await repository.actualizarPendiente(updated);
    if (updated.tieneRecordatorio && !updated.estaCompletado) {
      await notifications.programarRecordatorioPendiente(updated);
    }
    await cargarPendientes();
  }

  Future<void> restaurarCompletado(String id) async {
    await repository.alternarCompletado(id, false);
    final task = state.pendientes.where((p) => p.id == id).firstOrNull;
    if (task != null && task.tieneRecordatorio) {
      await notifications.programarRecordatorioPendiente(task);
    }
    await cargarPendientes();
  }

  Future<void> eliminarTodosCompletados() async {
    await repository.eliminarCompletados();
    await cargarPendientes();
  }
}

final pendientesProvider = StateNotifierProvider<PendientesNotifier, PendientesState>((ref) {
  final repository = ref.watch(pendienteRepositoryProvider);
  final notifications = ref.watch(notificationSchedulerProvider);
  return PendientesNotifier(repository, notifications);
});
