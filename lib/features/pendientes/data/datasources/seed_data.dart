import '../../domain/entities/hora_del_dia.dart';
import '../../domain/entities/pendiente.dart';
import '../../domain/entities/prioridad.dart';

abstract class SeedData {
  static List<Pendiente> obtenerPendientesIniciales() {
    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day);
    final yesterdayStr = todayStr.subtract(const Duration(days: 1));

    return [
      Pendiente(
        id: '1',
        titulo: 'Revisar correos',
        descripcion: 'Responder mensajes prioritarios y archivar newsletters.',
        fecha: todayStr,
        hora: const HoraDelDia(hora: 8, minuto: 0),
        prioridad: Prioridad.alta,
        tieneRecordatorio: true,
        minutosAntes: 10,
        estaCompletado: false,
        notificacionId: 1001,
      ),
      Pendiente(
        id: '2',
        titulo: 'Reunión con equipo',
        descripcion: 'Revisar avances del proyecto y definir próximos pasos.',
        fecha: todayStr,
        hora: const HoraDelDia(hora: 10, minuto: 30),
        prioridad: Prioridad.media,
        tieneRecordatorio: true,
        minutosAntes: 15,
        estaCompletado: true,
        fechaCompletado: todayStr,
        notificacionId: 1002,
      ),
      Pendiente(
        id: '3',
        titulo: 'Comprar materiales',
        descripcion: 'Adquirir libretas y suministros de oficina.',
        fecha: todayStr,
        hora: const HoraDelDia(hora: 15, minuto: 0),
        prioridad: Prioridad.baja,
        tieneRecordatorio: false,
        minutosAntes: 10,
        estaCompletado: false,
      ),
      Pendiente(
        id: '4',
        titulo: 'Hacer ejercicio',
        descripcion: 'Rutina de cardio y estiramiento por 45 minutos.',
        fecha: todayStr,
        hora: const HoraDelDia(hora: 18, minuto: 30),
        prioridad: Prioridad.baja,
        tieneRecordatorio: true,
        minutosAntes: 30,
        estaCompletado: false,
        notificacionId: 1004,
      ),
      // Completados
      Pendiente(
        id: 'c1',
        titulo: 'Enviar reporte semanal',
        descripcion: 'Reporte consolidado de métricas al supervisor.',
        fecha: todayStr,
        hora: const HoraDelDia(hora: 9, minuto: 15),
        prioridad: Prioridad.media,
        estaCompletado: true,
        fechaCompletado: todayStr,
      ),
      Pendiente(
        id: 'c2',
        titulo: 'Comprar pasajes',
        descripcion: 'Boletos de avión para el viaje de trabajo.',
        fecha: todayStr,
        hora: const HoraDelDia(hora: 11, minuto: 30),
        prioridad: Prioridad.alta,
        estaCompletado: true,
        fechaCompletado: todayStr,
        notificacionId: 1005,
      ),
      Pendiente(
        id: 'c3',
        titulo: 'Llamar al banco',
        descripcion: 'Confirmar recepción de transferencia internacional.',
        fecha: todayStr,
        hora: const HoraDelDia(hora: 16, minuto: 45),
        prioridad: Prioridad.baja,
        estaCompletado: true,
        fechaCompletado: todayStr,
      ),
      Pendiente(
        id: 'c4',
        titulo: 'Revisar presentación',
        descripcion: 'Diapositivas finales con diseño corporativo.',
        fecha: yesterdayStr,
        hora: const HoraDelDia(hora: 10, minuto: 20),
        prioridad: Prioridad.media,
        estaCompletado: true,
        fechaCompletado: yesterdayStr,
      ),
      Pendiente(
        id: 'c5',
        titulo: 'Pagar servicios',
        descripcion: 'Luz, internet y agua potable del mes.',
        fecha: yesterdayStr,
        hora: const HoraDelDia(hora: 18, minuto: 30),
        prioridad: Prioridad.alta,
        estaCompletado: true,
        fechaCompletado: yesterdayStr,
        notificacionId: 1006,
      ),
    ];
  }
}
