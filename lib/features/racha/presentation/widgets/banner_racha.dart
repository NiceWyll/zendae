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
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late Animation<double> _bobAnim;
  late Animation<double> _swayAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _flickerAnim;

  late AnimationController _clickController;
  late Animation<double> _clickScaleAnim;
  late Animation<double> _clickBurstAnim;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // 1. Animación continua pasiva (vaivén, respiración y parpadeo de llama)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Flotación vertical suave (-3.2px a 0.0px)
    _bobAnim = Tween<double>(begin: 0.0, end: -3.2).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    // Vaivén orgánico de inclinación (aprox. -2.2° a +2.2°)
    _swayAnim = Tween<double>(begin: -0.038, end: 0.038).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    // Parpadeo / pulsación suave del aura luminosa y sombra (glow)
    _glowAnim = Tween<double>(begin: 0.35, end: 0.90).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    // Titileo dinámico que simula el parpadeo de fuego
    _flickerAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.88, end: 1.0), weight: 28),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.72), weight: 22),
      TweenSequenceItem(tween: Tween<double>(begin: 0.72, end: 1.0), weight: 28),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.88), weight: 22),
    ]).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    // 2. Animación interactiva de clic (rebote elástico + destello)
    _clickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );

    _clickScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.18).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 55,
      ),
    ]).animate(_clickController);

    _clickBurstAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _clickController, curve: Curves.easeOut),
    );

    final bool esTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!esTest) {
      _idleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _clickController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = false);

    // Disparar animación de rebote y destello
    await _clickController.forward(from: 0.0);

    if (!mounted) return;
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
      animation: Listenable.merge([_idleController, _clickController]),
      builder: (context, _) {
        final double scale = _clickController.isAnimating
            ? _clickScaleAnim.value
            : (_isPressed ? 0.90 : 1.0);

        final double bob = _bobAnim.value;
        final double sway = _swayAnim.value;
        final double glow = _glowAnim.value;
        final double flicker = _flickerAnim.value;
        final double burst = _clickController.isAnimating ? _clickBurstAnim.value : 0.0;

        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.rotate(
            angle: sway,
            child: Transform.scale(
              scale: scale,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) {
                  setState(() => _isPressed = true);
                },
                onTapUp: (_) => _handleTap(),
                onTapCancel: () {
                  setState(() => _isPressed = false);
                },
                child: _buildChipContent(
                  context,
                  racha,
                  prendaId,
                  isDark,
                  glow,
                  flicker,
                  burst,
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
    double burst,
  ) {
    final tieneRacha = racha.diasActuales > 0;

    // Gradiente con efecto de titileo parpadeante sutil
    final gradientColors = tieneRacha
        ? [
            Color.lerp(const Color(0xFFF59E0B), const Color(0xFFFBBF24), (flicker - 0.72) / 0.28) ?? const Color(0xFFF59E0B),
            Color.lerp(const Color(0xFFD97706), const Color(0xFFEA580C), burst) ?? const Color(0xFFD97706),
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
    final double auraOpacity = (tieneRacha ? (glow * 0.45 + burst * 0.45) : (glow * 0.15)).clamp(0.0, 1.0);
    final double blurRadius = tieneRacha ? (6.0 + glow * 8.0 + burst * 8.0) : (4.0 + glow * 3.0);
    final double spreadRadius = tieneRacha ? (0.4 + glow * 1.2 + burst * 1.5) : 0.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compacto ? 8 : 12,
        vertical: widget.compacto ? 4 : 6,
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
              ? const Color(0xFFFDE68A).withOpacity(0.4 + glow * 0.45)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          width: tieneRacha ? (1.0 + glow * 0.6) : 1.0,
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
          if (burst > 0.05)
            BoxShadow(
              color: Colors.white.withOpacity(burst * 0.6),
              blurRadius: 14 * burst,
              spreadRadius: 2 * burst,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Personaje animado de Zendy en miniatura
          SizedBox(
            width: widget.compacto ? 20 : 24,
            height: widget.compacto ? 20 : 24,
            child: Center(
              child: ZendyPersonajeWidget(
                size: widget.compacto ? 18 : 24,
                prendaId: prendaId,
                animado: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${racha.diasActuales}',
            style: TextStyle(
              color: textColor,
              fontSize: widget.compacto ? 12 : 13,
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
                fontSize: 11,
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
