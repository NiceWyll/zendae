import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/providers/database_providers.dart';
import 'core/providers/notification_providers.dart';
import 'core/providers/preferences_providers.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/app_database.dart';
import 'presentation/providers/ajustes_provider.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀🚀🚀 MI_PENDIENTE_APP_STARTED 🚀🚀🚀');

  FlutterError.onError = (details) {
    debugPrint('🛑 FLUTTER ERROR: ${details.exceptionAsString()}');
    debugPrint(details.stack.toString());
  };

  GoogleFonts.config.allowRuntimeFetching = false;

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

class MiPendienteApp extends ConsumerWidget {
  const MiPendienteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('🚀🚀🚀 MI_PENDIENTE_APP BUILD CALLED 🚀🚀🚀');
    final ajustes = ref.watch(ajustesProvider);
    debugPrint('🚀🚀🚀 AJUSTES OBTAINED: ${ajustes.themeMode} 🚀🚀🚀');

    return MaterialApp(
      title: 'Mi Pendiente',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ajustes.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('es', ''),
        Locale('en', ''),
      ],
      locale: const Locale('es', 'ES'),
      home: const SplashScreen(),
    );
  }
}
