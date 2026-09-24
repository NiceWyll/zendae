import 'package:sqflite/sqflite.dart';
import 'package:mi_pendiente/features/pendientes/data/datasources/app_database.dart';
import '../../domain/entities/clase.dart';

abstract class HorarioLocalDataSource {
  Future<List<Clase>> getClases();
  Future<void> insertarClase(Clase clase);
  Future<void> actualizarClase(Clase clase);
  Future<void> eliminarClase(String id);
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
  }
}
