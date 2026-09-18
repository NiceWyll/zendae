import 'hito_racha.dart';

class Racha {
  final int diasActuales;
  final int mejorRacha;
  final DateTime? ultimaFechaCompletado;
  final List<String> logrosDesbloqueados;

  const Racha({
    required this.diasActuales,
    required this.mejorRacha,
    required this.ultimaFechaCompletado,
    required this.logrosDesbloqueados,
  });

  const Racha.inicial()
      : diasActuales = 0,
        mejorRacha = 0,
        ultimaFechaCompletado = null,
        logrosDesbloqueados = const [];

  bool get activaHoy {
    if (ultimaFechaCompletado == null) return false;
    final now = DateTime.now();
    return ultimaFechaCompletado!.year == now.year &&
        ultimaFechaCompletado!.month == now.month &&
        ultimaFechaCompletado!.day == now.day;
  }

  HitoRacha? get proximoHito {
    for (final hito in HitoRacha.values) {
      if (diasActuales < hito.dias) {
        return hito;
      }
    }
    return null;
  }

  double get progresoHaciaProximoHito {
    final proximo = proximoHito;
    if (proximo == null) return 1.0;

    int diasAnterior = 0;
    for (final h in HitoRacha.values) {
      if (h.dias < proximo.dias && h.dias > diasAnterior) {
        diasAnterior = h.dias;
      }
    }

    final rango = proximo.dias - diasAnterior;
    final alcanzadosEnRango = diasActuales - diasAnterior;
    if (alcanzadosEnRango <= 0) return 0.0;
    return (alcanzadosEnRango / rango).clamp(0.0, 1.0);
  }

  Racha copyWith({
    int? diasActuales,
    int? mejorRacha,
    DateTime? ultimaFechaCompletado,
    List<String>? logrosDesbloqueados,
  }) {
    return Racha(
      diasActuales: diasActuales ?? this.diasActuales,
      mejorRacha: mejorRacha ?? this.mejorRacha,
      ultimaFechaCompletado: ultimaFechaCompletado ?? this.ultimaFechaCompletado,
      logrosDesbloqueados: logrosDesbloqueados ?? this.logrosDesbloqueados,
    );
  }
}
