import 'package:sqflite/sqflite.dart';
import 'package:mi_pendiente/features/pendientes/data/datasources/app_database.dart';
import '../../domain/entities/clase.dart';
import '../../domain/entities/examen.dart';

abstract class HorarioLocalDataSource {
  Future<List<Clase>> getClases();
  Future<void> insertarClase(Clase clase);
  Future<void> actualizarClase(Clase clase);
  Future<void> eliminarClase(String id);

  Future<List<Examen>> getExamenes(String claseId);
  Future<List<Examen>> getTodosLosExamenes();
  Future<void> insertarExamen(Examen examen);
  Future<void> actualizarExamen(Examen examen);
  Future<void> eliminarExamen(String id);
}

class HorarioLocalDataSourceImpl implements HorarioLocalDataSource {
  final AppDatabase appDatabase;

  HorarioLocalDataSourceImpl({AppDatabase? db}) : appDatabase = db ?? AppDatabase.instance;

  @override
  Future<List<Clase>> getClases() async {
    final db = await appDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clases',
      orderBy: 'dia_semana ASC, hora_inicio ASC, minuto_inicio ASC',
    );
    return maps.map((m) => Clase.fromMap(m)).toList();
  }

  @override
  Future<void> insertarClase(Clase clase) async {
    final db = await appDatabase.database;
    await db.insert(
      'clases',
      clase.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> actualizarClase(Clase clase) async {
    final db = await appDatabase.database;
    await db.update(
      'clases',
      clase.toMap(),
      where: 'id = ?',
      whereArgs: [clase.id],
    );
  }

  @override
  Future<void> eliminarClase(String id) async {
    final db = await appDatabase.database;
    await db.delete(
      'clases',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Eliminar también los exámenes asociados
    await db.delete(
      'examenes',
      where: 'clase_id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Examen>> getExamenes(String claseId) async {
    final db = await appDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'examenes',
      where: 'clase_id = ?',
      whereArgs: [claseId],
      orderBy: 'fecha ASC, hora_hour ASC, hora_minute ASC',
    );
    return maps.map((m) => Examen.fromMap(m)).toList();
  }

  @override
  Future<List<Examen>> getTodosLosExamenes() async {
    final db = await appDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'examenes',
      orderBy: 'fecha ASC, hora_hour ASC, hora_minute ASC',
    );
    return maps.map((m) => Examen.fromMap(m)).toList();
  }

  @override
  Future<void> insertarExamen(Examen examen) async {
    final db = await appDatabase.database;
    await db.insert(
      'examenes',
      examen.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> actualizarExamen(Examen examen) async {
    final db = await appDatabase.database;
    await db.update(
      'examenes',
      examen.toMap(),
      where: 'id = ?',
      whereArgs: [examen.id],
    );
  }

  @override
  Future<void> eliminarExamen(String id) async {
    final db = await appDatabase.database;
    await db.delete(
      'examenes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
