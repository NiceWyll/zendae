import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/error/failure.dart';
import 'package:mi_pendiente/core/utils/date_time_utils.dart';
import 'package:mi_pendiente/core/widgets/estado_error.dart';
import 'package:mi_pendiente/core/widgets/priority_badge.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/presentation/mappers/prioridad_ui.dart';
import '../providers/pendientes_provider.dart';
import 'detalle_pendiente_screen.dart';

class MesScreen extends ConsumerStatefulWidget {
  const MesScreen({super.key});

  @override
  ConsumerState<MesScreen> createState() => _MesScreenState();
}

class _MesScreenState extends ConsumerState<MesScreen> {
  DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final asyncPendientes = ref.watch(pendientesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final selectedDate = ref.watch(fechaSeleccionadaProvider);
    final tasksForSelectedDay = ref.watch(pendientesPorFechaProvider(selectedDate)).valueOrNull ?? [];

    return asyncPendientes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EstadoError(
        mensaje: e is Failure ? e.mensaje : 'Algo salió mal al cargar el calendario',
        onReintentar: () => ref.invalidate(pendientesProvider),
      ),
      data: (allTasks) => Column(
      children: [
        // Selector de mes (< Mes Año >)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: primaryColor, size: 28),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                  });
                },
              ),
              Text(
                DateTimeUtils.formatMonthYear(_currentMonth),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : primaryColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: primaryColor, size: 28),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                  });
                },
              ),
            ],
          ),
        ),

        // Días de la semana (LUN, MAR, ...)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeekdayLabel('LUN'),
              _WeekdayLabel('MAR'),
              _WeekdayLabel('MIÉ'),
              _WeekdayLabel('JUE'),
              _WeekdayLabel('VIE'),
              _WeekdayLabel('SÁB'),
              _WeekdayLabel('DOM'),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Matriz de días del mes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMonthGrid(isDark, selectedDate, allTasks),
        ),

        Divider(height: 24, thickness: 1, color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9)),

        // Título de la sección de tareas del día
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Pendientes del ${selectedDate.day} de ${_getMonthName(selectedDate.month)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : primaryColor,
              ),
            ),
          ),
        ),

        // Lista de tareas del día seleccionado
        Expanded(
          child: tasksForSelectedDay.isEmpty
              ? Center(
                  child: Text(
                    'No hay pendientes para este día',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: tasksForSelectedDay.length,
                  itemBuilder: (context, index) {
                    final task = tasksForSelectedDay[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : const Color(0xFFEDF2F7),
                          width: 1.2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetallePendienteScreen(pendienteId: task.id),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            // Dot de prioridad + Hora
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: task.prioridad.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateTimeUtils.formatTime(task.hora),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Título
                            Expanded(
                              child: Text(
                                task.titulo,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Badge píldora de prioridad (Alta, Media, Baja)
                            PriorityBadge(
                              prioridad: task.prioridad,
                              asPill: true,
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
    );
  }

  Widget _buildMonthGrid(bool isDark, DateTime selectedDate, List<Pendiente> allTasks) {
    final primaryColor = Theme.of(context).primaryColor;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    
    // Normalizar inicio en lunes (1 = Lun, 7 = Dom)
    final startingWeekday = firstDayOfMonth.weekday; // 1 to 7
    final prevMonthDays = DateTime(_currentMonth.year, _currentMonth.month, 0).day;

    final List<Widget> dayWidgets = [];

    // Pre-indexar tareas del mes actual por día para búsqueda O(1) instantánea
    final Map<int, List<Pendiente>> tasksByDay = {};
    for (final task in allTasks) {
      if (task.fecha.year == _currentMonth.year && task.fecha.month == _currentMonth.month) {
        tasksByDay.putIfAbsent(task.fecha.day, () => []).add(task);
      }
    }

    // Días del mes anterior
    for (int i = startingWeekday - 1; i > 0; i--) {
      final dayNumber = prevMonthDays - i + 1;
      dayWidgets.add(_buildInactiveDayCell(dayNumber, isDark));
    }

    // Días del mes actual
    for (int d = 1; d <= daysInMonth; d++) {
      final thisDate = DateTime(_currentMonth.year, _currentMonth.month, d);
      final isSelected = DateTimeUtils.isSameDay(thisDate, selectedDate);
      final isToday = DateTimeUtils.isToday(thisDate);

      // Búsqueda O(1) sin recorrer la lista completa
      final tasksOnThisDay = tasksByDay[d] ?? const <Pendiente>[];

      dayWidgets.add(
        InkWell(
          onTap: () {
            ref.read(fechaSeleccionadaProvider.notifier).state = thisDate;
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : (isToday
                          ? (isDark ? primaryColor.withValues(alpha: 0.22) : AppColors.primaryBgLight)
                          : Colors.transparent),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$d',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isToday
                              ? primaryColor
                              : (isDark ? Colors.white : AppColors.textPrimary)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Dots indicadores de tareas
              SizedBox(
                height: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: tasksOnThisDay.take(3).map((t) {
                    return Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: t.prioridad.color,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Completar última fila con días del siguiente mes
    final remainingDays = (7 - (dayWidgets.length % 7)) % 7;
    for (int nextDay = 1; nextDay <= remainingDays; nextDay++) {
      dayWidgets.add(_buildInactiveDayCell(nextDay, isDark));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: dayWidgets,
    );
  }

  Widget _buildInactiveDayCell(int day, bool isDark) {
    return Center(
      child: Text(
        '$day',
        style: TextStyle(
          fontSize: 13,
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return months[month - 1];
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}
