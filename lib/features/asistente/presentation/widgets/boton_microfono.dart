import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/features/racha/domain/entities/hito_racha.dart';
import 'package:mi_pendiente/features/racha/presentation/providers/racha_provider.dart';

class BotonMicrofono extends ConsumerWidget {
  final ValueChanged<String>? onTextoReconocido;

  const BotonMicrofono({
    super.key,
    this.onTextoReconocido,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rachaAsync = ref.watch(rachaNotifierProvider);
    final racha = rachaAsync.valueOrNull;

    final dias = racha?.diasActuales ?? 0;
    final vozDesbloqueada = dias >= 50 ||
        (racha?.logrosDesbloqueados.contains(HitoRacha.dias50.name) ?? false);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          if (vozDesbloqueada) {
            _iniciarEscucha(context);
          } else {
            _mostrarDialogoBloqueo(context, dias);
          }
        },
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: vozDesbloqueada
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(
              color: vozDesbloqueada
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
          ),
          child: Icon(
            vozDesbloqueada ? Icons.mic_rounded : Icons.lock_outline_rounded,
            color: vozDesbloqueada ? AppColors.primary : const Color(0xFF94A3B8),
            size: 20,
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoBloqueo(BuildContext context, int diasLlevados) {
    final faltan = 50 - diasLlevados;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          title: const Row(
            children: [
              Text('🎙️', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Asistente por Voz',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Desbloquea el micrófono al llegar a 50 días de racha consecutiva.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Llevas $diasLlevados de 50 días (${faltan > 0 ? 'te faltan $faltan' : '¡casi listo!'}).\n\n'
                '¡Completa tus pendientes cada día para mantener encendida la llama y desbloquear el comando por voz!',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('¡Entendido! 💪', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _iniciarEscucha(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic_rounded, color: AppColors.primary, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Dictado por Voz Activo 🎙️',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Di lo que deseas programar en lenguaje natural...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onTextoReconocido?.call('Recuérdame reunión con el equipo mañana a las 10am');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Insertar dictado de ejemplo',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
