import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import '../../domain/entities/hito_racha.dart';
import '../../domain/entities/racha.dart';
import '../providers/racha_provider.dart';

class MisLogrosScreen extends ConsumerStatefulWidget {
  const MisLogrosScreen({super.key});

  @override
  ConsumerState<MisLogrosScreen> createState() => _MisLogrosScreenState();
}

class _MisLogrosScreenState extends ConsumerState<MisLogrosScreen> {
  RangoRacha _rangoSeleccionado = RangoRacha.bronce;
  final Set<RangoRacha> _rangosDesbloqueadosManualmente = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final rachaAsync = ref.watch(rachaNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Mis Logros y Racha 🔥',
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
      body: rachaAsync.when(
        data: (racha) => _buildContenido(context, racha, isDark, primaryColor),
        loading: () => Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudo cargar la racha'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(rachaNotifierProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContenido(BuildContext context, Racha racha, bool isDark, Color primaryColor) {
    final hitosDelRango = HitoRacha.values
        .where((h) => h.rango == _rangoSeleccionado)
        .toList();

    final rangoAlcanzado = _determinarRangoAlcanzado(racha.diasActuales);
    final estaRangoDesbloqueado = _rangoSeleccionado.diasMinimos <= racha.diasActuales ||
        _rangosDesbloqueadosManualmente.contains(_rangoSeleccionado);
    final puedeDesbloquearSiguiente = racha.diasActuales >= _rangoSeleccionado.diasMinimos &&
        !_rangosDesbloqueadosManualmente.contains(_rangoSeleccionado) &&
        _rangoSeleccionado != RangoRacha.bronce;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // Tarjeta principal de la Racha
        _buildHeroCard(racha, isDark, rangoAlcanzado),

        const SizedBox(height: 20),

        // Barra de progreso hacia el siguiente hito
        _buildProgresoSiguienteHito(racha, isDark, primaryColor),

        const SizedBox(height: 24),

        // Selector de Rangos (Niveles)
        _buildSelectorRangos(isDark, primaryColor, racha.diasActuales),

        const SizedBox(height: 16),

        // Banner informativo del rango seleccionado
        _buildBannerRango(
          racha,
          isDark,
          primaryColor,
          estaRangoDesbloqueado,
          puedeDesbloquearSiguiente,
        ),

        const SizedBox(height: 16),

        // Título de la sección
        Row(
          children: [
            Icon(Icons.military_tech_rounded, color: primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Recompensas: ${_rangoSeleccionado.nombre} ${_rangoSeleccionado.icono}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista de Hitos del Rango seleccionado
        ...hitosDelRango.map(
          (hito) => _buildHitoCard(hito, racha, isDark, estaRangoDesbloqueado, primaryColor),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  RangoRacha _determinarRangoAlcanzado(int dias) {
    if (dias >= 90) return RangoRacha.leyenda;
    if (dias >= 60) return RangoRacha.diamante;
    if (dias >= 30) return RangoRacha.oro;
    return RangoRacha.bronce;
  }

  Widget _buildHeroCard(Racha racha, bool isDark, RangoRacha rangoAlcanzado) {
    final tieneRacha = racha.diasActuales > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tieneRacha
              ? [const Color(0xFFFF5722), const Color(0xFFF57C00)]
              : (isDark
                  ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
                  : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (tieneRacha ? const Color(0xFFFF5722) : const Color(0xFF3B82F6))
                .withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                tieneRacha ? '🔥' : '🌱',
                style: const TextStyle(fontSize: 44),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${racha.diasActuales}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            racha.diasActuales == 1 ? 'DÍA DE RACHA ACTIVA' : 'DÍAS DE RACHA ACTIVA',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          // Badge de rango actual y récord
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(rangoAlcanzado.icono, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Text(
                      'Rango ${rangoAlcanzado.nombre}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Récord: ${racha.mejorRacha} ${racha.mejorRacha == 1 ? 'día' : 'días'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgresoSiguienteHito(Racha racha, bool isDark, Color primaryColor) {
    final proximo = racha.proximoHito;
    final progreso = racha.progresoHaciaProximoHito;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Próximo objetivo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Text(
                proximo != null
                    ? '${racha.diasActuales} / ${proximo.dias} días'
                    : '¡Todos alcanzados!',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 12,
              backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            proximo != null
                ? 'Faltan ${proximo.dias - racha.diasActuales} días para desbloquear: ${proximo.titulo}'
                : '¡Has conquistado todos los hitos de constancia! Eres una leyenda viviente.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorRangos(bool isDark, Color primaryColor, int diasActuales) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: RangoRacha.values.map((rango) {
          final isSelected = _rangoSeleccionado == rango;
          final desbloqueado = diasActuales >= rango.diasMinimos;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _rangoSeleccionado = rango;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF2C2C2C) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rango.icono,
                      style: TextStyle(
                        fontSize: 18,
                        color: desbloqueado ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rango.nombre,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.white : primaryColor)
                            : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBannerRango(
    Racha racha,
    bool isDark,
    Color primaryColor,
    bool estaRangoDesbloqueado,
    bool puedeDesbloquearSiguiente,
  ) {
    if (puedeDesbloquearSiguiente) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF59E0B)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(_rangoSeleccionado.icono, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Nivel ${_rangoSeleccionado.nombre} Disponible!',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Has alcanzado los ${_rangoSeleccionado.diasMinimos} días necesarios de racha.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _rangosDesbloqueadosManualmente.add(_rangoSeleccionado);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 ¡Nivel ${_rangoSeleccionado.nombre} desbloqueado con éxito!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
                label: Text(
                  'Desbloquear Nivel ${_rangoSeleccionado.nombre}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!estaRangoDesbloqueado) {
      final faltan = _rangoSeleccionado.diasMinimos - racha.diasActuales;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_clock_rounded, color: Color(0xFF94A3B8), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Alcanza ${_rangoSeleccionado.diasMinimos} días de racha para desbloquear el Nivel ${_rangoSeleccionado.nombre} (${faltan > 0 ? 'te faltan $faltan días' : 'listo para desbloquear'}).',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildHitoCard(
    HitoRacha hito,
    Racha racha,
    bool isDark,
    bool rangoDesbloqueado,
    Color primaryColor,
  ) {
    final desbloqueado = rangoDesbloqueado &&
        (racha.logrosDesbloqueados.contains(hito.name) || racha.diasActuales >= hito.dias);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: desbloqueado
              ? const Color(0xFFFFB74D)
              : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          width: desbloqueado ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono del hito
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: desbloqueado
                  ? const LinearGradient(
                      colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
                          : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
                    ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                desbloqueado ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
                color: desbloqueado ? Colors.white : const Color(0xFF94A3B8),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Título y Recompensa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        hito.titulo,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: desbloqueado
                            ? const Color(0xFFFFE082)
                            : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${hito.dias} días',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: desbloqueado
                              ? const Color(0xFF795548)
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hito.recompensa,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: desbloqueado
                        ? const Color(0xFFE65100)
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),

          // Badge de estado
          if (desbloqueado)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
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
