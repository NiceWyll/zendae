import '../../domain/entities/hora_del_dia.dart';
import '../../domain/entities/pendiente.dart';
import '../../domain/entities/prioridad.dart';
import '../../domain/entities/repeticion.dart';

class PendienteModel {
  static Pendiente fromMap(Map<String, dynamic> map) {
    // Soporte retrocompatible: si existen hora_hour y hora_minute o si viene como texto
    final HoraDelDia horaParsed;
    if (map['hora'] != null && map['hora'] is String) {
      horaParsed = HoraDelDia.desdeTexto(map['hora'] as String);
    } else if (map['hora_hour'] != null && map['hora_minute'] != null) {
      horaParsed = HoraDelDia(
        hora: map['hora_hour'] as int,
        minuto: map['hora_minute'] as int,
      );
    } else {
      horaParsed = const HoraDelDia(hora: 0, minuto: 0);
    }

    return Pendiente(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String?,
      fecha: DateTime.parse(map['fecha'] as String),
      hora: horaParsed,
      prioridad: Prioridad.fromString(map['prioridad'] as String),
      tieneRecordatorio: (map['tiene_recordatorio'] as int) == 1,
      minutosAntes: map['minutos_antes'] as int,
      repetir: Repeticion.desdeTexto(map['repetir'] as String? ?? 'No repetir'),
      estaCompletado: (map['esta_completado'] as int) == 1,
      fechaCompletado: map['fecha_completado'] != null
          ? DateTime.parse(map['fecha_completado'] as String)
          : null,
      notificacionId: map['notificacion_id'] as int?,
      claseId: map['clase_id'] as String?,
    );
  }

  static Map<String, dynamic> toMap(Pendiente p) {
    return {
      'id': p.id,
      'titulo': p.titulo,
      'descripcion': p.descripcion,
      'fecha': p.fecha.toIso8601String().split('T').first,
      'hora_hour': p.hora.hora,
      'hora_minute': p.hora.minuto,
      'prioridad': p.prioridad.name,
      'tiene_recordatorio': p.tieneRecordatorio ? 1 : 0,
      'minutos_antes': p.minutosAntes,
      'repetir': p.repetir.comoTexto,
      'esta_completado': p.estaCompletado ? 1 : 0,
      'fecha_completado': p.fechaCompletado?.toIso8601String(),
      'notificacion_id': p.notificacionId,
      'clase_id': p.claseId,
    };
  }
}
