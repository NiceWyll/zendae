import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_pendiente/core/providers/preferences_providers.dart';
import '../../domain/entities/personaje_state.dart';
import '../../domain/entities/prenda_personaje.dart';

class PersonajeNotifier extends StateNotifier<PersonajeState> {
  final SharedPreferences? _prefs;

  PersonajeNotifier(this._prefs) : super(const PersonajeState()) {
    _cargarEstado();
  }

  void _cargarEstado() {
    final prefs = _prefs;
    if (prefs == null) return;
    final equipada = prefs.getString('personaje_prenda_equipada') ?? 'ninguno';
    final desbloqueadas = prefs.getStringList('personaje_prendas_desbloqueadas') ?? [];
    final oportunidadUsada = prefs.getBool('personaje_oportunidad_usada') ?? false;

    state = PersonajeState(
      prendaEquipadaId: equipada,
      prendasDesbloqueadasIds: desbloqueadas,
      oportunidadProteccionUsada: oportunidadUsada,
    );
  }

  /// Equipa una prenda en el personaje
  Future<void> equiparPrenda(String prendaId) async {
    await _prefs?.setString('personaje_prenda_equipada', prendaId);
    state = state.copyWith(prendaEquipadaId: prendaId);
  }

  /// Desequipa cualquier prenda (queda al natural)
  Future<void> desequiparPrenda() async {
    await equiparPrenda('ninguno');
  }

  /// Comprueba si con los días actuales de racha se han desbloqueado nuevas prendas
  /// Devuelve la lista de prendas recién desbloqueadas (si las hay) para la animación
  List<PrendaPersonaje> verificarNuevosDesbloqueos(int diasRacha) {
    final recienDesbloqueadas = <PrendaPersonaje>[];
    final listaActual = List<String>.from(state.prendasDesbloqueadasIds);

    for (final prenda in CatalogoPrendas.todas) {
      if (diasRacha >= prenda.diasRequeridos && !listaActual.contains(prenda.id)) {
        listaActual.add(prenda.id);
        recienDesbloqueadas.add(prenda);
      }
    }

    if (recienDesbloqueadas.isNotEmpty) {
      _prefs?.setStringList('personaje_prendas_desbloqueadas', listaActual);
      state = state.copyWith(
        prendasDesbloqueadasIds: listaActual,
        ultimaPrendaDesbloqueadaId: recienDesbloqueadas.last.id,
      );
    }

    return recienDesbloqueadas;
  }

  /// Aplica las reglas al romperse la racha:
  /// - 1ra vez: Se consume la oportunidad (comodín). NO pierde la ropa.
  /// - 2da vez: Ya usada la oportunidad. SÍ pierde las prendas desbloqueadas.
  /// Retorna TRUE si perdió la ropa, FALSE si fue salvado por la oportunidad.
  Future<bool> procesarRupturaRacha() async {
    if (!state.oportunidadProteccionUsada) {
      // 1ra vez que se rompe: Usar el comodín de protección, NO pierde la ropa
      await _prefs?.setBool('personaje_oportunidad_usada', true);
      state = state.copyWith(oportunidadProteccionUsada: true);
      return false; // Ropa salvada
    } else {
      // 2da vez que se rompe: Pierde la ropa desbloqueada
      await _prefs?.setStringList('personaje_prendas_desbloqueadas', []);
      await _prefs?.setString('personaje_prenda_equipada', 'ninguno');
      state = state.copyWith(
        prendasDesbloqueadasIds: [],
        prendaEquipadaId: 'ninguno',
      );
      return true; // Ropa perdida
    }
  }

  void limpiarUltimaPrenda() {
    state = state.copyWith(limpiarUltimaPrenda: true);
  }
}

final personajeProvider = StateNotifierProvider<PersonajeNotifier, PersonajeState>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return PersonajeNotifier(prefs);
  } catch (_) {
    return PersonajeNotifier(null);
  }
});
