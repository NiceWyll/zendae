import 'package:flutter/material.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';

class SelectorRepeticionSheet extends StatefulWidget {
  final String repeticionActual;
  final ValueChanged<String> onSeleccionado;

  const SelectorRepeticionSheet({
    super.key,
    required this.repeticionActual,
    required this.onSeleccionado,
  });

  static Future<void> mostrar({
    required BuildContext context,
    required String repeticionActual,
    required ValueChanged<String> onSeleccionado,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SelectorRepeticionSheet(
        repeticionActual: repeticionActual,
        onSeleccionado: onSeleccionado,
      ),
    );
  }

  @override
  State<SelectorRepeticionSheet> createState() => _SelectorRepeticionSheetState();
}

class _SelectorRepeticionSheetState extends State<SelectorRepeticionSheet> {
  late String _seleccion;

  @override
  void initState() {
    super.initState();
    _seleccion = _normalizar(widget.repeticionActual);
  }

  String _normalizar(String valor) {
    final v = valor.toLowerCase().trim();
    if (v == 'no repetir' || v == 'una vez') return 'Una vez';
    if (v == 'diario' || v == 'diariamente') return 'Diariamente';
    if (v == 'lun a vie' || v == 'lunes a viernes') return 'Lun a Vie';
    if (v.contains('turno')) return 'Alarmas de turno';
    if (v.contains('personaliz')) return 'Personalizar';
    return valor;
  }

  void _seleccionarOpcion(String opcion) {
    setState(() => _seleccion = opcion);
    widget.onSeleccionado(opcion);
    Navigator.of(context).pop();
  }

  void _abrirAlarmasDeTurno() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final turnos = [
          'Turno Mañana (07:00)',
          'Turno Tarde (15:00)',
          'Turno Noche (23:00)',
          'Turno Rotativo (2x2)',
          'Turno Rotativo (4x2)',
        ];

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2127) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF525866) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Alarmas de turno',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...turnos.map((t) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: const Icon(Icons.work_history_rounded, color: Color(0xFF3B82F6)),
                      title: Text(
                        t,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _seleccionarOpcion('Alarmas de turno');
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirPersonalizar() {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final diasAbrev = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final seleccionados = <int>{0, 1, 2, 3, 4}; // Por defecto L-V

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2127) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF525866) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Personalizar días',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            if (seleccionados.isEmpty) {
                              _seleccionarOpcion('Una vez');
                            } else if (seleccionados.length == 7) {
                              _seleccionarOpcion('Diariamente');
                            } else if (seleccionados.length == 5 &&
                                seleccionados.contains(0) &&
                                seleccionados.contains(1) &&
                                seleccionados.contains(2) &&
                                seleccionados.contains(3) &&
                                seleccionados.contains(4)) {
                              _seleccionarOpcion('Lun a Vie');
                            } else {
                              final lista = seleccionados.toList()..sort();
                              final txt = lista.map((i) => diasAbrev[i]).join(', ');
                              _seleccionarOpcion('Personalizar ($txt)');
                            }
                          },
                          child: const Text(
                            'Aceptar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(7, (idx) {
                      final estaMarcado = seleccionados.contains(idx);
                      return CheckboxListTile(
                        value: estaMarcado,
                        activeColor: const Color(0xFF3B82F6),
                        title: Text(
                          dias[idx],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              seleccionados.add(idx);
                            } else {
                              seleccionados.remove(idx);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1B1E23) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF2B2F38) : Colors.white;
    const accentColor = Color(0xFF3B82F6); // Azul estándar de MIUI / captura 2

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pill / Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF525866) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Encabezado con flecha atrás y título
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    size: 24,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 16),
                Text(
                  'Repetir',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // PRIMERA TARJETA (Captura 2: Una vez, Diariamente, Lun a Vie)
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    _buildOptionItem(
                      titulo: 'Una vez',
                      seleccionado: _seleccion == 'Una vez',
                      isDark: isDark,
                      accentColor: accentColor,
                      onTap: () => _seleccionarOpcion('Una vez'),
                    ),
                    _buildOptionItem(
                      titulo: 'Diariamente',
                      seleccionado: _seleccion == 'Diariamente',
                      isDark: isDark,
                      accentColor: accentColor,
                      onTap: () => _seleccionarOpcion('Diariamente'),
                    ),
                    _buildOptionItem(
                      titulo: 'Lun a Vie',
                      seleccionado: _seleccion == 'Lun a Vie',
                      isDark: isDark,
                      accentColor: accentColor,
                      onTap: () => _seleccionarOpcion('Lun a Vie'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // SEGUNDA TARJETA (Captura 2: Alarmas de turno, Personalizar)
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    _buildNavigationItem(
                      titulo: 'Alarmas de turno',
                      isDark: isDark,
                      onTap: _abrirAlarmasDeTurno,
                    ),
                    _buildNavigationItem(
                      titulo: 'Personalizar',
                      isDark: isDark,
                      onTap: _abrirPersonalizar,
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

  Widget _buildOptionItem({
    required String titulo,
    required bool seleccionado,
    required bool isDark,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            if (seleccionado) ...[
              Icon(
                Icons.check,
                color: accentColor,
                size: 20,
              ),
              const SizedBox(width: 12),
            ] else ...[
              const SizedBox(width: 32),
            ],
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w400,
                  color: seleccionado
                      ? accentColor
                      : (isDark ? Colors.white : AppColors.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required String titulo,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3F444E) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: isDark ? const Color(0xFFB0B5C0) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
