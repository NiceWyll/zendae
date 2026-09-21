import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tema_app.dart';
import 'features/ajustes/presentation/providers/ajustes_provider.dart';
import 'shell/splash_screen.dart';

class MiPendienteApp extends ConsumerWidget {
  const MiPendienteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ajustes = ref.watch(ajustesProvider);
    final tema = TemasDisponibles.obtenerPorId(ajustes.temaId);

    return MaterialApp(
      title: 'Zendae',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.crearThemeData(tema, false),
      darkTheme: AppTheme.crearThemeData(tema, true),
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
