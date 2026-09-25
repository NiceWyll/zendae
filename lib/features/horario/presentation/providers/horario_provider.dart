import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/providers/notification_providers.dart';
import '../../data/datasources/horario_local_datasource.dart';
import '../../data/repositories/horario_repository_impl.dart';
import '../../domain/entities/clase.dart';
import '../../domain/entities/examen.dart';
import '../../domain/repositories/horario_repository.dart';

final horarioLocalDataSourceProvider = Provider<HorarioLocalDataSource>((ref) {
  return HorarioLocalDataSourceImpl();
});

final horarioRepositoryProvider = Provider<HorarioRepository>((ref) {
  final ds = ref.watch(horarioLocalDataSourceProvider);
  return HorarioRepositoryImpl(localDataSource: ds);
});

class ClasesNotifier extends AsyncNotifier<List<Clase>> {
  @override
  Future<List<Clase>> build() async {
    final repo = ref.watch(horarioRepositoryProvider);
    return await repo.obtenerTodasLasClases();
  }

  /// Verifica si una clase (nueva o editada) choca con alguna ya registrada
  Clase? buscarChoque(Clase clase) {
    final clasesActuales = state.valueOrNull ?? [];
    for (final c in clasesActuales) {
      if (c.hayChoque(clase)) {
        return c;
      }
    }
    return null;
  }

  Future<void> agregarClase(Clase clase) async {
    final repo = ref.read(horarioRepositoryProvider);
    await repo.agregarClase(clase);
    ref.invalidateSelf();
    await future;
  }

  Future<void> actualizarClase(Clase clase) async {
    final repo = ref.read(horarioRepositoryProvider);
    await repo.actualizarClase(clase);
    ref.invalidateSelf();
    await future;
  }

  Future<void> eliminarClase(String id) async {
    final repo = ref.read(horarioRepositoryProvider);
    await repo.eliminarClase(id);
    ref.invalidateSelf();
    await future;
  }
}

final clasesProvider = AsyncNotifierProvider<ClasesNotifier, List<Clase>>(() {
  return ClasesNotifier();
});

/// Clases registradas para un día de la semana (1 = Lunes, 7 = Domingo)
final clasesPorDiaProvider = Provider.family<List<Clase>, int>((ref, diaSemana) {
  final clases = ref.watch(clasesProvider).valueOrNull ?? [];
  final filtradas = clases.where((c) => c.diaSemana == diaSemana).toList();
  filtradas.sort((a, b) {
    final aMin = a.horaInicio * 60 + a.minutoInicio;
    final bMin = b.horaInicio * 60 + b.minutoInicio;
    return aMin.compareTo(bMin);
  });
  return filtradas;
});

/// Clases vigentes en una fecha específica (valida día de la semana y rango fechaInicio..fechaFin)
final clasesVigentesPorFechaProvider = Provider.family<List<Clase>, DateTime>((ref, fecha) {
  final clases = ref.watch(clasesProvider).valueOrNull ?? [];
  final vigentes = clases.where((c) => c.estaVigenteEn(fecha)).toList();
  vigentes.sort((a, b) {
    final aMin = a.horaInicio * 60 + a.minutoInicio;
    final bMin = b.horaInicio * 60 + b.minutoInicio;
    return aMin.compareTo(bMin);
  });
  return vigentes;
});

class ExamenesNotifier extends AsyncNotifier<List<Examen>> {
  @override
  Future<List<Examen>> build() async {
    final repo = ref.watch(horarioRepositoryProvider);
    return await repo.obtenerTodosLosExamenes();
  }

  Future<void> agregarExamen(Examen examen, String nombreMateria) async {
    final repo = ref.read(horarioRepositoryProvider);
    await repo.agregarExamen(examen);
    final scheduler = ref.read(notificationSchedulerProvider);
    await scheduler.programarRecordatorioExamen(examen, nombreMateria);
    ref.invalidateSelf();
    await future;
  }

  Future<void> eliminarExamen(Examen examen) async {
    final repo = ref.read(horarioRepositoryProvider);
    await repo.eliminarExamen(examen.id);
    final scheduler = ref.read(notificationSchedulerProvider);
    await scheduler.cancelarRecordatorioExamen(examen);
    ref.invalidateSelf();
    await future;
  }
}

final examenesProvider = AsyncNotifierProvider<ExamenesNotifier, List<Examen>>(() {
  return ExamenesNotifier();
});

final examenesPorClaseProvider = Provider.family<List<Examen>, String>((ref, claseId) {
  final examenes = ref.watch(examenesProvider).valueOrNull ?? [];
  final filtrados = examenes.where((e) => e.claseId == claseId).toList();
  filtrados.sort((a, b) => a.fechaHoraCompleta.compareTo(b.fechaHoraCompleta));
  return filtrados;
});

