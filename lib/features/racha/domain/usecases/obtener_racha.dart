import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import '../entities/racha.dart';
import '../repositories/racha_repository.dart';

class ObtenerRacha {
  const ObtenerRacha(this._repo, this._reloj);

  final RachaRepository _repo;
  final Reloj _reloj;

  Future<Result<Racha>> call() async {
    final res = await _repo.obtenerRacha();
    if (res case Fallo(:final failure)) {
      return Fallo(failure);
    }

    final racha = (res as Exito<Racha>).valor;
    if (racha.ultimaFechaCompletado == null) {
      return Exito(racha);
    }

    // Comprobar si la racha se rompió por inactividad (> 1 día sin completar)
    final ahora = _reloj.ahora();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final ultima = racha.ultimaFechaCompletado!;
    final ultimaFecha = DateTime(ultima.year, ultima.month, ultima.day);
    final diff = hoy.difference(ultimaFecha).inDays;

    if (diff > 1 && racha.diasActuales > 0) {
      // Se rompió la racha: resetear diasActuales a 0 (preservando récord y logros)
      final reseteada = racha.copyWith(diasActuales: 0);
      await _repo.guardarRacha(reseteada);
      return Exito(reseteada);
    }

    return Exito(racha);
  }
}
