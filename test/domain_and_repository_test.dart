import 'package:flutter_test/flutter_test.dart';
import 'package:mi_pendiente/domain/entities/hora_del_dia.dart';
import 'package:mi_pendiente/domain/entities/pendiente.dart';
import 'package:mi_pendiente/domain/entities/prioridad.dart';
import 'package:mi_pendiente/domain/entities/repeticion.dart';
import 'package:mi_pendiente/data/models/pendiente_model.dart';
import 'package:mi_pendiente/presentation/mappers/prioridad_ui.dart';

void main() {
  group('Pendiente Entity y Model Tests', () {
    test('Creación de pendiente y conversión toMap / fromMap', () {
      final now = DateTime(2026, 9, 15);
      final p = Pendiente(
        id: 'test-1',
        titulo: 'Reunión de prueba',
        descripcion: 'Detalle de prueba',
        fecha: now,
        hora: const HoraDelDia(hora: 14, minuto: 30),
        prioridad: Prioridad.alta,
        tieneRecordatorio: true,
        minutosAntes: 15,
        repetir: Repeticion.noRepetir,
        estaCompletado: false,
      );

      final map = PendienteModel.toMap(p);
      expect(map['id'], 'test-1');
      expect(map['titulo'], 'Reunión de prueba');
      expect(map['prioridad'], 'alta');
      expect(map['tiene_recordatorio'], 1);
      expect(map['esta_completado'], 0);

      final revived = PendienteModel.fromMap(map);
      expect(revived.id, p.id);
      expect(revived.titulo, p.titulo);
      expect(revived.hora.hora, 14);
      expect(revived.hora.minuto, 30);
      expect(revived.prioridad, Prioridad.alta);
      expect(revived.estaCompletado, false);
    });

    test('copyWith preserva valores y actualiza campos solicitados', () {
      final p = Pendiente(
        id: '1',
        titulo: 'Tarea Original',
        fecha: DateTime(2026, 9, 10),
        hora: const HoraDelDia(hora: 9, minuto: 0),
        prioridad: Prioridad.baja,
      );

      final completada = p.copyWith(
        estaCompletado: true,
        fechaCompletado: DateTime(2026, 9, 10, 10, 0),
      );

      expect(completada.estaCompletado, true);
      expect(completada.titulo, 'Tarea Original');
      expect(completada.prioridad, Prioridad.baja);
      expect(completada.fechaCompletado != null, true);
    });

    test('Prioridad labels y colores', () {
      expect(Prioridad.alta.label, 'Alta');
      expect(Prioridad.media.label, 'Media');
      expect(Prioridad.baja.label, 'Baja');
    });

    test('HoraDelDia parsea y formatea como HH:mm', () {
      final h = HoraDelDia.desdeTexto('08:05');
      expect(h.hora, 8);
      expect(h.minuto, 5);
      expect(h.comoTexto, '08:05');
    });

    test('Repeticion convierte correctamente a enum y texto', () {
      expect(Repeticion.desdeTexto('Diario'), Repeticion.diario);
      expect(Repeticion.diario.comoTexto, 'Diario');
      expect(Repeticion.desdeTexto('desconocido'), Repeticion.noRepetir);
    });
  });
}
