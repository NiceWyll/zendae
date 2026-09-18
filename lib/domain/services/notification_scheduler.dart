import '../entities/pendiente.dart';

abstract interface class NotificationScheduler {
  Future<void> programarRecordatorio({
    required int notificacionId,
    required String titulo,
    required String cuerpo,
    required DateTime cuando,
    String? payload,
  });

  Future<void> programarRecordatorioPendiente(Pendiente pendiente);

  Future<void> cancelarRecordatorio(int notificacionId);

  Future<void> cancelarRecordatorioPorIdString(String pendienteId);

  Future<void> cancelarTodas();

  Future<bool> pedirPermisos();

  Future<void> mostrarNotificacionInmediata({
    int id = 9999,
    required String titulo,
    required String cuerpo,
    String? payload,
  });
}
