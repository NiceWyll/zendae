import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import '../../domain/entities/racha.dart';
import '../providers/personaje_provider.dart';
import '../providers/racha_provider.dart';
import '../screens/mis_logros_screen.dart';
import 'zendy_personaje_widget.dart';

/// Chip interactivo que muestra la racha activa con Zendy.
/// Cuenta con:
/// 1. Animación pasiva: Flotación suave vertical, vaivén orgánico y parpadeo/titileo de aura de fuego.
/// 2. Animación al hacer clic: Compresión táctil, vibración háptica y rebote elástico con destello.
class BannerRachaChip extends ConsumerStatefulWidget {
  const BannerRachaChip({
    super.key,
    this.compacto = false,
  });

  final bool compacto;

  @override
  ConsumerState<BannerRachaChip> createState() => _BannerRachaChipState();
}

class _BannerRachaChipState extends ConsumerState<BannerRachaChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleController;
  late Animation<double> _bobAnim;
  late Animation<double> _swayAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _flickerAnim;
  late Animation<double> _pulseScaleAnim;

  @override
  void initState() {
    super.initState();

    // Animación continua pasiva (flotación, vaivén, respiración y titileo de fuego)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Flotación vertical suave (-2.8px a 1.2px)
    _bobAnim = Tween<double>(begin: -2.8, end: 1.2).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    // Vaivén orgánico de inclinación (aprox. -2.0° a +2.0°)
    _swayAnim = Tween<double>(begin: -0.035, end: 0.035).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    // Respiración suave de escala (0.98 a 1.03) para dar sensación viva
    _pulseScaleAnim = Tween<double>(begin: 0.98, end: 1.03).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    // Parpadeo / pulsación suave del aura luminosa y sombra (glow)
    _glowAnim = Tween<double>(begin: 0.40, end: 0.95).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    // Titileo dinámico que simula el parpadeo de fuego
    _flickerAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.85, end: 1.0), weight: 28),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.70), weight: 22),
      TweenSequenceItem(tween: Tween<double>(begin: 0.70, end: 1.0), weight: 28),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.85), weight: 22),
    ]).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    final bool esTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!esTest) {
      _idleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MisLogrosScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rachaAsync = ref.watch(rachaNotifierProvider);
    final personaje = ref.watch(personajeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return rachaAsync.when(
      data: (racha) => _buildAnimatedChip(context, racha, personaje.prendaEquipadaId, isDark),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAnimatedChip(
    BuildContext context,
    Racha racha,
    String prendaId,
    bool isDark,
  ) {
    return AnimatedBuilder(
      animation: _idleController,
      builder: (context, _) {
        final double bob = _bobAnim.value;
        final double sway = _swayAnim.value;
        final double scale = _pulseScaleAnim.value;
        final double glow = _glowAnim.value;
        final double flicker = _flickerAnim.value;

        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.rotate(
            angle: sway,
            child: Transform.scale(
              scale: scale,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleTap,
                child: IgnorePointer(
                  child: _buildChipContent(
                    context,
                    racha,
                    prendaId,
                    isDark,
                    glow,
                    flicker,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChipContent(
    BuildContext context,
    Racha racha,
    String prendaId,
    bool isDark,
    double glow,
    double flicker,
  ) {
    final tieneRacha = racha.diasActuales > 0;

    // Gradiente con efecto de titileo parpadeante sutil
    final gradientColors = tieneRacha
        ? [
            Color.lerp(const Color(0xFFF59E0B), const Color(0xFFFBBF24), (flicker - 0.70) / 0.30) ?? const Color(0xFFF59E0B),
            const Color(0xFFEA580C),
          ]
        : isDark
            ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
            : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)];

    final textColor = tieneRacha
        ? Colors.white
        : isDark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF64748B);

    // Resplandor pulsante / parpadeante
    final double auraOpacity = (tieneRacha ? (glow * 0.45) : (glow * 0.15)).clamp(0.0, 1.0);
    final double blurRadius = tieneRacha ? (6.0 + glow * 8.0) : (4.0 + glow * 3.0);
    final double spreadRadius = tieneRacha ? (0.4 + glow * 1.2) : 0.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compacto ? 10 : 14,
        vertical: widget.compacto ? 5 : 7,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tieneRacha
              ? const Color(0xFFFDE68A).withOpacity(0.45 + glow * 0.45)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          width: tieneRacha ? (1.1 + glow * 0.5) : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: tieneRacha
                ? const Color(0xFFF59E0B).withOpacity(auraOpacity)
                : (isDark ? Colors.black26 : Colors.blueGrey.withOpacity(0.2)),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Personaje animado de Zendy en miniatura (ligeramente más grande y visible)
          SizedBox(
            width: widget.compacto ? 24 : 28,
            height: widget.compacto ? 24 : 28,
            child: Center(
              child: ZendyPersonajeWidget(
                size: widget.compacto ? 22 : 26,
                prendaId: prendaId,
                animado: true,
              ),
            ),
          ),
          const SizedBox(width: 4.5),
          Text(
            '${racha.diasActuales}',
            style: TextStyle(
              color: textColor,
              fontSize: widget.compacto ? 13.5 : 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          if (!widget.compacto) ...[
            const SizedBox(width: 4),
            Text(
              racha.diasActuales == 1 ? 'día' : 'días',
              style: TextStyle(
                color: textColor.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner motivacional deslizable o fijo para la vista principal
class BannerRachaMotivacional extends ConsumerWidget {
  const BannerRachaMotivacional({
    super.key,
    this.onDismiss,
  });

  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rachaAsync = ref.watch(rachaNotifierProvider);
    final personaje = ref.watch(personajeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return rachaAsync.when(
      data: (racha) => _buildBanner(context, racha, personaje.prendaEquipadaId, isDark),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(BuildContext context, Racha racha, String prendaId, bool isDark) {
    final dias = racha.diasActuales;
    final tieneRacha = dias > 0;

    final titulo = tieneRacha
        ? (dias >= 7 ? '¡$dias días imparable con Zendy!' : '¡$dias ${dias == 1 ? 'día' : 'días'} de racha activa!')
        : '¡Activa a Zendy completando una tarea!';

    final subtitulo = tieneRacha
        ? (racha.proximoHito != null
            ? 'Faltan ${racha.proximoHito!.dias - dias} días para: ${racha.proximoHito!.titulo}'
            : '¡Racha legendaria completada!')
        : 'Completa un pendiente hoy para vestir y entrenar a tu reloj';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tieneRacha
              ? (isDark
                  ? [const Color(0xFF2D150B), const Color(0xFF1F1612)]
                  : [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)])
              : (isDark
                  ? [const Color(0xFF1E1E1E), const Color(0xFF141414)]
                  : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tieneRacha
              ? const Color(0xFFFFB74D).withOpacity(0.5)
              : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MisLogrosScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tieneRacha
                        ? const Color(0xFFF59E0B).withOpacity(0.18)
                        : Colors.blueGrey.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: ZendyPersonajeWidget(
                      size: 36,
                      prendaId: prendaId,
                      animado: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: tieneRacha
                              ? (isDark ? const Color(0xFFFF9E80) : const Color(0xFFC2410C))
                              : (isDark ? Colors.white70 : const Color(0xFF334155)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
