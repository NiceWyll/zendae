import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import '../entities/hito_racha.dart';
import '../entities/racha.dart';
import '../repositories/racha_repository.dart';

typedef ValidadorDiaActivo = Future<bool> Function(DateTime fecha);

class ActualizarRacha {
  const ActualizarRacha(this._repo, this._reloj, [this._validadorDiaActivo]);

  final RachaRepository _repo;
  final Reloj _reloj;
  final ValidadorDiaActivo? _validadorDiaActivo;

  Future<Result<Racha>> call() async {
    final ahora = _reloj.ahora();
    final hoyUtc = DateTime.utc(ahora.year, ahora.month, ahora.day);
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
      final ultimaUtc = DateTime.utc(ultima.year, ultima.month, ultima.day);
      final diferenciaDias = hoyUtc.difference(ultimaUtc).inDays;

      if (diferenciaDias == 0) {
        // Ya completó una tarea hoy: no incrementa dos veces el mismo día
        return Exito(actual);
      } else if (diferenciaDias == 1) {
        // Consecutivo (ayer completó al menos uno): suma +1 a la racha
        nuevosDias = actual.diasActuales + 1;
      } else {
        // Si hay días intermedios, verificar si fueron días sin clases ni pendientes (días neutros)
        bool todosNeutros = true;
        if (_validadorDiaActivo != null) {
          for (int i = 1; i < diferenciaDias; i++) {
            final diaIntermedio = ultimaUtc.add(Duration(days: i));
            final huboActividad = await _validadorDiaActivo(diaIntermedio);
            if (huboActividad) {
              todosNeutros = false;
              break;
            }
          }
        } else {
          todosNeutros = false;
        }

        if (todosNeutros) {
          // Ningún día intermedio tenía clases ni pendientes: día(s) neutro(s)
          // La racha continúa donde estaba y suma +1 por el día de hoy
          nuevosDias = actual.diasActuales + 1;
        } else {
          // Se rompió la racha (>1 día con actividad sin completar): empieza de nuevo en 1
          nuevosDias = 1;
        }
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
