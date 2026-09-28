import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import '../../domain/entities/prenda_personaje.dart';
import '../providers/personaje_provider.dart';
import '../providers/racha_provider.dart';
import '../widgets/zendy_personaje_widget.dart';

enum FiltroArmario { todos, ropa, cabeza, cuello, otros }

class ArmarioScreen extends ConsumerStatefulWidget {
  const ArmarioScreen({super.key});

  @override
  ConsumerState<ArmarioScreen> createState() => _ArmarioScreenState();
}

class _ArmarioScreenState extends ConsumerState<ArmarioScreen> {
  FiltroArmario _filtro = FiltroArmario.todos;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final personaje = ref.watch(personajeProvider);
    final rachaAsync = ref.watch(rachaNotifierProvider);
    final racha = rachaAsync.valueOrNull;
    final diasRacha = racha?.diasActuales ?? 0;
    final accentColor = isDark ? const Color(0xFF8B5CF6) : AppColors.primary;

    // Filtrar prendas según categoría
    final prendasFiltradas = CatalogoPrendas.todas.where((p) {
      switch (_filtro) {
        case FiltroArmario.todos:
          return true;
        case FiltroArmario.ropa:
          return p.categoria == CategoriaPrenda.ropa;
        case FiltroArmario.cabeza:
          return p.categoria == CategoriaPrenda.cabeza;
        case FiltroArmario.cuello:
          return p.categoria == CategoriaPrenda.cuello;
        case FiltroArmario.otros:
          return p.categoria == CategoriaPrenda.ojos ||
              p.categoria == CategoriaPrenda.espalda ||
              p.categoria == CategoriaPrenda.especial;
      }
    }).toList();

    final totalDesbloqueadas = CatalogoPrendas.todas.where((p) {
      return p.estaDesbloqueada(diasRacha, personaje.prendasDesbloqueadasIds);
    }).length;

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
          // ESCENARIO PRINCIPAL AMPLIO: Personaje en tamaño grande con podio interactivo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF8B5CF6) : Colors.black)
                      .withOpacity(isDark ? 0.2 : 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Resplandor de fondo y pedestal del personaje
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Halo de luz circular
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (isDark ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6))
                                .withOpacity(isDark ? 0.35 : 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Pedestal elíptico en la base
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: 140,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF090D16).withOpacity(0.6)
                              : Colors.black.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    // Zendy en tamaño grande (170 px)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ZendyPersonajeWidget(
                        size: 170,
                        prendaId: personaje.prendaEquipadaId,
                        animado: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Etiqueta y Nombre del Atuendo Actual
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      personaje.prendaEquipada != null
                          ? '${personaje.prendaEquipada!.iconoEmoji} ${personaje.prendaEquipada!.nombre}'
                          : '⏰ Zendy al Natural',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  personaje.prendaEquipada != null
                      ? personaje.prendaEquipada!.descripcion
                      : 'Sin ropa ni accesorios equipados. ¡Elige un traje o accesorio abajo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 12),

                // Contador de progreso del vestidor
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.checkroom_rounded, size: 15, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      Text(
                        'Desbloqueados: $totalDesbloqueadas de ${CatalogoPrendas.todas.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),

                if (personaje.prendaEquipadaId != 'ninguno') ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(personajeProvider.notifier).desequiparPrenda();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Atuendo retirado. Zendy está al natural.'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
                    label: const Text('Quitar atuendo actual'),
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
                            ? 'Si rompes la racha por primera vez, NO perderás tu ropa. ¡Tienes 1 oportunidad!'
                            : 'Ya usaste tu oportunidad. Si se vuelve a romper la racha, perderás las prendas acumuladas.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
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

          // TÍTULO DEL CATÁLOGO Y CHIP DE RACHA CON ALTO CONTRASTE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Colección de Ropa y Accesorios',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              // Chip de racha brillante que nunca se pierde en modo oscuro
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.6 : 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$diasRacha ${diasRacha == 1 ? 'día' : 'días'} de racha',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // SELECTOR DE PESTAÑAS / FILTRO DE CATEGORÍAS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFiltroChip('✨ Todos', FiltroArmario.todos, isDark),
                const SizedBox(width: 8),
                _buildFiltroChip('🤵 Ropa & Trajes', FiltroArmario.ropa, isDark),
                const SizedBox(width: 8),
                _buildFiltroChip('🧢 Cabeza', FiltroArmario.cabeza, isDark),
                const SizedBox(width: 8),
                _buildFiltroChip('🧣 Cuello', FiltroArmario.cuello, isDark),
                const SizedBox(width: 8),
                _buildFiltroChip('🕶️ Accesorios', FiltroArmario.otros, isDark),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // LISTA DE PRENDAS (DESBLOQUEADAS Y BLOQUEADAS)
          ...prendasFiltradas.map((prenda) {
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
              accentColor: accentColor,
            );
          }),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String label, FiltroArmario filtro, bool isDark) {
    final isSelected = _filtro == filtro;
    return GestureDetector(
      onTap: () => setState(() => _filtro = filtro),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF8B5CF6) : AppColors.primary)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
          ),
        ),
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
    required Color accentColor,
  }) {
    String tagCategoria = '';
    switch (prenda.categoria) {
      case CategoriaPrenda.ropa:
        tagCategoria = 'ROPA / TRAJE';
        break;
      case CategoriaPrenda.cabeza:
        tagCategoria = 'CABEZA';
        break;
      case CategoriaPrenda.cuello:
        tagCategoria = 'CUELLO';
        break;
      case CategoriaPrenda.ojos:
        tagCategoria = 'OJOS';
        break;
      case CategoriaPrenda.espalda:
        tagCategoria = 'ESPALDA';
        break;
      case CategoriaPrenda.especial:
        tagCategoria = 'ESPECIAL';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: esEquipada
              ? accentColor
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: esEquipada ? 2.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (esEquipada ? accentColor : Colors.black)
                .withOpacity(esEquipada ? 0.25 : (isDark ? 0.15 : 0.03)),
            blurRadius: esEquipada ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono avatar de la prenda
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: estaDesbloqueada
                  ? prenda.colorPrimario.withOpacity(isDark ? 0.25 : 0.15)
                  : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: estaDesbloqueada
                    ? prenda.colorPrimario.withOpacity(0.3)
                    : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(
                estaDesbloqueada ? prenda.iconoEmoji : '🔒',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Nombre, categoría y descripción
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        prenda.nombre,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: estaDesbloqueada
                              ? (isDark ? Colors.white : AppColors.textPrimary)
                              : (isDark ? Colors.white54 : AppColors.textSecondary),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: prenda.categoria == CategoriaPrenda.ropa
                            ? const Color(0xFF8B5CF6).withOpacity(0.18)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tagCategoria,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: prenda.categoria == CategoriaPrenda.ropa
                              ? const Color(0xFFA78BFA)
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    if (esEquipada) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PUESTO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  prenda.descripcion,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  estaDesbloqueada
                      ? (prenda.diasRequeridos == 1
                          ? '✨ Desbloqueado al día 1 de racha'
                          : 'Desbloqueado con ${prenda.diasRequeridos} días de racha')
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

          // Botón de acción con alto contraste
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
                    : accentColor,
                foregroundColor: esEquipada
                    ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
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
              Icons.lock_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
        ],
      ),
    );
  }
}
