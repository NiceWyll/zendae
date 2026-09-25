import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/providers/clock_providers.dart';
import 'package:mi_pendiente/core/utils/date_time_utils.dart';
import 'package:mi_pendiente/features/horario/domain/entities/clase.dart';
import 'package:mi_pendiente/features/horario/domain/entities/examen.dart';
import 'package:mi_pendiente/features/horario/presentation/providers/horario_provider.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/pendientes_provider.dart';
import 'package:mi_pendiente/features/pendientes/presentation/screens/detalle_pendiente_screen.dart';
import 'package:mi_pendiente/features/pendientes/presentation/screens/nuevo_pendiente_screen.dart';
import 'formulario_clase_screen.dart';

class DetalleClaseScreen extends ConsumerStatefulWidget {
  final Clase clase;

  const DetalleClaseScreen({super.key, required this.clase});

  @override
  ConsumerState<DetalleClaseScreen> createState() => _DetalleClaseScreenState();
}

class _DetalleClaseScreenState extends ConsumerState<DetalleClaseScreen> {
  late Clase _clase;

  @override
  void initState() {
    super.initState();
    _clase = widget.clase;
  }

  String _formatearFecha(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _abrirDialogoAgregarExamen(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tituloCtrl = TextEditingController(text: 'Examen de ${_clase.nombre}');
    final aulaCtrl = TextEditingController(text: _clase.aula ?? '');
    DateTime fechaSeleccionada = DateTime.now().add(const Duration(days: 7));
    TimeOfDay horaSeleccionada = TimeOfDay(hour: _clase.horaInicio, minute: _clase.minutoInicio);

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: Color(0xFFEF4444), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Marcar Examen',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Se programarán 2 avisos automáticos: 1 día antes Y 1 hora antes del examen.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: tituloCtrl,
                      decoration: InputDecoration(
                        labelText: 'Título del examen',
                        hintText: 'Ej. Primer Parcial',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Selector de fecha
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fechaSeleccionada,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => fechaSeleccionada = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFFEF4444)),
                            const SizedBox(width: 10),
                            Text(
                              'Fecha: ${_formatearFecha(fechaSeleccionada)}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Selector de hora
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: horaSeleccionada,
                        );
                        if (picked != null) {
                          setDialogState(() => horaSeleccionada = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFFEF4444)),
                            const SizedBox(width: 10),
                            Text(
                              'Hora: ${DateTimeUtils.formatTime(horaSeleccionada)}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: aulaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Aula / Salón (opcional)',
                        hintText: 'Ej. Edificio B, Salón 201',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tituloCtrl.text.trim().isEmpty) return;
                    Navigator.of(ctx).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Programar Examen'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado == true && mounted) {
      final genUuid = ref.read(uuidProvider);
      final nuevoExamen = Examen(
        id: genUuid(),
        claseId: _clase.id,
        titulo: tituloCtrl.text.trim(),
        fecha: DateTime(fechaSeleccionada.year, fechaSeleccionada.month, fechaSeleccionada.day),
        horaHour: horaSeleccionada.hour,
        horaMinute: horaSeleccionada.minute,
        aula: aulaCtrl.text.trim().isEmpty ? null : aulaCtrl.text.trim(),
      );

      await ref.read(examenesProvider.notifier).agregarExamen(nuevoExamen, _clase.nombre);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📝 Examen "${nuevoExamen.titulo}" programado con avisos 1 día y 1 hora antes'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmarEliminarExamen(Examen examen) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('¿Eliminar examen?'),
        content: Text('Se cancelarán los recordatorios para "${examen.titulo}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.priorityAlta,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await ref.read(examenesProvider.notifier).eliminarExamen(examen);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Examen eliminado y recordatorios cancelados'),
            backgroundColor: AppColors.priorityAlta,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos si la clase fue actualizada en la lista general
    final todasLasClases = ref.watch(clasesProvider).valueOrNull ?? [];
    final claseActualizada = todasLasClases.where((c) => c.id == _clase.id).firstOrNull;
    if (claseActualizada != null) {
      _clase = claseActualizada;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    // Pendientes vinculados a esta materia (Requisito 1)
    final todosLosPendientes = ref.watch(pendientesProvider).valueOrNull ?? [];
    final pendientesDeEstaClase = todosLosPendientes.where((p) => p.claseId == _clase.id).toList();

    // Exámenes de esta materia (Requisito 2)
    final examenesDeEstaClase = ref.watch(examenesPorClaseProvider(_clase.id));

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          _clase.nombre,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : primaryColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar clase',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FormularioClaseScreen(claseParaEditar: _clase),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        children: [
          // Tarjeta de Horario y Detalles de la clase
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFEDF2F7),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _clase.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _clase.nombre,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _clase.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _clase.diaNombre,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _clase.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Horario
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 18, color: _clase.color),
                    const SizedBox(width: 8),
                    Text(
                      '${_clase.horarioFormateado} hs',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      ),
                    ),
                    if (_clase.aula != null) ...[
                      const SizedBox(width: 12),
                      const Text('·', style: TextStyle(color: Color(0xFF94A3B8))),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        _clase.aula!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                // Fechas vigencia
                Row(
                  children: [
                    const Icon(Icons.date_range_outlined, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      'Del ${_formatearFecha(_clase.fechaInicio)} al ${_formatearFecha(_clase.fechaFin)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                if (_clase.minutosAntes > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.notifications_active_outlined, size: 16, color: _clase.color),
                      const SizedBox(width: 6),
                      Text(
                        'Aviso habitual: ${_clase.minutosAntes} min antes (+ recordatorio 5 min antes con tareas pendientes)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ================= SECCIÓN MODO EXAMEN (Requisito 2) =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_late_outlined, size: 20, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Text(
                    'Modo Examen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _abrirDialogoAgregarExamen(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Marcar Examen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Fechas especiales con alerta 1 día antes Y 1 hora antes.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),

          if (examenesDeEstaClase.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No tienes exámenes programados para esta materia.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...examenesDeEstaClase.map((examen) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF991B1B).withValues(alpha: 0.5) : const Color(0xFFFECACA),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school_rounded, color: Color(0xFFEF4444), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            examen.titulo,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF991B1B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '📅 ${_formatearFecha(examen.fecha)} · ${examen.horaFormateada} hs${examen.aula != null ? " · ${examen.aula}" : ""}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF7F1D1D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '🔔 Recordatorios: 1 día y 1 hora antes',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      color: AppColors.priorityAlta,
                      onPressed: () => _confirmarEliminarExamen(examen),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          // ================= SECCIÓN PENDIENTES DE ESTA MATERIA (Requisito 1) =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.checklist_rounded, size: 20, color: _clase.color),
                  const SizedBox(width: 8),
                  Text(
                    'Pendientes de esta materia',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NuevoPendienteScreen(claseIdInicial: _clase.id),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nuevo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (pendientesDeEstaClase.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(Icons.task_alt_rounded, size: 32, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  Text(
                    'No hay pendientes vinculados a "${_clase.nombre}".',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NuevoPendienteScreen(claseIdInicial: _clase.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Crear tarea para esta materia'),
                  ),
                ],
              ),
            )
          else
            ...pendientesDeEstaClase.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFEDF2F7),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: Checkbox(
                    value: p.estaCompletado,
                    activeColor: _clase.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      ref.read(pendientesProvider.notifier).alternarCompletado(p.id, val);
                    },
                  ),
                  title: Text(
                    p.titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: p.estaCompletado ? TextDecoration.lineThrough : null,
                      color: p.estaCompletado
                          ? const Color(0xFF94A3B8)
                          : (isDark ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                  subtitle: Text(
                    '📅 ${_formatearFecha(p.fecha)} · ${DateTimeUtils.formatTime(p.hora)} hs',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetallePendienteScreen(pendienteId: p.id),
                      ),
                    );
                  },
                ),
              );
            }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
