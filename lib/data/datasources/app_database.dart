import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../domain/entities/hora_del_dia.dart';
import '../../domain/entities/pendiente.dart';
import '../../domain/entities/prioridad.dart';
import '../models/pendiente_model.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase();
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
      // En Windows usamos APPDATA directamente de dart:io (sin canales nativos, 100% seguro)
      final appData = Platform.environment['APPDATA'] ?? Platform.environment['USERPROFILE'] ?? '.';
      final folder = Directory(p.join(appData, 'MiPendiente'));
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      dbFullPath = p.join(folder.path, filePath);
    } else {
      // En Android e iOS usamos el getDatabasesPath estándar de sqflite
      final dbPath = await getDatabasesPath();
      dbFullPath = p.join(dbPath, filePath);
    }

    final db = await openDatabase(
      dbFullPath,
      version: 1,
      onCreate: _createDB,
    );

    // Si la tabla existe pero está vacía, sembrar los datos iniciales
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM pendientes');
    final count = Sqflite.firstIntValue(countResult) ?? 0;
    if (count == 0) {
      await _seedInitialData(db);
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
        fecha_completado TEXT
      )
    ''');

    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day);
    final yesterdayStr = todayStr.subtract(const Duration(days: 1));

    final initialTasks = [
      Pendiente(
        id: '1',
        titulo: 'Revisar correos',
        descripcion: 'Responder mensajes prioritarios y archivar newsletters.',
        fecha: todayStr,
        hora: const HoraDelDia(hora: 8, minuto: 0),
        prioridad: Prioridad.alta,
        tieneRecordatorio: true,
        minutosAntes: 10,
        estaCompletado: false,
      ),
      Pendiente(
        id: '2',
        titulo: 'Reunión con equipo',
        descripcion: 'Revisar avances del proyecto y definir próximos pasos.',
        fecha: todayStr,
        hora: const HoraDelDia(hora: 10, minuto: 30),
        prioridad: Prioridad.media,
        tieneRecordatorio: true,
        minutosAntes: 15,
        estaCompletado: true,
        fechaCompletado: todayStr,
      ),
      Pendiente(
        id: '3',
        titulo: 'Comprar materiales',
        descripcion: 'Adquirir libretas y suministros de oficina.',
        fecha: todayStr,
        hora: const HoraDelDia(hora: 15, minuto: 0),
        prioridad: Prioridad.baja,
        tieneRecordatorio: false,
        minutosAntes: 10,
        estaCompletado: false,
      ),
      Pendiente(
        id: '4',
        titulo: 'Hacer ejercicio',
        descripcion: 'Rutina de cardio y estiramiento por 45 minutos.',
        fecha: todayStr,
        hora: const HoraDelDia(hora: 18, minuto: 30),
        prioridad: Prioridad.baja,
        tieneRecordatorio: true,
        minutosAntes: 30,
        estaCompletado: false,
      ),
      // Completados
      Pendiente(
        id: 'c1',
        titulo: 'Enviar reporte semanal',
        descripcion: 'Reporte consolidado de métricas al supervisor.',
        fecha: todayStr,
        hora: const HoraDelDia(hora: 9, minuto: 15),
        prioridad: Prioridad.media,
        estaCompletado: true,
        fechaCompletado: todayStr,
      ),
      Pendiente(
        id: 'c2',
        titulo: 'Comprar pasajes',
        descripcion: 'Boletos de avión para el viaje de trabajo.',
        fecha: todayStr,
        hora: const HoraDelDia(hora: 11, minuto: 30),
        prioridad: Prioridad.alta,
        estaCompletado: true,
        fechaCompletado: todayStr,
      ),
      Pendiente(
        id: 'c3',
        titulo: 'Llamar al banco',
        descripcion: 'Confirmar recepción de transferencia internacional.',
        fecha: todayStr,
        hora: const HoraDelDia(hora: 16, minuto: 45),
        prioridad: Prioridad.baja,
        estaCompletado: true,
        fechaCompletado: todayStr,
      ),
      Pendiente(
        id: 'c4',
        titulo: 'Revisar presentación',
        descripcion: 'Diapositivas finales con diseño corporativo.',
        fecha: yesterdayStr,
        hora: const HoraDelDia(hora: 10, minuto: 20),
        prioridad: Prioridad.media,
        estaCompletado: true,
        fechaCompletado: yesterdayStr,
      ),
      Pendiente(
        id: 'c5',
        titulo: 'Pagar servicios',
        descripcion: 'Luz, internet y agua potable del mes.',
        fecha: yesterdayStr,
        hora: const HoraDelDia(hora: 18, minuto: 30),
        prioridad: Prioridad.alta,
        estaCompletado: true,
        fechaCompletado: yesterdayStr,
      ),
    ];

    for (var task in initialTasks) {
      await db.insert('pendientes', PendienteModel.toMap(task));
    }
  }
}
