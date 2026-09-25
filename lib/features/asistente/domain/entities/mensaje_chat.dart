class MensajeChat {
  final String id;
  final String texto;
  final bool esUsuario;
  final DateTime fecha;
  final String? pendienteCreadoId;
  final String? tituloPendienteCreado;
  final bool esError;
  final bool debeLeerEnVozAlta;

  const MensajeChat({
    required this.id,
    required this.texto,
    required this.esUsuario,
    required this.fecha,
    this.pendienteCreadoId,
    this.tituloPendienteCreado,
    this.esError = false,
    this.debeLeerEnVozAlta = false,
  });

  MensajeChat copyWith({
    String? id,
    String? texto,
    bool? esUsuario,
    DateTime? fecha,
    String? pendienteCreadoId,
    String? tituloPendienteCreado,
    bool? esError,
    bool? debeLeerEnVozAlta,
  }) {
    return MensajeChat(
      id: id ?? this.id,
      texto: texto ?? this.texto,
      esUsuario: esUsuario ?? this.esUsuario,
      fecha: fecha ?? this.fecha,
      pendienteCreadoId: pendienteCreadoId ?? this.pendienteCreadoId,
      tituloPendienteCreado: tituloPendienteCreado ?? this.tituloPendienteCreado,
      esError: esError ?? this.esError,
      debeLeerEnVozAlta: debeLeerEnVozAlta ?? this.debeLeerEnVozAlta,
    );
  }
}
