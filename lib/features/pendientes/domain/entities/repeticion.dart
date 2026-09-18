enum Repeticion {
  noRepetir(texto: 'No repetir'),
  diario(texto: 'Diario'),
  semanal(texto: 'Semanal'),
  mensual(texto: 'Mensual');

  const Repeticion({required this.texto});
  final String texto;

  static Repeticion desdeTexto(String valor) {
    return switch (valor.toLowerCase().trim()) {
      'diario' => Repeticion.diario,
      'semanal' => Repeticion.semanal,
      'mensual' => Repeticion.mensual,
      _ => Repeticion.noRepetir,
    };
  }

  String get comoTexto => texto;

  @override
  String toString() => texto;
}
