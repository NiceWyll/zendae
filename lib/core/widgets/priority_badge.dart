import 'package:flutter/material.dart';
import '../../domain/entities/prioridad.dart';
import '../../presentation/mappers/prioridad_ui.dart';

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
    if (asPill) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: prioridad.bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          prioridad.label,
          style: TextStyle(
            color: prioridad.color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
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
