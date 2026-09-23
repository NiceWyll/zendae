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

  HoraDelDia _extraerHora(String rawText, DateTime ahora) {
    // 0. Pre-normalizar texto para variantes de am/pm de Siri / iOS dictation
    String text = rawText
        .replaceAll(RegExp(r'\bp\.\s*m\.?\b', caseSensitive: false), 'pm')
        .replaceAll(RegExp(r'\ba\.\s*m\.?\b', caseSensitive: false), 'am')
        .replaceAll(RegExp(r'\bdel\s+mediod[ií]a\b', caseSensitive: false), 'pm')
        .replaceAll(RegExp(r'\bdel\s+d[ií]a\b', caseSensitive: false), 'pm')
        .replaceAll(RegExp(r'\bde\s+la\s+tarde\b', caseSensitive: false), 'pm')
        .replaceAll(RegExp(r'\bde\s+la\s+noche\b', caseSensitive: false), 'pm')
        .replaceAll(RegExp(r'\bde\s+la\s+ma[nñ]ana\b', caseSensitive: false), 'am');

    const mapaPalabrasHora = {
      'una': 1, 'un': 1, 'uno': 1,
      'dos': 2, 'tres': 3, 'cuatro': 4,
      'cinco': 5, 'seis': 6, 'siete': 7,
      'ocho': 8, 'nueve': 9, 'diez': 10,
      'once': 11, 'doce': 12,
    };

    const mapaMinutos = {
      'media': 30, 'treinta': 30,
      'cuarto': 15, 'quince': 15,
      'veinte': 20, 'veinticinco': 25,
      'cuarenta': 40, 'cuarenta y cinco': 45,
      'cincuenta': 50, 'diez': 10, 'cinco': 5,
    };

    // 1. Formato con dos puntos: "12:30 pm", "15:30", "08:00 am", "4:15"
    final regexColon = RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)\s*(am|pm)?\b', caseSensitive: false);
    final matchColon = regexColon.firstMatch(text);
    if (matchColon != null) {
      int h = int.parse(matchColon.group(1)!);
      int m = int.parse(matchColon.group(2)!);
      final periodo = matchColon.group(3)?.toLowerCase();
      if (periodo == 'pm' && h < 12) h += 12;
      if (periodo == 'am' && h == 12) h = 0;
      return HoraDelDia(hora: h.clamp(0, 23), minuto: m.clamp(0, 59));
    }

    // 2. Número con AM/PM directo: "12 pm", "12pm", "3am", "11 pm"
    final regexNumAmPm = RegExp(r'\b(\d{1,2})\s*(am|pm)\b', caseSensitive: false);
    final matchNumAmPm = regexNumAmPm.firstMatch(text);
    if (matchNumAmPm != null) {
      int h = int.parse(matchNumAmPm.group(1)!);
      final periodo = matchNumAmPm.group(2)!.toLowerCase();
      if (periodo == 'pm' && h < 12) h += 12;
      if (periodo == 'am' && h == 12) h = 0;
      return HoraDelDia(hora: h.clamp(0, 23), minuto: 0);
    }

    // 3. Palabra de hora con AM/PM: "doce pm", "tres pm", "diez am"
    final regexPalabraAmPm = RegExp(
      r'\b(una|un|uno|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez|once|doce)\s*(am|pm)\b',
      caseSensitive: false,
    );
    final matchPalabraAmPm = regexPalabraAmPm.firstMatch(text);
    if (matchPalabraAmPm != null) {
      final palabra = matchPalabraAmPm.group(1)!.toLowerCase();
      int h = mapaPalabrasHora[palabra] ?? 12;
      final periodo = matchPalabraAmPm.group(2)!.toLowerCase();
      if (periodo == 'pm' && h < 12) h += 12;
      if (periodo == 'am' && h == 12) h = 0;
      return HoraDelDia(hora: h.clamp(0, 23), minuto: 0);
    }

    // 4. Con prefijo "a las / a la / para las / para la" y dígitos:
    // Ej: "a las 12", "a las 3 y media", "a la 1", "para las 4 y 30", "a las 5 pm"
    final regexPrefijoDigitos = RegExp(
      r'\b(?:a\s+las?|para\s+las?)\s+(\d{1,2})(?:\s*(?:y|:)\s*(\d{1,2}|media|cuarto|treinta|quince|veinte))?\s*(am|pm)?\b',
      caseSensitive: false,
    );
    final matchPrefijoDigitos = regexPrefijoDigitos.firstMatch(text);
    if (matchPrefijoDigitos != null) {
      int h = int.parse(matchPrefijoDigitos.group(1)!);
      int m = 0;
      final minutoMatch = matchPrefijoDigitos.group(2)?.toLowerCase();
      if (minutoMatch != null) {
        m = int.tryParse(minutoMatch) ?? mapaMinutos[minutoMatch] ?? 0;
      }
      final periodo = matchPrefijoDigitos.group(3)?.toLowerCase();

      if (periodo == 'pm' && h < 12) {
        h += 12;
      } else if (periodo == 'am' && h == 12) {
        h = 0;
      } else if (periodo == null) {
        // Heurística cotidiana si no especificó am/pm:
        // 1..6 -> tarde (13:00..18:00)
        // 12 -> mediodía (12:00)
        // 7..11 -> mañana (07:00..11:00)
        if (h >= 1 && h <= 6) h += 12;
      }
      return HoraDelDia(hora: h.clamp(0, 23), minuto: m.clamp(0, 59));
    }

    // 5. Con prefijo "a las / a la / para las / para la" y PALABRAS:
    // Ej: "a las doce", "a las tres y media", "a la una", "para las cuatro"
    final regexPrefijoPalabras = RegExp(
      r'\b(?:a\s+las?|para\s+las?)\s+(una|un|uno|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez|once|doce)(?:\s*(?:y|con)\s*(\d{1,2}|media|cuarto|treinta|quince|veinte))?\s*(am|pm)?\b',
      caseSensitive: false,
    );
    final matchPrefijoPalabras = regexPrefijoPalabras.firstMatch(text);
    if (matchPrefijoPalabras != null) {
      final palabraHora = matchPrefijoPalabras.group(1)!.toLowerCase();
      int h = mapaPalabrasHora[palabraHora] ?? 12;
      int m = 0;
      final minutoMatch = matchPrefijoPalabras.group(2)?.toLowerCase();
      if (minutoMatch != null) {
        m = int.tryParse(minutoMatch) ?? mapaMinutos[minutoMatch] ?? 0;
      }
      final periodo = matchPrefijoPalabras.group(3)?.toLowerCase();

      if (periodo == 'pm' && h < 12) {
        h += 12;
      } else if (periodo == 'am' && h == 12) {
        h = 0;
      } else if (periodo == null) {
        if (h >= 1 && h <= 6) h += 12;
      }
      return HoraDelDia(hora: h.clamp(0, 23), minuto: m.clamp(0, 59));
    }

    // 6. Expresiones generales del día sin hora numérica:
    if (rawText.contains('al mediodia') || rawText.contains('al medio dia') || rawText.contains('al mediodía')) {
      return const HoraDelDia(hora: 12, minuto: 0);
    }
    if (rawText.contains('en la noche') || rawText.contains('de noche')) {
      return const HoraDelDia(hora: 20, minuto: 0);
    }
    if (rawText.contains('en la tarde') || rawText.contains('de tarde')) {
      return const HoraDelDia(hora: 16, minuto: 0);
    }
    if (rawText.contains('en la manana') || rawText.contains('en la mañana') || rawText.contains('por la mañana')) {
      return const HoraDelDia(hora: 9, minuto: 0);
    }

    // 7. Por defecto: 1 hora después o 10:00 AM
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
      // Horas con conectores: "a las 12", "a las doce", "a la 1", "para las 3 y media", etc.
      RegExp(r'\b(?:a\s+las?|para\s+las?)\s+(?:\d{1,2}|una|un|uno|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez|once|doce)(?:\s*(?:y|:|con)\s*(?:\d{1,2}|media|cuarto|treinta|quince|veinte))?(?:\s*(?:am|pm|[ap]\.\s*m\.?|de\s+la\s+mañana|de\s+la\s+manana|de\s+la\s+tarde|de\s+la\s+noche|del\s+mediodía|del\s+mediodia|del\s+día|del\s+dia))?', caseSensitive: false),
      RegExp(r'\b(?:\d{1,2}|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez|once|doce)\s*(?:am|pm|[ap]\.\s*m\.?)', caseSensitive: false),
      RegExp(r'\b([01]?\d|2[0-3]):[0-5]\d\b', caseSensitive: false),
      RegExp(r'\b(al mediodía|al mediodia|en la mañana|en la manana|en la tarde|en la noche)\b', caseSensitive: false),
      RegExp(r'\b(?:del\s+mediod[ií]a|de\s+la\s+tarde|de\s+la\s+noche|de\s+la\s+ma[nñ]ana)\b', caseSensitive: false),
      RegExp(r'[ap]\.\s*m\.?', caseSensitive: false),
      RegExp(r'\b(am|pm)\b', caseSensitive: false),
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
