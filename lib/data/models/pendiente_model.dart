import 'package:flutter/material.dart';
import '../../domain/entities/pendiente.dart';
import '../../domain/entities/prioridad.dart';

class PendienteModel {
  static Pendiente fromMap(Map<String, dynamic> map) {
    return Pendiente(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String?,
      fecha: DateTime.parse(map['fecha'] as String),
      hora: TimeOfDay(
        hour: map['hora_hour'] as int,
        minute: map['hora_minute'] as int,
      ),
      prioridad: Prioridad.fromString(map['prioridad'] as String),
      tieneRecordatorio: (map['tiene_recordatorio'] as int) == 1,
      minutosAntes: map['minutos_antes'] as int,
      repetir: map['repetir'] as String? ?? 'No repetir',
      estaCompletado: (map['esta_completado'] as int) == 1,
      fechaCompletado: map['fecha_completado'] != null
          ? DateTime.parse(map['fecha_completado'] as String)
          : null,
    );
  }

  static Map<String, dynamic> toMap(Pendiente p) {
    return {
      'id': p.id,
      'titulo': p.titulo,
      'descripcion': p.descripcion,
      'fecha': p.fecha.toIso8601String().split('T').first,
      'hora_hour': p.hora.hour,
      'hora_minute': p.hora.minute,
      'prioridad': p.prioridad.name,
      'tiene_recordatorio': p.tieneRecordatorio ? 1 : 0,
      'minutos_antes': p.minutosAntes,
      'repetir': p.repetir,
      'esta_completado': p.estaCompletado ? 1 : 0,
      'fecha_completado': p.fechaCompletado?.toIso8601String(),
    };
  }
}
