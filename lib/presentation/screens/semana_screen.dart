import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/priority_badge.dart';
import '../../domain/entities/pendiente.dart';
import '../providers/pendientes_provider.dart';
import 'detalle_pendiente_screen.dart';

class SemanaScreen extends ConsumerStatefulWidget {
  const SemanaScreen({super.key});

  @override
  ConsumerState<SemanaScreen> createState() => _SemanaScreenState();
}

class _SemanaScreenState extends ConsumerState<SemanaScreen> {
  final Map<int, bool> _expandedDays = {
    0: true,  // Lunes
    1: true,  // Martes
    2: false, // Miércoles
    3: true,  // Jueves
    4: false, // Viernes
    5: false, // Sábado
    6: false, // Domingo
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pendientesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final startOfWeek = DateTimeUtils.startOfWeek(now);

    // Calcular días de la semana
    final daysOfWeek = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    // Calcular métricas de la semana
    final weekTasks = state.pendientes.where((p) {
      final diff = p.fecha.difference(startOfWeek).inDays;
      return diff >= 0 && diff < 7;
    }).toList();

    final completedCount = weekTasks.where((p) => p.estaCompletado).length;
    final totalCount = weekTasks.length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Tarjeta resumen semanal con mini gráfico de barras
        _buildWeeklySummaryCard(isDark, totalCount, completedCount, progress, daysOfWeek, state.pendientes),
        const SizedBox(height: 16),

        // Lista de días de la semana (acordeones)
        ...List.generate(7, (index) {
          final dayDate = daysOfWeek[index];
          final dayTasks = state.pendientes.where((p) {
            return DateTimeUtils.isSameDay(p.fecha, dayDate);
          }).toList();

          final isExpanded = _expandedDays[index] ?? false;

          return _buildDayAccordion(
            index: index,
            date: dayDate,
            tasks: dayTasks,
            isExpanded: isExpanded,
            isDark: isDark,
            onToggle: () {
              setState(() {
                _expandedDays[index] = !isExpanded;
              });
            },
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildWeeklySummaryCard(
    bool isDark,
    int total,
    int completed,
    double progress,
    List<DateTime> daysOfWeek,
    List<Pendiente> allTasks,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Textos y Barra de progreso
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta semana',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                // Barra de progreso redondeada
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$total pendientes · $completed completados',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Mini gráfico de barras estilizado (7 barras para los 7 días)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final dayDate = daysOfWeek[i];
              final count = allTasks.where((p) => DateTimeUtils.isSameDay(p.fecha, dayDate)).length;
              final height = (count * 6.0 + 8.0).clamp(10.0, 38.0);
              final isToday = DateTimeUtils.isToday(dayDate);

              return Container(
                width: 4.5,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primary : const Color(0xFF93C5FD),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayAccordion({
    required int index,
    required DateTime date,
    required List<Pendiente> tasks,
    required bool isExpanded,
    required bool isDark,
    required VoidCallback onToggle,
  }) {
    final dayName = DateTimeUtils.getDayNameShort(date);
    final dayMonth = DateTimeUtils.formatShortDayMonth(date);
    final isToday = DateTimeUtils.isToday(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? AppColors.primary.withOpacity(0.5)
              : (isDark ? AppColors.borderDark : const Color(0xFFEDF2F7)),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // Header del acordeón
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Día y fecha
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? AppColors.primary
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        dayMonth,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Cantidad de pendientes
                  Text(
                    '${tasks.length} ${tasks.length == 1 ? "pendiente" : "pendientes"}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Flecha desplegable
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),

          // Tareas desplegadas
          if (isExpanded && tasks.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, tIndex) {
                final task = tasks[tIndex];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetallePendienteScreen(pendienteId: task.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        // Checkbox
                        InkWell(
                          onTap: () {
                            ref
                                .read(pendientesProvider.notifier)
                                .alternarCompletado(task.id, !task.estaCompletado);
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: task.estaCompletado ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: task.estaCompletado ? AppColors.primary : const Color(0xFF93C5FD),
                                width: 1.8,
                              ),
                            ),
                            child: task.estaCompletado
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Título y Prioridad
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.titulo,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: task.estaCompletado
                                      ? AppColors.textMuted
                                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                                  decoration: task.estaCompletado
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 3),
                              PriorityBadge(prioridad: task.prioridad, asPill: false),
                            ],
                          ),
                        ),

                        // Hora al extremo derecho
                        Text(
                          DateTimeUtils.formatTime(task.hora),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
