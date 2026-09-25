import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/utils/date_time_utils.dart';
import 'package:mi_pendiente/features/horario/presentation/providers/horario_provider.dart';
import 'package:mi_pendiente/features/horario/presentation/screens/detalle_clase_screen.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/pendientes_provider.dart';
import 'package:mi_pendiente/features/pendientes/presentation/screens/detalle_pendiente_screen.dart';

class BuscadorGlobalDelegate extends SearchDelegate<void> {
  final WidgetRef ref;

  BuscadorGlobalDelegate({required this.ref})
      : super(
          searchFieldLabel: 'Buscar en tareas y clases...',
          searchFieldStyle: const TextStyle(fontSize: 15),
        );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        elevation: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          fontSize: 15,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultados(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultados(context);
  }

  Widget _buildResultados(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final cleanQuery = query.trim().toLowerCase();

    if (cleanQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 54,
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              'Escribe para buscar en tus tareas y clases',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final todosPendientes = ref.watch(pendientesProvider).valueOrNull ?? [];
    final todasClases = ref.watch(clasesProvider).valueOrNull ?? [];

    final pendientesFiltrados = todosPendientes.where((p) {
      final t = p.titulo.toLowerCase();
      final d = (p.descripcion ?? '').toLowerCase();
      return t.contains(cleanQuery) || d.contains(cleanQuery);
    }).toList();

    final clasesFiltradas = todasClases.where((c) {
      final n = c.nombre.toLowerCase();
      final a = (c.aula ?? '').toLowerCase();
      final dia = c.diaNombre.toLowerCase();
      return n.contains(cleanQuery) || a.contains(cleanQuery) || dia.contains(cleanQuery);
    }).toList();

    if (pendientesFiltrados.isEmpty && clasesFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 54,
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              'No se encontraron coincidencias para "$query"',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (clasesFiltradas.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.school_rounded, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Clases encontradas (${clasesFiltradas.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          ...clasesFiltradas.map((c) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFEDF2F7)),
              ),
              child: ListTile(
                leading: Container(
                  width: 10,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                title: Text(
                  c.nombre,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${c.diaNombre} · ${c.horarioFormateado} hs${c.aula != null ? " · ${c.aula}" : ""}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DetalleClaseScreen(clase: c),
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        if (pendientesFiltrados.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.checklist_rounded, size: 18, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(
                  'Tareas encontradas (${pendientesFiltrados.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          ...pendientesFiltrados.map((p) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFEDF2F7)),
              ),
              child: ListTile(
                leading: Checkbox(
                  value: p.estaCompletado,
                  activeColor: primaryColor,
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
                  '📅 ${DateTimeUtils.formatFullDate(p.fecha)} · ${DateTimeUtils.formatTime(p.hora)} hs',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
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
        ],
      ],
    );
  }
}
