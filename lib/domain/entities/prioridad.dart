enum Prioridad {
  alta(severidad: 3),
  media(severidad: 2),
  baja(severidad: 1);

  const Prioridad({required this.severidad});
  final int severidad;

  static Prioridad fromString(String value) {
    return Prioridad.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => Prioridad.media,
    );
  }
}
