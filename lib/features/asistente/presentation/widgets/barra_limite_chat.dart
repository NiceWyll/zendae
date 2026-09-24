import 'package:flutter/material.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import '../../domain/entities/limite_chat.dart';

class BarraLimiteChat extends StatelessWidget {
  final LimiteChat limite;

  const BarraLimiteChat({
    super.key,
    required this.limite,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final restantes = limite.restantes;
    final porcentaje = limite.mensajesUsadosHoy / limite.mensajesMaximosPorDia;

    final themeColor = isDark
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).primaryColor;

    final colorEstado = restantes <= 3
        ? AppColors.priorityAlta
        : (restantes <= 7 ? const Color(0xFFF59E0B) : themeColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? (Theme.of(context).cardTheme.color ?? AppColors.cardDark) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 18,
            color: colorEstado,
          ),
          const SizedBox(width: 8),
          Text(
            'Cupo diario: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF64748B),
            ),
          ),
          Text(
            '$restantes / ${limite.mensajesMaximosPorDia} disponibles',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorEstado,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 70,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (1.0 - porcentaje).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(colorEstado),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
