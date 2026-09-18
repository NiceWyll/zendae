import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/providers/notification_providers.dart';
import '../providers/ajustes_provider.dart';

class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ajustes = ref.watch(ajustesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Fila 1: Tema claro/oscuro
        _buildSettingCard(
          isDark: isDark,
          icon: Icons.palette_outlined,
          title: 'Tema claro/oscuro',
          trailing: _buildThemeToggle(isDark, ref),
        ),
        const SizedBox(height: 12),

        // Fila 2: Notificaciones
        _buildSettingCard(
          isDark: isDark,
          icon: Icons.notifications_none_rounded,
          title: 'Notificaciones',
          trailing: Switch(
            value: ajustes.notificaciones,
            activeColor: AppColors.primary,
            onChanged: (val) async {
              ref.read(ajustesProvider.notifier).alternarNotificaciones(val);
              final scheduler = ref.read(notificationSchedulerProvider);
              if (val) {
                await scheduler.pedirPermisos();
              } else {
                await scheduler.cancelarTodas();
              }
            },
          ),
        ),
        const SizedBox(height: 12),

        // Fila 3: Sonido
        _buildSettingCard(
          isDark: isDark,
          icon: Icons.volume_up_outlined,
          title: 'Sonido',
          trailing: Switch(
            value: ajustes.sonido,
            activeColor: AppColors.primary,
            onChanged: (val) {
              ref.read(ajustesProvider.notifier).alternarSonido(val);
            },
          ),
        ),
        const SizedBox(height: 12),

        // Fila 4: Vibración
        _buildSettingCard(
          isDark: isDark,
          icon: Icons.vibration_rounded,
          title: 'Vibración',
          trailing: Switch(
            value: ajustes.vibracion,
            activeColor: AppColors.primary,
            onChanged: (val) {
              ref.read(ajustesProvider.notifier).alternarVibracion(val);
            },
          ),
        ),
        const SizedBox(height: 12),

        // Fila 5: Hora predeterminada de recordatorio
        _buildSettingCard(
          isDark: isDark,
          icon: Icons.access_time_rounded,
          title: 'Hora predeterminada\nde recordatorio',
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: ajustes.horaPredeterminada,
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
              items: const [
                DropdownMenuItem(value: '08:00', child: Text('08:00')),
                DropdownMenuItem(value: '09:00', child: Text('09:00')),
                DropdownMenuItem(value: '10:00', child: Text('10:00')),
                DropdownMenuItem(value: '12:00', child: Text('12:00')),
                DropdownMenuItem(value: '18:00', child: Text('18:00')),
              ],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              onChanged: (val) {
                if (val != null) {
                  ref.read(ajustesProvider.notifier).cambiarHoraPredeterminada(val);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Fila 6: Primer día de la semana
        _buildSettingCard(
          isDark: isDark,
          icon: Icons.calendar_month_outlined,
          title: 'Primer día de la semana',
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: ajustes.primerDiaSemana,
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
              items: const [
                DropdownMenuItem(value: 'Lunes', child: Text('Lunes')),
                DropdownMenuItem(value: 'Domingo', child: Text('Domingo')),
                DropdownMenuItem(value: 'Sábado', child: Text('Sábado')),
              ],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              onChanged: (val) {
                if (val != null) {
                  ref.read(ajustesProvider.notifier).cambiarPrimerDiaSemana(val);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Fila 7: Eliminar completados
        _buildSettingCard(
          isDark: isDark,
          icon: Icons.delete_outline_rounded,
          title: 'Eliminar completados',
          trailing: Switch(
            value: ajustes.eliminarCompletados,
            activeColor: AppColors.primary,
            onChanged: (val) {
              ref.read(ajustesProvider.notifier).alternarEliminarCompletados(val);
            },
          ),
        ),
        const SizedBox(height: 12),

        // Fila 8: Acerca de la aplicación
        _buildSettingCard(
          isDark: isDark,
          icon: Icons.info_outline_rounded,
          title: 'Acerca de la aplicación',
          trailing: const Icon(
            Icons.chevron_right,
            color: Color(0xFF94A3B8),
            size: 22,
          ),
          onTap: () => _mostrarAcercaDe(context),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildThemeToggle(bool isDark, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => ref.read(ajustesProvider.notifier).alternarTema(false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: !isDark ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.wb_sunny_rounded,
                size: 16,
                color: !isDark ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(ajustesProvider.notifier).alternarTema(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.nightlight_round,
                size: 16,
                color: isDark ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEDF2F7),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarAcercaDe(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Mi Pendiente', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versión 1.0.0 (MVP)'),
            SizedBox(height: 8),
            Text('Aplicación móvil de organización personal simple e intuitiva.'),
            SizedBox(height: 12),
            Text(
              'Construida con Flutter, Clean Architecture y Riverpod para Android e iOS.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
