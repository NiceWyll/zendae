enum RangoRacha {
  bronce(nombre: 'Bronce', icono: '🥉', diasMinimos: 0, nivel: 1),
  oro(nombre: 'Oro', icono: '🥇', diasMinimos: 30, nivel: 2),
  diamante(nombre: 'Diamante', icono: '💎', diasMinimos: 60, nivel: 3),
  leyenda(nombre: 'Leyenda', icono: '👑', diasMinimos: 90, nivel: 4);

  const RangoRacha({
    required this.nombre,
    required this.icono,
    required this.diasMinimos,
    required this.nivel,
  });

  final String nombre;
  final String icono;
  final int diasMinimos;
  final int nivel;
}

enum HitoRacha {
  // RANGO 1: BRONCE (1 a 30 días)
  dias3(
    dias: 3,
    recompensa: 'Insignia de bronce',
    titulo: 'Hábito Inicial',
    rango: RangoRacha.bronce,
  ),
  dias7(
    dias: 7,
    recompensa: 'Tema "Atardecer" desbloqueado',
    titulo: 'Primera Semana',
    rango: RangoRacha.bronce,
  ),
  dias10(
    dias: 10,
    recompensa: 'Icono especial + Comodín de racha',
    titulo: 'Constancia',
    rango: RangoRacha.bronce,
  ),
  dias15(
    dias: 15,
    recompensa: 'Asistente por voz desbloqueado 🎙️',
    titulo: 'Poder de la Voz',
    rango: RangoRacha.bronce,
  ),
  dias22(
    dias: 22,
    recompensa: 'Pack de sonidos + Insignia de Enfoque',
    titulo: 'Enfoque Imparable',
    rango: RangoRacha.bronce,
  ),
  dias30(
    dias: 30,
    recompensa: 'Tema "Aurora" + Estadísticas avanzadas',
    titulo: 'Maestría Mensual',
    rango: RangoRacha.bronce,
  ),

  // RANGO 2: ORO (31 a 60 días)
  dias37(
    dias: 37,
    recompensa: 'Insignia de Oro + Widget exclusivo',
    titulo: 'Impulso Dorado',
    rango: RangoRacha.oro,
  ),
  dias44(
    dias: 44,
    recompensa: 'Tema "Bosque" + Doble comodín',
    titulo: 'Disciplina Férrea',
    rango: RangoRacha.oro,
  ),
  dias51(
    dias: 51,
    recompensa: 'Modo Superproductivo + Sonidos Zen',
    titulo: 'Hábito de Acero',
    rango: RangoRacha.oro,
  ),
  dias58(
    dias: 58,
    recompensa: 'Insignia de Campeón + Respaldo prioritario',
    titulo: 'Respaldo de Campeón',
    rango: RangoRacha.oro,
  ),

  // RANGO 3: DIAMANTE (61 a 90 días)
  dias65(
    dias: 65,
    recompensa: 'Insignia Diamante + Filtro exclusivo',
    titulo: 'Mente Brillante',
    rango: RangoRacha.diamante,
  ),
  dias72(
    dias: 72,
    recompensa: 'Tema "Neón" + 3 Comodines de racha',
    titulo: 'Constancia Pura',
    rango: RangoRacha.diamante,
  ),
  dias79(
    dias: 79,
    recompensa: 'Avatar exclusivo Diamante',
    titulo: 'Voluntad Inquebrantable',
    rango: RangoRacha.diamante,
  ),
  dias86(
    dias: 86,
    recompensa: 'Reporte de productividad exportable',
    titulo: 'Maestro de la Rutina',
    rango: RangoRacha.diamante,
  ),

  // RANGO 4: LEYENDA (91 a 100+ días)
  dias93(
    dias: 93,
    recompensa: 'Insignia Suprema + Efectos especiales',
    titulo: 'Cerca de la Gloria',
    rango: RangoRacha.leyenda,
  ),
  dias100(
    dias: 100,
    recompensa: 'Tema "Racha Dorada" + Insignia máxima',
    titulo: 'Centenario Legendario',
    rango: RangoRacha.leyenda,
  );

  const HitoRacha({
    required this.dias,
    required this.recompensa,
    required this.titulo,
    required this.rango,
  });

  final int dias;
  final String recompensa;
  final String titulo;
  final RangoRacha rango;
}
