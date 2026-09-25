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
  final bool esExclusivoAndroid;

  const TemaApp({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.colorPrimario,
    required this.colorSecundario,
    this.colorAcento,
    this.esDesbloqueablePorRacha = false,
    this.diasRequeridos,
    this.esExclusivoAndroid = false,
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

  static const TemaApp zafiro = TemaApp(
    id: 'zafiro',
    nombre: 'Zafiro Real',
    descripcion: 'Fuerza y elegancia con tonos azul eléctrico y cobalto',
    colorPrimario: Color(0xFF1E40AF),
    colorSecundario: Color(0xFF3B82F6),
    colorAcento: Color(0xFF60A5FA),
  );

  static const TemaApp cerezo = TemaApp(
    id: 'cerezo',
    nombre: 'Sakura Carmesí',
    descripcion: 'Frescura y vitalidad con carmesí suave y rosa magenta',
    colorPrimario: Color(0xFFBE123C),
    colorSecundario: Color(0xFFF43F5E),
    colorAcento: Color(0xFFFDA4AF),
  );

  static const TemaApp menta = TemaApp(
    id: 'menta',
    nombre: 'Menta Pastel',
    descripcion: 'Claridad mental con menta suave y salvia relajante',
    colorPrimario: Color(0xFF0F766E),
    colorSecundario: Color(0xFF14B8A6),
    colorAcento: Color(0xFF5EEAD4),
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

  static const TemaApp ambar = TemaApp(
    id: 'ambar',
    nombre: 'Ámbar Brillante',
    descripcion: 'Calidez luminosa y dinamismo con matices de miel y caramelo',
    colorPrimario: Color(0xFFB45309),
    colorSecundario: Color(0xFFF59E0B),
    colorAcento: Color(0xFFFDE68A),
    esDesbloqueablePorRacha: true,
    diasRequeridos: 10,
  );

  static const TemaApp fondoPersonalizado = TemaApp(
    id: 'fondo_personalizado',
    nombre: 'Fondo Personalizado',
    descripcion: 'Sube tu propio GIF animado o imagen con difuminado dinámico',
    colorPrimario: Color(0xFF8B5CF6),
    colorSecundario: Color(0xFF06B6D4),
    colorAcento: Color(0xFFEC4899),
    esDesbloqueablePorRacha: true,
    diasRequeridos: 10,
    esExclusivoAndroid: false,
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

  static const TemaApp cyberpunk = TemaApp(
    id: 'cyberpunk',
    nombre: 'Cyberpunk Neón',
    descripcion: 'Futurismo rebelde con violeta neón y azul cian luminoso',
    colorPrimario: Color(0xFF4C1D95),
    colorSecundario: Color(0xFF06B6D4),
    colorAcento: Color(0xFFA855F7),
    esDesbloqueablePorRacha: true,
    diasRequeridos: 50,
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

  static const TemaApp obsidiana = TemaApp(
    id: 'obsidiana',
    nombre: 'Obsidiana Estelar',
    descripcion: 'Minimalismo y elegancia pura en carbón profundo y plata titanio',
    colorPrimario: Color(0xFF0F172A),
    colorSecundario: Color(0xFF94A3B8),
    colorAcento: Color(0xFFE2E8F0),
    esDesbloqueablePorRacha: true,
    diasRequeridos: 150,
  );

  static const List<TemaApp> todos = [
    clasico,
    esmeralda,
    lavanda,
    zafiro,
    cerezo,
    menta,
    atardecer,
    ambar,
    fondoPersonalizado,
    aurora,
    cyberpunk,
    dorado,
    obsidiana,
  ];

  static List<TemaApp> todosParaPlataforma({required bool esAndroid}) {
    if (esAndroid) return todos;
    return todos.where((t) => !t.esExclusivoAndroid).toList();
  }

  static TemaApp obtenerPorId(String id) {
    for (final t in todos) {
      if (t.id == id) return t;
    }
    return clasico;
  }
}
