import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  static final AppDatabase instance = AppDatabase();
  static const int _version = 5;
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
        notificacion_id INTEGER,
        clase_id TEXT
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_pendientes_fecha ON pendientes(fecha);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pendientes_completado ON pendientes(esta_completado);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pendientes_clase ON pendientes(clase_id);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS racha (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        dias_actuales INTEGER NOT NULL,
        mejor_racha INTEGER NOT NULL,
        ultima_fecha TEXT,
        logros TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clases (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        dia_semana INTEGER NOT NULL,
        hora_inicio INTEGER NOT NULL,
        minuto_inicio INTEGER NOT NULL,
        hora_fin INTEGER NOT NULL,
        minuto_fin INTEGER NOT NULL,
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT NOT NULL,
        minutos_antes INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        aula TEXT,
        notificacion_id INTEGER
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_clases_dia ON clases(dia_semana);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS examenes (
        id TEXT PRIMARY KEY,
        clase_id TEXT NOT NULL,
        titulo TEXT NOT NULL,
        fecha TEXT NOT NULL,
        hora_hour INTEGER NOT NULL,
        hora_minute INTEGER NOT NULL,
        aula TEXT,
        notificacion_1d_id INTEGER,
        notificacion_1h_id INTEGER
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_examenes_clase ON examenes(clase_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_examenes_fecha ON examenes(fecha);');
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
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS clases (
          id TEXT PRIMARY KEY,
          nombre TEXT NOT NULL,
          dia_semana INTEGER NOT NULL,
          hora_inicio INTEGER NOT NULL,
          minuto_inicio INTEGER NOT NULL,
          hora_fin INTEGER NOT NULL,
          minuto_fin INTEGER NOT NULL,
          fecha_inicio TEXT NOT NULL,
          fecha_fin TEXT NOT NULL,
          minutos_antes INTEGER NOT NULL,
          color_value INTEGER NOT NULL,
          aula TEXT,
          notificacion_id INTEGER
        );
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_clases_dia ON clases(dia_semana);');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE pendientes ADD COLUMN clase_id TEXT;');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pendientes_clase ON pendientes(clase_id);');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS examenes (
          id TEXT PRIMARY KEY,
          clase_id TEXT NOT NULL,
          titulo TEXT NOT NULL,
          fecha TEXT NOT NULL,
          hora_hour INTEGER NOT NULL,
          hora_minute INTEGER NOT NULL,
          aula TEXT,
          notificacion_1d_id INTEGER,
          notificacion_1h_id INTEGER
        );
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_examenes_clase ON examenes(clase_id);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_examenes_fecha ON examenes(fecha);');
    }
  }

  Future<void> sembrarDatos(Database db) async {
    // Instalación limpia sin pendientes precargados para nuevos usuarios
  }
}
