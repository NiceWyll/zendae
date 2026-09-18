import '../../core/error/result.dart';
import '../entities/pendiente.dart';

abstract interface class PendienteRepository {
  Future<Result<List<Pendiente>>> getPendientes();
  Future<Result<List<Pendiente>>> getPendientesPorFecha(DateTime fecha);
  Future<Result<List<Pendiente>>> getPendientesPorRango(DateTime inicio, DateTime fin);
  Future<Result<List<Pendiente>>> getPendientesCompletados();
  Future<Result<Pendiente?>> getPendientePorId(String id);
  Future<Result<void>> insertarPendiente(Pendiente pendiente);
  Future<Result<void>> actualizarPendiente(Pendiente pendiente);
  Future<Result<void>> eliminarPendiente(String id);
  Future<Result<void>> alternarCompletado(String id, bool completado);
  Future<Result<void>> eliminarCompletados();
}
