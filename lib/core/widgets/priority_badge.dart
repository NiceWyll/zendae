import 'package:flutter/material.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/prioridad.dart';
import 'package:mi_pendiente/features/pendientes/presentation/mappers/prioridad_ui.dart';

class PriorityBadge extends StatelessWidget {
  final Prioridad prioridad;
  final bool asPill;

  const PriorityBadge({
    super.key,
    required this.prioridad,
    this.asPill = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (asPill) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? prioridad.color.withValues(alpha: 0.2)
              : prioridad.bgColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark
              ? Border.all(
                  color: prioridad.color.withValues(alpha: 0.45),
                  width: 1,
                )
              : null,
        ),
        child: Text(
          prioridad.label,
          style: TextStyle(
            color: isDark ? prioridad.color : prioridad.color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: prioridad.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          prioridad.label,
          style: TextStyle(
            color: prioridad.color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
