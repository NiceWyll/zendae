import 'package:flutter/material.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/constants/app_sounds.dart';
import 'package:mi_pendiente/core/services/notification_service.dart';

class SelectorSonidoDialog extends StatelessWidget {
  final String sonidoActualId;
  final String tipo; // 'pendiente' o 'clase'
  final bool vibracionActiva;
  final ValueChanged<String> onSonidoSeleccionado;

  const SelectorSonidoDialog({
    super.key,
    required this.sonidoActualId,
    required this.tipo,
    required this.vibracionActiva,
    required this.onSonidoSeleccionado,
  });

  static Future<void> mostrar({
    required BuildContext context,
    required String sonidoActualId,
    required String tipo,
    required bool vibracionActiva,
    required ValueChanged<String> onSonidoSeleccionado,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => SelectorSonidoDialog(
        sonidoActualId: sonidoActualId,
        tipo: tipo,
        vibracionActiva: vibracionActiva,
        onSonidoSeleccionado: onSonidoSeleccionado,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final esClase = tipo == 'clase';

    return AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: esClase
                  ? const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.15)
                  : primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              esClase ? Icons.school_rounded : Icons.notifications_active_rounded,
              color: esClase ? const Color(0xFF8B5CF6) : primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esClase ? 'Sonido de Clases' : 'Sonido de Pendientes',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Elige un tono distintivo para esta alerta',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: SonidosDisponibles.lista.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
          ),
          itemBuilder: (context, index) {
            final sonido = SonidosDisponibles.lista[index];
            final esSeleccionado = sonido.id == sonidoActualId;

            return InkWell(
              onTap: () {
                onSonidoSeleccionado(sonido.id);
                // Probar el sonido inmediatamente
                NotificationServiceImpl.instance.probarSonido(
                  soundId: sonido.id,
                  tipo: tipo,
                  vibracion: vibracionActiva,
                );
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    // Radio button indicador
                    Icon(
                      esSeleccionado
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: esSeleccionado ? primaryColor : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    const SizedBox(width: 10),

                    // Icono del tono
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: esSeleccionado
                            ? primaryColor.withValues(alpha: 0.15)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        sonido.icono,
                        color: esSeleccionado ? primaryColor : const Color(0xFF64748B),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Nombre y descripción
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sonido.nombre,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: esSeleccionado ? FontWeight.w700 : FontWeight.w500,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            sonido.descripcion,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botón para probar/escuchar sonido
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, size: 20),
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      tooltip: 'Escuchar prueba',
                      onPressed: () {
                        NotificationServiceImpl.instance.probarSonido(
                          soundId: sonido.id,
                          tipo: tipo,
                          vibracion: vibracionActiva,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cerrar',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
