import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Selector de hora moderno estilo alarma con ruedas CupertinoPicker y selector AM/PM.
/// Reutilizable en Pendientes, Horario y cualquier pantalla de la app.
class AlarmaTimePickerSheet extends StatefulWidget {
  final TimeOfDay horaInicial;
  final bool isDark;
  final ValueChanged<TimeOfDay> onHoraConfirmada;

  const AlarmaTimePickerSheet({
    super.key,
    required this.horaInicial,
    required this.isDark,
    required this.onHoraConfirmada,
  });

  /// Muestra el bottom sheet de selección de hora y retorna la hora seleccionada o null si se cancela.
  static Future<TimeOfDay?> mostrar(
    BuildContext context, {
    required TimeOfDay horaInicial,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    TimeOfDay? resultado;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return AlarmaTimePickerSheet(
          horaInicial: horaInicial,
          isDark: isDark,
          onHoraConfirmada: (nuevaHora) {
            resultado = nuevaHora;
          },
        );
      },
    );

    return resultado;
  }

  @override
  State<AlarmaTimePickerSheet> createState() => _AlarmaTimePickerSheetState();
}

class _AlarmaTimePickerSheetState extends State<AlarmaTimePickerSheet> {
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
                onPressed: () {
                  final horaElegida = TimeOfDay(
                    hour: _hour24,
                    minute: _selectedMinute,
                  );
                  widget.onHoraConfirmada(horaElegida);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check_rounded, color: Colors.white),
                label: const Text(
                  'Confirmar hora',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
