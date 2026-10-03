import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/repeticion.dart';
import 'package:mi_pendiente/features/pendientes/presentation/widgets/selector_repeticion_sheet.dart';

void main() {
  group('SelectorRepeticionSheet Tests (Captura 2)', () {
    testWidgets('renderiza opciones de Repetir según diseño de la app', (tester) async {
      String? seleccion;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SelectorRepeticionSheet.mostrar(
                    context: context,
                    repeticionActual: 'Una vez',
                    onSeleccionado: (v) => seleccion = v,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Verificar título
      expect(find.text('Repetir'), findsOneWidget);

      // Verificar opciones de la tarjeta 1
      expect(find.text('Una vez'), findsOneWidget);
      expect(find.text('Diariamente'), findsOneWidget);
      expect(find.text('Lun a Vie'), findsOneWidget);

      // Verificar que NO están las opciones descartadas
      expect(find.text('Alarmas de turno'), findsNothing);
      expect(find.text('Personalizar'), findsNothing);

      // Tocar "Diariamente"
      await tester.tap(find.text('Diariamente'));
      await tester.pumpAndSettle();

      expect(seleccion, 'Diariamente');
    });

    test('Repeticion enum soporta todas las opciones de la captura', () {
      expect(Repeticion.desdeTexto('Una vez'), Repeticion.noRepetir);
      expect(Repeticion.desdeTexto('No repetir'), Repeticion.noRepetir);
      expect(Repeticion.desdeTexto('Diariamente'), Repeticion.diario);
      expect(Repeticion.desdeTexto('Lun a Vie'), Repeticion.lunAVie);
      expect(Repeticion.desdeTexto('Alarmas de turno'), Repeticion.alarmasDeTurno);
      expect(Repeticion.desdeTexto('Personalizar'), Repeticion.personalizar);
    });
  });
}
