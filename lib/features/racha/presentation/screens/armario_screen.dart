import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import '../../domain/entities/prenda_personaje.dart';
import '../providers/personaje_provider.dart';
import '../providers/racha_provider.dart';
import '../widgets/zendy_personaje_widget.dart';

class ArmarioScreen extends ConsumerWidget {
  const ArmarioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final personaje = ref.watch(personajeProvider);
    final rachaAsync = ref.watch(rachaNotifierProvider);
    final racha = rachaAsync.valueOrNull;
    final diasRacha = racha?.diasActuales ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Vestidor de Zendy 👔',
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
          // ESCENARIO PRINCIPAL: Personaje animado con su prenda actual
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Personaje en tamaño grande con movimiento continuo
                ZendyPersonajeWidget(
                  size: 150,
                  prendaId: personaje.prendaEquipadaId,
                  animado: true,
                ),
                const SizedBox(height: 16),

                // Nombre de la prenda actual
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      personaje.prendaEquipada != null
                          ? '${personaje.prendaEquipada!.iconoEmoji} ${personaje.prendaEquipada!.nombre}'
                          : '⏰ Zendy al Natural',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  personaje.prendaEquipada != null
                      ? personaje.prendaEquipada!.descripcion
                      : 'Sin accesorios equipados por el momento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),

                if (personaje.prendaEquipadaId != 'ninguno') ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(personajeProvider.notifier).desequiparPrenda();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Accesorios retirados. Zendy está al natural.'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    label: const Text('Quitar accesorio'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // TARJETA DE REGLAS DE LA RACHA Y COMODÍN DE PROTECCIÓN
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: personaje.tieneOportunidadDisponible
                    ? const Color(0xFF10B981).withOpacity(0.4)
                    : const Color(0xFFF97316).withOpacity(0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: personaje.tieneOportunidadDisponible
                        ? const Color(0xFF10B981).withOpacity(0.15)
                        : const Color(0xFFF97316).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      personaje.tieneOportunidadDisponible ? '🛡️' : '⚠️',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personaje.tieneOportunidadDisponible
                            ? 'Oportunidad de Protección: ACTIVA'
                            : 'Oportunidad de Protección: USADA',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: personaje.tieneOportunidadDisponible
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF97316),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        personaje.tieneOportunidadDisponible
                            ? 'Si rompes la racha por primera vez, NO perderás tu ropa desbloqueada. ¡Tienes 1 oportunidad!'
                            : 'Ya usaste tu oportunidad. Si se vuelve a romper la racha, perderás las prendas acumuladas.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // TÍTULO DEL CATÁLOGO DE PRENDAS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Armario de Accesorios',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                'Racha: $diasRacha ${diasRacha == 1 ? 'día' : 'días'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // LISTA DE PRENDAS (DESBLOQUEADAS Y BLOQUEADAS)
          ...CatalogoPrendas.todas.map((prenda) {
            final estaDesbloqueada = prenda.estaDesbloqueada(
              diasRacha,
              personaje.prendasDesbloqueadasIds,
            );
            final esEquipada = personaje.prendaEquipadaId == prenda.id;

            return _buildItemPrenda(
              context: context,
              ref: ref,
              prenda: prenda,
              estaDesbloqueada: estaDesbloqueada,
              esEquipada: esEquipada,
              diasRacha: diasRacha,
              isDark: isDark,
            );
          }),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildItemPrenda({
    required BuildContext context,
    required WidgetRef ref,
    required PrendaPersonaje prenda,
    required bool estaDesbloqueada,
    required bool esEquipada,
    required int diasRacha,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esEquipada
              ? AppColors.primary
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: esEquipada ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono avatar de la prenda
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: estaDesbloqueada
                  ? prenda.colorPrimario.withOpacity(0.15)
                  : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                estaDesbloqueada ? prenda.iconoEmoji : '🔒',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Nombre y descripción
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      prenda.nombre,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: estaDesbloqueada
                            ? (isDark ? Colors.white : AppColors.textPrimary)
                            : (isDark ? Colors.white38 : AppColors.textSecondary),
                      ),
                    ),
                    if (esEquipada) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PUESTO',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  prenda.descripcion,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  estaDesbloqueada
                      ? 'Desbloqueado con ${prenda.diasRequeridos} días de racha'
                      : 'Se desbloquea a los ${prenda.diasRequeridos} días de racha (llevas $diasRacha)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: estaDesbloqueada
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Botón de acción
          if (estaDesbloqueada)
            ElevatedButton(
              onPressed: () {
                if (esEquipada) {
                  ref.read(personajeProvider.notifier).desequiparPrenda();
                } else {
                  ref.read(personajeProvider.notifier).equiparPrenda(prenda.id);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: esEquipada
                    ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                    : AppColors.primary,
                foregroundColor: esEquipada
                    ? (isDark ? Colors.white70 : AppColors.textPrimary)
                    : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: esEquipada ? 0 : 2,
              ),
              child: Text(
                esEquipada ? 'Quitar' : 'Poner',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            )
          else
            const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
        ],
      ),
    );
  }
}
