import 'package:flutter/material.dart';
import 'package:mi_pendiente/core/constants/app_typography.dart';

/// Widget visual para estados vacíos interactivos y atractivos.
class EmptyStateWidget extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? textoBoton;
  final VoidCallback? alPresionarBoton;
  final Color? colorAcento;

  const EmptyStateWidget({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.textoBoton,
    this.alPresionarBoton,
    this.colorAcento,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = colorAcento ?? Theme.of(context).primaryColor;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Círculo concéntrico estilizado con icono
            Stack(
              alignment: Alignment.center,
              children: [
                // Halo exterior
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
                // Anillo medio
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                ),
                // Icono central
                Icon(
                  icono,
                  size: 42,
                  color: primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Título
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),

            // Mensaje descriptivo
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                mensaje,
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary.copyWith(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
            ),

            // Botón de acción opcional
            if (textoBoton != null && alPresionarBoton != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: alPresionarBoton,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: primaryColor.withValues(alpha: 0.35),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  textoBoton!,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
