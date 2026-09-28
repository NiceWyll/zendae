import 'package:flutter_test/flutter_test.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/hora_del_dia.dart';

void main() {
  group('Pruebas de tiempos de aviso (Avisarme)', () {
    test('Pendiente tiene minutosAntes = 15 por defecto', () {
      final p = Pendiente(
        id: 'p-1',
        titulo: 'Revisar avances',
        fecha: DateTime(2026, 9, 28),
        hora: const HoraDelDia(hora: 10, minuto: 30),
      );

      expect(p.minutosAntes, 15);
      expect(p.momentoDeAviso, DateTime(2026, 9, 28, 10, 15));
    });

    test('Soporta todos los intervalos solicitados (15m, 30m, 1h, 2h, 3h)', () {
      const opciones = [15, 30, 60, 120, 180];
      for (final m in opciones) {
        final p = Pendiente(
          id: 'p-$m',
          titulo: 'Tarea $m',
          fecha: DateTime(2026, 9, 28),
          hora: const HoraDelDia(hora: 12, minuto: 0),
          minutosAntes: m,
        );
        expect(p.minutosAntes, m);
        expect(p.momentoDeAviso, DateTime(2026, 9, 28, 12, 0).subtract(Duration(minutes: m)));
      }
    });

    test('CopyWith preserva y actualiza minutosAntes correctamente', () {
      final p1 = Pendiente(
        id: 'p-base',
        titulo: 'Base',
        fecha: DateTime(2026, 9, 28),
        hora: const HoraDelDia(hora: 10, minuto: 0),
        minutosAntes: 15,
      );

      final p2 = p1.copyWith(minutosAntes: 120);
      expect(p2.minutosAntes, 120);
      expect(p2.momentoDeAviso, DateTime(2026, 9, 28, 8, 0));

      final p3 = p1.copyWith(minutosAntes: 180);
      expect(p3.minutosAntes, 180);
      expect(p3.momentoDeAviso, DateTime(2026, 9, 28, 7, 0));
    });
  });
}
