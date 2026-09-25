import '../entities/clase.dart';
import '../entities/examen.dart';

abstract class HorarioRepository {
  Future<List<Clase>> obtenerTodasLasClases();
  Future<List<Clase>> obtenerClasesPorDia(int diaSemana);
  Future<List<Clase>> obtenerClasesVigentesEnFecha(DateTime fecha);
  Future<void> agregarClase(Clase clase);
  Future<void> actualizarClase(Clase clase);
  Future<void> eliminarClase(String id);

  Future<List<Examen>> obtenerExamenesDeClase(String claseId);
  Future<List<Examen>> obtenerTodosLosExamenes();
  Future<void> agregarExamen(Examen examen);
  Future<void> actualizarExamen(Examen examen);
  Future<void> eliminarExamen(String id);
}
