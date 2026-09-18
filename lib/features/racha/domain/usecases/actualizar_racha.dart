import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import '../entities/hito_racha.dart';
import '../entities/racha.dart';
import '../repositories/racha_repository.dart';

class ActualizarRacha {
  const ActualizarRacha(this._repo, this._reloj);

  final RachaRepository _repo;
  final Reloj _reloj;

  Future<Result<Racha>> call() async {
    final ahora = _reloj.ahora();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final res = await _repo.obtenerRacha();
    final actual = switch (res) {
      Exito(:final valor) => valor,
      Fallo() => const Racha.inicial(),
    };

    int nuevosDias;
    final ultima = actual.ultimaFechaCompletado;

    if (ultima == null) {
      nuevosDias = 1;
    } else {
      final ultimaSoloFecha = DateTime(ultima.year, ultima.month, ultima.day);
      final diferenciaDias = hoy.difference(ultimaSoloFecha).inDays;

      if (diferenciaDias == 0) {
        // Ya completó una tarea hoy: no incrementa dos veces el mismo día
        return Exito(actual);
      } else if (diferenciaDias == 1) {
        // Consecutivo (ayer completó al menos uno): suma +1 a la racha
        nuevosDias = actual.diasActuales + 1;
      } else {
        // Se rompió la racha (>1 día sin completar): empieza de nuevo en 1
        nuevosDias = 1;
      }
    }

    final nuevaMejor = nuevosDias > actual.mejorRacha ? nuevosDias : actual.mejorRacha;

    // Calcular nuevos logros desbloqueados
    final nuevosLogros = List<String>.from(actual.logrosDesbloqueados);
    for (final hito in HitoRacha.values) {
      if (nuevosDias >= hito.dias && !nuevosLogros.contains(hito.name)) {
        nuevosLogros.add(hito.name);
      }
    }

    final actualizada = Racha(
      diasActuales: nuevosDias,
      mejorRacha: nuevaMejor,
      ultimaFechaCompletado: ahora,
      logrosDesbloqueados: nuevosLogros,
    );

    final guardado = await _repo.guardarRacha(actualizada);
    if (guardado case Fallo(:final failure)) {
      return Fallo(failure);
    }

    return Exito(actualizada);
  }
}
