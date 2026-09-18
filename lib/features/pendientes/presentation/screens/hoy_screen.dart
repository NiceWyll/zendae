import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/error/failure.dart';
import 'package:mi_pendiente/core/utils/date_time_utils.dart';
import 'package:mi_pendiente/core/widgets/empty_state_widget.dart';
import 'package:mi_pendiente/core/widgets/estado_error.dart';
import 'package:mi_pendiente/core/widgets/task_card.dart';
import '../providers/pendientes_provider.dart';
import 'detalle_pendiente_screen.dart';
import 'nuevo_pendiente_screen.dart';

class HoyScreen extends ConsumerWidget {
  const HoyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHoy = ref.watch(pendientesDeHoyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fecha actual
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                DateTimeUtils.formatFullDate(now),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Lista de pendientes de hoy
        Expanded(
          child: asyncHoy.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EstadoError(
              mensaje: e is Failure ? e.mensaje : 'Algo salió mal al cargar los pendientes',
              onReintentar: () => ref.invalidate(pendientesProvider),
            ),
            data: (hoyList) => hoyList.isEmpty
                ? EmptyStateWidget(
                    icono: Icons.task_alt_rounded,
                    titulo: '¡Todo al día por hoy!',
                    mensaje: 'No tienes tareas pendientes para hoy. Disfruta tu día o agrega una nueva tarea.',
                    textoBoton: 'Nuevo pendiente',
                    alPresionarBoton: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NuevoPendienteScreen()),
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    itemCount: hoyList.length,
                    itemBuilder: (context, index) {
                      final task = hoyList[index];
                      return TaskCard(
                        pendiente: task,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetallePendienteScreen(pendienteId: task.id),
                            ),
                          );
                        },
                        onToggleComplete: (val) {
                          ref
                              .read(pendientesProvider.notifier)
                              .alternarCompletado(task.id, val);
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
