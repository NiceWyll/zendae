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

/// Sección de personalización de fondo animado EXCLUSIVA para Android.
/// En iOS no se muestra en lo absoluto.
class SeccionFondoPersonalizado extends ConsumerWidget {
  const SeccionFondoPersonalizado({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Verificación estricta de plataforma: EXCLUSIVO PARA ANDROID
    final esAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (!esAndroid) {
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
          // Cabecera con badge Exclusivo Android
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
                child: const Icon(Icons.movie_filter_rounded, color: Colors.white, size: 20),
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
                            'Fondo Animado Personalizado',
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
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ANDROID',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tieneFondoActivo
                          ? 'Fondo animado en bucle activo con difuminado'
                          : 'Sube tu propio GIF o video corto en bucle (máx 10 MB)',
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
                    onPressed: () => _seleccionarArchivo(context, ref),
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(
                      tieneFondoActivo ? 'Cambiar fondo' : 'Subir fondo animado',
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
                    child: const Text('Restaurar defecto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
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
                    'Límite máx: 10 MB. Se valida antes de cargar para proteger tu memoria y batería.',
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

  Future<void> _seleccionarArchivo(BuildContext context, WidgetRef ref) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gif', 'webp', 'mp4', 'png', 'jpg', 'jpeg'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      final tamanoBytes = await file.length() ?? file.lengthSync() ?? 0;
      const limiteBytes = 10 * 1024 * 1024; // 10 MB

      // VALIDACIÓN ESTRICTA DEL LÍMITE DE 10 MB ANTES DE PROCESAR
      if (tamanoBytes > limiteBytes) {
        final mb = (tamanoBytes / (1024 * 1024)).toStringAsFixed(1);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ El archivo seleccionado pesa $mb MB y supera el límite máximo permitido de 10 MB. Elige un GIF o video más corto para no agotar tu batería.',
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
      if (file.path != null) {
        fileLocal = File(file.path!);
      } else {
        final bytes = await file.readAsBytes();
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(p.join(tempDir.path, file.name));
        await tempFile.writeAsBytes(bytes);
        fileLocal = tempFile;
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
          ),
        );
      }
    }
  }
}
