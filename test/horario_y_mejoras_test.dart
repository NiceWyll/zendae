import 'package:flutter_test/flutter_test.dart';
import 'package:mi_pendiente/core/constants/app_sounds.dart';
import 'package:mi_pendiente/features/horario/domain/entities/clase.dart';

void main() {
  group('Horario y Clases - Entidad y Lógica de Negocio', () {
    final hoy = DateTime(2026, 9, 24);

    test('Clase model serialización y deserialización correcta', () {
      final clase = Clase(
        id: 'clase_1',
        nombre: 'Cálculo Avanzado',
        diaSemana: 1, // Lunes
        horaInicio: 8,
        minutoInicio: 0,
        horaFin: 10,
        minutoFin: 0,
        fechaInicio: DateTime(2026, 9, 1),
        fechaFin: DateTime(2026, 12, 15),
        colorValue: 0xFF3B82F6,
        minutosAntes: 30,
        aula: 'Pabellón B - 204',
      );

      final map = clase.toMap();
      expect(map['id'], 'clase_1');
      expect(map['nombre'], 'Cálculo Avanzado');
      expect(map['dia_semana'], 1);
      expect(map['hora_inicio'], 8);
      expect(map['minuto_inicio'], 0);
      expect(map['minutos_antes'], 30);

      final fromMap = Clase.fromMap(map);
      expect(fromMap.id, clase.id);
      expect(fromMap.nombre, clase.nombre);
      expect(fromMap.horaInicio, 8);
      expect(fromMap.minutoInicio, 0);
      expect(fromMap.horaFin, 10);
      expect(fromMap.minutoFin, 0);
      expect(fromMap.minutosAntes, 30);
      expect(fromMap.aula, 'Pabellón B - 204');
    });

    test('estaVigenteEn verifica correctamente el rango [fechaInicio, fechaFin]', () {
      final clase = Clase(
        id: 'clase_2',
        nombre: 'Física',
        diaSemana: 2, // Martes
        horaInicio: 10,
        minutoInicio: 0,
        horaFin: 12,
        minutoFin: 0,
        fechaInicio: DateTime(2026, 9, 1),
        fechaFin: DateTime(2026, 9, 30),
      );

      // Antes del inicio
      expect(clase.estaVigenteEn(DateTime(2026, 8, 31)), isFalse);
      // Durante la vigencia (martes)
      expect(clase.estaVigenteEn(DateTime(2026, 9, 1)), isTrue); // Martes
      expect(clase.estaVigenteEn(DateTime(2026, 9, 15)), isTrue); // Martes
      expect(clase.estaVigenteEn(DateTime(2026, 9, 29)), isTrue); // Martes
      // Dentro del rango pero miércoles (no es su día)
      expect(clase.estaVigenteEn(DateTime(2026, 9, 30)), isFalse);
      // Después del fin
      expect(clase.estaVigenteEn(DateTime(2026, 10, 1)), isFalse);
    });

    test('finalizaPronto detecta cursos con 3 días o menos de vigencia restante', () {
      // Finaliza en exactamente 2 días
      final claseFinalizaPronto = Clase(
        id: 'clase_3',
        nombre: 'Taller',
        diaSemana: 3,
        horaInicio: 14,
        minutoInicio: 0,
        horaFin: 16,
        minutoFin: 0,
        fechaInicio: hoy.subtract(const Duration(days: 30)),
        fechaFin: hoy.add(const Duration(days: 2)),
      );
      expect(claseFinalizaPronto.finalizaProntoEn(hoy), isTrue);

      // Finaliza en más de 3 días (ej. 5 días)
      final claseConTiempo = Clase(
        id: 'clase_4',
        nombre: 'Historia',
        diaSemana: 4,
        horaInicio: 9,
        minutoInicio: 0,
        horaFin: 11,
        minutoFin: 0,
        fechaInicio: hoy.subtract(const Duration(days: 10)),
        fechaFin: hoy.add(const Duration(days: 5)),
      );
      expect(claseConTiempo.finalizaProntoEn(hoy), isFalse);

      // Ya finalizó en el pasado
      final claseVencida = Clase(
        id: 'clase_5',
        nombre: 'Seminario',
        diaSemana: 5,
        horaInicio: 8,
        minutoInicio: 0,
        horaFin: 10,
        minutoFin: 0,
        fechaInicio: hoy.subtract(const Duration(days: 20)),
        fechaFin: hoy.subtract(const Duration(days: 1)),
      );
      expect(claseVencida.finalizaProntoEn(hoy), isFalse);
    });

    test('Detección de cruce o choque de horario entre clases', () {
      final claseA = Clase(
        id: 'a',
        nombre: 'Química',
        diaSemana: 1, // Lunes
        horaInicio: 8,
        minutoInicio: 0,
        horaFin: 10,
        minutoFin: 0,
        fechaInicio: hoy,
        fechaFin: hoy.add(const Duration(days: 30)),
      );

      final claseB = Clase(
        id: 'b',
        nombre: 'Biología',
        diaSemana: 1, // Mismo lunes
        horaInicio: 9,
        minutoInicio: 30,
        horaFin: 11,
        minutoFin: 30,
        fechaInicio: hoy,
        fechaFin: hoy.add(const Duration(days: 30)),
      );

      final claseC = Clase(
        id: 'c',
        nombre: 'Matemática',
        diaSemana: 1, // Mismo lunes pero después
        horaInicio: 10,
        minutoInicio: 0,
        horaFin: 12,
        minutoFin: 0,
        fechaInicio: hoy,
        fechaFin: hoy.add(const Duration(days: 30)),
      );

      final claseD = Clase(
        id: 'd',
        nombre: 'Arte',
        diaSemana: 2, // Martes diferente día
        horaInicio: 8,
        minutoInicio: 30,
        horaFin: 9,
        minutoFin: 30,
        fechaInicio: hoy,
        fechaFin: hoy.add(const Duration(days: 30)),
      );

      expect(claseA.hayChoque(claseB), isTrue, reason: '08:00-10:00 se cruza con 09:30-11:30');
      expect(claseA.hayChoque(claseC), isFalse, reason: 'Termina a las 10:00 y la otra empieza a las 10:00 (contiguas)');
      expect(claseA.hayChoque(claseD), isFalse, reason: 'Diferente día de la semana');
    });
  });

  group('Sonidos de Notificación Disponibles', () {
    test('Sonidos disponibles cuenta con tonos variados y válidos', () {
      expect(SonidosDisponibles.lista.length, greaterThanOrEqualTo(5));

      final campana = SonidosDisponibles.obtenerPorId('campana');
      expect(campana.nombre, 'Campana Clásica');

      final zen = SonidosDisponibles.obtenerPorId('zen');
      expect(zen.nombre, 'Zen Armónico');

      final desconocido = SonidosDisponibles.obtenerPorId('no_existe');
      expect(desconocido.id, 'campana', reason: 'Debe fallbackear al primer sonido si no existe');
    });
  });
}
