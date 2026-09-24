import 'package:flutter/material.dart';

class Clase {
  final String id;
  final String nombre;
  final int diaSemana; // 1 = Lunes, 7 = Domingo (ISO standard DateTime.weekday)
  final int horaInicio;
  final int minutoInicio;
  final int horaFin;
  final int minutoFin;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int minutosAntes; // 30 o 60, o 0
  final int colorValue; // ARGB Color int
  final String? aula;
  final int? notificacionId;

  const Clase({
    required this.id,
    required this.nombre,
    required this.diaSemana,
    required this.horaInicio,
    required this.minutoInicio,
    required this.horaFin,
    required this.minutoFin,
    required this.fechaInicio,
    required this.fechaFin,
    this.minutosAntes = 30,
    this.colorValue = 0xFF6366F1,
    this.aula,
    this.notificacionId,
  });

  Color get color => Color(colorValue);

  String get diaNombre {
    switch (diaSemana) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Día $diaSemana';
    }
  }

  String get horarioFormateado {
    final hIni = horaInicio.toString().padLeft(2, '0');
    final mIni = minutoInicio.toString().padLeft(2, '0');
    final hFin = horaFin.toString().padLeft(2, '0');
    final mFin = minutoFin.toString().padLeft(2, '0');
    return '$hIni:$mIni - $hFin:$mFin';
  }

  /// Verifica si la clase está vigente y corresponde al día de la semana de la fecha dada
  bool estaVigenteEn(DateTime fecha) {
    final d = DateTime(fecha.year, fecha.month, fecha.day);
    final ini = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);

    if (d.isBefore(ini) || d.isAfter(fin)) return false;
    return d.weekday == diaSemana;
  }

  /// Indica si faltan 3 días o menos para la fecha de fin (aviso de proximidad)
  bool finalizaProntoEn([DateTime? fechaBase]) {
    final now = fechaBase ?? DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
    final diff = fin.difference(hoy).inDays;
    return diff >= 0 && diff <= 3;
  }

  bool get finalizaPronto => finalizaProntoEn();

  /// Días que restan para que concluya el curso
  int get diasRestantes {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
    return fin.difference(hoy).inDays;
  }

  /// Indica si la fecha de fin ya transcurrió
  bool get haExpirado {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
    return fin.isBefore(hoy);
  }

  /// Detecta si hay choque de horario con otra clase
  bool hayChoque(Clase otra) {
    if (id == otra.id) return false;
    if (diaSemana != otra.diaSemana) return false;

    // Verificar si los periodos de vigencia se tocan
    final ini1 = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    final fin1 = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
    final ini2 = DateTime(otra.fechaInicio.year, otra.fechaInicio.month, otra.fechaInicio.day);
    final fin2 = DateTime(otra.fechaFin.year, otra.fechaFin.month, otra.fechaFin.day);

    final seSolapanFechas = !(fin1.isBefore(ini2) || ini1.isAfter(fin2));
    if (!seSolapanFechas) return false;

    // Verificar si las horas se solapan
    final inicioMinutos1 = horaInicio * 60 + minutoInicio;
    final finMinutos1 = horaFin * 60 + minutoFin;
    final inicioMinutos2 = otra.horaInicio * 60 + otra.minutoInicio;
    final finMinutos2 = otra.horaFin * 60 + otra.minutoFin;

    return !(finMinutos1 <= inicioMinutos2 || inicioMinutos1 >= finMinutos2);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'dia_semana': diaSemana,
      'hora_inicio': horaInicio,
      'minuto_inicio': minutoInicio,
      'hora_fin': horaFin,
      'minuto_fin': minutoFin,
      'fecha_inicio': '${fechaInicio.year.toString().padLeft(4, '0')}-${fechaInicio.month.toString().padLeft(2, '0')}-${fechaInicio.day.toString().padLeft(2, '0')}',
      'fecha_fin': '${fechaFin.year.toString().padLeft(4, '0')}-${fechaFin.month.toString().padLeft(2, '0')}-${fechaFin.day.toString().padLeft(2, '0')}',
      'minutos_antes': minutosAntes,
      'color_value': colorValue,
      'aula': aula,
      'notificacion_id': notificacionId,
    };
  }

  factory Clase.fromMap(Map<String, dynamic> map) {
    return Clase(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      diaSemana: map['dia_semana'] as int,
      horaInicio: map['hora_inicio'] as int,
      minutoInicio: map['minuto_inicio'] as int,
      horaFin: map['hora_fin'] as int,
      minutoFin: map['minuto_fin'] as int,
      fechaInicio: DateTime.parse(map['fecha_inicio'] as String),
      fechaFin: DateTime.parse(map['fecha_fin'] as String),
      minutosAntes: map['minutos_antes'] as int? ?? 30,
      colorValue: map['color_value'] as int? ?? 0xFF6366F1,
      aula: map['aula'] as String?,
      notificacionId: map['notificacion_id'] as int?,
    );
  }

  Clase copyWith({
    String? id,
    String? nombre,
    int? diaSemana,
    int? horaInicio,
    int? minutoInicio,
    int? horaFin,
    int? minutoFin,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? minutosAntes,
    int? colorValue,
    String? aula,
    int? notificacionId,
  }) {
    return Clase(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      diaSemana: diaSemana ?? this.diaSemana,
      horaInicio: horaInicio ?? this.horaInicio,
      minutoInicio: minutoInicio ?? this.minutoInicio,
      horaFin: horaFin ?? this.horaFin,
      minutoFin: minutoFin ?? this.minutoFin,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      minutosAntes: minutosAntes ?? this.minutosAntes,
      colorValue: colorValue ?? this.colorValue,
      aula: aula ?? this.aula,
      notificacionId: notificacionId ?? this.notificacionId,
    );
  }
}
