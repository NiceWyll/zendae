import 'package:mi_pendiente/domain/entities/pendiente.dart';
import 'package:mi_pendiente/domain/repositories/pendiente_repository.dart';
import 'package:mi_pendiente/domain/services/notification_scheduler.dart';

class FakeRepository implements PendienteRepository {
  final List<Pendiente> _pendientes;
  FakeRepository([List<Pendiente>? pendientes]) : _pendientes = pendientes != null ? List.from(pendientes) : [];

  @override
  Future<List<Pendiente>> getPendientes() async => List.unmodifiable(_pendientes);

  @override
  Future<List<Pendiente>> getPendientesPorFecha(DateTime fecha) async => _pendientes;

  @override
  Future<List<Pendiente>> getPendientesPorRango(DateTime inicio, DateTime fin) async => _pendientes;

  @override
  Future<List<Pendiente>> getPendientesCompletados() async =>
      _pendientes.where((p) => p.estaCompletado).toList();

  @override
  Future<Pendiente?> getPendientePorId(String id) async =>
      _pendientes.where((p) => p.id == id).firstOrNull;

  @override
  Future<void> insertarPendiente(Pendiente pendiente) async => _pendientes.add(pendiente);

  @override
  Future<void> actualizarPendiente(Pendiente pendiente) async {
    final idx = _pendientes.indexWhere((p) => p.id == pendiente.id);
    if (idx != -1) {
      _pendientes[idx] = pendiente;
    }
  }

  @override
  Future<void> eliminarPendiente(String id) async => _pendientes.removeWhere((p) => p.id == id);

  @override
  Future<void> alternarCompletado(String id, bool completado) async {
    final idx = _pendientes.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _pendientes[idx] = _pendientes[idx].copyWith(
        estaCompletado: completado,
        fechaCompletado: completado ? DateTime.now() : null,
      );
    }
  }

  @override
  Future<void> eliminarCompletados() async =>
      _pendientes.removeWhere((p) => p.estaCompletado);
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
