import '../entities/clase.dart';

abstract class HorarioRepository {
  Future<List<Clase>> obtenerTodasLasClases();
  Future<List<Clase>> obtenerClasesPorDia(int diaSemana);
  Future<List<Clase>> obtenerClasesVigentesEnFecha(DateTime fecha);
  Future<void> agregarClase(Clase clase);
  Future<void> actualizarClase(Clase clase);
  Future<void> eliminarClase(String id);
}
