import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import 'package:mi_pendiente/features/horario/domain/entities/clase.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import '../../data/datasources/ia_datasource.dart';

class InterpretarMensaje {
  final IaDatasource _datasource;
  final Reloj _reloj;

  const InterpretarMensaje(this._datasource, this._reloj);

  Future<Result<ResultadoInterpretacion>> call(
    String texto, {
    List<Pendiente> pendientesExistentes = const [],
    List<Clase> clasesExistentes = const [],
    List<Pendiente>? candidatosPendientesEliminacion,
  }) async {
    try {
      final ahora = _reloj.ahora();
      final resultado = await _datasource.interpretarTexto(
        texto,
        ahora,
        pendientesExistentes: pendientesExistentes,
        clasesExistentes: clasesExistentes,
        candidatosPendientesEliminacion: candidatosPendientesEliminacion,
      );
      return Exito(resultado);
    } catch (e) {
      return const Exito(
        ResultadoInterpretacion(
          respuestaTexto: 'Ocurrió un inconveniente al interpretar tu mensaje. Por favor intenta de nuevo.',
          esConversacional: true,
        ),
      );
    }
  }
}
