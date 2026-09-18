import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/constants/app_typography.dart';
import 'package:mi_pendiente/core/widgets/wave_background.dart';
import 'package:mi_pendiente/features/racha/presentation/providers/racha_provider.dart';
import 'home_shell_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀🚀🚀 SPLASH SCREEN INITSTATE CALLED 🚀🚀🚀');
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeShellScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final rachaAsync = ref.watch(rachaNotifierProvider);
    final diasRacha = rachaAsync.valueOrNull?.diasActuales ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: Stack(
        children: [
          // Ondas inferiores decorativas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: WaveBackground(
              height: 200,
              isDark: isDark,
            ),
          ),

          // Contenido central
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono 3D de Calendario con Check
                    _buildCalendarLogo(primaryColor),
                    const SizedBox(height: 28),

                    // Título de la app con AppTypography
                    Text(
                      'Mi Pendiente',
                      style: AppTypography.displayLarge.copyWith(
                        color: primaryColor,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtítulo
                    Text(
                      'Organiza tu día, semana y mes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Badge interactivo de racha
                    _buildRachaBadge(isDark, diasRacha, primaryColor),
                    const SizedBox(height: 40),

                    // Loader circular dinámico acorde al tema
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          primaryColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRachaBadge(bool isDark, int dias, Color primary) {
    final tieneRacha = dias > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: tieneRacha
            ? const Color(0xFFFF5722).withValues(alpha: isDark ? 0.2 : 0.1)
            : primary.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tieneRacha
              ? const Color(0xFFFF5722).withValues(alpha: 0.35)
              : primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tieneRacha ? '🔥' : '✨', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            tieneRacha
                ? 'Racha activa: $dias ${dias == 1 ? 'día' : 'días'}'
                : '¡Mantén tu racha al día!',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tieneRacha
                  ? const Color(0xFFEA580C)
                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarLogo(Color primaryColor) {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base del calendario
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Cabecera del calendario con degradado del color primario
                Container(
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.8),
                        primaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                ),
                // Cuadrícula de días
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(6, (index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Anillos superiores del calendario
          Positioned(
            top: 2,
            left: 28,
            child: _buildRing(primaryColor),
          ),
          Positioned(
            top: 2,
            right: 28,
            child: _buildRing(primaryColor),
          ),

          // Badge Check en la esquina inferior derecha
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    Color.lerp(primaryColor, Colors.black, 0.2) ?? primaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRing(Color color) {
    return Container(
      width: 8,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
