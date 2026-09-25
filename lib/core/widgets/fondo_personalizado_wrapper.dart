import 'dart:io';
import 'dart:ui';
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
        // 1. Imagen / GIF / Video corto animado en bucle optimizado de fondo
        Image.file(
          file,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (ctx, err, stack) => const SizedBox.expand(),
        ),

        // 2. Capa de difuminado (Blur) y tinte adaptable para legibilidad en modo claro y oscuro
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              color: isDark
                  ? const Color(0xFF0F172A).withOpacity(0.72)
                  : Colors.white.withOpacity(0.78),
            ),
          ),
        ),

        // 3. Contenido de la aplicación encima del fondo difuminado
        child,
      ],
    );
  }
}
