import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/error/failure.dart';
import 'package:mi_pendiente/core/utils/date_time_utils.dart';
import 'package:mi_pendiente/core/widgets/empty_state_widget.dart';
import 'package:mi_pendiente/core/widgets/estado_error.dart';
import 'package:mi_pendiente/core/widgets/task_card.dart';
import 'package:mi_pendiente/features/horario/domain/entities/clase.dart';
import 'package:mi_pendiente/features/horario/presentation/providers/horario_provider.dart';
import 'package:mi_pendiente/features/horario/presentation/screens/detalle_clase_screen.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/presentation/mappers/prioridad_ui.dart';
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

    return asyncHoy.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EstadoError(
        mensaje: e is Failure ? e.mensaje : 'Algo salió mal al cargar los pendientes',
        onReintentar: () => ref.invalidate(pendientesProvider),
      ),
      data: (hoyList) {
        final clasesHoy = ref.watch(clasesVigentesPorFechaProvider(now));

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Cabecera: Fecha actual y Resumen combinado de hoy
            SliverToBoxAdapter(
              child: Column(
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

                  // Resumen combinado: Próxima clase Y Próximo pendiente (Punto 7)
                  _buildResumenCombinado(context, isDark, now, clasesHoy, hoyList),

                  const SizedBox(height: 18),

                  // Título de la sección de lista
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pendientes de hoy',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                        if (hoyList.isNotEmpty)
                          Text(
                            '${hoyList.where((p) => !p.estaCompletado).length} restantes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Lista o Estado vacío
            if (hoyList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  icono: Icons.task_alt_rounded,
                  titulo: '¡Todo al día por hoy!',
                  mensaje: 'No tienes tareas pendientes para hoy. Disfruta tu día o agrega una nueva tarea.',
                  textoBoton: 'Nuevo pendiente',
                  alPresionarBoton: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NuevoPendienteScreen()),
                    );
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
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
                    childCount: hoyList.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        );
      },
    );
  }

  /// Construye el widget de resumen combinado de lo más urgente:
  /// Próxima clase Y próximo pendiente juntos en una sola vista.
  Widget _buildResumenCombinado(
    BuildContext context,
    bool isDark,
    DateTime now,
    List<Clase> clasesHoy,
    List<Pendiente> hoyList,
  ) {
    final ahoraMinutos = now.hour * 60 + now.minute;

    // 1. Determinar próxima clase o clase en curso
    Clase? proximaClase;
    bool esClaseEnCurso = false;

    // Buscar si hay clase en curso ahora mismo
    for (final c in clasesHoy) {
      final inicio = c.horaInicio * 60 + c.minutoInicio;
      final fin = c.horaFin * 60 + c.minutoFin;
      if (ahoraMinutos >= inicio && ahoraMinutos <= fin) {
        proximaClase = c;
        esClaseEnCurso = true;
        break;
      }
    }

    // Si no hay clase en curso, buscar la próxima que empiece después de ahora
    if (proximaClase == null) {
      for (final c in clasesHoy) {
        final inicio = c.horaInicio * 60 + c.minutoInicio;
        if (inicio > ahoraMinutos) {
          proximaClase = c;
          break;
        }
      }
    }

    final hayClasesTerminadas = clasesHoy.isNotEmpty && proximaClase == null;

    // 2. Determinar próximo pendiente incompleto
    final pendientesIncompletos = hoyList.where((p) => !p.estaCompletado).toList();
    final proximoPendiente = pendientesIncompletos.isNotEmpty ? pendientesIncompletos.first : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la tarjeta combinada
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LO MÁS URGENTE DE HOY',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // SECCIÓN 1: PRÓXIMA CLASE
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: proximaClase != null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetalleClaseScreen(clase: proximaClase!),
                        ),
                      );
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: proximaClase != null
                            ? Color(proximaClase.colorValue).withOpacity(0.15)
                            : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        size: 22,
                        color: proximaClase != null
                            ? Color(proximaClase.colorValue)
                            : (isDark ? Colors.white54 : Colors.black45),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                esClaseEnCurso
                                    ? 'EN CURSO'
                                    : (proximaClase != null
                                        ? 'PRÓXIMA CLASE'
                                        : (hayClasesTerminadas
                                            ? 'CLASES CONCLUIDAS'
                                            : 'SIN CLASES HOY')),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: esClaseEnCurso
                                      ? const Color(0xFF10B981)
                                      : (proximaClase != null
                                          ? AppColors.primary
                                          : AppColors.textSecondary),
                                ),
                              ),
                              if (esClaseEnCurso) ...[
                                const SizedBox(width: 5),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            proximaClase != null
                                ? proximaClase.nombre
                                : (hayClasesTerminadas
                                    ? 'Terminaste tus clases de hoy'
                                    : 'Sin clases programadas'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            proximaClase != null
                                ? '${proximaClase.horarioFormateado}${proximaClase.aula != null && proximaClase.aula!.isNotEmpty ? ' • ${proximaClase.aula}' : ''}'
                                : (hayClasesTerminadas
                                    ? '${clasesHoy.length} ${clasesHoy.length == 1 ? 'clase completada' : 'clases completadas'}'
                                    : 'Día libre de clases'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (proximaClase != null)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                height: 1,
                thickness: 0.6,
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),

            // SECCIÓN 2: PRÓXIMO PENDIENTE
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: proximoPendiente != null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetallePendienteScreen(pendienteId: proximoPendiente.id),
                        ),
                      );
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: proximoPendiente != null
                            ? proximoPendiente.prioridad.bgColor
                            : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        proximoPendiente != null
                            ? Icons.assignment_outlined
                            : Icons.check_circle_outline_rounded,
                        size: 22,
                        color: proximoPendiente != null
                            ? proximoPendiente.prioridad.color
                            : (isDark ? Colors.white54 : Colors.black45),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            proximoPendiente != null
                                ? 'PRÓXIMO PENDIENTE'
                                : (hoyList.isNotEmpty
                                    ? '¡TODO AL DÍA!'
                                    : 'SIN PENDIENTES'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: proximoPendiente != null
                                  ? proximoPendiente.prioridad.color
                                  : const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            proximoPendiente != null
                                ? proximoPendiente.titulo
                                : (hoyList.isNotEmpty
                                    ? 'Completaste todas tus tareas 🎉'
                                    : 'No tienes pendientes para hoy'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            proximoPendiente != null
                                ? '${proximoPendiente.hora.comoTexto} • Prioridad ${proximoPendiente.prioridad.label}'
                                : (hoyList.isNotEmpty
                                    ? '${hoyList.length} ${hoyList.length == 1 ? 'tarea realizada' : 'tareas realizadas'}'
                                    : 'Disfruta tu día o crea una tarea'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (proximoPendiente != null)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

