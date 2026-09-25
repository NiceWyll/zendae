import '../entities/pendiente.dart';

abstract interface class NotificationScheduler {
  Future<void> programarRecordatorio({
    required int notificacionId,
    required String titulo,
    required String cuerpo,
    required DateTime cuando,
    String? payload,
  });

  Future<void> programarRecordatorioPendiente(Pendiente pendiente, {String? sonido, bool vibracion = true});

  Future<void> programarRecordatorioClase(dynamic clase, {String? sonido, bool vibracion = true});

  Future<void> programarRecordatorioExamen(dynamic examen, String nombreClase, {String? sonido, bool vibracion = true});

  Future<void> cancelarRecordatorio(int notificacionId);

  Future<void> cancelarRecordatorioPorIdString(String pendienteId);

  Future<void> cancelarRecordatorioClase(String claseId);

  Future<void> cancelarRecordatorioExamen(dynamic examen);

  Future<void> cancelarTodas();

  Future<bool> pedirPermisos();

  Future<void> mostrarNotificacionInmediata({
    int id = 9999,
    required String titulo,
    required String cuerpo,
    String? payload,
    String? sonido,
    bool vibracion = true,
  });

  Future<void> probarSonido({
    required String soundId,
    required String tipo,
    bool vibracion = true,
  });

  Future<void> programarResumenDiario({
    required int notificacionId,
    required String titulo,
    required String cuerpo,
    required int hora,
    required int minuto,
  });
}
