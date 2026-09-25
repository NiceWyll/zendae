class Examen {
  final String id;
  final String claseId;
  final String titulo;
  final DateTime fecha;
  final int horaHour;
  final int horaMinute;
  final String? aula;
  final int? notificacion1dId;
  final int? notificacion1hId;

  const Examen({
    required this.id,
    required this.claseId,
    required this.titulo,
    required this.fecha,
    required this.horaHour,
    required this.horaMinute,
    this.aula,
    this.notificacion1dId,
    this.notificacion1hId,
  });

  String get horaFormateada {
    final h = horaHour.toString().padLeft(2, '0');
    final m = horaMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime get fechaHoraCompleta {
    return DateTime(fecha.year, fecha.month, fecha.day, horaHour, horaMinute);
  }

  Examen copyWith({
    String? id,
    String? claseId,
    String? titulo,
    DateTime? fecha,
    int? horaHour,
    int? horaMinute,
    String? aula,
    int? notificacion1dId,
    int? notificacion1hId,
  }) {
    return Examen(
      id: id ?? this.id,
      claseId: claseId ?? this.claseId,
      titulo: titulo ?? this.titulo,
      fecha: fecha ?? this.fecha,
      horaHour: horaHour ?? this.horaHour,
      horaMinute: horaMinute ?? this.horaMinute,
      aula: aula ?? this.aula,
      notificacion1dId: notificacion1dId ?? this.notificacion1dId,
      notificacion1hId: notificacion1hId ?? this.notificacion1hId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clase_id': claseId,
      'titulo': titulo,
      'fecha': fecha.toIso8601String().split('T').first,
      'hora_hour': horaHour,
      'hora_minute': horaMinute,
      'aula': aula,
      'notificacion_1d_id': notificacion1dId,
      'notificacion_1h_id': notificacion1hId,
    };
  }

  factory Examen.fromMap(Map<String, dynamic> map) {
    return Examen(
      id: map['id'] as String,
      claseId: map['clase_id'] as String,
      titulo: map['titulo'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      horaHour: map['hora_hour'] as int,
      horaMinute: map['hora_minute'] as int,
      aula: map['aula'] as String?,
      notificacion1dId: map['notificacion_1d_id'] as int?,
      notificacion1hId: map['notificacion_1h_id'] as int?,
    );
  }
}
