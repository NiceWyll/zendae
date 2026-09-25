import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/services/notification_service.dart';
import 'package:mi_pendiente/features/horario/domain/entities/clase.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/pendientes_provider.dart';
import '../providers/horario_provider.dart';
import 'detalle_clase_screen.dart';
import 'formulario_clase_screen.dart';

class HorarioScreen extends ConsumerStatefulWidget {
  const HorarioScreen({super.key});

  @override
  ConsumerState<HorarioScreen> createState() => _HorarioScreenState();
}

class _HorarioScreenState extends ConsumerState<HorarioScreen> {
  late Map<int, bool> _diasDesplegados;

  @override
  void initState() {
    super.initState();
    final hoyWeekday = DateTime.now().weekday; // 1 = Lunes, 7 = Domingo
    _diasDesplegados = {
      for (int i = 1; i <= 7; i++) i: (i == hoyWeekday),
    };
  }

  static const List<Map<String, dynamic>> _diasInfo = [
    {'dia': 1, 'nombre': 'Lunes'},
    {'dia': 2, 'nombre': 'Martes'},
    {'dia': 3, 'nombre': 'Miércoles'},
    {'dia': 4, 'nombre': 'Jueves'},
    {'dia': 5, 'nombre': 'Viernes'},
    {'dia': 6, 'nombre': 'Sábado'},
    {'dia': 7, 'nombre': 'Domingo'},
  ];

  Future<void> _confirmarEliminarClase(Clase clase) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('¿Eliminar clase?'),
        content: Text('Se eliminará "${clase.nombre}" de tu horario semanal y sus recordatorios.'),
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

    if (confirmar == true) {
      await ref.read(clasesProvider.notifier).eliminarClase(clase.id);
      await NotificationServiceImpl.instance.cancelarRecordatorioClase(clase.id);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('🗑️ Clase eliminada del horario'),
          backgroundColor: AppColors.priorityAlta,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatearFecha(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final asyncClases = ref.watch(clasesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final hoyWeekday = DateTime.now().weekday;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Mi Horario',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : primaryColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: asyncClases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Inconveniente al cargar el horario: $e'),
        ),
        data: (todasLasClases) {
          // Organizar clases por día de la semana (1 a 7)
          final Map<int, List<Clase>> clasesPorDia = {
            for (int i = 1; i <= 7; i++) i: <Clase>[],
          };

          for (final c in todasLasClases) {
            clasesPorDia[c.diaSemana]?.add(c);
          }

          for (final lista in clasesPorDia.values) {
            lista.sort((a, b) {
              final aMin = a.horaInicio * 60 + a.minutoInicio;
              final bMin = b.horaInicio * 60 + b.minutoInicio;
              return aMin.compareTo(bMin);
            });
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            children: [
              // Encabezado descriptivo
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFC7D2FE),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_view_week_rounded,
                        color: Color(0xFF6366F1),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Horario de Clases y Actividades',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Toca cada día para desplegar y agregar tus clases. Se repiten automáticamente semana a semana.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 7 Días de la semana (Lunes a Domingo)
              ..._diasInfo.map((info) {
                final int diaNum = info['dia'] as int;
                final String diaNombre = info['nombre'] as String;
                final clasesDelDia = clasesPorDia[diaNum] ?? [];
                final bool estaDesplegado = _diasDesplegados[diaNum] ?? false;
                final bool esHoy = diaNum == hoyWeekday;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: esHoy
                          ? (isDark
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
                              : Theme.of(context).primaryColor.withValues(alpha: 0.5))
                          : (isDark ? AppColors.borderDark : const Color(0xFFEDF2F7)),
                      width: esHoy ? 1.8 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header del acordeón del día
                      InkWell(
                        onTap: () {
                          setState(() {
                            _diasDesplegados[diaNum] = !estaDesplegado;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              // Chip indicador del día
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: esHoy
                                      ? (isDark ? Theme.of(context).colorScheme.primary : Theme.of(context).primaryColor)
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  diaNombre.substring(0, 3).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: esHoy
                                        ? Colors.white
                                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Nombre completo del día
                              Text(
                                diaNombre,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              if (esHoy) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Hoy',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),

                              // Conteo de clases
                              Text(
                                '${clasesDelDia.length} ${clasesDelDia.length == 1 ? "clase" : "clases"}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 8),

                              Icon(
                                estaDesplegado ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Contenido desplegado del día
                      if (estaDesplegado) ...[
                        Divider(
                          height: 1,
                          color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
                        ),
                        if (clasesDelDia.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                Text(
                                  'No tienes clases registradas para el $diaNombre',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => FormularioClaseScreen(diaSemanaInicial: diaNum),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: Text('Agregar clase al $diaNombre'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryColor,
                                    side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                ...clasesDelDia.map((clase) {
                                  return _buildClaseCard(context, clase, isDark);
                                }),
                                const SizedBox(height: 8),
                                // Botón agregar otra clase al día
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => FormularioClaseScreen(diaSemanaInicial: diaNum),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Agregar otra clase'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: primaryColor,
                                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClaseCard(BuildContext context, Clase clase, bool isDark) {
    final finalizaPronto = clase.finalizaPronto;
    final haExpirado = clase.haExpirado;
    final todosLosPendientes = ref.watch(pendientesProvider).valueOrNull ?? [];
    final pendientesDeClase = todosLosPendientes.where((p) => p.claseId == clase.id).toList();
    final examenesDeClase = ref.watch(examenesPorClaseProvider(clase.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: finalizaPronto
              ? const Color(0xFFF59E0B)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: finalizaPronto ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetalleClaseScreen(clase: clase),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de aviso si el curso finaliza pronto (3 días o menos)
            if (finalizaPronto)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ Este curso finaliza en ${clase.diasRestantes} días. Recuerda actualizar o quitar este horario.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (haExpirado)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF991B1B), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Período finalizado. No se enviarán más recordatorios.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra lateral de color asignado
                  Container(
                    width: 5,
                    height: 48,
                    decoration: BoxDecoration(
                      color: clase.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Contenido de la clase
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clase.nombre,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Horario y Aula
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 14, color: clase.color),
                            const SizedBox(width: 4),
                            Text(
                              clase.horarioFormateado,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                            ),
                            if (clase.aula != null) ...[
                              const SizedBox(width: 10),
                              const Text('·', style: TextStyle(color: Color(0xFF94A3B8))),
                              const SizedBox(width: 10),
                              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 3),
                              Text(
                                clase.aula!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Vigencia, Recordatorio, Pendientes y Exámenes
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '📅 Hasta ${_formatearFecha(clase.fechaFin)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            if (clase.minutosAntes > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: clase.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '🔔 ${clase.minutosAntes}m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: clase.color,
                                  ),
                                ),
                              ),
                            if (pendientesDeClase.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '📝 ${pendientesDeClase.length} ${pendientesDeClase.length == 1 ? "tarea" : "tareas"}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            if (examenesDeClase.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '🎓 ${examenesDeClase.length} ${examenesDeClase.length == 1 ? "examen" : "exámenes"}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Acciones (Editar y Eliminar)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 19),
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FormularioClaseScreen(claseParaEditar: clase),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 19),
                        color: AppColors.priorityAlta,
                        onPressed: () => _confirmarEliminarClase(clase),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
