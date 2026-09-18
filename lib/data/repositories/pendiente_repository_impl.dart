import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/pendiente.dart';
import '../../domain/repositories/pendiente_repository.dart';
import '../datasources/app_database.dart';
import '../models/pendiente_model.dart';

class PendienteRepositoryImpl implements PendienteRepository {
  final AppDatabase appDatabase;

  PendienteRepositoryImpl({required this.appDatabase});

  @override
  Future<Result<List<Pendiente>>> getPendientes() async {
    try {
      final db = await appDatabase.database;
      final maps = await db.query(
        'pendientes',
        orderBy: 'fecha ASC, hora_hour ASC, hora_minute ASC',
      );
      return Exito(maps.map((e) => PendienteModel.fromMap(e)).toList());
    } on DatabaseException catch (e) {
      debugPrint('Error en getPendientes: $e');
      return const Fallo(FallaBaseDeDatos('No se pudieron cargar tus pendientes'));
    } catch (e) {
      debugPrint('Error inesperado en getPendientes: $e');
      return const Fallo(FallaBaseDeDatos('Error inesperado al cargar pendientes'));
    }
  }

  @override
  Future<Result<List<Pendiente>>> getPendientesPorFecha(DateTime fecha) async {
    try {
      final db = await appDatabase.database;
      final dateStr = fecha.toIso8601String().split('T').first;
      final maps = await db.query(
        'pendientes',
        where: 'fecha = ?',
        whereArgs: [dateStr],
        orderBy: 'hora_hour ASC, hora_minute ASC',
      );
      return Exito(maps.map((e) => PendienteModel.fromMap(e)).toList());
    } on DatabaseException catch (e) {
      debugPrint('Error en getPendientesPorFecha: $e');
      return const Fallo(FallaBaseDeDatos('No se pudieron cargar los pendientes de la fecha'));
    } catch (e) {
      return const Fallo(FallaBaseDeDatos('Error inesperado al consultar por fecha'));
    }
  }

  @override
  Future<Result<List<Pendiente>>> getPendientesPorRango(DateTime inicio, DateTime fin) async {
    try {
      final db = await appDatabase.database;
      final inicioStr = inicio.toIso8601String().split('T').first;
      final finStr = fin.toIso8601String().split('T').first;

      final maps = await db.query(
        'pendientes',
        where: 'fecha >= ? AND fecha <= ?',
        whereArgs: [inicioStr, finStr],
        orderBy: 'fecha ASC, hora_hour ASC, hora_minute ASC',
      );
      return Exito(maps.map((e) => PendienteModel.fromMap(e)).toList());
    } on DatabaseException catch (e) {
      debugPrint('Error en getPendientesPorRango: $e');
      return const Fallo(FallaBaseDeDatos('No se pudieron cargar los pendientes del rango'));
    } catch (e) {
      return const Fallo(FallaBaseDeDatos('Error inesperado al consultar por rango'));
    }
  }

  @override
  Future<Result<List<Pendiente>>> getPendientesCompletados() async {
    try {
      final db = await appDatabase.database;
      final maps = await db.query(
        'pendientes',
        where: 'esta_completado = 1',
        orderBy: 'fecha_completado DESC, fecha DESC',
      );
      return Exito(maps.map((e) => PendienteModel.fromMap(e)).toList());
    } on DatabaseException catch (e) {
      debugPrint('Error en getPendientesCompletados: $e');
      return const Fallo(FallaBaseDeDatos('No se pudieron cargar los pendientes completados'));
    } catch (e) {
      return const Fallo(FallaBaseDeDatos('Error inesperado al cargar completados'));
    }
  }

  @override
  Future<Result<Pendiente?>> getPendientePorId(String id) async {
    try {
      final db = await appDatabase.database;
      final maps = await db.query(
        'pendientes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Exito(PendienteModel.fromMap(maps.first));
      }
      return const Exito(null);
    } on DatabaseException catch (e) {
      debugPrint('Error en getPendientePorId: $e');
      return const Fallo(FallaBaseDeDatos('No se pudo encontrar el pendiente'));
    } catch (e) {
      return const Fallo(FallaBaseDeDatos('Error al consultar el pendiente'));
    }
  }

  @override
  Future<Result<void>> insertarPendiente(Pendiente pendiente) async {
    try {
      final db = await appDatabase.database;
      Pendiente aGuardar = pendiente;
      if (aGuardar.notificacionId == null && aGuardar.tieneRecordatorio) {
        final nuevoNotifId = DateTime.now().microsecondsSinceEpoch.remainder(1 << 31);
        aGuardar = aGuardar.copyWith(notificacionId: nuevoNotifId);
      }

      await db.insert(
        'pendientes',
        PendienteModel.toMap(aGuardar),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Exito(null);
    } on DatabaseException catch (e) {
      debugPrint('Error en insertarPendiente: $e');
      return const Fallo(FallaBaseDeDatos('No se pudo guardar el pendiente'));
    } catch (e) {
      return const Fallo(FallaBaseDeDatos('Error inesperado al guardar'));
    }
  }

  @override
  Future<Result<void>> actualizarPendiente(Pendiente pendiente) async {
    try {
      final db = await appDatabase.database;
      await db.update(
        'pendientes',
        PendienteModel.toMap(pendiente),
        where: 'id = ?',
        whereArgs: [pendiente.id],
      );
      return const Exito(null);
    } on DatabaseException catch (e) {
      debugPrint('Error en actualizarPendiente: $e');
      return const Fallo(FallaBaseDeDatos('No se pudo actualizar el pendiente'));
    } catch (e) {
      return const Fallo(FallaBaseDeDatos('Error al actualizar'));
    }
  }

  @override
  Future<Result<void>> eliminarPendiente(String id) async {
    try {
      final db = await appDatabase.database;
      await db.delete(
        'pendientes',
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Exito(null);
    } on DatabaseException catch (e) {
      debugPrint('Error en eliminarPendiente: $e');
      return const Fallo(FallaBaseDeDatos('No se pudo eliminar el pendiente'));
    } catch (e) {
      return const Fallo(FallaBaseDeDatos('Error al eliminar'));
    }
  }

  @override
  Future<Result<void>> alternarCompletado(String id, bool completado) async {
    try {
      final db = await appDatabase.database;
      await db.update(
        'pendientes',
        {
          'esta_completado': completado ? 1 : 0,
          'fecha_completado': completado ? DateTime.now().toIso8601String() : null,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Exito(null);
    } on DatabaseException catch (e) {
      debugPrint('Error en alternarCompletado: $e');
      return const Fallo(FallaBaseDeDatos('No se pudo actualizar el estado del pendiente'));
    } catch (e) {
      return const Fallo(FallaBaseDeDatos('Error al alternar estado'));
    }
  }

  @override
  Future<Result<void>> eliminarCompletados() async {
    try {
      final db = await appDatabase.database;
      await db.delete(
        'pendientes',
        where: 'esta_completado = 1',
      );
      return const Exito(null);
    } on DatabaseException catch (e) {
      debugPrint('Error en eliminarCompletados: $e');
      return const Fallo(FallaBaseDeDatos('No se pudieron eliminar los completados'));
    } catch (e) {
      return const Fallo(FallaBaseDeDatos('Error al eliminar completados'));
    }
  }
}
