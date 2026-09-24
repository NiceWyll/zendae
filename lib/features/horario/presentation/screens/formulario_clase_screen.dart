import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/services/notification_service.dart';
import 'package:mi_pendiente/features/horario/domain/entities/clase.dart';
import '../providers/horario_provider.dart';

class FormularioClaseScreen extends ConsumerStatefulWidget {
  final int diaSemanaInicial;
  final Clase? claseParaEditar;

  const FormularioClaseScreen({
    super.key,
    this.diaSemanaInicial = 1,
    this.claseParaEditar,
  });

  @override
  ConsumerState<FormularioClaseScreen> createState() => _FormularioClaseScreenState();
}

class _FormularioClaseScreenState extends ConsumerState<FormularioClaseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _aulaCtrl;

  late int _diaSemana;
  late TimeOfDay _horaInicio;
  late TimeOfDay _horaFin;
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  late int _minutosAntes;
  late int _colorSeleccionado;

  static const List<int> _coloresDisponibles = [
    0xFF6366F1, // Indigo
    0xFF8B5CF6, // Violeta
    0xFF06B6D4, // Cian
    0xFF10B981, // Esmeralda
    0xFF059669, // Menta oscuro
    0xFFF59E0B, // Ámbar
    0xFFEA580C, // Naranja
    0xFFE11D48, // Rosa carmesí
    0xFF2563EB, // Azul royal
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.claseParaEditar;
    final now = DateTime.now();

    _nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    _aulaCtrl = TextEditingController(text: c?.aula ?? '');
    _diaSemana = c?.diaSemana ?? widget.diaSemanaInicial;
    _horaInicio = c != null
        ? TimeOfDay(hour: c.horaInicio, minute: c.minutoInicio)
        : const TimeOfDay(hour: 8, minute: 0);
    _horaFin = c != null
        ? TimeOfDay(hour: c.horaFin, minute: c.minutoFin)
        : const TimeOfDay(hour: 10, minute: 0);
    _fechaInicio = c?.fechaInicio ?? DateTime(now.year, now.month, now.day);
    _fechaFin = c?.fechaFin ?? DateTime(now.year, now.month + 3, now.day);
    _minutosAntes = c?.minutosAntes ?? 30;
    _colorSeleccionado = c?.colorValue ?? _coloresDisponibles[(_diaSemana - 1) % _coloresDisponibles.length];
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _aulaCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarHora({required bool esInicio}) async {
    final horaActual = esInicio ? _horaInicio : _horaFin;
    final pick = await showTimePicker(
      context: context,
      initialTime: horaActual,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (pick != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = pick;
          // Si la hora de fin es anterior o igual, sugerir +1 hora
          final iniMin = _horaInicio.hour * 60 + _horaInicio.minute;
          final finMin = _horaFin.hour * 60 + _horaFin.minute;
          if (finMin <= iniMin) {
            _horaFin = TimeOfDay(
              hour: (_horaInicio.hour + 1) % 24,
              minute: _horaInicio.minute,
            );
          }
        } else {
          _horaFin = pick;
        }
      });
    }
  }

  Future<void> _seleccionarFecha({required bool esInicio}) async {
    final now = DateTime.now();
    final inicial = esInicio ? _fechaInicio : _fechaFin;
    final pick = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );

    if (pick != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = DateTime(pick.year, pick.month, pick.day);
          if (_fechaFin.isBefore(_fechaInicio)) {
            _fechaFin = _fechaInicio.add(const Duration(days: 90));
          }
        } else {
          _fechaFin = DateTime(pick.year, pick.month, pick.day);
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final iniMin = _horaInicio.hour * 60 + _horaInicio.minute;
    final finMin = _horaFin.hour * 60 + _horaFin.minute;

    if (finMin <= iniMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ La hora de fin debe ser posterior a la hora de inicio.'),
          backgroundColor: AppColors.priorityAlta,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_fechaFin.isBefore(_fechaInicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ La fecha de fin no puede ser anterior a la fecha de inicio.'),
          backgroundColor: AppColors.priorityAlta,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final id = widget.claseParaEditar?.id ?? const Uuid().v4();
    final nuevaClase = Clase(
      id: id,
      nombre: _nombreCtrl.text.trim(),
      diaSemana: _diaSemana,
      horaInicio: _horaInicio.hour,
      minutoInicio: _horaInicio.minute,
      horaFin: _horaFin.hour,
      minutoFin: _horaFin.minute,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      minutosAntes: _minutosAntes,
      colorValue: _colorSeleccionado,
      aula: _aulaCtrl.text.trim().isEmpty ? null : _aulaCtrl.text.trim(),
    );

    // Validación de Choque de Horario
    final choque = ref.read(clasesProvider.notifier).buscarChoque(nuevaClase);
    if (choque != null && choque.id != nuevaClase.id) {
      final proceder = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 28),
                SizedBox(width: 10),
                Text('¡Choque de Horario!'),
              ],
            ),
            content: Text(
              'Ya tienes la clase "${choque.nombre}" programada los ${choque.diaNombre} de ${choque.horarioFormateado}.\n\n¿Deseas guardar de todos modos con este cruce?',
              style: TextStyle(
                color: isDark ? const Color(0xFFE2E8F0) : AppColors.textPrimary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Corregir hora'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
                child: const Text('Guardar igual', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      if (proceder != true) return;
    }

    if (widget.claseParaEditar != null) {
      await ref.read(clasesProvider.notifier).actualizarClase(nuevaClase);
    } else {
      await ref.read(clasesProvider.notifier).agregarClase(nuevaClase);
    }

    // Programar o actualizar recordatorio
    if (_minutosAntes > 0) {
      await NotificationServiceImpl.instance.programarRecordatorioClase(nuevaClase);
    } else {
      await NotificationServiceImpl.instance.cancelarRecordatorioClase(nuevaClase.id);
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.claseParaEditar != null
              ? '✅ Horario actualizado correctamente'
              : '✅ Clase guardada en el horario semanal',
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.claseParaEditar != null ? 'Editar Clase' : 'Agregar a Horario',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : primaryColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. Nombre de la clase
              Text(
                'Nombre del curso o clase *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE2E8F0) : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreCtrl,
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ej. Cálculo Integral, Inglés, Programación',
                  hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                  ),
                  prefixIcon: const Icon(Icons.school_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa el nombre de la clase';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 2. Día de la semana
              Text(
                'Día de la semana *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE2E8F0) : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _diaSemana,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Lunes')),
                      DropdownMenuItem(value: 2, child: Text('Martes')),
                      DropdownMenuItem(value: 3, child: Text('Miércoles')),
                      DropdownMenuItem(value: 4, child: Text('Jueves')),
                      DropdownMenuItem(value: 5, child: Text('Viernes')),
                      DropdownMenuItem(value: 6, child: Text('Sábado')),
                      DropdownMenuItem(value: 7, child: Text('Domingo')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _diaSemana = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Horario (Inicio y Fin)
              Text(
                'Horario de la clase *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE2E8F0) : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _seleccionarHora(esInicio: true),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF6366F1)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Inicio', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                Text(
                                  _formatTimeOfDay(_horaInicio),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _seleccionarHora(esInicio: false),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 20, color: Color(0xFF8B5CF6)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Fin', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                Text(
                                  _formatTimeOfDay(_horaFin),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Periodo de vigencia (Fecha Inicio y Fin del curso)
              Text(
                'Periodo de vigencia del curso *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE2E8F0) : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Se repetirá automáticamente cada semana durante este rango de fechas.',
                style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _seleccionarFecha(esInicio: true),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fecha de inicio', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(_fechaInicio),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _seleccionarFecha(esInicio: false),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fecha de fin', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(_fechaFin),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5. Notificación previa
              Text(
                'Recordatorio antes de la clase',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE2E8F0) : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('30 min antes'),
                    selected: _minutosAntes == 30,
                    onSelected: (val) {
                      if (val) setState(() => _minutosAntes = 30);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('1 hora antes'),
                    selected: _minutosAntes == 60,
                    onSelected: (val) {
                      if (val) setState(() => _minutosAntes = 60);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Sin aviso'),
                    selected: _minutosAntes == 0,
                    onSelected: (val) {
                      if (val) setState(() => _minutosAntes = 0);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 6. Color identificador
              Text(
                'Color de identificación',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE2E8F0) : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: _coloresDisponibles.map((colorInt) {
                  final esSel = _colorSeleccionado == colorInt;
                  return GestureDetector(
                    onTap: () => setState(() => _colorSeleccionado = colorInt),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Color(colorInt),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: esSel ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (esSel)
                            BoxShadow(
                              color: Color(colorInt).withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: esSel
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 7. Aula / Ubicación (opcional)
              Text(
                'Aula o enlace virtual (opcional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE2E8F0) : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aulaCtrl,
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ej. Aula 204, Pabellón B, Zoom',
                  hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                  ),
                  prefixIcon: const Icon(Icons.meeting_room_outlined),
                ),
              ),
              const SizedBox(height: 32),

              // Botón Guardar
              ElevatedButton(
                onPressed: _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(_colorSeleccionado),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
                child: Text(
                  widget.claseParaEditar != null ? 'Guardar Cambios' : 'Guardar en Horario',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
