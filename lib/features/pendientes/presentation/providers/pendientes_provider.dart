import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/providers/database_providers.dart';
import '../../data/datasources/app_database.dart';
import '../../data/repositories/pendiente_repository_impl.dart';
import '../../domain/entities/pendiente.dart';
import '../../domain/repositories/pendiente_repository.dart';
import '../../domain/usecases/actualizar_pendiente.dart';
import '../../domain/usecases/alternar_completado.dart';
import '../../domain/usecases/crear_pendiente.dart';
import '../../domain/usecases/eliminar_pendiente.dart';
import '../../domain/usecases/posponer_para_manana.dart';
import 'usecase_providers.dart';

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
  final AlternarCompletado alternarCompletadoCasoDeUso;
  final PosponerParaManana posponerParaMananaCasoDeUso;
  final CrearPendiente crearPendienteCasoDeUso;
  final ActualizarPendiente actualizarPendienteCasoDeUso;
  final EliminarPendiente eliminarPendienteCasoDeUso;

  PendientesNotifier({
    required this.repository,
    required this.alternarCompletadoCasoDeUso,
    required this.posponerParaMananaCasoDeUso,
    required this.crearPendienteCasoDeUso,
    required this.actualizarPendienteCasoDeUso,
    required this.eliminarPendienteCasoDeUso,
  }) : super(PendientesState()) {
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
    final task = state.pendientes.where((p) => p.id == id).firstOrNull;
    if (task == null) return;
    final res = await alternarCompletadoCasoDeUso(task, valor);
    if (res case Fallo(:final failure)) {
      state = state.copyWith(errorMessage: failure.mensaje);
      return;
    }
    await cargarPendientes();
  }

  Future<void> crearPendiente(Pendiente pendiente) async {
    final res = await crearPendienteCasoDeUso(pendiente);
    if (res case Fallo(:final failure)) {
      state = state.copyWith(errorMessage: failure.mensaje);
      return;
    }
    await cargarPendientes();
  }

  Future<void> actualizarPendiente(Pendiente pendiente) async {
    final res = await actualizarPendienteCasoDeUso(pendiente);
    if (res case Fallo(:final failure)) {
      state = state.copyWith(errorMessage: failure.mensaje);
      return;
    }
    await cargarPendientes();
  }

  Future<void> eliminarPendiente(String id) async {
    final task = state.pendientes.where((p) => p.id == id).firstOrNull;
    final res = await eliminarPendienteCasoDeUso(id, task?.notificacionId);
    if (res case Fallo(:final failure)) {
      state = state.copyWith(errorMessage: failure.mensaje);
      return;
    }
    await cargarPendientes();
  }

  Future<void> posponerParaManana(String id) async {
    final task = state.pendientes.where((p) => p.id == id).firstOrNull;
    if (task == null) return;
    final res = await posponerParaMananaCasoDeUso(task);
    if (res case Fallo(:final failure)) {
      state = state.copyWith(errorMessage: failure.mensaje);
      return;
    }
    await cargarPendientes();
  }

  Future<void> restaurarCompletado(String id) async {
    await alternarCompletado(id, false);
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
  return PendientesNotifier(
    repository: repository,
    alternarCompletadoCasoDeUso: ref.watch(alternarCompletadoProvider),
    posponerParaMananaCasoDeUso: ref.watch(posponerParaMananaProvider),
    crearPendienteCasoDeUso: ref.watch(crearPendienteProvider),
    actualizarPendienteCasoDeUso: ref.watch(actualizarPendienteProvider),
    eliminarPendienteCasoDeUso: ref.watch(eliminarPendienteProvider),
  );
});
