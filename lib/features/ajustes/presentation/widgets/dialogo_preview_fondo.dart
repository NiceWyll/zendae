import 'dart:io';
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

      // 1. Eliminar archivo anterior y desalojar de ImageCache
      final oldPath = ref.read(ajustesProvider).fondoPersonalizadoPath;
      if (oldPath != null && oldPath.isNotEmpty) {
        try {
          FileImage(File(oldPath)).evict();
          final oldFile = File(oldPath);
          if (oldFile.existsSync()) {
            oldFile.deleteSync();
          }
        } catch (_) {}
      }

      // 2. Limpiar cache de imágenes en memoria para refresco visual inmediato
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 3. Generar path único con timestamp para garantizar refresco instantáneo sin reiniciar la app
      final ext = p.extension(widget.archivoTemporal.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final destPath = p.join(bgDir.path, 'fondo_animado_$timestamp$ext');

      // Copiar archivo a almacenamiento permanente
      await widget.archivoTemporal.copy(destPath);

      // Guardar en ajustes
      await ref.read(ajustesProvider.notifier).guardarFondoPersonalizado(destPath);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ ¡Fondo aplicado con éxito!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
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
    final accentColor = Theme.of(context).colorScheme.primary;
    final mb = (widget.tamanoBytes / (1024 * 1024)).toStringAsFixed(2);
    final screenHeight = MediaQuery.of(context).size.height;
    final previewHeight = (screenHeight * 0.46).clamp(320.0, 440.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Row(
              children: [
                Icon(
                  Icons.wallpaper_rounded,
                  color: isDark ? const Color(0xFF818CF8) : AppColors.primary,
                  size: 22,
                ),
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
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
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

            // VISUALIZADOR DE PANTALLA COMPLETO Y NÍTIDO (SIN DIFUMINAR, SIN TAREAS FALSAS)
            Container(
              height: previewHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagen o GIF 100% nítida y visible
                    Image.file(
                      widget.archivoTemporal,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),

                    // Badge discreto inferior indicando preview exitoso
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vista previa nítida de tu fondo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
                      foregroundColor: isDark ? Colors.white70 : AppColors.textSecondary,
                      side: BorderSide(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _aplicarFondo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
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
