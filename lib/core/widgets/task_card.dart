import 'package:flutter/material.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/constants/app_typography.dart';
import 'package:mi_pendiente/core/utils/date_time_utils.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/presentation/mappers/prioridad_ui.dart';
import 'priority_badge.dart';

/// Tarjeta de pendiente moderna con acento cromático de prioridad,
/// micro-animación en el checkbox y transición Hero fluida.
class TaskCard extends StatelessWidget {
  final Pendiente pendiente;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleComplete;

  const TaskCard({
    super.key,
    required this.pendiente,
    required this.onTap,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = pendiente.estaCompletado;
    final priorityColor = pendiente.prioridad.color;
    final primaryColor = Theme.of(context).primaryColor;

    return Hero(
      tag: 'task_card_${pendiente.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCompleted
                  ? (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))
                  : (isDark ? AppColors.borderDark : const Color(0xFFEDF2F7)),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barra indicadora de prioridad lateral
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.textMuted.withValues(alpha: 0.4)
                          : priorityColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                    ),
                  ),

                  // Contenido interactivo de la tarjeta
                  Expanded(
                    child: InkWell(
                      onTap: onTap,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                        child: Row(
                          children: [
                            // Chip de hora estilizado
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? (isDark
                                        ? const Color(0xFF334155).withValues(alpha: 0.3)
                                        : const Color(0xFFF1F5F9))
                                    : primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: isCompleted
                                        ? AppColors.textMuted
                                        : primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateTimeUtils.formatTime(pendiente.hora),
                                    style: AppTypography.timeLabel.copyWith(
                                      fontSize: 12.5,
                                      color: isCompleted
                                          ? AppColors.textMuted
                                          : primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Título y Prioridad
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    pendiente.titulo,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isCompleted
                                          ? AppColors.textMuted
                                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      decorationColor: AppColors.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  PriorityBadge(
                                    prioridad: pendiente.prioridad,
                                    asPill: false,
                                  ),
                                ],
                              ),
                            ),

                            // Checkbox con micro-animación
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => onToggleComplete(!isCompleted),
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isCompleted ? primaryColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCompleted
                                        ? primaryColor
                                        : (isDark
                                            ? const Color(0xFF475569)
                                            : const Color(0xFFCBD5E1)),
                                    width: 2,
                                  ),
                                  boxShadow: isCompleted
                                      ? [
                                          BoxShadow(
                                            color: primaryColor.withValues(alpha: 0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: AnimatedScale(
                                    scale: isCompleted ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutBack,
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 17,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
