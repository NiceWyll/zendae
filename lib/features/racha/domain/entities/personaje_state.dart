import 'prenda_personaje.dart';

class PersonajeState {
  final String prendaEquipadaId;
  final List<String> prendasDesbloqueadasIds;
  final bool oportunidadProteccionUsada;
  final String? ultimaPrendaDesbloqueadaId;

  const PersonajeState({
    this.prendaEquipadaId = 'ninguno',
    this.prendasDesbloqueadasIds = const [],
    this.oportunidadProteccionUsada = false,
    this.ultimaPrendaDesbloqueadaId,
  });

  PrendaPersonaje? get prendaEquipada => CatalogoPrendas.obtenerPorId(prendaEquipadaId);

  bool get tieneOportunidadDisponible => !oportunidadProteccionUsada;

  PersonajeState copyWith({
    String? prendaEquipadaId,
    List<String>? prendasDesbloqueadasIds,
    bool? oportunidadProteccionUsada,
    String? ultimaPrendaDesbloqueadaId,
    bool limpiarUltimaPrenda = false,
  }) {
    return PersonajeState(
      prendaEquipadaId: prendaEquipadaId ?? this.prendaEquipadaId,
      prendasDesbloqueadasIds: prendasDesbloqueadasIds ?? this.prendasDesbloqueadasIds,
      oportunidadProteccionUsada: oportunidadProteccionUsada ?? this.oportunidadProteccionUsada,
      ultimaPrendaDesbloqueadaId: limpiarUltimaPrenda
          ? null
          : (ultimaPrendaDesbloqueadaId ?? this.ultimaPrendaDesbloqueadaId),
    );
  }
}
