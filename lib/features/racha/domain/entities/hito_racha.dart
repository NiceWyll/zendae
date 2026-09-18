enum HitoRacha {
  dias3(dias: 3, recompensa: 'Insignia de bronce', titulo: 'Hábito Inicial'),
  dias7(dias: 7, recompensa: 'Tema "Atardecer" desbloqueado', titulo: 'Primera Semana'),
  dias15(dias: 15, recompensa: 'Icono especial + Comodín de racha', titulo: 'Constancia'),
  dias30(dias: 30, recompensa: 'Tema "Aurora" + Estadísticas avanzadas', titulo: 'Maestría Mensual'),
  dias50(dias: 50, recompensa: 'Asistente por voz desbloqueado', titulo: 'Poder de la Racha'),
  dias100(dias: 100, recompensa: 'Tema "Racha Dorada" + Insignia máxima', titulo: 'Centenario Legendario');

  const HitoRacha({
    required this.dias,
    required this.recompensa,
    required this.titulo,
  });

  final int dias;
  final String recompensa;
  final String titulo;
}
