import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'tema_app.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => crearThemeData(TemasDisponibles.clasico, false);

  static ThemeData get darkTheme => crearThemeData(TemasDisponibles.clasico, true);

  static ThemeData crearThemeData(TemaApp tema, bool esOscuro) {
    final primary = tema.colorPrimario;
    final secondary = tema.colorSecundario;

    if (esOscuro) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: secondary,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: ColorScheme.dark(
          primary: secondary,
          secondary: tema.colorAcento ?? secondary,
          surface: AppColors.surfaceDark,
          error: AppColors.priorityAlta,
        ),
        fontFamily: GoogleFonts.inter().fontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: secondary),
          titleTextStyle: TextStyle(
            color: secondary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderDark, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: secondary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: secondary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        ),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.priorityAlta,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: primary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),
    );
  }
}
