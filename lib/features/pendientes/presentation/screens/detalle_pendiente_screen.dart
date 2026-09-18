import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/utils/date_time_utils.dart';
import 'package:mi_pendiente/core/widgets/priority_badge.dart';
import 'package:mi_pendiente/core/widgets/wave_background.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/pendientes_provider.dart';
import 'nuevo_pendiente_screen.dart';

class DetallePendienteScreen extends ConsumerWidget {
  final String pendienteId;

  const DetallePendienteScreen({super.key, required this.pendienteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendientesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pendiente = state.pendientes.where((p) => p.id == pendienteId).firstOrNull;
    if (pendiente == null) {
      if (state.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return const Scaffold(body: Center(child: Text('Pendiente no encontrado')));
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Detalle',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Ondas inferiores decorativas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: WaveBackground(
              height: 120,
              isDark: isDark,
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta principal con la información del pendiente
                Container(
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
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado con icono y título
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBgLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              pendiente.titulo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Fila: Fecha
                      _buildInfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Fecha',
                        value: DateTimeUtils.formatFullDate(pendiente.fecha),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),

                      // Fila: Hora
                      _buildInfoRow(
                        icon: Icons.access_time_rounded,
                        label: 'Hora',
                        value: '${DateTimeUtils.formatTime(pendiente.hora)} hs',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),

                      // Fila: Prioridad
                      Row(
                        children: [
                          const Icon(Icons.outlined_flag_rounded, size: 20, color: AppColors.primary),
                          const SizedBox(width: 14),
                          Text(
                            'Prioridad',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          PriorityBadge(
                            prioridad: pendiente.prioridad,
                            asPill: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Fila: Recordatorio
                      _buildInfoRow(
                        icon: Icons.notifications_none_rounded,
                        label: 'Recordatorio',
                        value: pendiente.tieneRecordatorio
                            ? '${pendiente.minutosAntes} minutos antes'
                            : 'Sin recordatorio',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 18),

                      // Fila: Descripción
                      if (pendiente.descripcion != null && pendiente.descripcion!.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Descripción',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pendiente.descripcion!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sección Acciones
                const Text(
                  'Acciones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),

                // Lista de acciones
                _buildActionItem(
                  icon: Icons.check_circle_outline_rounded,
                  label: pendiente.estaCompletado ? 'Marcar como pendiente' : 'Completar',
                  isDark: isDark,
                  onTap: () {
                    ref
                        .read(pendientesProvider.notifier)
                        .alternarCompletado(pendiente.id, !pendiente.estaCompletado);
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 10),

                _buildActionItem(
                  icon: Icons.edit_outlined,
                  label: 'Editar',
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NuevoPendienteScreen(pendienteAEditar: pendiente),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                _buildActionItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Cambiar fecha',
                  isDark: isDark,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: pendiente.fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      final updated = pendiente.copyWith(fecha: picked);
                      await ref.read(pendientesProvider.notifier).actualizarPendiente(updated);
                    }
                  },
                ),
                const SizedBox(height: 10),

                _buildActionItem(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Pasar para mañana',
                  isDark: isDark,
                  onTap: () async {
                    await ref.read(pendientesProvider.notifier).posponerParaManana(pendiente.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pendiente postergado para mañana con éxito'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                ),
                const SizedBox(height: 10),

                _buildActionItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Eliminar',
                  isDestructive: true,
                  isDark: isDark,
                  onTap: () => _confirmarEliminacion(context, ref, pendiente.id),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.priorityAlta : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEDF2F7),
          width: 1.2,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Icon(icon, color: color, size: 22),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
        ),
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar pendiente?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.priorityAlta),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Cierra dialog
              await ref.read(pendientesProvider.notifier).eliminarPendiente(id);
              if (context.mounted) Navigator.of(context).pop(); // Regresa a pantalla anterior
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
