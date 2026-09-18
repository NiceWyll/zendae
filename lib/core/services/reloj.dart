abstract interface class Reloj {
  DateTime ahora();
}

class RelojDelSistema implements Reloj {
  const RelojDelSistema();

  @override
  DateTime ahora() => DateTime.now();
}

class RelojFijo implements Reloj {
  final DateTime fechaFija;
  const RelojFijo(this.fechaFija);

  @override
  DateTime ahora() => fechaFija;
}
