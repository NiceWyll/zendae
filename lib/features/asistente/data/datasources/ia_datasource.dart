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

    // 4. Extracción de fecha
    final fecha = _extraerFecha(lower, ahora);

    // 5. Extracción de hora
    final hora = _extraerHora(lower, ahora);

    // 6. Extracción y limpieza del título
    final titulo = _extraerTitulo(cleanPrompt);

    if (titulo.length < 2) {
      return const ResultadoInterpretacion(
        respuestaTexto: 'No logré identificar el nombre de la tarea. Prueba diciendo: "Anotar comprar leche hoy a las 5pm".',
        esConversacional: true,
      );
    }

    final horaFormateada = '${hora.hora.toString().padLeft(2, '0')}:${hora.minuto.toString().padLeft(2, '0')}';
    final fechaTexto = _describirFecha(fecha, ahora);

    final respuesta = '¡Listo! Programé **"$titulo"** para $fechaTexto a las $horaFormateada.';

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
    if (text.contains('prioridad alta') || text.contains('urgente') || text.contains('muy importante')) {
      return Prioridad.alta;
    }
    if (text.contains('prioridad baja') || text.contains('sin prisa') || text.contains('poco urgente')) {
      return Prioridad.baja;
    }
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

    if (text.contains('pasado mañana')) {
      return hoy.add(const Duration(days: 2));
    }
    if (text.contains('mañana')) {
      return hoy.add(const Duration(days: 1));
    }
    if (text.contains('hoy')) {
      return hoy;
    }

    final diasSemana = {
      'lunes': DateTime.monday,
      'martes': DateTime.tuesday,
      'miercoles': DateTime.wednesday,
      'miércoles': DateTime.wednesday,
      'jueves': DateTime.thursday,
      'viernes': DateTime.friday,
      'sabado': DateTime.saturday,
      'sábado': DateTime.saturday,
      'domingo': DateTime.sunday,
    };

    for (final entry in diasSemana.entries) {
      if (text.contains(entry.key)) {
        int diff = entry.value - ahora.weekday;
        if (diff <= 0) diff += 7; // Próximo día de la semana
        return hoy.add(Duration(days: diff));
      }
    }

    return hoy;
  }

  HoraDelDia _extraerHora(String text, DateTime ahora) {
    // 1. Formato 12h: "3:30 pm", "4pm", "11am", "8 am", "5:15 p.m."
    final regex12h = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)', caseSensitive: false);
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

    // 2. Formato 24h: "a las 15:30", "18:00", "09:45"
    final regex24h = RegExp(r'(\d{1,2}):(\d{2})');
    final match24h = regex24h.firstMatch(text);
    if (match24h != null) {
      int h = int.parse(match24h.group(1)!);
      int m = int.parse(match24h.group(2)!);
      return HoraDelDia(hora: h.clamp(0, 23), minuto: m.clamp(0, 59));
    }

    // 3. Formato simple: "a las 4 de la tarde", "a las 9 de la noche", "a las 8 de la mañana"
    final regexSimple = RegExp(r'a las (\d{1,2})(?:\s*(de la mañana|de la tarde|de la noche))?', caseSensitive: false);
    final matchSimple = regexSimple.firstMatch(text);
    if (matchSimple != null) {
      int h = int.parse(matchSimple.group(1)!);
      final periodo = matchSimple.group(2)?.toLowerCase() ?? '';
      if ((periodo.contains('tarde') || periodo.contains('noche')) && h < 12) {
        h += 12;
      }
      return HoraDelDia(hora: h.clamp(0, 23), minuto: 0);
    }

    // 4. Períodos generales del día
    if (text.contains('en la noche')) return const HoraDelDia(hora: 20, minuto: 0);
    if (text.contains('en la tarde')) return const HoraDelDia(hora: 16, minuto: 0);
    if (text.contains('en la mañana')) return const HoraDelDia(hora: 9, minuto: 0);

    // Por defecto: 1 hora después o 10:00 AM
    int defaultHour = ahora.hour + 1;
    if (defaultHour >= 24) defaultHour = 9;
    return HoraDelDia(hora: defaultHour, minuto: 0);
  }

  String _extraerTitulo(String prompt) {
    String cleaned = prompt;

    // Quitar prefijos comunes
    final prefijos = [
      RegExp(r'^(por favor\s*)?(recuérdame|recordarme|recuerdame)\s*(de\s*|que\s*)?', caseSensitive: false),
      RegExp(r'^(por favor\s*)?(anota|anotar|crear|agrega|agregar|nueva tarea|nuevo pendiente)\s*(para\s*|que\s*)?', caseSensitive: false),
      RegExp(r'^(pon un recordatorio para|haz un recordatorio para|programa)\s*', caseSensitive: false),
    ];

    for (final p in prefijos) {
      cleaned = cleaned.replaceFirst(p, '');
    }

    // Quitar sufijos de hora/fecha/prioridad del título para que quede limpio
    final patronesSufijo = [
      RegExp(r'\s*(hoy|mañana|pasado mañana)(\s+a las\s+\d{1,2}(:\d{2})?\s*(am|pm)?)?', caseSensitive: false),
      RegExp(r'\s*el\s+(lunes|martes|miércoles|miercoles|jueves|viernes|sábado|sabado|domingo)(\s+a las\s+\d{1,2}(:\d{2})?\s*(am|pm)?)?', caseSensitive: false),
      RegExp(r'\s*a las\s+\d{1,2}(:\d{2})?\s*(am|pm|de la mañana|de la tarde|de la noche)?', caseSensitive: false),
      RegExp(r'\s*\d{1,2}(:\d{2})?\s*(am|pm)', caseSensitive: false),
      RegExp(r'\s*con prioridad\s+(alta|media|baja)', caseSensitive: false),
      RegExp(r'\s*prioridad\s+(alta|media|baja)', caseSensitive: false),
      RegExp(r'\s*(urgente|muy importante)', caseSensitive: false),
      RegExp(r'\s*(todos los días|todos los dias|cada día|cada dia|diario|semanal|mensual)', caseSensitive: false),
    ];

    for (final pat in patronesSufijo) {
      cleaned = cleaned.replaceAll(pat, '');
    }

    // Capitalizar la primera letra
    cleaned = cleaned.trim();
    if (cleaned.isEmpty) return 'Pendiente';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  String _describirFecha(DateTime fecha, DateTime ahora) {
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final diff = fecha.difference(hoy).inDays;

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
