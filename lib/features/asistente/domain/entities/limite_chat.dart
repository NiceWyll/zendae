class LimiteChat {
  final int mensajesUsadosHoy;
  final int mensajesMaximosPorDia;
  final DateTime fecha;

  const LimiteChat({
    required this.mensajesUsadosHoy,
    this.mensajesMaximosPorDia = 35,
    required this.fecha,
  });

  bool get puedeEnviar => mensajesUsadosHoy < mensajesMaximosPorDia;
  int get restantes => (mensajesMaximosPorDia - mensajesUsadosHoy).clamp(0, mensajesMaximosPorDia);

  LimiteChat copyWith({
    int? mensajesUsadosHoy,
    int? mensajesMaximosPorDia,
    DateTime? fecha,
  }) {
    return LimiteChat(
      mensajesUsadosHoy: mensajesUsadosHoy ?? this.mensajesUsadosHoy,
      mensajesMaximosPorDia: mensajesMaximosPorDia ?? this.mensajesMaximosPorDia,
      fecha: fecha ?? this.fecha,
    );
  }
}
