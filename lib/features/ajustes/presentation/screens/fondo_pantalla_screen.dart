import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/theme/tema_app.dart';
import '../providers/ajustes_provider.dart';
import '../widgets/seccion_fondo_personalizado.dart';
import 'selector_temas_screen.dart';

/// Pantalla dedicada e independiente para personalizar el Fondo de Pantalla
/// Permite al usuario elegir cualquier foto o GIF animado mientras conserva
/// la paleta de colores que prefiera en toda la app.
class FondoPantallaScreen extends ConsumerWidget {
  const FondoPantallaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ajustes = ref.watch(ajustesProvider);
    final temaActual = TemasDisponibles.obtenerPorId(ajustes.temaId);
    final colorAcento = isDark ? temaActual.colorSecundario : temaActual.colorPrimario;
    final tieneFondo = ajustes.fondoPersonalizadoPath != null &&
        ajustes.fondoPersonalizadoPath!.trim().isNotEmpty &&
        File(ajustes.fondoPersonalizadoPath!).existsSync();

    return Scaffold(
      backgroundColor: tieneFondo
          ? Colors.transparent
          : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
      appBar: AppBar(
        title: const Text(
          'Fondo de Pantalla 🖼️',
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
          // Banner explicativo: Fondo independiente de la paleta de colores
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorAcento.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: colorAcento,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Totalmente personalizable',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Puedes colocar cualquier foto o GIF animado. Tus botones, íconos y detalles conservarán los colores de tu tema actual (${temaActual.nombre}).',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sección de subida, vista previa y eliminación del fondo
          const SeccionFondoPersonalizado(),

          const SizedBox(height: 10),

          // Tarjeta de vinculación con la paleta de colores
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: colorAcento,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: colorAcento.withValues(alpha: 0.45),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tema de color actual:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      temaActual.nombre,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '¿Quieres combinar este fondo con otro color de botones e íconos?',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SelectorTemasScreen()),
                      );
                    },
                    icon: Icon(Icons.palette_rounded, size: 18, color: colorAcento),
                    label: Text(
                      'Explorar paletas de colores y temas',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: colorAcento,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorAcento,
                      side: BorderSide(
                        color: colorAcento.withValues(alpha: isDark ? 0.75 : 0.5),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
