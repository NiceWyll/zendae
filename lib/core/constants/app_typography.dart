import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Sistema de jerarquía tipográfica unificada para Mi Pendiente.
/// Basado en la familia tipográfica Inter con pesos y espaciados armonizados.
class AppTypography {
  AppTypography._();

  /// Título display de gran impacto (Splash, bienvenidas, estadísticas)
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: -0.6,
        height: 1.2,
      );

  /// Título de pantallas principales o modales destacados
  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
        height: 1.25,
      );

  /// Título de AppBar y encabezados de sección
  static TextStyle get headerTitle => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  /// Título de tarjetas grandes, diálogos y secciones destacadas
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: -0.3,
      );

  /// Título de tarjetas de tareas y elementos de lista
  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  /// Texto de cuerpo principal (lectura amplia)
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.45,
      );

  /// Texto de cuerpo estándar
  static TextStyle get bodyRegular => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Texto secundario para subtítulos, fechas secundarias y pistas
  static TextStyle get bodySecondary => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.35,
      );

  /// Números de métricas, contadores y racha
  static TextStyle get statNumber => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );

  /// Etiqueta de tiempo (chips de hora en tarjetas y detalles)
  static TextStyle get timeLabel => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 0.1,
      );

  /// Tags y badges compactos (ej. chips de prioridad o estado)
  static TextStyle get tagText => GoogleFonts.inter(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      );

  /// Botones de acción principal
  static TextStyle get buttonLarge => GoogleFonts.inter(
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.1,
      );
}
