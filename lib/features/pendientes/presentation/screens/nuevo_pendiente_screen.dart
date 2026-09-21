import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/utils/date_time_utils.dart';
import 'package:mi_pendiente/core/providers/notification_providers.dart';
import 'package:mi_pendiente/core/providers/clock_providers.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/prioridad.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/repeticion.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/pendientes_provider.dart';
import 'package:mi_pendiente/features/pendientes/presentation/mappers/hora_ui.dart';
import 'package:mi_pendiente/features/pendientes/presentation/mappers/prioridad_ui.dart';

class NuevoPendienteScreen extends ConsumerStatefulWidget {
  final Pendiente? pendienteAEditar;

  const NuevoPendienteScreen({super.key, this.pendienteAEditar});

  @override
  ConsumerState<NuevoPendienteScreen> createState() => _NuevoPendienteScreenState();
}

class _NuevoPendienteScreenState extends ConsumerState<NuevoPendienteScreen> {
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _tituloController;
  late TextEditingController _descController;
  late DateTime _fechaSeleccionada;
  late TimeOfDay _horaSeleccionada;
  late Prioridad _prioridad;
  late bool _tieneRecordatorio;
  late int _minutosAntes;
  late String _repetir;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.pendienteAEditar;
    _tituloController = TextEditingController(text: p?.titulo ?? '');
    _descController = TextEditingController(text: p?.descripcion ?? '');
    _fechaSeleccionada = p?.fecha ?? DateTime.now();
    _horaSeleccionada = p?.hora.comoTimeOfDay ?? const TimeOfDay(hour: 10, minute: 30);
    _prioridad = p?.prioridad ?? Prioridad.media;
    _tieneRecordatorio = p?.tieneRecordatorio ?? true;
    _minutosAntes = p?.minutosAntes ?? 10;
    _repetir = p?.repetir.comoTexto ?? 'No repetir';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tituloController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un título para el pendiente'),
          backgroundColor: AppColors.priorityAlta,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final id = widget.pendienteAEditar?.id ?? ref.read(uuidProvider)();
      final nuevo = Pendiente(
        id: id,
        titulo: titulo,
        descripcion: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        fecha: DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, _fechaSeleccionada.day),
        hora: _horaSeleccionada.comoHoraDelDia,
        prioridad: _prioridad,
        tieneRecordatorio: _tieneRecordatorio,
        minutosAntes: _minutosAntes,
        repetir: Repeticion.desdeTexto(_repetir),
        estaCompletado: widget.pendienteAEditar?.estaCompletado ?? false,
        fechaCompletado: widget.pendienteAEditar?.fechaCompletado,
      );

      if (nuevo.tieneRecordatorio) {
        await ref.read(notificationSchedulerProvider).pedirPermisos();
      }

      final notifier = ref.read(pendientesProvider.notifier);
      if (widget.pendienteAEditar != null) {
        await notifier.actualizarPendiente(nuevo);
      } else {
        await notifier.crearPendiente(nuevo);
      }

      // También seleccionamos la fecha en el estado para que se vea reflejada en el calendario
      notifier.seleccionarFecha(nuevo.fecha);

      if (mounted) {
        final esHoy = DateTimeUtils.isToday(nuevo.fecha);
        final fechaTexto = esHoy ? 'Hoy' : DateTimeUtils.formatDayMonth(nuevo.fecha);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Pendiente "$titulo" guardado para $fechaTexto!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.priorityAlta,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final isEditing = widget.pendienteAEditar != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditing ? 'Editar pendiente' : 'Nuevo pendiente',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Campo: Título del pendiente
            _buildCardField(
              isDark: isDark,
              icon: Icons.description_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Título del pendiente',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  TextField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Reunión con el equipo',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.only(top: 4, bottom: 2),
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Campo: Descripción
            _buildCardField(
              isDark: isDark,
              icon: Icons.chat_bubble_outline_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  TextField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Revisar avances y definir próximos pasos',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.only(top: 4, bottom: 2),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Campo: Fecha (con scroll al calendario integrado)
            _buildCardRow(
              isDark: isDark,
              icon: Icons.calendar_today_outlined,
              label: 'Fecha',
              onTap: _irACalendarioOSeleccionar,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? primaryColor.withValues(alpha: 0.2) : AppColors.primaryBgLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.edit_calendar_rounded, color: primaryColor, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Campo: Hora (Selector moderno en BottomSheet)
            _buildCardRow(
              isDark: isDark,
              icon: Icons.access_time_rounded,
              label: 'Hora',
              onTap: _abrirSelectorHoraModerno,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? primaryColor.withValues(alpha: 0.2) : AppColors.primaryBgLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      DateTimeUtils.formatTime(_horaSeleccionada),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: primaryColor, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Campo: Prioridad
            _buildCardRow(
              isDark: isDark,
              icon: Icons.outlined_flag_rounded,
              label: 'Prioridad',
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<Prioridad>(
                  value: _prioridad,
                  icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
                  items: Prioridad.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: p.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (p) {
                    if (p != null) setState(() => _prioridad = p);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Campo: Recordatorio Switch
            _buildCardRow(
              isDark: isDark,
              icon: Icons.notifications_none_rounded,
              label: 'Recordatorio',
              trailing: Switch(
                value: _tieneRecordatorio,
                activeThumbColor: primaryColor,
                activeTrackColor: isDark ? primaryColor.withValues(alpha: 0.3) : AppColors.primaryBgLight,
                onChanged: (val) => setState(() => _tieneRecordatorio = val),
              ),
            ),
            const SizedBox(height: 12),

            // Campo: Avisarme
            if (_tieneRecordatorio) ...[
              _buildCardRow(
                isDark: isDark,
                icon: Icons.alarm_rounded,
                label: 'Avisarme',
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _minutosAntes,
                    icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 minutos antes')),
                      DropdownMenuItem(value: 10, child: Text('10 minutos antes')),
                      DropdownMenuItem(value: 15, child: Text('15 minutos antes')),
                      DropdownMenuItem(value: 30, child: Text('30 minutos antes')),
                      DropdownMenuItem(value: 60, child: Text('1 hora antes')),
                    ],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                    onChanged: (val) {
                      if (val != null) setState(() => _minutosAntes = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Campo: Repetir
            _buildCardRow(
              isDark: isDark,
              icon: Icons.sync_rounded,
              label: 'Repetir',
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _repetir,
                  icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
                  items: const [
                    DropdownMenuItem(value: 'No repetir', child: Text('No repetir')),
                    DropdownMenuItem(value: 'Diario', child: Text('Diario')),
                    DropdownMenuItem(value: 'Semanal', child: Text('Semanal')),
                    DropdownMenuItem(value: 'Mensual', child: Text('Mensual')),
                  ],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                  onChanged: (val) {
                    if (val != null) setState(() => _repetir = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mini calendario visual interactivo
            _buildMiniCalendar(isDark),
            const SizedBox(height: 24),

            // Botón de guardar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 4,
                  shadowColor: primaryColor.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        isEditing ? 'Actualizar pendiente' : 'Guardar pendiente',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCardField({
    required bool isDark,
    required IconData icon,
    required Widget child,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEDF2F7),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildCardRow({
    required bool isDark,
    required IconData icon,
    required String label,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    final rowWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEDF2F7),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          trailing,
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: rowWidget,
      );
    }
    return rowWidget;
  }

  Widget _buildMiniCalendar(bool isDark) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEDF2F7),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // Mes y año
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: primaryColor, size: 24),
                onPressed: () {
                  setState(() {
                    _fechaSeleccionada = DateTime(
                      _fechaSeleccionada.year,
                      _fechaSeleccionada.month - 1,
                      _fechaSeleccionada.day.clamp(1, 28),
                    );
                  });
                },
              ),
              Text(
                DateTimeUtils.formatMonthYear(_fechaSeleccionada),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: primaryColor, size: 24),
                onPressed: () {
                  setState(() {
                    _fechaSeleccionada = DateTime(
                      _fechaSeleccionada.year,
                      _fechaSeleccionada.month + 1,
                      _fechaSeleccionada.day.clamp(1, 28),
                    );
                  });
                },
              ),
            ],
          ),

          // Días de la semana
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('LUN', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
              Text('MAR', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
              Text('MIÉ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
              Text('JUE', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
              Text('VIE', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
              Text('SÁB', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
              Text('DOM', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),

          // Cuadrícula reducida de días
          _buildMiniGridDays(isDark),
        ],
      ),
    );
  }

  Widget _buildMiniGridDays(bool isDark) {
    final primaryColor = Theme.of(context).primaryColor;
    final firstDay = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, 1);
    final daysInMonth = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1: Lun ... 7: Dom

    final cells = <Widget>[];

    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int d = 1; d <= daysInMonth; d++) {
      final isSelected = _fechaSeleccionada.day == d;
      final isToday = DateTimeUtils.isToday(DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, d));

      cells.add(
        InkWell(
          onTap: () {
            setState(() {
              _fechaSeleccionada = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, d);
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : (isToday ? AppColors.primaryBgLight : Colors.transparent),
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
                      : (isToday ? primaryColor : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }

  void _irACalendarioOSeleccionar() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // Selector de Hora Estilo Alarma (Ruedas desplegables para hora y minutos)
  void _abrirSelectorHoraModerno() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _AlarmaTimePickerSheet(
          horaInicial: _horaSeleccionada,
          isDark: isDark,
          onHoraConfirmada: (nuevaHora) {
            setState(() {
              _horaSeleccionada = nuevaHora;
            });
          },
        );
      },
    );
  }
}

class _AlarmaTimePickerSheet extends StatefulWidget {
  final TimeOfDay horaInicial;
  final bool isDark;
  final ValueChanged<TimeOfDay> onHoraConfirmada;

  const _AlarmaTimePickerSheet({
    required this.horaInicial,
    required this.isDark,
    required this.onHoraConfirmada,
  });

  @override
  State<_AlarmaTimePickerSheet> createState() => _AlarmaTimePickerSheetState();
}

class _AlarmaTimePickerSheetState extends State<_AlarmaTimePickerSheet> {
  static const List<int> _hours = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  late int _selectedHourIndex;
  late int _selectedMinute;
  late bool _isAm;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _isAm = widget.horaInicial.hour < 12;
    _selectedHourIndex = widget.horaInicial.hour % 12;
    _selectedMinute = widget.horaInicial.minute;
    _hourController = FixedExtentScrollController(initialItem: _selectedHourIndex);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  int get _hour24 {
    final h = _hours[_selectedHourIndex];
    if (_isAm) {
      return h == 12 ? 0 : h;
    } else {
      return h == 12 ? 12 : h + 12;
    }
  }

  String get _displayHour => _hours[_selectedHourIndex].toString().padLeft(2, '0');
  String get _displayMinute => _selectedMinute.toString().padLeft(2, '0');

  Widget _buildAmPmButton(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    final primaryColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryColor = Theme.of(context).primaryColor;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Agarre superior
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.alarm_rounded, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Ajustar Hora',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Desliza las ruedas y elige AM o PM',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),

            // Display Digital Grande con AM/PM y Selector
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.primaryBgLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$_displayHour : $_displayMinute',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isAm ? 'AM' : 'PM',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Selector interactivo de botones AM / PM
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAmPmButton('AM', _isAm, () {
                          setState(() => _isAm = true);
                        }, isDark),
                        const SizedBox(width: 4),
                        _buildAmPmButton('PM', !_isAm, () {
                          setState(() => _isAm = false);
                        }, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ruedas desplegables estilo alarma
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark.withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  // Etiquetas de columnas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'HORA (1-12)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'MINUTOS (0-59)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Las dos ruedas de selección estilo reloj / alarma
                  SizedBox(
                    height: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Rueda de Horas (12 a 11)
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: _hourController,
                            itemExtent: 44,
                            looping: true,
                            selectionOverlay: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                _selectedHourIndex = index % 12;
                              });
                            },
                            children: List.generate(12, (index) {
                              final isSelected = index == _selectedHourIndex;
                              final hourText = _hours[index].toString().padLeft(2, '0');
                              return Center(
                                child: Text(
                                  hourText,
                                  style: TextStyle(
                                    fontSize: isSelected ? 26 : 20,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                    color: isSelected
                                        ? primaryColor
                                        : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        // Separador ":"
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                            ),
                          ),
                        ),

                        // Rueda de Minutos
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: _minuteController,
                            itemExtent: 44,
                            looping: true,
                            selectionOverlay: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                _selectedMinute = index % 60;
                              });
                            },
                            children: List.generate(60, (index) {
                              final isSelected = index == _selectedMinute;
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: isSelected ? 26 : 20,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                    color: isSelected
                                        ? primaryColor
                                        : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botón confirmar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Confirmar hora',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                onPressed: () {
                  widget.onHoraConfirmada(TimeOfDay(hour: _hour24, minute: _selectedMinute));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
