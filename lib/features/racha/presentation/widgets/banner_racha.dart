import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import '../../domain/entities/racha.dart';
import '../providers/personaje_provider.dart';
import '../providers/racha_provider.dart';
import '../screens/mis_logros_screen.dart';
import 'zendy_personaje_widget.dart';

/// Chip compacto interactivo que muestra la racha activa con el personaje Zendy animado
class BannerRachaChip extends ConsumerWidget {
  const BannerRachaChip({
    super.key,
    this.compacto = false,
  });

  final bool compacto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rachaAsync = ref.watch(rachaNotifierProvider);
    final personaje = ref.watch(personajeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return rachaAsync.when(
      data: (racha) => _buildChip(context, racha, personaje.prendaEquipadaId, isDark),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildChip(BuildContext context, Racha racha, String prendaId, bool isDark) {
    final tieneRacha = racha.diasActuales > 0;

    final gradientColors = tieneRacha
        ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
        : isDark
            ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
            : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)];

    final textColor = tieneRacha
        ? Colors.white
        : isDark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MisLogrosScreen(),
            ),
          );
        },
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compacto ? 6 : 12,
            vertical: compacto ? 3 : 5,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: tieneRacha
                ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Personaje animado de Zendy en miniatura
              ZendyPersonajeWidget(
                size: compacto ? 19 : 24,
                prendaId: prendaId,
                animado: true,
              ),
              const SizedBox(width: 4),
              Text(
                '${racha.diasActuales}',
                style: TextStyle(
                  color: textColor,
                  fontSize: compacto ? 12 : 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              if (!compacto) ...[
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
        ),
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
