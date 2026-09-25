import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mi_pendiente/core/constants/app_colors.dart';
import '../providers/ajustes_provider.dart';

class DialogoPreviewFondo extends ConsumerStatefulWidget {
  final File archivoTemporal;
  final int tamanoBytes;

  const DialogoPreviewFondo({
    super.key,
    required this.archivoTemporal,
    required this.tamanoBytes,
  });

  static Future<bool?> mostrar(
    BuildContext context, {
    required File archivo,
    required int tamanoBytes,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogoPreviewFondo(
        archivoTemporal: archivo,
        tamanoBytes: tamanoBytes,
      ),
    );
  }

  @override
  ConsumerState<DialogoPreviewFondo> createState() => _DialogoPreviewFondoState();
}

class _DialogoPreviewFondoState extends ConsumerState<DialogoPreviewFondo> {
  bool _guardando = false;

  Future<void> _aplicarFondo() async {
    setState(() => _guardando = true);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final bgDir = Directory(p.join(appDir.path, 'custom_bg'));
      if (!await bgDir.exists()) {
        await bgDir.create(recursive: true);
      }

      final ext = p.extension(widget.archivoTemporal.path);
      final destPath = p.join(bgDir.path, 'fondo_animado$ext');

      // Copiar archivo a almacenamiento permanente
      await widget.archivoTemporal.copy(destPath);

      // Guardar en ajustes
      await ref.read(ajustesProvider.notifier).guardarFondoPersonalizado(destPath);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ ¡Fondo animado aplicado con éxito!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el fondo: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mb = (widget.tamanoBytes / (1024 * 1024)).toStringAsFixed(2);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Row(
              children: [
                const Icon(Icons.wallpaper_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vista Previa del Fondo',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$mb MB (≤ 10 MB)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // SIMULADOR DE PANTALLA CON EL FONDO Y DIFUMINADO
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Fondo animado / imagen
                    Image.file(
                      widget.archivoTemporal,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),

                    // Capa difuminada (Blur)
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        color: isDark
                            ? const Color(0xFF0F172A).withOpacity(0.72)
                            : Colors.white.withOpacity(0.78),
                      ),
                    ),

                    // Elementos simulados de la app para ver contraste y legibilidad
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header simulado
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mi Pendiente',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),

                          // Tarjeta simulada de clase
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.school_rounded, color: Color(0xFF6366F1), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '10:00 - Cálculo Integral (Aula 302)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Tarjeta simulada de tarea
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ejercicios de física cuántica cap. 4',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // AVISO DE BATERÍA
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.battery_alert_rounded, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este fondo animado consumirá un poco más de batería que un tema estático.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // BOTONES
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _guardando ? null : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _aplicarFondo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Aplicar Fondo', style: TextStyle(fontWeight: FontWeight.w700)),
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
