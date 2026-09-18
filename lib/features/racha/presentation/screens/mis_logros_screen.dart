import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import '../../domain/entities/hito_racha.dart';
import '../../domain/entities/racha.dart';
import '../providers/racha_provider.dart';

class MisLogrosScreen extends ConsumerWidget {
  const MisLogrosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rachaAsync = ref.watch(rachaNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Mis Logros y Racha 🔥',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        elevation: 0,
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        centerTitle: true,
      ),
      body: rachaAsync.when(
        data: (racha) => _buildContenido(context, racha, isDark),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudo cargar la racha'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(rachaNotifierProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContenido(BuildContext context, Racha racha, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // Tarjeta principal de la Racha
        _buildHeroCard(racha, isDark),

        const SizedBox(height: 24),

        // Barra de progreso hacia el siguiente hito
        _buildProgresoSiguienteHito(racha, isDark),

        const SizedBox(height: 28),

        // Título de la sección de hitos
        Row(
          children: [
            const Icon(Icons.military_tech_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Hitos y Recompensas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Lista de Hitos
        ...HitoRacha.values.map(
          (hito) => _buildHitoCard(hito, racha, isDark),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeroCard(Racha racha, bool isDark) {
    final tieneRacha = racha.diasActuales > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tieneRacha
              ? [const Color(0xFFFF5722), const Color(0xFFF57C00)]
              : (isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                  : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (tieneRacha ? const Color(0xFFFF5722) : const Color(0xFF3B82F6))
                .withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                tieneRacha ? '🔥' : '🌱',
                style: const TextStyle(fontSize: 44),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${racha.diasActuales}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            racha.diasActuales == 1 ? 'DÍA DE RACHA ACTIVA' : 'DÍAS DE RACHA ACTIVA',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Mejor récord histórico: ${racha.mejorRacha} ${racha.mejorRacha == 1 ? 'día' : 'días'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgresoSiguienteHito(Racha racha, bool isDark) {
    final proximo = racha.proximoHito;
    final progreso = racha.progresoHaciaProximoHito;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Próximo objetivo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Text(
                proximo != null
                    ? '${racha.diasActuales} / ${proximo.dias} días'
                    : '¡Todos alcanzados!',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 12,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            proximo != null
                ? 'Faltan ${proximo.dias - racha.diasActuales} días para desbloquear: ${proximo.titulo}'
                : '¡Has conquistado todos los hitos de constancia! Eres legendario.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHitoCard(HitoRacha hito, Racha racha, bool isDark) {
    final desbloqueado = racha.logrosDesbloqueados.contains(hito.name) ||
        racha.diasActuales >= hito.dias;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: desbloqueado
              ? const Color(0xFFFFB74D)
              : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          width: desbloqueado ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono del hito
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: desbloqueado
                  ? const LinearGradient(
                      colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF334155), const Color(0xFF1E293B)]
                          : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
                    ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                desbloqueado ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
                color: desbloqueado ? Colors.white : const Color(0xFF94A3B8),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Título y Recompensa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hito.titulo,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: desbloqueado
                            ? const Color(0xFFFFE082)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${hito.dias} días',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: desbloqueado
                              ? const Color(0xFF795548)
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hito.recompensa,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: desbloqueado
                        ? const Color(0xFFE65100)
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),

          // Badge de estado
          if (desbloqueado)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            )
          else
            const Icon(
              Icons.lock_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
        ],
      ),
    );
  }
}
