import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/ajustes/presentation/providers/ajustes_provider.dart';

/// Wrapper de pantalla completa para fondo personalizado con difuminado/blur.
/// Soporta Android e iOS con aceleración por hardware y mínimo consumo.
class FondoPersonalizadoWrapper extends ConsumerWidget {
  final Widget child;

  const FondoPersonalizadoWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) {
      return child;
    }

    final ajustes = ref.watch(ajustesProvider);
    final temaActivo = ajustes.temaId;
    final path = ajustes.fondoPersonalizadoPath;

    // Solo se activa si el tema actual es fondo_personalizado y el archivo existe
    if (temaActivo != 'fondo_personalizado' || path == null || path.isEmpty) {
      return child;
    }

    final file = File(path);
    if (!file.existsSync()) {
      return child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Imagen / GIF animado nítido (SIN difuminar / sin blur)
        Image.file(
          file,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (ctx, err, stack) => const SizedBox.expand(),
        ),

        // 2. Capa de contraste y tinte adaptativo:
        // Mantiene la foto 100% nítida y visible, pero con un tinte calibrado
        // para que textos blancos o negros nunca se pierdan sobre fotos claras u oscuras.
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF070B14).withOpacity(0.58),
                      const Color(0xFF0B0F19).withOpacity(0.42),
                      const Color(0xFF070B14).withOpacity(0.62),
                    ]
                  : [
                      Colors.white.withOpacity(0.70),
                      Colors.white.withOpacity(0.55),
                      Colors.white.withOpacity(0.72),
                    ],
            ),
          ),
        ),

        // 3. Contenido de la aplicación encima del fondo nítido
        child,
      ],
    );
  }
}
