import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/providers/clock_providers.dart';
import 'package:mi_pendiente/core/providers/database_providers.dart';
import '../../../../features/horario/presentation/providers/horario_provider.dart';
import '../../../../features/pendientes/presentation/providers/pendientes_provider.dart';
import '../../data/repositories/racha_repository_impl.dart';
import '../../domain/entities/racha.dart';
import '../../domain/repositories/racha_repository.dart';
import '../../domain/usecases/actualizar_racha.dart';
import '../../domain/usecases/obtener_racha.dart';

class InMemoryRachaRepository implements RachaRepository {
  Racha _racha = const Racha.inicial();

  @override
  Future<Result<Racha>> obtenerRacha() async => Exito(_racha);

  @override
  Future<Result<void>> guardarRacha(Racha racha) async {
    _racha = racha;
    return const Exito(null);
  }
}

final rachaRepositoryProvider = Provider<RachaRepository>((ref) {
  try {
    final appDb = ref.watch(databaseProvider);
    return RachaRepositoryImpl(appDatabase: appDb);
  } catch (_) {
    return InMemoryRachaRepository();
  }
});

final validadorDiaActivoProvider = Provider<ValidadorDiaActivo>((ref) {
  return (DateTime fecha) async {
    // 1. Verificar si hay clases vigentes en esta fecha (Fase Horario)
    try {
      final horarioRepo = ref.read(horarioRepositoryProvider);
      final clases = await horarioRepo.obtenerTodasLasClases();
      if (clases.any((c) => c.estaVigenteEn(fecha))) {
        return true;
      }
    } catch (_) {}

    // 2. Verificar si hay pendientes programados para esta fecha
    try {
      final pendienteRepo = ref.read(pendienteRepositoryProvider);
      final res = await pendienteRepo.getPendientesPorFecha(fecha);
      if (res case Exito(:final valor)) {
        if (valor.isNotEmpty) return true;
      }
    } catch (_) {}

    // No hay ni clases ni pendientes: día neutro (vacaciones, receso, etc.)
    return false;
  };
});

final actualizarRachaProvider = Provider<ActualizarRacha>((ref) {
  final repo = ref.watch(rachaRepositoryProvider);
  final reloj = ref.watch(relojProvider);
  final validador = ref.watch(validadorDiaActivoProvider);
  return ActualizarRacha(repo, reloj, validador);
});

final obtenerRachaProvider = Provider<ObtenerRacha>((ref) {
  final repo = ref.watch(rachaRepositoryProvider);
  final reloj = ref.watch(relojProvider);
  final validador = ref.watch(validadorDiaActivoProvider);
  return ObtenerRacha(repo, reloj, validador);
});

class RachaNotifier extends AsyncNotifier<Racha> {
  @override
  Future<Racha> build() async {
    final caso = ref.watch(obtenerRachaProvider);
    final res = await caso();
    return switch (res) {
      Exito(:final valor) => valor,
      Fallo(:final failure) => throw failure,
    };
  }

  Future<void> refrescar() async {
    state = const AsyncLoading();
    final caso = ref.read(obtenerRachaProvider);
    final res = await caso();
    if (res case Exito(:final valor)) {
      state = AsyncData(valor);
    }
  }

  Future<Racha?> actualizarTrasCompletado() async {
    final caso = ref.read(actualizarRachaProvider);
    final res = await caso();
    if (res case Exito(:final valor)) {
      state = AsyncData(valor);
      return valor;
    }
    return null;
  }
}

final rachaNotifierProvider =
    AsyncNotifierProvider<RachaNotifier, Racha>(RachaNotifier.new);
