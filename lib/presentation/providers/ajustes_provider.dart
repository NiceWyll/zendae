import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/preferences_providers.dart';

class AjustesState {
  final ThemeMode themeMode;
  final bool notificaciones;
  final bool sonido;
  final bool vibracion;
  final String horaPredeterminada;
  final String primerDiaSemana;
  final bool eliminarCompletados;

  const AjustesState({
    this.themeMode = ThemeMode.light,
    this.notificaciones = true,
    this.sonido = true,
    this.vibracion = false,
    this.horaPredeterminada = '09:00',
    this.primerDiaSemana = 'Lunes',
    this.eliminarCompletados = false,
  });

  AjustesState copyWith({
    ThemeMode? themeMode,
    bool? notificaciones,
    bool? sonido,
    bool? vibracion,
    String? horaPredeterminada,
    String? primerDiaSemana,
    bool? eliminarCompletados,
  }) {
    return AjustesState(
      themeMode: themeMode ?? this.themeMode,
      notificaciones: notificaciones ?? this.notificaciones,
      sonido: sonido ?? this.sonido,
      vibracion: vibracion ?? this.vibracion,
      horaPredeterminada: horaPredeterminada ?? this.horaPredeterminada,
      primerDiaSemana: primerDiaSemana ?? this.primerDiaSemana,
      eliminarCompletados: eliminarCompletados ?? this.eliminarCompletados,
    );
  }
}

class AjustesNotifier extends StateNotifier<AjustesState> {
  final SharedPreferences prefs;

  AjustesNotifier(this.prefs) : super(const AjustesState()) {
    _cargarAjustes();
  }

  void _cargarAjustes() {
    final isDark = prefs.getBool('es_oscuro') ?? false;
    final notif = prefs.getBool('notificaciones') ?? true;
    final sonido = prefs.getBool('sonido') ?? true;
    final vibra = prefs.getBool('vibracion') ?? false;
    final hora = prefs.getString('hora_pred') ?? '09:00';
    final primerDia = prefs.getString('primer_dia') ?? 'Lunes';
    final autoDel = prefs.getBool('eliminar_comp') ?? false;

    state = state.copyWith(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      notificaciones: notif,
      sonido: sonido,
      vibracion: vibra,
      horaPredeterminada: hora,
      primerDiaSemana: primerDia,
      eliminarCompletados: autoDel,
    );
  }

  Future<void> alternarTema(bool esOscuro) async {
    await prefs.setBool('es_oscuro', esOscuro);
    state = state.copyWith(themeMode: esOscuro ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> alternarNotificaciones(bool valor) async {
    await prefs.setBool('notificaciones', valor);
    state = state.copyWith(notificaciones: valor);
  }

  Future<void> alternarSonido(bool valor) async {
    await prefs.setBool('sonido', valor);
    state = state.copyWith(sonido: valor);
  }

  Future<void> alternarVibracion(bool valor) async {
    await prefs.setBool('vibracion', valor);
    state = state.copyWith(vibracion: valor);
  }

  Future<void> cambiarHoraPredeterminada(String hora) async {
    await prefs.setString('hora_pred', hora);
    state = state.copyWith(horaPredeterminada: hora);
  }

  Future<void> cambiarPrimerDiaSemana(String dia) async {
    await prefs.setString('primer_dia', dia);
    state = state.copyWith(primerDiaSemana: dia);
  }

  Future<void> alternarEliminarCompletados(bool valor) async {
    await prefs.setBool('eliminar_comp', valor);
    state = state.copyWith(eliminarCompletados: valor);
  }
}

final ajustesProvider = StateNotifierProvider<AjustesNotifier, AjustesState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AjustesNotifier(prefs);
});
