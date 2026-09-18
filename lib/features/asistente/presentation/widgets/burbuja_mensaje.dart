import 'package:flutter/material.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import '../../domain/entities/mensaje_chat.dart';

class BurbujaMensaje extends StatelessWidget {
  final MensajeChat mensaje;
  final VoidCallback? onVerPendiente;

  const BurbujaMensaje({
    super.key,
    required this.mensaje,
    this.onVerPendiente,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final esUsuario = mensaje.esUsuario;

    final horaFormateada =
        '${mensaje.fecha.hour.toString().padLeft(2, '0')}:${mensaje.fecha.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!esUsuario) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.76,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: esUsuario
                    ? AppColors.primary
                    : (mensaje.esError
                        ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB))
                        : (isDark ? AppColors.cardDark : Colors.white)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(esUsuario ? 18 : 4),
                  bottomRight: Radius.circular(esUsuario ? 4 : 18),
                ),
                border: esUsuario
                    ? null
                    : Border.all(
                        color: mensaje.esError
                            ? const Color(0xFFF59E0B)
                            : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mensaje.texto,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                      color: esUsuario
                          ? Colors.white
                          : (mensaje.esError
                              ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E))
                              : (isDark ? Colors.white : AppColors.textPrimary)),
                    ),
                  ),
                  if (mensaje.pendienteCreadoId != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF059669).withValues(alpha: 0.2) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF059669).withValues(alpha: 0.45) : const Color(0xFFA7F3D0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Tarea agregada: ${mensaje.tituloPendienteCreado ?? 'Pendiente'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      horaFormateada,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: esUsuario
                            ? Colors.white70
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
