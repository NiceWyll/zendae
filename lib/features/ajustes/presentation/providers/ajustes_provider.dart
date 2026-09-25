import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_pendiente/core/providers/preferences_providers.dart';

class AjustesState {
  final ThemeMode themeMode;
  final String temaId;
  final bool notificaciones;
  final bool sonido;
  final bool vibracion;
  final String sonidoPendientes;
  final String sonidoPendientesNombre;
  final String sonidoClases;
  final String sonidoClasesNombre;
  final String horaPredeterminada;
  final String primerDiaSemana;
  final bool eliminarCompletados;
  final bool resumenMatutino;
  final String horaResumenMatutino;

  const AjustesState({
    this.themeMode = ThemeMode.light,
    this.temaId = 'clasico',
    this.notificaciones = true,
    this.sonido = true,
    this.vibracion = true,
    this.sonidoPendientes = 'campana',
    this.sonidoPendientesNombre = 'Campana Clásica',
    this.sonidoClases = 'zen',
    this.sonidoClasesNombre = 'Zen Armónico',
    this.horaPredeterminada = '09:00',
    this.primerDiaSemana = 'Lunes',
    this.eliminarCompletados = false,
    this.resumenMatutino = true,
    this.horaResumenMatutino = '08:00',
  });

  AjustesState copyWith({
    ThemeMode? themeMode,
    String? temaId,
    bool? notificaciones,
    bool? sonido,
    bool? vibracion,
    String? sonidoPendientes,
    String? sonidoPendientesNombre,
    String? sonidoClases,
    String? sonidoClasesNombre,
    String? horaPredeterminada,
    String? primerDiaSemana,
    bool? eliminarCompletados,
    bool? resumenMatutino,
    String? horaResumenMatutino,
  }) {
    return AjustesState(
      themeMode: themeMode ?? this.themeMode,
      temaId: temaId ?? this.temaId,
      notificaciones: notificaciones ?? this.notificaciones,
      sonido: sonido ?? this.sonido,
      vibracion: vibracion ?? this.vibracion,
      sonidoPendientes: sonidoPendientes ?? this.sonidoPendientes,
      sonidoPendientesNombre: sonidoPendientesNombre ?? this.sonidoPendientesNombre,
      sonidoClases: sonidoClases ?? this.sonidoClases,
      sonidoClasesNombre: sonidoClasesNombre ?? this.sonidoClasesNombre,
      horaPredeterminada: horaPredeterminada ?? this.horaPredeterminada,
      primerDiaSemana: primerDiaSemana ?? this.primerDiaSemana,
      eliminarCompletados: eliminarCompletados ?? this.eliminarCompletados,
      resumenMatutino: resumenMatutino ?? this.resumenMatutino,
      horaResumenMatutino: horaResumenMatutino ?? this.horaResumenMatutino,
    );
  }
}

class AjustesNotifier extends StateNotifier<AjustesState> {
  final SharedPreferences? prefs;

  AjustesNotifier(this.prefs) : super(const AjustesState()) {
    _cargarAjustes();
  }

  void _cargarAjustes() {
    if (prefs == null) return;
    final isDark = prefs!.getBool('es_oscuro') ?? false;
    final tema = prefs!.getString('tema_id') ?? 'clasico';
    final notif = prefs!.getBool('notificaciones') ?? true;
    final sonido = prefs!.getBool('sonido') ?? true;
    final vibra = prefs!.getBool('vibracion') ?? true;
    final sonidoPend = prefs!.getString('sonido_pendientes') ?? 'campana';
    final sonidoPendNombre = prefs!.getString('sonido_pendientes_nombre') ?? 'Campana Clásica';
    final sonidoClas = prefs!.getString('sonido_clases') ?? 'zen';
    final sonidoClasNombre = prefs!.getString('sonido_clases_nombre') ?? 'Zen Armónico';
    final hora = prefs!.getString('hora_pred') ?? '09:00';
    final primerDia = prefs!.getString('primer_dia') ?? 'Lunes';
    final autoDel = prefs!.getBool('eliminar_comp') ?? false;
    final resumen = prefs!.getBool('resumen_matutino') ?? true;
    final horaResumen = prefs!.getString('hora_resumen_matutino') ?? '08:00';

    state = state.copyWith(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      temaId: tema,
      notificaciones: notif,
      sonido: sonido,
      vibracion: vibra,
      sonidoPendientes: sonidoPend,
      sonidoPendientesNombre: sonidoPendNombre,
      sonidoClases: sonidoClas,
      sonidoClasesNombre: sonidoClasNombre,
      horaPredeterminada: hora,
      primerDiaSemana: primerDia,
      eliminarCompletados: autoDel,
      resumenMatutino: resumen,
      horaResumenMatutino: horaResumen,
    );
  }

  Future<void> alternarTema(bool esOscuro) async {
    await prefs?.setBool('es_oscuro', esOscuro);
    state = state.copyWith(themeMode: esOscuro ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> cambiarTema(String nuevoTemaId) async {
    await prefs?.setString('tema_id', nuevoTemaId);
    state = state.copyWith(temaId: nuevoTemaId);
  }

  Future<void> alternarNotificaciones(bool valor) async {
    await prefs?.setBool('notificaciones', valor);
    state = state.copyWith(notificaciones: valor);
  }

  Future<void> alternarSonido(bool valor) async {
    await prefs?.setBool('sonido', valor);
    state = state.copyWith(sonido: valor);
  }

  Future<void> alternarVibracion(bool valor) async {
    await prefs?.setBool('vibracion', valor);
    state = state.copyWith(vibracion: valor);
  }

  Future<void> cambiarSonidoPendientes(String soundId, [String? nombre]) async {
    await prefs?.setString('sonido_pendientes', soundId);
    if (nombre != null) {
      await prefs?.setString('sonido_pendientes_nombre', nombre);
    }
    state = state.copyWith(
      sonidoPendientes: soundId,
      sonidoPendientesNombre: nombre,
    );
  }

  Future<void> cambiarSonidoClases(String soundId, [String? nombre]) async {
    await prefs?.setString('sonido_clases', soundId);
    if (nombre != null) {
      await prefs?.setString('sonido_clases_nombre', nombre);
    }
    state = state.copyWith(
      sonidoClases: soundId,
      sonidoClasesNombre: nombre,
    );
  }

  Future<void> cambiarHoraPredeterminada(String hora) async {
    await prefs?.setString('hora_pred', hora);
    state = state.copyWith(horaPredeterminada: hora);
  }

  Future<void> cambiarPrimerDiaSemana(String dia) async {
    await prefs?.setString('primer_dia', dia);
    state = state.copyWith(primerDiaSemana: dia);
  }

  Future<void> alternarEliminarCompletados(bool valor) async {
    await prefs?.setBool('eliminar_comp', valor);
    state = state.copyWith(eliminarCompletados: valor);
  }

  Future<void> alternarResumenMatutino(bool valor) async {
    await prefs?.setBool('resumen_matutino', valor);
    state = state.copyWith(resumenMatutino: valor);
  }

  Future<void> cambiarHoraResumenMatutino(String hora) async {
    await prefs?.setString('hora_resumen_matutino', hora);
    state = state.copyWith(horaResumenMatutino: hora);
  }
}

final ajustesProvider = StateNotifierProvider<AjustesNotifier, AjustesState>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AjustesNotifier(prefs);
  } catch (_) {
    return AjustesNotifier(null);
  }
});
