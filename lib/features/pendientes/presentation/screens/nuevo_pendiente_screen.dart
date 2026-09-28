import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/utils/date_time_utils.dart';
import 'package:mi_pendiente/core/widgets/alarma_time_picker_sheet.dart';
import 'package:mi_pendiente/core/providers/notification_providers.dart';
import 'package:mi_pendiente/core/providers/clock_providers.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/prioridad.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/repeticion.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/pendientes_provider.dart';
import 'package:mi_pendiente/features/pendientes/presentation/mappers/hora_ui.dart';
import 'package:mi_pendiente/features/pendientes/presentation/mappers/prioridad_ui.dart';
import 'package:mi_pendiente/features/horario/presentation/providers/horario_provider.dart';

class NuevoPendienteScreen extends ConsumerStatefulWidget {
  final Pendiente? pendienteAEditar;
  final String? claseIdInicial;

  const NuevoPendienteScreen({super.key, this.pendienteAEditar, this.claseIdInicial});

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
  String? _claseId;
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
    final int minutosCargados = p?.minutosAntes ?? 15;
    const opcionesValidas = [15, 30, 60, 120, 180];
    _minutosAntes = opcionesValidas.contains(minutosCargados) ? minutosCargados : 15;
    _repetir = p?.repetir.comoTexto ?? 'No repetir';
    _claseId = p?.claseId ?? widget.claseIdInicial;
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
        claseId: _claseId,
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
        final isDark = Theme.of(context).brightness == Brightness.dark;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF6EE7B7),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¡Pendiente "$titulo" guardado para $fechaTexto!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isDark
                  ? const BorderSide(color: Color(0xFF334155), width: 1.2)
                  : BorderSide.none,
            ),
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
    final clases = ref.watch(clasesProvider).valueOrNull ?? [];

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
                      DropdownMenuItem(value: 15, child: Text('15 minutos antes')),
                      DropdownMenuItem(value: 30, child: Text('30 minutos antes')),
                      DropdownMenuItem(value: 60, child: Text('1 hora antes')),
                      DropdownMenuItem(value: 120, child: Text('2 horas antes')),
                      DropdownMenuItem(value: 180, child: Text('3 horas antes')),
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
            const SizedBox(height: 12),

            // Campo: Vincular a materia/clase (Punto 1)
            if (clases.isNotEmpty) ...[
              _buildCardRow(
                isDark: isDark,
                icon: Icons.school_outlined,
                label: 'Materia / Clase',
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _claseId != null && clases.any((c) => c.id == _claseId) ? _claseId : null,
                    icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Ninguna (General)'),
                      ),
                      ...clases.map((c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: c.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 140),
                              child: Text(
                                c.nombre,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                    onChanged: (val) {
                      setState(() => _claseId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

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
  Future<void> _abrirSelectorHoraModerno() async {
    final pick = await AlarmaTimePickerSheet.mostrar(
      context,
      horaInicial: _horaSeleccionada,
    );
    if (pick != null) {
      setState(() {
        _horaSeleccionada = pick;
      });
    }
  }
}
