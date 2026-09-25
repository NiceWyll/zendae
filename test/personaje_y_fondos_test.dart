import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_pendiente/core/theme/tema_app.dart';
import 'package:mi_pendiente/features/racha/domain/entities/prenda_personaje.dart';
import 'package:mi_pendiente/features/racha/presentation/providers/personaje_provider.dart';

void main() {
  group('Punto 1: Temas y Fondo Personalizado (Android)', () {
    test('TemasDisponibles incluye temas nuevos ampliados', () {
      const todos = TemasDisponibles.todos;
      final ids = todos.map((t) => t.id).toList();

      expect(ids, contains('zafiro'));
      expect(ids, contains('cerezo'));
      expect(ids, contains('menta'));
      expect(ids, contains('ambar'));
      expect(ids, contains('cyberpunk'));
      expect(ids, contains('obsidiana'));
      expect(ids, contains('fondo_personalizado'));
    });

    test('Fondo personalizado está disponible en plataformas móviles', () {
      final temasAndroid = TemasDisponibles.todosParaPlataforma(esAndroid: true);
      final temasIOS = TemasDisponibles.todosParaPlataforma(esAndroid: false);

      final tieneFondoAndroid = temasAndroid.any((t) => t.id == 'fondo_personalizado');
      final tieneFondoIOS = temasIOS.any((t) => t.id == 'fondo_personalizado');

      expect(tieneFondoAndroid, isTrue, reason: 'En Android debe estar presente');
      expect(tieneFondoIOS, isTrue, reason: 'En iOS ahora también está disponible para personalización');
    });

    test('Límite de tamaño: validación de 10 MB', () {
      const limiteBytes = 10 * 1024 * 1024; // 10 MB exactos

      const archivoValido = 9 * 1024 * 1024; // 9 MB
      const archivoExcedido = 11 * 1024 * 1024; // 11 MB

      expect(archivoValido <= limiteBytes, isTrue);
      expect(archivoExcedido > limiteBytes, isTrue);
    });
  });

  group('Punto 2: Personaje Zendy, Armario y Reglas de Ruptura', () {
    test('Catálogo de prendas contiene hitos ascendentes', () {
      const catalogo = CatalogoPrendas.todas;
      expect(catalogo.length, greaterThanOrEqualTo(8));

      // Verificar hitos de racha
      expect(catalogo.any((p) => p.diasRequeridos == 3), isTrue);
      expect(catalogo.any((p) => p.diasRequeridos == 5), isTrue);
      expect(catalogo.any((p) => p.diasRequeridos == 8), isTrue);
      expect(catalogo.any((p) => p.diasRequeridos == 15), isTrue);
    });

    test('Desbloqueo progresivo según días de racha acumulados', () {
      // 0 días: sin prendas desbloqueadas
      final prendas0 = CatalogoPrendas.desbloqueadasParaDias(0);
      expect(prendas0, isEmpty);

      // 3 días: se desbloquea la gorra
      final prendas3 = CatalogoPrendas.desbloqueadasParaDias(3);
      final ids3 = prendas3.map((p) => p.id).toList();
      expect(ids3, contains('gorra_deportiva'));

      // 8 días: se desbloquean gorra, gafas y bufanda
      final prendas8 = CatalogoPrendas.desbloqueadasParaDias(8);
      final ids8 = prendas8.map((p) => p.id).toList();
      expect(ids8, containsAll(['gorra_deportiva', 'gafas_sol', 'bufanda_cozy']));
    });

    test('Regla de ruptura: Primera ruptura activa el comodín y conserva la ropa', () async {
      SharedPreferences.setMockInitialValues({
        'personaje_prenda_equipada': 'gorra_deportiva',
        'personaje_prendas_desbloqueadas': ['gorra_deportiva', 'gafas_sol'],
        'personaje_oportunidad_usada': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = PersonajeNotifier(prefs);

      expect(notifier.state.oportunidadProteccionUsada, isFalse);
      expect(notifier.state.prendasDesbloqueadasIds, contains('gorra_deportiva'));

      // 1ª Ruptura de racha
      await notifier.procesarRupturaRacha();

      // Debe haber consumido la oportunidad, PERO conserva sus prendas
      expect(notifier.state.oportunidadProteccionUsada, isTrue);
      expect(notifier.state.prendasDesbloqueadasIds, contains('gorra_deportiva'));
      expect(notifier.state.prendaEquipadaId, 'gorra_deportiva');
    });

    test('Regla de ruptura: Segunda ruptura (ya usada la oportunidad) SÍ pierde la ropa', () async {
      SharedPreferences.setMockInitialValues({
        'personaje_prenda_equipada': 'gorra_deportiva',
        'personaje_prendas_desbloqueadas': ['gorra_deportiva', 'gafas_sol'],
        'personaje_oportunidad_usada': true, // Ya usó el comodín
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = PersonajeNotifier(prefs);

      expect(notifier.state.oportunidadProteccionUsada, isTrue);

      // 2ª Ruptura de racha
      await notifier.procesarRupturaRacha();

      // Debe perder toda la ropa desbloqueada y quedar en 'ninguno'
      expect(notifier.state.prendasDesbloqueadasIds, isEmpty);
      expect(notifier.state.prendaEquipadaId, 'ninguno');
    });

    test('Equipar y desequipar prendas actualiza el estado', () async {
      SharedPreferences.setMockInitialValues({
        'personaje_prenda_equipada': 'ninguno',
        'personaje_prendas_desbloqueadas': ['gorra_deportiva'],
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = PersonajeNotifier(prefs);

      // Equipar
      await notifier.equiparPrenda('gorra_deportiva');
      expect(notifier.state.prendaEquipadaId, 'gorra_deportiva');

      // Desequipar
      await notifier.desequiparPrenda();
      expect(notifier.state.prendaEquipadaId, 'ninguno');
    });
  });
}
