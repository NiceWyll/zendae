import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/pendiente_model.dart';
import 'seed_data.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase();
  static const int _version = 3;
  Database? _database;

  AppDatabase({Database? db}) : _database = db;

  static Future<AppDatabase> abrir({String filePath = 'mi_pendiente.db'}) async {
    final appDb = AppDatabase();
    await appDb.database;
    return appDb;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mi_pendiente.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String dbFullPath;

    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? Platform.environment['USERPROFILE'] ?? '.';
      final folder = Directory(p.join(appData, 'MiPendiente'));
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      dbFullPath = p.join(folder.path, filePath);
    } else {
      final dbPath = await getDatabasesPath();
      dbFullPath = p.join(dbPath, filePath);
    }

    final db = await openDatabase(
      dbFullPath,
      version: _version,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    // Si la tabla existe pero está vacía, sembrar los datos iniciales
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM pendientes');
    final count = Sqflite.firstIntValue(countResult) ?? 0;
    if (count == 0) {
      await sembrarDatos(db);
    }

    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pendientes (
        id TEXT PRIMARY KEY,
        titulo TEXT NOT NULL,
        descripcion TEXT,
        fecha TEXT NOT NULL,
        hora_hour INTEGER NOT NULL,
        hora_minute INTEGER NOT NULL,
        prioridad TEXT NOT NULL,
        tiene_recordatorio INTEGER NOT NULL,
        minutos_antes INTEGER NOT NULL,
        repetir TEXT NOT NULL,
        esta_completado INTEGER NOT NULL,
        fecha_completado TEXT,
        notificacion_id INTEGER
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_pendientes_fecha ON pendientes(fecha);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pendientes_completado ON pendientes(esta_completado);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS racha (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        dias_actuales INTEGER NOT NULL,
        mejor_racha INTEGER NOT NULL,
        ultima_fecha TEXT,
        logros TEXT NOT NULL
      );
    ''');

    await sembrarDatos(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE pendientes ADD COLUMN notificacion_id INTEGER;');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pendientes_fecha ON pendientes(fecha);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pendientes_completado ON pendientes(esta_completado);');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS racha (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          dias_actuales INTEGER NOT NULL,
          mejor_racha INTEGER NOT NULL,
          ultima_fecha TEXT,
          logros TEXT NOT NULL
        );
      ''');
    }
  }

  Future<void> sembrarDatos(Database db) async {
    final tasks = SeedData.obtenerPendientesIniciales();
    for (final task in tasks) {
      await db.insert('pendientes', PendienteModel.toMap(task));
    }
  }
}
