import 'package:flutter/material.dart';
import 'package:mi_pendiente/core/constants/app_config.dart';

enum CategoriaPrenda {
  cabeza,
  ojos,
  cuello,
  ropa,
  espalda,
  especial,
}

class PrendaPersonaje {
  final String id;
  final String nombre;
  final String descripcion;
  final int diasRequeridos;
  final CategoriaPrenda categoria;
  final String iconoEmoji;
  final Color colorPrimario;
  final Color colorSecundario;

  const PrendaPersonaje({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.diasRequeridos,
    required this.categoria,
    required this.iconoEmoji,
    required this.colorPrimario,
    required this.colorSecundario,
  });

  bool estaDesbloqueada(int diasRacha, List<String> prendasDesbloqueadas) {
    if (AppConfig.todoDesbloqueado) return true;
    if (prendasDesbloqueadas.contains(id)) return true;
    return diasRacha >= diasRequeridos;
  }
}

class CatalogoPrendas {
  CatalogoPrendas._();

  // DÍA 1: Primer hito de racha (accesorio inicial)
  static const PrendaPersonaje corbataIniciador = PrendaPersonaje(
    id: 'corbata_iniciador',
    nombre: 'Corbata Roja Elegante',
    descripcion: 'Corbata roja clásica para lucir formal desde tu primer día consecutivo.',
    diasRequeridos: 1,
    categoria: CategoriaPrenda.cuello,
    iconoEmoji: '👔',
    colorPrimario: Color(0xFFDC2626),
    colorSecundario: Color(0xFFEF4444),
  );

  // DÍA 2: Bandana de concentración
  static const PrendaPersonaje bandanaEnfoque = PrendaPersonaje(
    id: 'bandana_enfoque',
    nombre: 'Bandana de Enfoque',
    descripcion: 'Cinta frontal de concentración mental para no rendirte en tus pendientes.',
    diasRequeridos: 2,
    categoria: CategoriaPrenda.cabeza,
    iconoEmoji: '🎗️',
    colorPrimario: Color(0xFFE11D48),
    colorSecundario: Color(0xFFFB7185),
  );

  // DÍA 3: Gorra deportiva
  static const PrendaPersonaje gorraDeportiva = PrendaPersonaje(
    id: 'gorra_deportiva',
    nombre: 'Gorra Deportiva',
    descripcion: 'Gorra con visera moderna para entrenar tu constancia diaria.',
    diasRequeridos: 3,
    categoria: CategoriaPrenda.cabeza,
    iconoEmoji: '🧢',
    colorPrimario: Color(0xFF2563EB),
    colorSecundario: Color(0xFF1D4ED8),
  );

  // DÍA 5: Gafas de sol
  static const PrendaPersonaje gafasSol = PrendaPersonaje(
    id: 'gafas_sol',
    nombre: 'Gafas de Sol Cool',
    descripcion: 'Lentes oscuros con reflejos para mantener el estilo bajo presión.',
    diasRequeridos: 5,
    categoria: CategoriaPrenda.ojos,
    iconoEmoji: '🕶️',
    colorPrimario: Color(0xFF0F172A),
    colorSecundario: Color(0xFF38BDF8),
  );

  // DÍA 7: Traje de Gala Negro (Ropa completa: chaqueta negra, camisa y corbata)
  static const PrendaPersonaje trajeGalaNegro = PrendaPersonaje(
    id: 'traje_gala_negro',
    nombre: 'Traje de Gala Negro',
    descripcion: 'Traje elegante de etiqueta negra con solapas, camisa blanca y corbata clásica.',
    diasRequeridos: 7,
    categoria: CategoriaPrenda.ropa,
    iconoEmoji: '🤵',
    colorPrimario: Color(0xFF0F172A),
    colorSecundario: Color(0xFFDC2626),
  );

  // DÍA 8: Bufanda abrigada
  static const PrendaPersonaje bufandaCozy = PrendaPersonaje(
    id: 'bufanda_cozy',
    nombre: 'Bufanda Abrigada',
    descripcion: 'Bufanda tejida suave que te protege del frío de la procrastinación.',
    diasRequeridos: 8,
    categoria: CategoriaPrenda.cuello,
    iconoEmoji: '🧣',
    colorPrimario: Color(0xFFDC2626),
    colorSecundario: Color(0xFFEF4444),
  );

  // DÍA 10: Chaleco y Corbata Real
  static const PrendaPersonaje chalecoCaballero = PrendaPersonaje(
    id: 'chaleco_caballero',
    nombre: 'Chaleco y Corbata Real',
    descripcion: 'Chaleco azul marino entallado con corbata dorada de distinción.',
    diasRequeridos: 10,
    categoria: CategoriaPrenda.ropa,
    iconoEmoji: '🦺',
    colorPrimario: Color(0xFF1E3A8A),
    colorSecundario: Color(0xFFF59E0B),
  );

  // DÍA 12: Auriculares Neón
  static const PrendaPersonaje auricularesGamer = PrendaPersonaje(
    id: 'auriculares_gamer',
    nombre: 'Auriculares Neón',
    descripcion: 'Diadema con luces RGB y cancelación de ruido para enfoque total.',
    diasRequeridos: 12,
    categoria: CategoriaPrenda.cabeza,
    iconoEmoji: '🎧',
    colorPrimario: Color(0xFF8B5CF6),
    colorSecundario: Color(0xFF06B6D4),
  );

  // DÍA 15: Pajarita de Gala
  static const PrendaPersonaje corbataGala = PrendaPersonaje(
    id: 'corbata_gala',
    nombre: 'Pajarita de Gala',
    descripcion: 'Elegancia pura para días de exámenes y reuniones importantes.',
    diasRequeridos: 15,
    categoria: CategoriaPrenda.cuello,
    iconoEmoji: '👔',
    colorPrimario: Color(0xFF1E293B),
    colorSecundario: Color(0xFFF59E0B),
  );

  // DÍA 20: Capa de superhéroe
  static const PrendaPersonaje capaHeroe = PrendaPersonaje(
    id: 'capa_heroe',
    nombre: 'Capa de Superhéroe',
    descripcion: 'Capa ondeante que simboliza tu poder para vencer cualquier tarea.',
    diasRequeridos: 20,
    categoria: CategoriaPrenda.espalda,
    iconoEmoji: '🦸',
    colorPrimario: Color(0xFFEA580C),
    colorSecundario: Color(0xFFF97316),
  );

  // DÍA 25: Esmoquin Imperial
  static const PrendaPersonaje esmoquinImperial = PrendaPersonaje(
    id: 'esmoquin_imperial',
    nombre: 'Esmoquin Imperial',
    descripcion: 'Chaqueta de noche blanca y negra de alta costura con corbatín.',
    diasRequeridos: 25,
    categoria: CategoriaPrenda.ropa,
    iconoEmoji: '🕴️',
    colorPrimario: Color(0xFFF8FAFC),
    colorSecundario: Color(0xFF0F172A),
  );

  // DÍA 30: Corona Real Dorada
  static const PrendaPersonaje coronaDorada = PrendaPersonaje(
    id: 'corona_dorada',
    nombre: 'Corona Real Dorada',
    descripcion: 'Prestigio supremo con joyas brillantes para el rey de la productividad.',
    diasRequeridos: 30,
    categoria: CategoriaPrenda.cabeza,
    iconoEmoji: '👑',
    colorPrimario: Color(0xFFF59E0B),
    colorSecundario: Color(0xFFFDE047),
  );

  // DÍA 50: Casco Espacial
  static const PrendaPersonaje cascoAstronauta = PrendaPersonaje(
    id: 'casco_astronauta',
    nombre: 'Casco Espacial',
    descripcion: 'Visor polarizado para misiones hacia objetivos de otro planeta.',
    diasRequeridos: 50,
    categoria: CategoriaPrenda.cabeza,
    iconoEmoji: '🧑‍🚀',
    colorPrimario: Color(0xFFE2E8F0),
    colorSecundario: Color(0xFF06B6D4),
  );

  // DÍA 100: Halo Legendario
  static const PrendaPersonaje haloCelestial = PrendaPersonaje(
    id: 'halo_celestial',
    nombre: 'Halo Legendario',
    descripcion: 'Aura mística reservada únicamente para los 100 días de racha invicta.',
    diasRequeridos: 100,
    categoria: CategoriaPrenda.especial,
    iconoEmoji: '✨',
    colorPrimario: Color(0xFFFBBF24),
    colorSecundario: Color(0xFF67E8F9),
  );

  static const List<PrendaPersonaje> todas = [
    corbataIniciador,
    bandanaEnfoque,
    gorraDeportiva,
    gafasSol,
    trajeGalaNegro,
    bufandaCozy,
    chalecoCaballero,
    auricularesGamer,
    corbataGala,
    capaHeroe,
    esmoquinImperial,
    coronaDorada,
    cascoAstronauta,
    haloCelestial,
  ];

  static PrendaPersonaje? obtenerPorId(String id) {
    for (final p in todas) {
      if (p.id == id) return p;
    }
    return null;
  }

  static List<PrendaPersonaje> desbloqueadasParaDias(int dias) {
    return todas.where((p) => dias >= p.diasRequeridos).toList();
  }
}
