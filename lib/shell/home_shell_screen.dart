import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/utils/date_time_utils.dart';
import 'package:mi_pendiente/core/widgets/segmented_view_tabs.dart';
import 'package:mi_pendiente/core/widgets/wave_background.dart';
import 'package:mi_pendiente/core/providers/notification_providers.dart';
import 'package:mi_pendiente/features/pendientes/presentation/providers/pendientes_provider.dart';
import 'package:mi_pendiente/features/pendientes/presentation/mappers/prioridad_ui.dart';
import 'package:mi_pendiente/features/pendientes/presentation/screens/hoy_screen.dart';
import 'package:mi_pendiente/features/pendientes/presentation/screens/semana_screen.dart';
import 'package:mi_pendiente/features/pendientes/presentation/screens/mes_screen.dart';
import 'package:mi_pendiente/features/pendientes/presentation/screens/nuevo_pendiente_screen.dart';
import 'package:mi_pendiente/features/completados/presentation/screens/completados_screen.dart';
import 'package:mi_pendiente/features/ajustes/presentation/screens/ajustes_screen.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/racha/domain/entities/racha.dart';
import 'package:mi_pendiente/features/racha/presentation/widgets/banner_racha.dart';
import 'package:mi_pendiente/features/racha/presentation/screens/mis_logros_screen.dart';
import 'package:mi_pendiente/features/racha/presentation/providers/racha_provider.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _bottomNavIndex = 0; // 0: Pendientes, 1: Calendario, 2: Completados, 3: Ajustes
  int _topTabIndex = 0;    // 0: Hoy, 1: Semana, 2: Mes
  bool _mostroBannerInicial = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_mostroBannerInicial) {
      _mostroBannerInicial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final racha = ref.read(rachaNotifierProvider).valueOrNull;
        if (racha != null) {
          _mostrarBannerBienvenidaRacha(racha);
        }
      });
    }
  }

  void _mostrarBannerBienvenidaRacha(Racha racha) {
    final dias = racha.diasActuales;
    final mensaje = dias > 0
        ? '🔥 ¡Llevas $dias ${dias == 1 ? 'día' : 'días'} de racha activa!'
        : '💪 ¡Empecemos de nuevo! Completa un pendiente hoy';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 2000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: dias > 0 ? const Color(0xFFFF5722) : const Color(0xFF1E293B),
        content: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncPendientes = ref.watch(pendientesProvider);
    final pendientes = asyncPendientes.valueOrNull ?? const <Pendiente>[];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      // Drawer lateral interactivo (Menú de las 3 rayitas)
      drawer: _buildAppDrawer(isDark, pendientes),
      body: Stack(
        children: [
          // Ondas decorativas en la parte inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: WaveBackground(
              height: 120,
              isDark: isDark,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Barra superior de la aplicación con Menú y Campanita
                _buildAppBar(isDark, pendientes),

                // Selector de pestañas (Hoy | Semana | Mes) solo cuando estamos en la pestaña 'Pendientes'
                if (_bottomNavIndex == 0) ...[
                  const BannerRachaMotivacional(),
                  SegmentedViewTabs(
                    selectedIndex: _topTabIndex,
                    onTabSelected: (index) {
                      setState(() {
                        _topTabIndex = index;
                      });
                    },
                  ),
                ],

                // Contenido principal según la pestaña activa
                Expanded(
                  child: _buildCurrentView(),
                ),
              ],
            ),
          ),
        ],
      ),

      // Botón flotante (+) para crear nuevo pendiente
      floatingActionButton: (_bottomNavIndex == 0 || _bottomNavIndex == 1)
          ? Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NuevoPendienteScreen(),
                    ),
                  );
                },
                backgroundColor: AppColors.primary,
                elevation: 4,
                child: const Icon(Icons.add, size: 28, color: Colors.white),
              ),
            )
          : null,

      // Barra de navegación inferior limpia (Pendientes, Calendario, Completados, Ajustes)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : const Color(0xFFEDF2F7),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTap: (index) {
            setState(() {
              _bottomNavIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Pendientes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Calendario',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.check_circle),
              label: 'Completados',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark, List<Pendiente> pendientes) {
    String title = 'Mis pendientes';
    if (_bottomNavIndex == 1) title = 'Calendario';
    if (_bottomNavIndex == 2) title = 'Completados';
    if (_bottomNavIndex == 3) title = 'Ajustes';

    // Contar tareas que tienen recordatorio activo
    final reminderCount = pendientes.where((p) => p.tieneRecordatorio && !p.estaCompletado).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón de las 3 rayitas (Abre el Drawer lateral)
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.primary, size: 28),
              onPressed: () {
                Scaffold.of(ctx).openDrawer();
              },
              tooltip: 'Menú principal',
            ),
          ),

          // Título central
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BannerRachaChip(compacto: true),
              const SizedBox(width: 4),
              // Campanita con badge de notificaciones
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 28),
                    onPressed: () => _mostrarModalNotificaciones(context, pendientes),
                    tooltip: 'Recordatorios',
                  ),
                  if (reminderCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.priorityAlta,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$reminderCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Menú Drawer Lateral
  Widget _buildAppDrawer(bool isDark, List<Pendiente> pendientes) {
    final pendientesActivos = pendientes.where((p) => !p.estaCompletado).length;
    final completados = pendientes.where((p) => p.estaCompletado).length;

    return Drawer(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      child: Column(
        children: [
          // Cabecera estilizada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Mi Pendiente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Organiza tu día, semana y mes',
                  style: TextStyle(
                    color: Color(0xFFDBEAFE),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Tarjetas de métricas rápidas
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBgLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$pendientesActivos',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Activos',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$completados',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.priorityBaja,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Completos',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MisLogrosScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Consumer(
                              builder: (context, ref, _) {
                                final rachaAsync = ref.watch(rachaNotifierProvider);
                                final dias = rachaAsync.valueOrNull?.diasActuales ?? 0;
                                return Text(
                                  '$dias 🔥',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFEA580C),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Racha',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Opciones de navegación del Drawer
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.assignment_outlined,
                  label: 'Mis Pendientes',
                  isSelected: _bottomNavIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _bottomNavIndex = 0);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Vista Calendario',
                  isSelected: _bottomNavIndex == 1,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _bottomNavIndex = 1);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Tareas Completadas',
                  isSelected: _bottomNavIndex == 2,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _bottomNavIndex = 2);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Mis Logros 🔥',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MisLogrosScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Ajustes',
                  isSelected: _bottomNavIndex == 3,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _bottomNavIndex = 3);
                  },
                ),
                const SizedBox(height: 16),
                // Botón directo para crear pendiente
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final nav = Navigator.of(context);
                      nav.pop();
                      nav.push(
                        MaterialPageRoute(
                          builder: (_) => const NuevoPendienteScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Crear pendiente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pie del Drawer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Mi Pendiente · v1.0.0 (MVP)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : const Color(0xFF64748B),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : const Color(0xFF1E293B),
        ),
      ),
      tileColor: isSelected ? AppColors.primaryBgLight : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
    );
  }

  // Modal de la Campanita de Notificaciones
  void _mostrarModalNotificaciones(BuildContext context, List<Pendiente> pendientes) {
    final conRecordatorio = pendientes
        .where((p) => p.tieneRecordatorio && !p.estaCompletado)
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra superior de agarre
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBgLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Recordatorios Activos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (conRecordatorio.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'No tienes recordatorios pendientes.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: conRecordatorio.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = conRecordatorio[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.alarm_rounded, color: item.prioridad.color, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.titulo,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  Text(
                                    '${DateTimeUtils.formatFullDate(item.fecha)} a las ${DateTimeUtils.formatTime(item.hora)} (${item.minutosAntes} min antes)',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.notifications_active_rounded, color: Colors.white),
                  label: const Text(
                    '🔔 Probar notificación ("Ver nubecita")',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onPressed: () async {
                    final notificaciones = ref.read(notificationSchedulerProvider);
                    await notificaciones.pedirPermisos();
                    await notificaciones.mostrarNotificacionInmediata(
                      titulo: '¡Tienes un pendiente programado!',
                      cuerpo: 'Reunión con el equipo - Tienes este pendiente ahora',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🚀 ¡Notificación enviada! Revisa la parte superior de tu pantalla.'),
                          backgroundColor: AppColors.primary,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentView() {
    switch (_bottomNavIndex) {
      case 0: // Pendientes (Hoy / Semana / Mes)
        switch (_topTabIndex) {
          case 0:
            return const HoyScreen();
          case 1:
            return const SemanaScreen();
          case 2:
            return const MesScreen();
          default:
            return const HoyScreen();
        }
      case 1: // Calendario directo
        return const MesScreen();
      case 2: // Completados
        return const CompletadosScreen();
      case 3: // Ajustes
        return const AjustesScreen();
      default:
        return const HoyScreen();
    }
  }
}
