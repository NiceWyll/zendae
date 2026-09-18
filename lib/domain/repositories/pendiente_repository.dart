import '../entities/pendiente.dart';

abstract class PendienteRepository {
  Future<List<Pendiente>> getPendientes();
  Future<List<Pendiente>> getPendientesPorFecha(DateTime fecha);
  Future<List<Pendiente>> getPendientesPorRango(DateTime inicio, DateTime fin);
  Future<List<Pendiente>> getPendientesCompletados();
  Future<Pendiente?> getPendientePorId(String id);
  Future<void> insertarPendiente(Pendiente pendiente);
  Future<void> actualizarPendiente(Pendiente pendiente);
  Future<void> eliminarPendiente(String id);
  Future<void> alternarCompletado(String id, bool completado);
  Future<void> eliminarCompletados();
}
