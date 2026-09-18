import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import '../../data/datasources/ia_datasource.dart';

class InterpretarMensaje {
  final IaDatasource _datasource;
  final Reloj _reloj;

  const InterpretarMensaje(this._datasource, this._reloj);

  Future<Result<ResultadoInterpretacion>> call(String texto) async {
    try {
      final ahora = _reloj.ahora();
      final resultado = await _datasource.interpretarTexto(texto, ahora);
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
