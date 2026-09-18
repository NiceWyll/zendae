import 'package:flutter/material.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import '../constants/app_colors.dart';
import '../utils/date_time_utils.dart';
import 'priority_badge.dart';

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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEDF2F7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              // Hora
              SizedBox(
                width: 52,
                child: Text(
                  DateTimeUtils.formatTime(pendiente.hora),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? AppColors.textMuted
                        : AppColors.primary,
                  ),
                ),
              ),

              // Separador vertical sutil
              Container(
                width: 1.5,
                height: 36,
                color: isCompleted
                    ? AppColors.textMuted.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.4),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),

              // Contenido central (Título y Prioridad)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pendiente.titulo,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? AppColors.textMuted
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    PriorityBadge(
                      prioridad: pendiente.prioridad,
                      asPill: false,
                    ),
                  ],
                ),
              ),

              // Checkbox estilizado
              InkWell(
                onTap: () => onToggleComplete(!isCompleted),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.primary
                          : const Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
