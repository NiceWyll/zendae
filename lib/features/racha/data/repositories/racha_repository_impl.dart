import 'package:sqflite/sqflite.dart';
import 'package:mi_pendiente/core/error/failure.dart';
import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/features/pendientes/data/datasources/app_database.dart';
import '../../domain/entities/racha.dart';
import '../../domain/repositories/racha_repository.dart';

class RachaRepositoryImpl implements RachaRepository {
  final AppDatabase appDatabase;

  const RachaRepositoryImpl({required this.appDatabase});

  @override
  Future<Result<Racha>> obtenerRacha() async {
    try {
      final db = await appDatabase.database;
      final maps = await db.query(
        'racha',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (maps.isEmpty) {
        return const Exito(Racha.inicial());
      }

      final map = maps.first;
      final diasActuales = map['dias_actuales'] as int? ?? 0;
      final mejorRacha = map['mejor_racha'] as int? ?? 0;
      final ultimaFechaStr = map['ultima_fecha'] as String?;
      final logrosStr = map['logros'] as String? ?? '';

      final ultimaFecha = ultimaFechaStr != null ? DateTime.tryParse(ultimaFechaStr) : null;
      final logros = logrosStr.isNotEmpty ? logrosStr.split(',') : <String>[];

      return Exito(
        Racha(
          diasActuales: diasActuales,
          mejorRacha: mejorRacha,
          ultimaFechaCompletado: ultimaFecha,
          logrosDesbloqueados: logros,
        ),
      );
    } on DatabaseException catch (e) {
      return Fallo(FallaBaseDeDatos('Error al consultar racha: $e'));
    } catch (e) {
      return Fallo(FallaBaseDeDatos('Error inesperado al consultar racha: $e'));
    }
  }

  @override
  Future<Result<void>> guardarRacha(Racha racha) async {
    try {
      final db = await appDatabase.database;
      final map = {
        'id': 1,
        'dias_actuales': racha.diasActuales,
        'mejor_racha': racha.mejorRacha,
        'ultima_fecha': racha.ultimaFechaCompletado?.toIso8601String(),
        'logros': racha.logrosDesbloqueados.join(','),
      };

      await db.insert(
        'racha',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return const Exito(null);
    } on DatabaseException catch (e) {
      return Fallo(FallaBaseDeDatos('Error al guardar racha: $e'));
    } catch (e) {
      return Fallo(FallaBaseDeDatos('Error inesperado al guardar racha: $e'));
    }
  }
}
