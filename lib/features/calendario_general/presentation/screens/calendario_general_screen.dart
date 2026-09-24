import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/utils/date_time_utils.dart';
import 'package:mi_pendiente/core/widgets/priority_badge.dart';
import 'package:mi_pendiente/features/horario/domain/entities/clase.dart';
import 'package:mi_pendiente/features/horario/presentation/providers/horario_provider.dart';
import 'package:mi_pendiente/features/horario/presentation/screens/formulario_clase_screen.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/pendientes_provider.dart';
import 'package:mi_pendiente/features/pendientes/presentation/screens/detalle_pendiente_screen.dart';

enum FiltroCalendarioGeneral { pendientes, horario, todo }

class CalendarioGeneralScreen extends ConsumerStatefulWidget {
  const CalendarioGeneralScreen({super.key});

  @override
  ConsumerState<CalendarioGeneralScreen> createState() => _CalendarioGeneralScreenState();
}

class _CalendarioGeneralScreenState extends ConsumerState<CalendarioGeneralScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  FiltroCalendarioGeneral _filtroActivo = FiltroCalendarioGeneral.todo;

  static const List<String> _weekdays = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final asyncPendientes = ref.watch(pendientesProvider);
    final asyncClases = ref.watch(clasesProvider);

    final todosPendientes = asyncPendientes.valueOrNull ?? [];
    final todasClases = asyncClases.valueOrNull ?? [];

    // Pendientes y clases para el día seleccionado
    final pendientesDelDia = todosPendientes.where((p) => _isSameDay(p.fecha, _selectedDate)).toList();
    pendientesDelDia.sort((a, b) {
      final aMin = a.hora.hora * 60 + a.hora.minuto;
      final bMin = b.hora.hora * 60 + b.hora.minuto;
      return aMin.compareTo(bMin);
    });

    final clasesDelDia = todasClases.where((c) => c.estaVigenteEn(_selectedDate)).toList();
    clasesDelDia.sort((a, b) {
      final aMin = a.horaInicio * 60 + a.minutoInicio;
      final bMin = b.horaInicio * 60 + b.minutoInicio;
      return aMin.compareTo(bMin);
    });

    return Column(
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
                '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekdays.map((w) => SizedBox(
              width: 36,
              child: Text(
                w,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 6),

        // Matriz de días del mes con indicadores duales
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMonthGrid(isDark, todosPendientes, todasClases),
        ),

        Divider(
          height: 20,
          thickness: 1,
          color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
        ),

        // Encabezado del día seleccionado y los 3 Botones de Filtro
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedDate.day} de ${_getMonthName(_selectedDate.month)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : primaryColor,
                    ),
                  ),
                  Text(
                    DateTimeUtils.getDayName(_selectedDate),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 3 Botones Interactivos ("Ver pendientes", "Ver horario", "Ver todo")
              Row(
                children: [
                  _buildFiltroButton(
                    label: 'Ver pendientes',
                    count: pendientesDelDia.length,
                    filtro: FiltroCalendarioGeneral.pendientes,
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFiltroButton(
                    label: 'Ver horario',
                    count: clasesDelDia.length,
                    filtro: FiltroCalendarioGeneral.horario,
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFiltroButton(
                    label: 'Ver todo',
                    count: pendientesDelDia.length + clasesDelDia.length,
                    filtro: FiltroCalendarioGeneral.todo,
                    color: isDark ? Theme.of(context).colorScheme.primary : Theme.of(context).primaryColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Lista de contenido dinámico según el botón seleccionado
        Expanded(
          child: _buildListaContenido(
            isDark: isDark,
            pendientes: pendientesDelDia,
            clases: clasesDelDia,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltroButton({
    required String label,
    required int count,
    required FiltroCalendarioGeneral filtro,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _filtroActivo == filtro;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _filtroActivo = filtro;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGrid(
    bool isDark,
    List<Pendiente> todosPendientes,
    List<Clase> todasClases,
  ) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Lunes, 7 = Domingo

    final List<Widget> dayWidgets = [];

    // Celdas vacías del mes anterior
    for (int i = 1; i < startingWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 36, height: 42));
    }

    // Días del mes
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isSelected = _isSameDay(date, _selectedDate);
      final isToday = DateTimeUtils.isToday(date);

      // Comprobar indicadores visuales para este día
      final hasPendientes = todosPendientes.any((p) => _isSameDay(p.fecha, date));
      final hasClases = todasClases.any((c) => c.estaVigenteEn(date));

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 36,
            height: 42,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? Theme.of(context).colorScheme.primary : Theme.of(context).primaryColor)
                  : (isToday ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)) : Colors.transparent),
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(
                      color: isDark ? Theme.of(context).colorScheme.primary : Theme.of(context).primaryColor,
                      width: 1.5,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isToday
                            ? (isDark ? Theme.of(context).colorScheme.primary : Theme.of(context).primaryColor)
                            : (isDark ? Colors.white : AppColors.textPrimary)),
                  ),
                ),
                const SizedBox(height: 2),

                // Indicador visual: antelación de si tiene pendientes (azul), clases (violeta), o ambos
                if (hasPendientes || hasClases)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasPendientes)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (hasClases)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.amberAccent : const Color(0xFF8B5CF6),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  )
                else
                  const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: (MediaQuery.of(context).size.width - 32 - (36 * 7)) / 7,
      runSpacing: 4,
      children: dayWidgets,
    );
  }

  Widget _buildListaContenido({
    required bool isDark,
    required List<Pendiente> pendientes,
    required List<Clase> clases,
  }) {
    switch (_filtroActivo) {
      case FiltroCalendarioGeneral.pendientes:
        return _buildListaSoloPendientes(isDark, pendientes);
      case FiltroCalendarioGeneral.horario:
        return _buildListaSoloClases(isDark, clases);
      case FiltroCalendarioGeneral.todo:
        return _buildListaUnificada(isDark, pendientes, clases);
    }
  }

  Widget _buildListaSoloPendientes(bool isDark, List<Pendiente> pendientes) {
    if (pendientes.isEmpty) {
      return Center(
        child: Text(
          'No hay pendientes registrados para este día',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: pendientes.length,
      itemBuilder: (context, index) {
        final task = pendientes[index];
        return _buildPendienteTile(context, task, isDark);
      },
    );
  }

  Widget _buildListaSoloClases(bool isDark, List<Clase> clases) {
    if (clases.isEmpty) {
      return Center(
        child: Text(
          'No tienes clases en tu horario para este día',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: clases.length,
      itemBuilder: (context, index) {
        final clase = clases[index];
        return _buildClaseTile(context, clase, isDark);
      },
    );
  }

  Widget _buildListaUnificada(
    bool isDark,
    List<Pendiente> pendientes,
    List<Clase> clases,
  ) {
    // Unir ambas listas en elementos ordenados cronológicamente
    final List<_ItemAgenda> items = [];

    for (final p in pendientes) {
      items.add(_ItemAgenda.pendiente(p));
    }
    for (final c in clases) {
      items.add(_ItemAgenda.clase(c));
    }

    if (items.isEmpty) {
      return Center(
        child: Text(
          'Sin actividades ni pendientes programados para hoy',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
          ),
        ),
      );
    }

    items.sort((a, b) => a.minutosDesdeMedianoche.compareTo(b.minutosDesdeMedianoche));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.esClase) {
          return _buildClaseTile(context, item.clase!, isDark);
        } else {
          return _buildPendienteTile(context, item.pendiente!, isDark);
        }
      },
    );
  }

  Widget _buildPendienteTile(BuildContext context, Pendiente task, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                  color: task.estaCompletado
                      ? (isDark ? Theme.of(context).colorScheme.primary : Theme.of(context).primaryColor)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: task.estaCompletado
                        ? (isDark ? Theme.of(context).colorScheme.primary : Theme.of(context).primaryColor)
                        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    width: 1.8,
                  ),
                ),
                child: task.estaCompletado
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Etiqueta PENDIENTE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Pendiente',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Título
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
                          : (isDark ? Colors.white : AppColors.textPrimary),
                      decoration: task.estaCompletado ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  PriorityBadge(prioridad: task.prioridad, asPill: false),
                ],
              ),
            ),

            // Hora
            Text(
              DateTimeUtils.formatTime(task.hora),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaseTile(BuildContext context, Clase clase, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: clase.finalizaPronto
              ? const Color(0xFFF59E0B)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFEDF2F7)),
          width: clase.finalizaPronto ? 1.4 : 1.2,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FormularioClaseScreen(claseParaEditar: clase),
            ),
          );
        },
        child: Row(
          children: [
            // Indicador de color de la clase
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: clase.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),

            // Etiqueta CLASE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: clase.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Clase',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: clase.color,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Nombre y aula
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clase.nombre,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (clase.aula != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '📍 ${clase.aula!}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Horario
            Text(
              clase.horarioFormateado,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemAgenda {
  final bool esClase;
  final Pendiente? pendiente;
  final Clase? clase;
  final int minutosDesdeMedianoche;

  _ItemAgenda.pendiente(this.pendiente)
      : esClase = false,
        clase = null,
        minutosDesdeMedianoche = pendiente!.hora.hora * 60 + pendiente.hora.minuto;

  _ItemAgenda.clase(this.clase)
      : esClase = true,
        pendiente = null,
        minutosDesdeMedianoche = clase!.horaInicio * 60 + clase.minutoInicio;
}
