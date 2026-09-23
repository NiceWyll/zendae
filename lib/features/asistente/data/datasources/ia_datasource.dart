import 'package:mi_pendiente/features/pendientes/domain/entities/hora_del_dia.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/prioridad.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/repeticion.dart';
import '../../domain/entities/pendiente_parseado.dart';

class ResultadoInterpretacion {
  final PendienteParseado? pendiente;
  final String respuestaTexto;
  final bool esConversacional;

  const ResultadoInterpretacion({
    this.pendiente,
    required this.respuestaTexto,
    this.esConversacional = false,
  });
}

abstract class IaDatasource {
  Future<ResultadoInterpretacion> interpretarTexto(String prompt, DateTime ahora);
}

/// Procesador inteligente de lenguaje natural en español para Mi Pendiente
class NlpIaDatasource implements IaDatasource {
  const NlpIaDatasource();

  @override
  Future<ResultadoInterpretacion> interpretarTexto(String prompt, DateTime ahora) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      return const ResultadoInterpretacion(
        respuestaTexto: '¿En qué puedo ayudarte? Puedes pedirme: "Recuérdame llamar al dentista mañana a las 3pm".',
        esConversacional: true,
      );
    }

    final lower = _normalizar(cleanPrompt);

    // 1. Detección de intenciones conversacionales o saludos
    if (_esSaludoOConsulta(lower)) {
      return ResultadoInterpretacion(
        respuestaTexto: _obtenerRespuestaConversacional(lower),
        esConversacional: true,
      );
    }

    // 2. Extracción de prioridad
    final prioridad = _extraerPrioridad(lower);

    // 3. Extracción de repetición
    final repeticion = _extraerRepeticion(lower);

    // 4. Extracción de fecha relativa o absoluta
    final fecha = _extraerFecha(lower, ahora);

    // 5. Extracción de hora
    final hora = _extraerHora(lower, ahora);

    // 6. Extracción y limpieza exhaustiva del título de la tarea
    final titulo = _extraerTitulo(cleanPrompt);

    if (titulo.length < 2) {
      return const ResultadoInterpretacion(
        respuestaTexto: 'No logré identificar el nombre de la tarea. Prueba diciendo: "Anotar comprar leche hoy a las 5pm".',
        esConversacional: true,
      );
    }

    final horaFormateada = '${hora.hora.toString().padLeft(2, '0')}:${hora.minuto.toString().padLeft(2, '0')}';
    final fechaTexto = _describirFecha(fecha, ahora);
    final prioridadTexto = prioridad == Prioridad.alta
        ? ' (prioridad alta)'
        : (prioridad == Prioridad.baja ? ' (prioridad baja)' : '');

    final respuesta = '¡Listo! Programé **"$titulo"** para $fechaTexto a las $horaFormateada$prioridadTexto.';

    final pendiente = PendienteParseado(
      titulo: titulo,
      fecha: fecha,
      hora: hora,
      prioridad: prioridad,
      tieneRecordatorio: true,
      minutosAntes: 10,
      repetir: repeticion,
      explicacionRespuesta: respuesta,
    );

    return ResultadoInterpretacion(
      pendiente: pendiente,
      respuestaTexto: respuesta,
      esConversacional: false,
    );
  }

  bool _esSaludoOConsulta(String text) {
    const saludos = [
      'hola', 'buenos dias', 'buenas tardes', 'buenas noches', 'que tal',
      'que puedes hacer', 'ayuda', 'quien eres', 'gracias', 'adios', 'chau'
    ];
    for (final s in saludos) {
      if (text == s || text.startsWith('$s ') || text.contains('que puedes hacer') || text.contains('como funcionas')) {
        return true;
      }
    }
    return false;
  }

  String _obtenerRespuestaConversacional(String text) {
    if (text.contains('gracias')) {
      return '¡Con gusto! Aquí estaré siempre que necesites organizar tus pendientes. 😊';
    }
    if (text.contains('que puedes hacer') || text.contains('ayuda') || text.contains('como funcionas')) {
      return 'Soy tu Asistente IA. Escribe o dicta lo que debes hacer y lo programaré automáticamente.\n\n'
          '📌 Ejemplos:\n'
          '• "Recuérdame pagar la tarjeta mañana a las 5pm prioridad alta"\n'
          '• "Comprar fruta el viernes a las 10:30"\n'
          '• "Hacer ejercicio todos los días a las 7am"';
    }
    return '¡Hola! Soy tu asistente de Zendae ✨. ¿Qué tarea o recordatorio te gustaría registrar hoy?';
  }

  Prioridad _extraerPrioridad(String text) {
    // Alta prioridad: alta, alto, urgente, urgentisimo, muy importante, maxima
    final regexAlta = RegExp(
      r'\b(prioridad\s+alta|alta\s+prioridad|con\s+prioridad\s+alta|urgente|urgentisimo|muy\s+importante|maxima|maximo|alta|alto)\b',
      caseSensitive: false,
    );
    if (regexAlta.hasMatch(text)) {
      return Prioridad.alta;
    }

    // Baja prioridad: baja, bajo, sin prisa, poco urgente, minima
    final regexBaja = RegExp(
      r'\b(prioridad\s+baja|baja\s+prioridad|con\s+prioridad\s+baja|sin\s+prisa|poco\s+urgente|minima|minimo|baja|bajo)\b',
      caseSensitive: false,
    );
    if (regexBaja.hasMatch(text)) {
      return Prioridad.baja;
    }

    // Media prioridad explícita o por defecto
    return Prioridad.media;
  }

  Repeticion _extraerRepeticion(String text) {
    if (text.contains('todos los dias') || text.contains('cada dia') || text.contains('diario') || text.contains('diariamente')) {
      return Repeticion.diario;
    }
    if (text.contains('todas las semanas') || text.contains('cada semana') || text.contains('semanal') || text.contains('semanalmente')) {
      return Repeticion.semanal;
    }
    if (text.contains('todos los meses') || text.contains('cada mes') || text.contains('mensual') || text.contains('mensualmente')) {
      return Repeticion.mensual;
    }
    return Repeticion.noRepetir;
  }

  DateTime _extraerFecha(String text, DateTime ahora) {
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    // 1. "pasado mañana" / "pasado manana"
    if (text.contains('pasado manana') || text.contains('pasado mañana')) {
      return hoy.add(const Duration(days: 2));
    }

    // 2. "mañana" / "manana" (al inicio, en medio o al final)
    if (RegExp(r'\b(manana|mañana)\b', caseSensitive: false).hasMatch(text)) {
      return hoy.add(const Duration(days: 1));
    }

    // 3. Día de un mes específico: "el 16 de mayo", "16 de octubre", etc.
    const meses = {
      'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4,
      'mayo': 5, 'junio': 6, 'julio': 7, 'agosto': 8,
      'septiembre': 9, 'setiembre': 9, 'octubre': 10,
      'noviembre': 11, 'diciembre': 12,
    };
    final regexDiaMes = RegExp(
      r'\b(?:el\s+(?:dia\s+)?)?(\d{1,2})\s+de\s+([a-z]+)\b',
      caseSensitive: false,
    );
    final matchDiaMes = regexDiaMes.firstMatch(text);
    if (matchDiaMes != null) {
      final dia = int.tryParse(matchDiaMes.group(1)!) ?? 0;
      final nombreMes = matchDiaMes.group(2)!.toLowerCase();
      if (meses.containsKey(nombreMes) && dia >= 1 && dia <= 31) {
        final mes = meses[nombreMes]!;
        int anio = ahora.year;
        if (mes < ahora.month || (mes == ahora.month && dia < ahora.day)) {
          anio += 1;
        }
        return DateTime(anio, mes, dia);
      }
    }

    // 4. Día específico del mes corriente: "el 16", "para el 16", "el dia 16"
    final regexDiaSolo = RegExp(
      r'\b(?:para\s+el|el\s+dia|el)\s+(\d{1,2})\b',
      caseSensitive: false,
    );
    final matchDiaSolo = regexDiaSolo.firstMatch(text);
    if (matchDiaSolo != null) {
      final dia = int.tryParse(matchDiaSolo.group(1)!) ?? 0;
      if (dia >= 1 && dia <= 31) {
        int anio = ahora.year;
        int mes = ahora.month;
        if (dia < ahora.day) {
          // Si el día ya pasó este mes, se asume para el próximo mes
          mes += 1;
          if (mes > 12) {
            mes = 1;
            anio += 1;
          }
        }
        return DateTime(anio, mes, dia);
      }
    }

    // 5. Días de la semana ("el próximo lunes", "el lunes", "este viernes", etc.)
    final diasSemana = {
      'lunes': DateTime.monday,
      'martes': DateTime.tuesday,
      'miercoles': DateTime.wednesday,
      'jueves': DateTime.thursday,
      'viernes': DateTime.friday,
      'sabado': DateTime.saturday,
      'domingo': DateTime.sunday,
    };

    for (final entry in diasSemana.entries) {
      final reg = RegExp('\\b(?:el\\s+)?(?:proximo|este)?\\s*${entry.key}\\b', caseSensitive: false);
      if (reg.hasMatch(text)) {
        int diff = entry.value - ahora.weekday;
        if (diff <= 0) diff += 7; // Próximo día de la semana
        return hoy.add(Duration(days: diff));
      }
    }

    // 6. "hoy"
    if (RegExp(r'\bhoy\b', caseSensitive: false).hasMatch(text)) {
      return hoy;
    }

    return hoy;
  }

  HoraDelDia _extraerHora(String text, DateTime ahora) {
    // 1. Formato 12h: "12 pm", "12:30 pm", "4pm", "11am", "8 am", "5:15 p.m."
    final regex12h = RegExp(r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)\b', caseSensitive: false);
    final match12h = regex12h.firstMatch(text);
    if (match12h != null) {
      int h = int.parse(match12h.group(1)!);
      int m = match12h.group(2) != null ? int.parse(match12h.group(2)!) : 0;
      final periodo = match12h.group(3)!.toLowerCase();

      final esPm = periodo.contains('pm') || periodo.contains('p.m.');
      if (esPm && h < 12) h += 12;
      if (!esPm && h == 12) h = 0;

      return HoraDelDia(hora: h.clamp(0, 23), minuto: m.clamp(0, 59));
    }

    // 2. Formato 24h: "15:30", "18:00", "09:45"
    final regex24h = RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)\b');
    final match24h = regex24h.firstMatch(text);
    if (match24h != null) {
      int h = int.parse(match24h.group(1)!);
      int m = int.parse(match24h.group(2)!);
      return HoraDelDia(hora: h.clamp(0, 23), minuto: m.clamp(0, 59));
    }

    // 3. Formato simple: "a las 4 de la tarde", "a las 12", "a las 9 de la noche", "a las 8 de la mañana"
    final regexSimple = RegExp(r'\ba\s+las\s+(\d{1,2})(?::(\d{2}))?\s*(de\s+la\s+mañana|de\s+la\s+manana|de\s+la\s+tarde|de\s+la\s+noche)?\b', caseSensitive: false);
    final matchSimple = regexSimple.firstMatch(text);
    if (matchSimple != null) {
      int h = int.parse(matchSimple.group(1)!);
      int m = matchSimple.group(2) != null ? int.parse(matchSimple.group(2)!) : 0;
      final periodo = matchSimple.group(3)?.toLowerCase() ?? '';
      if ((periodo.contains('tarde') || periodo.contains('noche')) && h < 12) {
        h += 12;
      }
      return HoraDelDia(hora: h.clamp(0, 23), minuto: m.clamp(0, 59));
    }

    // 4. Períodos generales del día
    if (text.contains('al mediodia') || text.contains('al medio dia')) return const HoraDelDia(hora: 12, minuto: 0);
    if (text.contains('en la noche')) return const HoraDelDia(hora: 20, minuto: 0);
    if (text.contains('en la tarde')) return const HoraDelDia(hora: 16, minuto: 0);
    if (text.contains('en la manana') || text.contains('en la mañana')) return const HoraDelDia(hora: 9, minuto: 0);

    // Por defecto: 1 hora después o 10:00 AM
    int defaultHour = ahora.hour + 1;
    if (defaultHour >= 24) defaultHour = 9;
    return HoraDelDia(hora: defaultHour, minuto: 0);
  }

  String _extraerTitulo(String prompt) {
    String cleaned = prompt;

    // 1. Quitar prefijos comunes de comando al inicio
    final prefijos = [
      RegExp(r'^(por favor\s*)?(recuérdame|recordarme|recuerdame)\s*(de\s*|que\s*)?', caseSensitive: false),
      RegExp(r'^(por favor\s*)?(anota|anotar|crear|agrega|agregar|nueva tarea|nuevo pendiente|programa|programar)\s*(para\s*|que\s*)?', caseSensitive: false),
      RegExp(r'^(pon un recordatorio para|haz un recordatorio para)\s*', caseSensitive: false),
      RegExp(r'^por favor\s*', caseSensitive: false),
    ];

    for (final p in prefijos) {
      cleaned = cleaned.replaceFirst(p, '');
    }

    // 2. Quitar componentes temporales (fecha y hora) de cualquier parte de la frase
    final patronesTemporales = [
      // Fechas relativas
      RegExp(r'\b(pasado mañana|pasado manana)\b', caseSensitive: false),
      RegExp(r'\b(mañana|manana)\b', caseSensitive: false),
      RegExp(r'\bhoy\b', caseSensitive: false),
      // Días de semana
      RegExp(r'\b(el\s+)?(próximo|proximo|este)?\s*(lunes|martes|miércoles|miercoles|jueves|viernes|sábado|sabado|domingo)\b', caseSensitive: false),
      // Días del mes: "el 16 de mayo", "el 16", "para el 16"
      RegExp(r'\b(?:para\s+el|el\s+dia|el)?\s*\d{1,2}\s+de\s+[a-z]+\b', caseSensitive: false),
      RegExp(r'\b(?:para\s+el|el\s+dia|el)\s+\d{1,2}\b', caseSensitive: false),
      // Horas
      RegExp(r'\ba\s+las\s+\d{1,2}(:\d{2})?\s*(am|pm|a\.m\.|p\.m\.|de la mañana|de la tarde|de la noche)?\b', caseSensitive: false),
      RegExp(r'\b\d{1,2}(:\d{2})?\s*(am|pm|a\.m\.|p\.m\.)\b', caseSensitive: false),
      RegExp(r'\b([01]?\d|2[0-3]):[0-5]\d\b', caseSensitive: false),
      RegExp(r'\b(al mediodía|al mediodia|en la mañana|en la manana|en la tarde|en la noche)\b', caseSensitive: false),
    ];

    for (final pat in patronesTemporales) {
      cleaned = cleaned.replaceAll(pat, ' ');
    }

    // 3. Quitar expresiones de prioridad de cualquier parte
    final patronesPrioridad = [
      RegExp(r'\b(con\s+prioridad|prioridad)\s+(alta|media|baja)\b', caseSensitive: false),
      RegExp(r'\b(muy importante|urgente|urgentisimo)\b', caseSensitive: false),
      RegExp(r'\b(sin prisa|poco urgente)\b', caseSensitive: false),
      RegExp(r'\b(alta|alto|media|medio|baja|bajo)\b', caseSensitive: false),
    ];

    for (final pat in patronesPrioridad) {
      cleaned = cleaned.replaceAll(pat, ' ');
    }

    // 4. Quitar repetición
    final patronesRepeticion = [
      RegExp(r'\b(todos los días|todos los dias|cada día|cada dia|diario|diariamente)\b', caseSensitive: false),
      RegExp(r'\b(todas las semanas|cada semana|semanal|semanalmente)\b', caseSensitive: false),
      RegExp(r'\b(todos los meses|cada mes|mensual|mensualmente)\b', caseSensitive: false),
    ];

    for (final pat in patronesRepeticion) {
      cleaned = cleaned.replaceAll(pat, ' ');
    }

    // 5. Limpieza de preposiciones sueltas al inicio o final (ej: "para", "de", "a")
    cleaned = cleaned.trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^(para|de|a)\s+', caseSensitive: false), '');
    cleaned = cleaned.replaceFirst(RegExp(r'\s+(para|de|a|con)$', caseSensitive: false), '');

    // 6. Colapsar espacios múltiples
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.isEmpty) return 'Pendiente';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  String _describirFecha(DateTime fecha, DateTime ahora) {
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final target = DateTime(fecha.year, fecha.month, fecha.day);
    final diff = target.difference(hoy).inDays;

    if (diff == 0) return 'hoy';
    if (diff == 1) return 'mañana';
    if (diff == 2) return 'pasado mañana';

    const dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    return 'el ${dias[fecha.weekday - 1]} ${fecha.day}/${fecha.month}';
  }

  String _normalizar(String s) {
    return s
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }
}
