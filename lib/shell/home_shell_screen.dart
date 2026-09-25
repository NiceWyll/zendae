import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/utils/date_time_utils.dart';
import 'package:mi_pendiente/core/widgets/buscador_global_delegate.dart';
import 'package:mi_pendiente/core/widgets/segmented_view_tabs.dart';
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
import 'package:mi_pendiente/features/asistente/presentation/screens/chat_screen.dart';
import 'package:mi_pendiente/features/horario/presentation/screens/horario_screen.dart';
import 'package:mi_pendiente/features/calendario_general/presentation/screens/calendario_general_screen.dart';

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
    final hoyList = ref.watch(pendientesDeHoyProvider).valueOrNull ?? [];
    final mostrarFab = _bottomNavIndex == 1 || (_bottomNavIndex == 0 && hoyList.isNotEmpty);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      // Drawer lateral interactivo (Menú de las 3 rayitas)
      drawer: _buildAppDrawer(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior de la aplicación con Menú y Campanita
            _buildAppBar(isDark),

            // Selector de pestañas (Hoy | Semana | Mes) solo cuando estamos en la pestaña 'Pendientes'
            if (_bottomNavIndex == 0) ...[
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

      // Botón flotante (+) para crear nuevo pendiente (oculto en pantalla vacía para no duplicar botón)
      floatingActionButton: mostrarFab
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
                backgroundColor: Theme.of(context).primaryColor,
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

  Widget _buildAppBar(bool isDark) {
    String title = 'Mis pendientes';
    if (_bottomNavIndex == 1) title = 'Calendario';
    if (_bottomNavIndex == 2) title = 'Completados';
    if (_bottomNavIndex == 3) title = 'Ajustes';

    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Lado izquierdo: Botón de las 3 rayitas + Título agrupados
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (ctx) => InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Icon(Icons.menu_rounded, color: primaryColor, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          // Lado derecho: Racha y Botón '✨ IA' (sin campanita, con espacio de sobra)
          Row(
            children: [
              const BannerRachaChip(compacto: true),
              const SizedBox(width: 4),

              // Buscador de texto (Requisito 8: ícono de lupa)
              IconButton(
                icon: Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                ),
                tooltip: 'Buscar en tareas y clases',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: BuscadorGlobalDelegate(ref: ref),
                  );
                },
              ),
              const SizedBox(width: 8),

              // Botón estilizado '✨ IA'
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChatScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.12),
                        const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.25 : 0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.45 : 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 15),
                      SizedBox(width: 4),
                      Text(
                        'IA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Menú Drawer Lateral
  Widget _buildAppDrawer(bool isDark) {
    final primaryColor = Theme.of(context).primaryColor;
    final paddingTop = MediaQuery.of(context).padding.top;

    return Drawer(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      child: Column(
        children: [
          // Espacio limpio superior que respeta la barra de estado del sistema
          SizedBox(height: paddingTop + 10),

          // Tarjeta cabecera estilizada con borde redondeado y límite superior claro
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B0F19), Color(0xFF162032)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF162032).withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/icons/logo_main.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Zendae',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tu día con absoluta claridad',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Tarjetas de métricas rápidas con Consumer localizado
          Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer(
              builder: (context, ref, _) {
                final pendientes = ref.watch(pendientesProvider).valueOrNull ?? const <Pendiente>[];
                final pendientesActivos = pendientes.where((p) => !p.estaCompletado).length;
                final completados = pendientes.where((p) => p.estaCompletado).length;

                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$pendientesActivos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Activos',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
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
                          color: isDark
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$completados',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF34D399) : AppColors.priorityBaja,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Completos',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
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
                              color: isDark
                                  ? const Color(0xFFF97316).withValues(alpha: 0.2)
                                  : const Color(0xFFFFF7ED),
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
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Racha',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          Divider(height: 1, color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9)),

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
                  icon: Icons.calendar_view_week_rounded,
                  label: 'Horario',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HorarioScreen(),
                      ),
                    );
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
                  icon: Icons.auto_awesome_rounded,
                  label: 'Asistente IA ✨',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChatScreen(),
                      ),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final reminderCount = ref.watch(
                      pendientesProvider.select(
                        (asyncP) => asyncP.valueOrNull
                                ?.where((p) => p.tieneRecordatorio && !p.estaCompletado)
                                .length ??
                            0,
                      ),
                    );
                    return ListTile(
                      leading: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF64748B),
                      ),
                      title: const Text(
                        'Recordatorios',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: reminderCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.priorityAlta,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$reminderCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () {
                        Navigator.pop(context);
                        final pendientes = ref.read(pendientesProvider).valueOrNull ?? const <Pendiente>[];
                        _mostrarModalNotificaciones(context, pendientes);
                      },
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
                      backgroundColor: primaryColor,
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
              'Zendae · v1.0.0',
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
    final primaryColor = Theme.of(context).primaryColor;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryColor : const Color(0xFF64748B),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? primaryColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B)),
        ),
      ),
      tileColor: isSelected ? primaryColor.withValues(alpha: 0.12) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
    );
  }

  // Modal de la Campanita de Notificaciones
  void _mostrarModalNotificaciones(BuildContext context, List<Pendiente> pendientes) {
    final conRecordatorio = pendientes
        .where((p) => p.tieneRecordatorio && !p.estaCompletado)
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
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
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
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
                      color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.notifications_active_rounded, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Recordatorios Activos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (conRecordatorio.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'No tienes recordatorios pendientes.',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        fontSize: 14,
                      ),
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
                          color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                          ),
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${DateTimeUtils.formatFullDate(item.fecha)} a las ${DateTimeUtils.formatTime(item.hora)} (${item.minutosAntes} min antes)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                    ),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentView() {
    Widget view;
    switch (_bottomNavIndex) {
      case 0: // Pendientes (Hoy / Semana / Mes)
        switch (_topTabIndex) {
          case 0:
            view = const HoyScreen(key: ValueKey('hoy'));
          case 1:
            view = const SemanaScreen(key: ValueKey('semana'));
          case 2:
            view = const MesScreen(key: ValueKey('mes'));
          default:
            view = const HoyScreen(key: ValueKey('hoy_default'));
        }
      case 1: // Calendario general de la app (todo en conjunto: pendientes + horario con filtros)
        view = const CalendarioGeneralScreen(key: ValueKey('calendario_general'));
      case 2: // Completados
        view = const CompletadosScreen(key: ValueKey('completados'));
      case 3: // Ajustes
        view = const AjustesScreen(key: ValueKey('ajustes'));
      default:
        view = const HoyScreen(key: ValueKey('hoy_fallback'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: view,
    );
  }
}
