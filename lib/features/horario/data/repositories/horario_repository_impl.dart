import '../../domain/entities/clase.dart';
import '../../domain/repositories/horario_repository.dart';
import '../datasources/horario_local_datasource.dart';

class HorarioRepositoryImpl implements HorarioRepository {
  final HorarioLocalDataSource localDataSource;

  HorarioRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Clase>> obtenerTodasLasClases() async {
    return await localDataSource.getClases();
  }

  @override
  Future<List<Clase>> obtenerClasesPorDia(int diaSemana) async {
    final todas = await localDataSource.getClases();
    return todas.where((c) => c.diaSemana == diaSemana).toList();
  }

  @override
  Future<List<Clase>> obtenerClasesVigentesEnFecha(DateTime fecha) async {
    final todas = await localDataSource.getClases();
    final vigentes = todas.where((c) => c.estaVigenteEn(fecha)).toList();
    vigentes.sort((a, b) {
      final aMin = a.horaInicio * 60 + a.minutoInicio;
      final bMin = b.horaInicio * 60 + b.minutoInicio;
      return aMin.compareTo(bMin);
    });
    return vigentes;
  }

  @override
  Future<void> agregarClase(Clase clase) async {
    await localDataSource.insertarClase(clase);
  }

  @override
  Future<void> actualizarClase(Clase clase) async {
    await localDataSource.actualizarClase(clase);
  }

  @override
  Future<void> eliminarClase(String id) async {
    await localDataSource.eliminarClase(id);
  }
}
