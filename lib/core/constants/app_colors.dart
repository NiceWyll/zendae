import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primarios y de marca (Azul oscuro en modo claro / Azul Zafiro en modo oscuro)
  static const Color primary = Color(0xFF162032);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF0B0F19);
  static const Color primaryBgLight = Color(0xFFF1F5F9);

  // Fondos y superficies
  static const Color backgroundLight = Color(0xFFF7FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFEDF2F7);

  // Tema Oscuro (Neutral profundo, sin tinte azulado)
  static const Color backgroundDark = Color(0xFF101010);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color borderDark = Color(0xFF2C2C2C);

  // Textos
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);

  // Prioridades
  // Alta
  static const Color priorityAlta = Color(0xFFEF4444);
  static const Color priorityAltaBg = Color(0xFFFEE2E2);

  // Media
  static const Color priorityMedia = Color(0xFFF59E0B);
  static const Color priorityMediaBg = Color(0xFFFEF3C7);

  // Baja
  static const Color priorityBaja = Color(0xFF10B981);
  static const Color priorityBajaBg = Color(0xFFD1FAE5);

  // Decorativos
  static const Color waveLight1 = Color(0xFFDCE8FD);
  static const Color waveLight2 = Color(0xFF91BAFC);
  static const Color divider = Color(0xFFF1F5F9);
}
