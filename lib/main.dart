import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
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

  // Inicializar servicio de notificaciones
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await NotificationService.instance.init();
    await NotificationService.instance.pedirPermisos();
  }

  runApp(
    const ProviderScope(
      child: MiPendienteApp(),
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
