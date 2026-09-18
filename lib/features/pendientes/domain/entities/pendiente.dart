import 'hora_del_dia.dart';
import 'prioridad.dart';
import 'repeticion.dart';

class Pendiente {
  final String id;
  final String titulo;
  final String? descripcion;
  final DateTime fecha;
  final HoraDelDia hora;
  final Prioridad prioridad;
  final bool tieneRecordatorio;
  final int minutosAntes; // Ej. 10, 15, 30, 60
  final Repeticion repetir;
  final bool estaCompletado;
  final DateTime? fechaCompletado;
  final int? notificacionId;

  const Pendiente({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.fecha,
    required this.hora,
    this.prioridad = Prioridad.media,
    this.tieneRecordatorio = false,
    this.minutosAntes = 10,
    this.repetir = Repeticion.noRepetir,
    this.estaCompletado = false,
    this.fechaCompletado,
    this.notificacionId,
  });

  Pendiente copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    DateTime? fecha,
    HoraDelDia? hora,
    Prioridad? prioridad,
    bool? tieneRecordatorio,
    int? minutosAntes,
    Repeticion? repetir,
    bool? estaCompletado,
    DateTime? fechaCompletado,
    int? notificacionId,
    bool limpiarFechaCompletado = false,
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
      fechaCompletado: limpiarFechaCompletado ? null : (fechaCompletado ?? this.fechaCompletado),
      notificacionId: notificacionId ?? this.notificacionId,
    );
  }

  DateTime get fechaHoraCompleta {
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hora,
      hora.minuto,
    );
  }

  DateTime get momentoDeAviso {
    return fechaHoraCompleta.subtract(Duration(minutes: minutosAntes));
  }
}
