enum Repeticion {
  noRepetir(texto: 'Una vez'),
  diario(texto: 'Diariamente'),
  lunAVie(texto: 'Lun a Vie'),
  alarmasDeTurno(texto: 'Alarmas de turno'),
  personalizar(texto: 'Personalizar'),
  semanal(texto: 'Semanal'),
  mensual(texto: 'Mensual');

  const Repeticion({required this.texto});
  final String texto;

  static Repeticion desdeTexto(String valor) {
    final v = valor.toLowerCase().trim();
    if (v == 'una vez' || v == 'no repetir' || v == 'norepetir') {
      return Repeticion.noRepetir;
    }
    if (v == 'diariamente' || v == 'diario') {
      return Repeticion.diario;
    }
    if (v == 'lun a vie' || v == 'lunes a viernes' || v == 'lun-vie') {
      return Repeticion.lunAVie;
    }
    if (v.contains('turno')) {
      return Repeticion.alarmasDeTurno;
    }
    if (v.contains('personaliz')) {
      return Repeticion.personalizar;
    }
    if (v == 'semanal') {
      return Repeticion.semanal;
    }
    if (v == 'mensual') {
      return Repeticion.mensual;
    }
    return Repeticion.noRepetir;
  }

  String get comoTexto => texto;

  @override
  String toString() => texto;
}
