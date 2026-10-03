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
    return valor;
  }

  void _seleccionarOpcion(String opcion) {
    setState(() => _seleccion = opcion);
    widget.onSeleccionado(opcion);
    Navigator.of(context).pop();
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

            // TARJETA ÚNICA (Una vez, Diariamente, Lun a Vie)
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
}
