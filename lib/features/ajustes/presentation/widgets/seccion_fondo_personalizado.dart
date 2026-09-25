import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/constants/app_config.dart';
import 'package:mi_pendiente/core/theme/tema_app.dart';
import 'package:mi_pendiente/features/racha/presentation/providers/racha_provider.dart';
import '../providers/ajustes_provider.dart';
import 'dialogo_preview_fondo.dart';

/// Sección de personalización de fondo animado e imagen disponible en Android e iOS.
class SeccionFondoPersonalizado extends ConsumerWidget {
  const SeccionFondoPersonalizado({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Disponible en plataformas móviles (Android e iOS)
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ajustes = ref.watch(ajustesProvider);
    final rachaAsync = ref.watch(rachaNotifierProvider);
    final racha = rachaAsync.valueOrNull;
    final diasRacha = racha?.diasActuales ?? 0;
    final logros = racha?.logrosDesbloqueados ?? const <String>[];

    const temaFondo = TemasDisponibles.fondoPersonalizado;
    final estaDesbloqueado = AppConfig.todoDesbloqueado ||
        temaFondo.estaDesbloqueado(diasRacha, logros);

    final tieneFondoActivo = ajustes.temaId == 'fondo_personalizado' &&
        ajustes.fondoPersonalizadoPath != null &&
        File(ajustes.fondoPersonalizadoPath!).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tieneFondoActivo
              ? const Color(0xFF8B5CF6)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: tieneFondoActivo ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (tieneFondoActivo ? const Color(0xFF8B5CF6) : Colors.black)
                .withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera con badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wallpaper_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Fondo Personalizado',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'GIF / FOTO',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tieneFondoActivo
                          ? 'Fondo activo con difuminado dinámico'
                          : 'Sube tu propio GIF animado, foto o imagen (máx 10 MB)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // SI ESTÁ BLOQUEADO POR RACHA
          if (!estaDesbloqueado) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Se desbloquea al alcanzar ${temaFondo.diasRequeridos} días de racha activa (llevas $diasRacha días).',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFF97316) : const Color(0xFFC2410C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // SI ESTÁ DESBLOQUEADO: Botones de subida, vista previa y restaurar
            if (tieneFondoActivo) ...[
              // Preview thumbnail del fondo actual
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: Image.file(
                    File(ajustes.fondoPersonalizadoPath!),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _mostrarOpcionesDeOrigen(context, ref),
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(
                      tieneFondoActivo ? 'Cambiar fondo' : 'Subir fondo (Archivos o Fotos)',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (tieneFondoActivo) ...[
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(ajustesProvider.notifier).restaurarTemaPorDefecto();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tema por defecto restaurado con éxito.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Restaurar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Nota informativa sobre el límite de 10 MB y optimización de batería
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Límite máx: 10 MB. Puedes subir desde la app Archivos o tu Galería de Fotos.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _mostrarOpcionesDeOrigen(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Seleccionar fondo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Elige desde dónde deseas cargar tu fondo (máx. 10 MB):',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_open_rounded, color: Color(0xFF8B5CF6)),
                ),
                title: const Text('Archivos del dispositivo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('GIFs, WebP o imágenes en Archivos / iCloud / Descargas', style: TextStyle(fontSize: 12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _seleccionarArchivo(context, ref, desdeGaleria: false);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF3B82F6)),
                ),
                title: const Text('Galería de Fotos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Fotos, imágenes o capturas de tu biblioteca', style: TextStyle(fontSize: 12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _seleccionarArchivo(context, ref, desdeGaleria: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarArchivo(
    BuildContext context,
    WidgetRef ref, {
    required bool desdeGaleria,
  }) async {
    try {
      final files = desdeGaleria
          ? await FilePicker.pickFiles(type: FileType.image)
          : await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['gif', 'webp', 'png', 'jpg', 'jpeg'],
            );

      if (files.isEmpty) return;

      final file = files.first;
      final tamanoBytes = file.lengthSync() ?? (await file.length()) ?? 0;
      const limiteBytes = 10 * 1024 * 1024; // 10 MB

      // VALIDACIÓN ESTRICTA DEL LÍMITE DE 10 MB ANTES DE PROCESAR
      if (tamanoBytes > limiteBytes) {
        final mb = (tamanoBytes / (1024 * 1024)).toStringAsFixed(1);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ El archivo seleccionado pesa $mb MB y supera el límite máximo permitido de 10 MB. Elige una imagen o GIF de menor tamaño.',
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      File? fileLocal;
      if (file.path != null && file.path!.isNotEmpty) {
        fileLocal = File(file.path!);
      } else {
        final bytes = await file.readAsBytes();
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(p.join(tempDir.path, file.name));
        await tempFile.writeAsBytes(bytes);
        fileLocal = tempFile;
      }

      if (!fileLocal.existsSync()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el archivo seleccionado.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // MOSTRAR VISTA PREVIA CON DIFUMINADO ANTES DE GUARDAR
      if (context.mounted) {
        await DialogoPreviewFondo.mostrar(
          context,
          archivo: fileLocal,
          tamanoBytes: tamanoBytes,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el selector: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
