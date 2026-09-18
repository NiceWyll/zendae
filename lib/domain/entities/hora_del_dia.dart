class HoraDelDia implements Comparable<HoraDelDia> {
  final int hora; // 0–23
  final int minuto; // 0–59

  const HoraDelDia({required this.hora, required this.minuto})
      : assert(hora >= 0 && hora <= 23, 'La hora debe estar entre 0 y 23'),
        assert(minuto >= 0 && minuto <= 59, 'El minuto debe estar entre 0 y 59');

  /// Formato de persistencia: "HH:mm" — idéntico al actual, sin migración de DB.
  factory HoraDelDia.desdeTexto(String texto) {
    final partes = texto.split(':');
    return HoraDelDia(
      hora: int.parse(partes[0]),
      minuto: int.parse(partes[1]),
    );
  }

  String get comoTexto =>
      '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';

  @override
  int compareTo(HoraDelDia otra) =>
      (hora * 60 + minuto).compareTo(otra.hora * 60 + otra.minuto);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HoraDelDia && other.hora == hora && other.minuto == minuto;

  @override
  int get hashCode => Object.hash(hora, minuto);

  @override
  String toString() => comoTexto;
}
