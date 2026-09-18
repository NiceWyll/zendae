import 'package:mi_pendiente/features/pendientes/domain/entities/hora_del_dia.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/prioridad.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/repeticion.dart';

class PendienteParseado {
  final String titulo;
  final String? descripcion;
  final DateTime fecha;
  final HoraDelDia hora;
  final Prioridad prioridad;
  final bool tieneRecordatorio;
  final int minutosAntes;
  final Repeticion repetir;
  final String explicacionRespuesta;

  const PendienteParseado({
    required this.titulo,
    this.descripcion,
    required this.fecha,
    required this.hora,
    this.prioridad = Prioridad.media,
    this.tieneRecordatorio = true,
    this.minutosAntes = 10,
    this.repetir = Repeticion.noRepetir,
    required this.explicacionRespuesta,
  });
}
