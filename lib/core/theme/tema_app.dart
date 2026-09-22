import 'package:flutter/material.dart';
import '../constants/app_config.dart';

class TemaApp {
  final String id;
  final String nombre;
  final String descripcion;
  final Color colorPrimario;
  final Color colorSecundario;
  final Color? colorAcento;
  final bool esDesbloqueablePorRacha;
  final int? diasRequeridos;

  const TemaApp({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.colorPrimario,
    required this.colorSecundario,
    this.colorAcento,
    this.esDesbloqueablePorRacha = false,
    this.diasRequeridos,
  });

  bool estaDesbloqueado(int diasRacha, List<String> logrosDesbloqueados) {
    if (AppConfig.todoDesbloqueado) return true;
    if (!esDesbloqueablePorRacha) return true;
    if (diasRequeridos == null) return true;

    // Se desbloquea si tiene los días necesarios o el logro correspondiente
    if (diasRacha >= diasRequeridos!) return true;

    final idHito = 'dias$diasRequeridos';
    return logrosDesbloqueados.contains(idHito) ||
        logrosDesbloqueados.contains(id) ||
        logrosDesbloqueados.contains('tema_$id');
  }
}

class TemasDisponibles {
  TemasDisponibles._();

  static const TemaApp clasico = TemaApp(
    id: 'clasico',
    nombre: 'Azul Clásico',
    descripcion: 'Equilibrio profesional y limpio en tonos azul marino profundo',
    colorPrimario: Color(0xFF162032),
    colorSecundario: Color(0xFF60A5FA),
    colorAcento: Color(0xFF93C5FD),
  );

  static const TemaApp esmeralda = TemaApp(
    id: 'esmeralda',
    nombre: 'Esmeralda Fresco',
    descripcion: 'Serenidad y enfoque con verdes naturales y menta',
    colorPrimario: Color(0xFF059669),
    colorSecundario: Color(0xFF10B981),
    colorAcento: Color(0xFF34D399),
  );

  static const TemaApp lavanda = TemaApp(
    id: 'lavanda',
    nombre: 'Lavanda Cósmica',
    descripcion: 'Creatividad y elegancia en violetas e índigos',
    colorPrimario: Color(0xFF7C3AED),
    colorSecundario: Color(0xFF8B5CF6),
    colorAcento: Color(0xFFA78BFA),
  );

  static const TemaApp atardecer = TemaApp(
    id: 'atardecer',
    nombre: 'Atardecer Cálido',
    descripcion: 'Energía y motivación en corales y ámbar radiante',
    colorPrimario: Color(0xFFEA580C),
    colorSecundario: Color(0xFFF97316),
    colorAcento: Color(0xFFFB923C),
    esDesbloqueablePorRacha: true,
    diasRequeridos: 7,
  );

  static const TemaApp aurora = TemaApp(
    id: 'aurora',
    nombre: 'Aurora Boreal',
    descripcion: 'Misticismo nórdico en cian y turquesa vibrante',
    colorPrimario: Color(0xFF0D9488),
    colorSecundario: Color(0xFF14B8A6),
    colorAcento: Color(0xFF2DD4BF),
    esDesbloqueablePorRacha: true,
    diasRequeridos: 30,
  );

  static const TemaApp dorado = TemaApp(
    id: 'dorado',
    nombre: 'Racha Dorada',
    descripcion: 'Prestigio centenario en oro legendario y ámbar',
    colorPrimario: Color(0xFFD97706),
    colorSecundario: Color(0xFFF59E0B),
    colorAcento: Color(0xFFFBBF24),
    esDesbloqueablePorRacha: true,
    diasRequeridos: 100,
  );

  static const List<TemaApp> todos = [
    clasico,
    esmeralda,
    lavanda,
    atardecer,
    aurora,
    dorado,
  ];

  static TemaApp obtenerPorId(String id) {
    for (final t in todos) {
      if (t.id == id) return t;
    }
    return clasico;
  }
}
