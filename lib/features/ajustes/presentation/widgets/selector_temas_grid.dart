import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/theme/tema_app.dart';
import 'package:mi_pendiente/features/racha/presentation/providers/racha_provider.dart';
import '../providers/ajustes_provider.dart';

class SelectorTemasGrid extends ConsumerWidget {
  const SelectorTemasGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ajustes = ref.watch(ajustesProvider);
    final rachaAsync = ref.watch(rachaNotifierProvider);
    final racha = rachaAsync.valueOrNull;

    final diasRacha = racha?.diasActuales ?? 0;
    final logros = racha?.logrosDesbloqueados ?? const <String>[];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final esAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final temas = TemasDisponibles.todosParaPlataforma(esAndroid: esAndroid);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: temas.length,
      itemBuilder: (context, index) {
        final tema = temas[index];
        final esActivo = ajustes.temaId == tema.id;
        final estaDesbloqueado = tema.estaDesbloqueado(diasRacha, logros);

        return _buildTarjetaTema(
          context: context,
          ref: ref,
          tema: tema,
          esActivo: esActivo,
          estaDesbloqueado: estaDesbloqueado,
          diasRacha: diasRacha,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildTarjetaTema({
    required BuildContext context,
    required WidgetRef ref,
    required TemaApp tema,
    required bool esActivo,
    required bool estaDesbloqueado,
    required int diasRacha,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (estaDesbloqueado) {
            ref.read(ajustesProvider.notifier).cambiarTema(tema.id);
          } else {
            _mostrarDialogoBloqueo(context, tema, diasRacha);
          }
        },
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: esActivo
                  ? tema.colorPrimario
                  : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
              width: esActivo ? 2.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: esActivo
                    ? tema.colorPrimario.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: esActivo ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Swatch de colores
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: tema.colorPrimario,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tema.colorPrimario.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: tema.colorSecundario,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Spacer(),
                  if (esActivo)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: tema.colorPrimario,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    )
                  else if (!estaDesbloqueado)
                    const Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 18),
                ],
              ),
              const Spacer(),

              // Título del tema
              Text(
                tema.nombre,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),

              // Descripción o requisito
              if (estaDesbloqueado)
                Text(
                  esActivo ? 'En uso actual' : 'Toca para aplicar',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: esActivo ? FontWeight.w700 : FontWeight.w500,
                    color: esActivo
                        ? tema.colorPrimario
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                )
              else
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, size: 13, color: Color(0xFFEA580C)),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'Racha: ${tema.diasRequeridos} días',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEA580C),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoBloqueo(BuildContext context, TemaApp tema, int diasRacha) {
    final faltan = (tema.diasRequeridos ?? 0) - diasRacha;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          title: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tema.colorPrimario,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tema.nombre,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFF97316).withValues(alpha: 0.15)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFF97316).withValues(alpha: 0.3)
                        : const Color(0xFFFFEDD5),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Desbloquea este tema al alcanzar ${tema.diasRequeridos} días de racha activa.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFFB923C)
                              : const Color(0xFFC2410C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${tema.descripcion}.\n\n'
                'Llevas $diasRacha de ${tema.diasRequeridos} días (${faltan > 0 ? 'te faltan $faltan días' : '¡casi listo!'}).\n'
                '¡Completa una tarea hoy para mantener tu racha activa y sumar progreso!',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido 💪', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }
}
