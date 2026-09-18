import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/repositories/pendiente_repository.dart';
import 'package:mi_pendiente/features/pendientes/domain/services/notification_scheduler.dart';

class FakeRepository implements PendienteRepository {
  final List<Pendiente> _pendientes;
  FakeRepository([List<Pendiente>? pendientes]) : _pendientes = pendientes != null ? List.from(pendientes) : [];

  @override
  Future<Result<List<Pendiente>>> getPendientes() async =>
      Exito(List.unmodifiable(_pendientes));

  @override
  Future<Result<List<Pendiente>>> getPendientesPorFecha(DateTime fecha) async =>
      Exito(_pendientes);

  @override
  Future<Result<List<Pendiente>>> getPendientesPorRango(DateTime inicio, DateTime fin) async =>
      Exito(_pendientes);

  @override
  Future<Result<List<Pendiente>>> getPendientesCompletados() async =>
      Exito(_pendientes.where((p) => p.estaCompletado).toList());

  @override
  Future<Result<Pendiente?>> getPendientePorId(String id) async =>
      Exito(_pendientes.where((p) => p.id == id).firstOrNull);

  @override
  Future<Result<void>> insertarPendiente(Pendiente pendiente) async {
    _pendientes.add(pendiente);
    return const Exito(null);
  }

  @override
  Future<Result<void>> actualizarPendiente(Pendiente pendiente) async {
    final idx = _pendientes.indexWhere((p) => p.id == pendiente.id);
    if (idx != -1) {
      _pendientes[idx] = pendiente;
    }
    return const Exito(null);
  }

  @override
  Future<Result<void>> eliminarPendiente(String id) async {
    _pendientes.removeWhere((p) => p.id == id);
    return const Exito(null);
  }

  @override
  Future<Result<void>> alternarCompletado(String id, bool completado) async {
    final idx = _pendientes.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _pendientes[idx] = _pendientes[idx].copyWith(
        estaCompletado: completado,
        fechaCompletado: completado ? DateTime.now() : null,
      );
    }
    return const Exito(null);
  }

  @override
  Future<Result<void>> eliminarCompletados() async {
    _pendientes.removeWhere((p) => p.estaCompletado);
    return const Exito(null);
  }
}

class FakeNotificationScheduler implements NotificationScheduler {
  @override
  Future<void> programarRecordatorio({
    required int notificacionId,
    required String titulo,
    required String cuerpo,
    required DateTime cuando,
    String? payload,
  }) async {}

  @override
  Future<void> programarRecordatorioPendiente(Pendiente pendiente) async {}

  @override
  Future<void> cancelarRecordatorio(int notificacionId) async {}

  @override
  Future<void> cancelarRecordatorioPorIdString(String pendienteId) async {}

  @override
  Future<void> cancelarTodas() async {}

  @override
  Future<bool> pedirPermisos() async => true;

  @override
  Future<void> mostrarNotificacionInmediata({
    int id = 9999,
    required String titulo,
    required String cuerpo,
    String? payload,
  }) async {}
}
