import 'package:mi_pendiente/core/error/result.dart';
import '../entities/racha.dart';

abstract class RachaRepository {
  Future<Result<Racha>> obtenerRacha();
  Future<Result<void>> guardarRacha(Racha racha);
}
