import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/error/failure.dart';
import 'package:mi_pendiente/core/utils/date_time_utils.dart';
import 'package:mi_pendiente/core/widgets/empty_state_widget.dart';
import 'package:mi_pendiente/core/widgets/estado_error.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/pendientes_provider.dart';

class CompletadosScreen extends ConsumerWidget {
  const CompletadosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCompletados = ref.watch(pendientesCompletadosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return asyncCompletados.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EstadoError(
        mensaje: e is Failure ? e.mensaje : 'Algo salió mal al cargar las tareas completadas',
        onReintentar: () => ref.invalidate(pendientesProvider),
      ),
      data: (completados) {
        // Agrupar por: Hoy, Ayer, Esta semana / Anteriores
        final hoyTasks = completados.where((p) {
          final d = p.fechaCompletado ?? p.fecha;
          return DateTimeUtils.isToday(d);
        }).toList();

        final ayerTasks = completados.where((p) {
          final d = p.fechaCompletado ?? p.fecha;
          return DateTimeUtils.isYesterday(d);
        }).toList();

        final anterioresTasks = completados.where((p) {
          final d = p.fechaCompletado ?? p.fecha;
          return !DateTimeUtils.isToday(d) && !DateTimeUtils.isYesterday(d);
        }).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // Tarjeta de felicitación y métrica semanal
            _buildWeeklyBadgeCard(context, isDark, completados.length),
            const SizedBox(height: 20),
            if (completados.isEmpty) ...[
              const SizedBox(height: 10),
              const EmptyStateWidget(
                icono: Icons.checklist_rounded,
                titulo: 'Sin tareas completadas aún',
                mensaje: 'Completa tus pendientes diarios para verlos registrados aquí y sumar progreso en tu racha.',
              ),
            ] else ...[
              // Tarjeta de felicitación y métrica semanal
              _buildWeeklyBadgeCard(context, isDark, completados.length),
              const SizedBox(height: 20),

              // Grupo: Hoy
              if (hoyTasks.isNotEmpty) ...[
                _buildSectionHeader(context, 'Hoy', isDark),
                _buildGroupCard(isDark, hoyTasks, ref),
                const SizedBox(height: 16),
              ],

              // Grupo: Ayer
              if (ayerTasks.isNotEmpty) ...[
                _buildSectionHeader(context, 'Ayer', isDark),
                _buildGroupCard(isDark, ayerTasks, ref),
                const SizedBox(height: 16),
              ],

              // Grupo: Esta semana / Anteriores
              if (anterioresTasks.isNotEmpty) ...[
                _buildSectionHeader(context, 'Esta semana', isDark),
                _buildGroupCard(isDark, anterioresTasks, ref),
                const SizedBox(height: 16),
              ],
            ],

            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildWeeklyBadgeCard(BuildContext context, bool isDark, int count) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEDF2F7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono circular con gráfico ascendente
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isDark ? primaryColor.withValues(alpha: 0.2) : const Color(0xFFE2EDFE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),

          // Texto
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta semana completaste',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count ${count == 1 ? "pendiente" : "pendientes"}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    final primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : primaryColor,
        ),
      ),
    );
  }

  Widget _buildGroupCard(bool isDark, List<Pendiente> tasks, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEDF2F7),
          width: 1.2,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9)),
        itemBuilder: (context, index) {
          final task = tasks[index];
          final primaryColor = Theme.of(context).primaryColor;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Check verde de completado
                const Icon(
                  Icons.check_circle,
                  color: AppColors.priorityBaja,
                  size: 22,
                ),
                const SizedBox(width: 12),

                // Hora o Día + Hora
                SizedBox(
                  width: 50,
                  child: Text(
                    DateTimeUtils.formatTime(task.hora),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Título
                Expanded(
                  child: Text(
                    task.titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Botón Restaurar
                InkWell(
                  onTap: () {
                    ref.read(pendientesProvider.notifier).restaurarCompletado(task.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${task.titulo}" restaurado a pendientes'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: primaryColor,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 16, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Restaurar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
