import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/constants/app_config.dart';
import 'package:mi_pendiente/features/racha/presentation/providers/racha_provider.dart';
import 'package:mi_pendiente/features/racha/presentation/widgets/zendy_personaje_widget.dart';
import '../widgets/seccion_fondo_personalizado.dart';
import '../widgets/selector_temas_grid.dart';

class SelectorTemasScreen extends ConsumerWidget {
  const SelectorTemasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rachaAsync = ref.watch(rachaNotifierProvider);
    final racha = rachaAsync.valueOrNull;
    final dias = racha?.diasActuales ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Temas y Colores 🎨',
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Banner de contexto y racha con Zendy
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFBFDBFE),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: Center(
                    child: ZendyPersonajeWidget(
                      tamano: 48,
                      animar: true,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu Racha: $dias ${dias == 1 ? 'día' : 'días'}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppConfig.todoDesbloqueado
                            ? '¡Todos los temas y colores están 100% desbloqueados para ti!'
                            : 'Completa tareas diarias para mantener a Zendy contento y desbloquear temas exclusivos.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF3B82F6),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Sección de fondo personalizado con difuminado (EXCLUSIVO ANDROID)
          const SeccionFondoPersonalizado(),

          // Título del grid
          Text(
            'Elige tu paleta favorita',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Grid de selección
          const SelectorTemasGrid(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
