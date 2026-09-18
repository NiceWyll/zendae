import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/ajustes/presentation/providers/ajustes_provider.dart';
import 'shell/splash_screen.dart';

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
