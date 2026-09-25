import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/providers/notification_providers.dart';
import 'package:mi_pendiente/core/theme/tema_app.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/usecase_providers.dart';
import 'package:mi_pendiente/core/constants/app_sounds.dart';
import '../providers/ajustes_provider.dart';
import '../widgets/selector_sonido_dialog.dart';
import 'selector_temas_screen.dart';

class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ajustes = ref.watch(ajustesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final temaActual = TemasDisponibles.obtenerPorId(ajustes.temaId);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Fila 1: Tema claro/oscuro
        _buildSettingCard(
          isDark: isDark,
          primaryColor: primaryColor,
          icon: Icons.palette_outlined,
          title: 'Tema claro/oscuro',
          trailing: _buildThemeToggle(isDark, ref, primaryColor),
          onTap: () => ref.read(ajustesProvider.notifier).alternarTema(!isDark),
        ),
        const SizedBox(height: 12),

        // Fila: Paleta de colores y temas
        _buildSettingCard(
          isDark: isDark,
          primaryColor: primaryColor,
          icon: Icons.color_lens_outlined,
          title: 'Paleta de colores y temas',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: temaActual.colorPrimario,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: temaActual.colorPrimario.withValues(alpha: 0.35),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                temaActual.nombre,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SelectorTemasScreen()),
            );
          },
        ),
        const SizedBox(height: 12),

        // Fila 2: Notificaciones
        _buildSettingCard(
          isDark: isDark,
          primaryColor: primaryColor,
          icon: Icons.notifications_none_rounded,
          title: 'Notificaciones',
          trailing: Switch(
            value: ajustes.notificaciones,
            activeColor: primaryColor,
            onChanged: (val) async {
              ref.read(ajustesProvider.notifier).alternarNotificaciones(val);
              final scheduler = ref.read(notificationSchedulerProvider);
              if (val) {
                await scheduler.pedirPermisos();
                if (ajustes.resumenMatutino) {
                  final horaParts = ajustes.horaResumenMatutino.split(':');
                  await ref.read(programarResumenMatutinoProvider)(
                    habilitado: true,
                    hora: int.parse(horaParts[0]),
                    minuto: int.parse(horaParts[1]),
                  );
                }
              } else {
                await scheduler.cancelarTodas();
              }
            },
          ),
        ),
        const SizedBox(height: 12),

        // Fila 2.1: Resumen matutino diario ("Tu Plan de Hoy")
        _buildSettingCard(
          isDark: isDark,
          primaryColor: primaryColor,
          icon: Icons.wb_sunny_outlined,
          title: 'Resumen matutino diario\n("Tu Plan de Hoy")',
          trailing: Switch(
            value: ajustes.resumenMatutino && ajustes.notificaciones,
            activeColor: primaryColor,
            onChanged: ajustes.notificaciones
                ? (val) async {
                    await ref.read(ajustesProvider.notifier).alternarResumenMatutino(val);
                    final horaParts = ajustes.horaResumenMatutino.split(':');
                    await ref.read(programarResumenMatutinoProvider)(
                      habilitado: val,
                      hora: int.parse(horaParts[0]),
                      minuto: int.parse(horaParts[1]),
                    );
                  }
                : null,
          ),
        ),
        const SizedBox(height: 12),

        // Fila 2.2: Hora del resumen matutino
        if (ajustes.resumenMatutino && ajustes.notificaciones) ...[
          _buildSettingCard(
            isDark: isDark,
            primaryColor: primaryColor,
            icon: Icons.alarm_rounded,
            title: 'Hora del resumen matutino',
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: ajustes.horaResumenMatutino,
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                items: const [
                  DropdownMenuItem(value: '06:30', child: Text('06:30 AM')),
                  DropdownMenuItem(value: '07:00', child: Text('07:00 AM')),
                  DropdownMenuItem(value: '07:30', child: Text('07:30 AM')),
                  DropdownMenuItem(value: '08:00', child: Text('08:00 AM')),
                  DropdownMenuItem(value: '08:30', child: Text('08:30 AM')),
                  DropdownMenuItem(value: '09:00', child: Text('09:00 AM')),
                  DropdownMenuItem(value: '09:30', child: Text('09:30 AM')),
                  DropdownMenuItem(value: '10:00', child: Text('10:00 AM')),
                ],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
                onChanged: (val) async {
                  if (val != null) {
                    await ref.read(ajustesProvider.notifier).cambiarHoraResumenMatutino(val);
                    final horaParts = val.split(':');
                    await ref.read(programarResumenMatutinoProvider)(
                      habilitado: true,
                      hora: int.parse(horaParts[0]),
                      minuto: int.parse(horaParts[1]),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Fila 3: Sonido
        _buildSettingCard(
          isDark: isDark,
          primaryColor: primaryColor,
          icon: Icons.volume_up_outlined,
          title: 'Sonido',
          trailing: Switch(
            value: ajustes.sonido,
            activeColor: primaryColor,
            onChanged: (val) {
              ref.read(ajustesProvider.notifier).alternarSonido(val);
            },
          ),
        ),
        const SizedBox(height: 12),

        // Fila 4: Vibración
        _buildSettingCard(
          isDark: isDark,
          primaryColor: primaryColor,
          icon: Icons.vibration_rounded,
          title: 'Vibración',
          trailing: Switch(
            value: ajustes.vibracion,
            activeColor: primaryColor,
            onChanged: (val) {
              ref.read(ajustesProvider.notifier).alternarVibracion(val);
            },
          ),
        ),
        const SizedBox(height: 12),

        // Fila 4.1: Sonido para Pendientes
        if (ajustes.sonido) ...[
          _buildSettingCard(
            isDark: isDark,
            primaryColor: primaryColor,
            icon: Icons.notifications_active_rounded,
            title: 'Sonido para Pendientes',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ajustes.sonidoPendientesNombre.isNotEmpty
                      ? ajustes.sonidoPendientesNombre
                      : SonidosDisponibles.obtenerPorId(ajustes.sonidoPendientes).nombre,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
              ],
            ),
            onTap: () {
              SelectorSonidoDialog.mostrar(
                context: context,
                sonidoActualId: ajustes.sonidoPendientes,
                tipo: 'pendiente',
                vibracionActiva: ajustes.vibracion,
                onSonidoSeleccionado: (nuevoId, [nombre]) {
                  ref.read(ajustesProvider.notifier).cambiarSonidoPendientes(nuevoId, nombre);
                },
              );
            },
          ),
          const SizedBox(height: 12),

          // Fila 4.2: Sonido para Horario de Clases
          _buildSettingCard(
            isDark: isDark,
            primaryColor: primaryColor,
            icon: Icons.school_rounded,
            title: 'Sonido para Horario (Clases)',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ajustes.sonidoClasesNombre.isNotEmpty
                      ? ajustes.sonidoClasesNombre
                      : SonidosDisponibles.obtenerPorId(ajustes.sonidoClases).nombre,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
              ],
            ),
            onTap: () {
              SelectorSonidoDialog.mostrar(
                context: context,
                sonidoActualId: ajustes.sonidoClases,
                tipo: 'clase',
                vibracionActiva: ajustes.vibracion,
                onSonidoSeleccionado: (nuevoId, [nombre]) {
                  ref.read(ajustesProvider.notifier).cambiarSonidoClases(nuevoId, nombre);
                },
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        // Fila 5: Hora predeterminada de recordatorio
        _buildSettingCard(
          isDark: isDark,
          primaryColor: primaryColor,
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
          primaryColor: primaryColor,
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
          primaryColor: primaryColor,
          icon: Icons.delete_outline_rounded,
          title: 'Eliminar completados',
          trailing: Switch(
            value: ajustes.eliminarCompletados,
            activeColor: primaryColor,
            onChanged: (val) {
              ref.read(ajustesProvider.notifier).alternarEliminarCompletados(val);
            },
          ),
        ),
        const SizedBox(height: 12),

        // Fila 8: Acerca de la aplicación
        _buildSettingCard(
          isDark: isDark,
          primaryColor: primaryColor,
          icon: Icons.info_outline_rounded,
          title: 'Acerca de la aplicación',
          trailing: const Icon(
            Icons.chevron_right,
            color: Color(0xFF94A3B8),
            size: 22,
          ),
          onTap: () => _mostrarAcercaDe(context, primaryColor),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildThemeToggle(bool isDark, WidgetRef ref, Color primaryColor) {
    return GestureDetector(
      onTap: () => ref.read(ajustesProvider.notifier).alternarTema(!isDark),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: !isDark ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.wb_sunny_rounded,
                size: 16,
                color: !isDark ? Colors.white : const Color(0xFF737373),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.nightlight_round,
                size: 16,
                color: isDark ? Colors.white : const Color(0xFF737373),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required bool isDark,
    required Color primaryColor,
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
              Icon(icon, color: primaryColor, size: 24),
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

  void _mostrarAcercaDe(BuildContext context, Color primaryColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: primaryColor),
            const SizedBox(width: 10),
            const Text('Zendae', style: TextStyle(fontWeight: FontWeight.w700)),
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
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
