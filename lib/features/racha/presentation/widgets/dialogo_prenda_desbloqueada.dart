import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import '../../domain/entities/prenda_personaje.dart';
import '../providers/personaje_provider.dart';
import '../screens/armario_screen.dart';
import 'zendy_personaje_widget.dart';

class DialogoPrendaDesbloqueada extends ConsumerWidget {
  final PrendaPersonaje prenda;

  const DialogoPrendaDesbloqueada({super.key, required this.prenda});

  static Future<void> mostrar(BuildContext context, PrendaPersonaje prenda) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => DialogoPrendaDesbloqueada(prenda: prenda),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge superior de felicitaciones
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('✨', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text(
                    '¡NUEVA PRENDA DESBLOQUEADA!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Vista previa animada del personaje con la prenda puesta
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [const Color(0xFF334155), const Color(0xFF1E293B)]
                      : [const Color(0xFFFEF3C7), const Color(0xFFFFFBEB)],
                ),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.2),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: ZendyPersonajeWidget(
                  size: 130,
                  prendaId: prenda.id,
                  animado: true,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Nombre y detalles de la prenda
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(prenda.iconoEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  prenda.nombre,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              prenda.descripcion,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Alcanzado a los ${prenda.diasRequeridos} días de racha activa ⭐',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ArmarioScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      'Ir al Vestidor',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(personajeProvider.notifier).equiparPrenda(prenda.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✨ ¡${prenda.nombre} equipada en Zendy!'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Equipar ahora',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
