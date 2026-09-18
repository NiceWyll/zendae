import 'package:flutter/material.dart';
import 'prioridad.dart';

class Pendiente {
  final String id;
  final String titulo;
  final String? descripcion;
  final DateTime fecha;
  final TimeOfDay hora;
  final Prioridad prioridad;
  final bool tieneRecordatorio;
  final int minutosAntes; // Ej. 10, 15, 30, 60
  final String repetir; // "No repetir", "Diario", "Semanal", "Mensual"
  final bool estaCompletado;
  final DateTime? fechaCompletado;

  const Pendiente({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.fecha,
    required this.hora,
    this.prioridad = Prioridad.media,
    this.tieneRecordatorio = false,
    this.minutosAntes = 10,
    this.repetir = 'No repetir',
    this.estaCompletado = false,
    this.fechaCompletado,
  });

  Pendiente copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    DateTime? fecha,
    TimeOfDay? hora,
    Prioridad? prioridad,
    bool? tieneRecordatorio,
    int? minutosAntes,
    String? repetir,
    bool? estaCompletado,
    DateTime? fechaCompletado,
  }) {
    return Pendiente(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      prioridad: prioridad ?? this.prioridad,
      tieneRecordatorio: tieneRecordatorio ?? this.tieneRecordatorio,
      minutosAntes: minutosAntes ?? this.minutosAntes,
      repetir: repetir ?? this.repetir,
      estaCompletado: estaCompletado ?? this.estaCompletado,
      fechaCompletado: fechaCompletado ?? this.fechaCompletado,
    );
  }

  DateTime get fechaHoraCompleta {
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );
  }
}
