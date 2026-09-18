import 'package:sqflite/sqflite.dart';
import '../../domain/entities/pendiente.dart';
import '../../domain/repositories/pendiente_repository.dart';
import '../datasources/app_database.dart';
import '../models/pendiente_model.dart';

class PendienteRepositoryImpl implements PendienteRepository {
  final AppDatabase appDatabase;

  PendienteRepositoryImpl({required this.appDatabase});

  @override
  Future<List<Pendiente>> getPendientes() async {
    final db = await appDatabase.database;
    final maps = await db.query(
      'pendientes',
      orderBy: 'fecha ASC, hora_hour ASC, hora_minute ASC',
    );
    return maps.map((e) => PendienteModel.fromMap(e)).toList();
  }

  @override
  Future<List<Pendiente>> getPendientesPorFecha(DateTime fecha) async {
    final db = await appDatabase.database;
    final dateStr = fecha.toIso8601String().split('T').first;
    final maps = await db.query(
      'pendientes',
      where: 'fecha = ?',
      whereArgs: [dateStr],
      orderBy: 'hora_hour ASC, hora_minute ASC',
    );
    return maps.map((e) => PendienteModel.fromMap(e)).toList();
  }

  @override
  Future<List<Pendiente>> getPendientesPorRango(DateTime inicio, DateTime fin) async {
    final db = await appDatabase.database;
    final inicioStr = inicio.toIso8601String().split('T').first;
    final finStr = fin.toIso8601String().split('T').first;

    final maps = await db.query(
      'pendientes',
      where: 'fecha >= ? AND fecha <= ?',
      whereArgs: [inicioStr, finStr],
      orderBy: 'fecha ASC, hora_hour ASC, hora_minute ASC',
    );
    return maps.map((e) => PendienteModel.fromMap(e)).toList();
  }

  @override
  Future<List<Pendiente>> getPendientesCompletados() async {
    final db = await appDatabase.database;
    final maps = await db.query(
      'pendientes',
      where: 'esta_completado = 1',
      orderBy: 'fecha_completado DESC, fecha DESC',
    );
    return maps.map((e) => PendienteModel.fromMap(e)).toList();
  }

  @override
  Future<Pendiente?> getPendientePorId(String id) async {
    final db = await appDatabase.database;
    final maps = await db.query(
      'pendientes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return PendienteModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> insertarPendiente(Pendiente pendiente) async {
    final db = await appDatabase.database;
    await db.insert(
      'pendientes',
      PendienteModel.toMap(pendiente),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> actualizarPendiente(Pendiente pendiente) async {
    final db = await appDatabase.database;
    await db.update(
      'pendientes',
      PendienteModel.toMap(pendiente),
      where: 'id = ?',
      whereArgs: [pendiente.id],
    );
  }

  @override
  Future<void> eliminarPendiente(String id) async {
    final db = await appDatabase.database;
    await db.delete(
      'pendientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> alternarCompletado(String id, bool completado) async {
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
  }

  @override
  Future<void> eliminarCompletados() async {
    final db = await appDatabase.database;
    await db.delete(
      'pendientes',
      where: 'esta_completado = 1',
    );
  }
}
