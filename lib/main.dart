import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'core/providers/database_providers.dart';
import 'core/providers/notification_providers.dart';
import 'core/providers/preferences_providers.dart';
import 'core/services/notification_service.dart';
import 'features/pendientes/data/datasources/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀🚀🚀 MI_PENDIENTE_APP_STARTED 🚀🚀🚀');

  FlutterError.onError = (details) {
    debugPrint('🛑 FLUTTER ERROR: ${details.exceptionAsString()}');
    debugPrint(details.stack.toString());
  };


  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 1. Inicializar SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // 2. Abrir base de datos
  final db = await AppDatabase.abrir();

  // 3. Inicializar servicio de notificaciones
  final notificaciones = NotificationServiceImpl();
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await notificaciones.init();
    await notificaciones.pedirPermisos();
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        notificationSchedulerProvider.overrideWithValue(notificaciones),
      ],
      child: const MiPendienteApp(),
    ),
  );
}
