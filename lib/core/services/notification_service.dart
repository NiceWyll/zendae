import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/services/notification_scheduler.dart';

class NotificationServiceImpl implements NotificationScheduler {
  NotificationServiceImpl();

  // Instancia singleton transitoria para retrocompatibilidad
  static final NotificationServiceImpl instance = NotificationServiceImpl();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String channelId = 'mi_pendiente_alarmas';
  static const String channelName = 'Recordatorios de Pendientes';
  static const String channelDesc = 'Alertas flotantes y recordatorios importantes de tus pendientes';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      // 1. Inicializar zonas horarias
      tz.initializeTimeZones();

      // 2. Configuración para Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // 3. Configuración para Darwin / iOS
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('🔔 Notificación interactuada con payload: ${response.payload}');
        },
      );

      // 4. Crear canal de alta prioridad (heads-up / nubecita flotante)
      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          const channel = AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDesc,
            importance: Importance.max, // Máxima prioridad para mostrar banner flotante ("la nubecita")
            playSound: true,
            enableVibration: true,
            showBadge: true,
          );
          await androidPlugin.createNotificationChannel(channel);
        }
      }

      _initialized = true;
      debugPrint('✅ NotificationService inicializado correctamente');
    } catch (e) {
      debugPrint('⚠️ Error al inicializar NotificationService: $e');
    }
  }

  /// Solicitar permisos al usuario (indispensable en Android 13+)
  @override
  Future<bool> pedirPermisos() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestNotificationsPermission() ?? false;
          try {
            await androidPlugin.requestExactAlarmsPermission();
          } catch (_) {}
          return granted;
        }
      } else if (Platform.isIOS) {
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ?? false;
          return granted;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error pidiendo permisos de notificación: $e');
    }
    return false;
  }

  /// Dispara una notificación inmediata de alta prioridad con banner emergente ("la nubecita")
  @override
  Future<void> mostrarNotificacionInmediata({
    int id = 9999,
    required String titulo,
    required String cuerpo,
    String? payload,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        ticker: 'Recordatorio de Zendae',
        category: AndroidNotificationCategory.reminder,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          cuerpo,
          contentTitle: titulo,
          summaryText: 'Zendae',
        ),
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _plugin.show(
        id: id,
        title: titulo,
        body: cuerpo,
        notificationDetails: details,
        payload: payload,
      );
      debugPrint('🚀 Notificación inmediata lanzada exitosamente: $titulo');
    } catch (e) {
      debugPrint('⚠️ Error al mostrar notificación inmediata: $e');
    }
  }

  /// Implementación del contrato NotificationScheduler
  @override
  Future<void> programarRecordatorio({
    required int notificacionId,
    required String titulo,
    required String cuerpo,
    required DateTime cuando,
    String? payload,
  }) async {
    final tzDate = tz.TZDateTime.from(cuando, tz.local);
    await _agendarZoned(
      id: notificacionId,
      titulo: titulo,
      cuerpo: cuerpo,
      date: tzDate,
      payload: payload,
    );
  }

  /// Método de conveniencia para la entidad Pendiente
  @override
  Future<void> programarRecordatorioPendiente(Pendiente pendiente) async {
    if (!pendiente.tieneRecordatorio) return;

    try {
      final int notifId = pendiente.notificacionId ?? (pendiente.id.hashCode & 0x7fffffff);
      final scheduledDate = pendiente.momentoDeAviso;
      final now = DateTime.now();

      if (scheduledDate.isBefore(now)) {
        if (pendiente.fechaHoraCompleta.isAfter(now)) {
          await programarRecordatorio(
            notificacionId: notifId,
            titulo: '⏰ ¡Tienes un pendiente ahora!',
            cuerpo: '${pendiente.titulo}${pendiente.descripcion != null ? ' - ${pendiente.descripcion}' : ''}',
            cuando: pendiente.fechaHoraCompleta,
            payload: pendiente.id,
          );
        }
        return;
      }

      final String aviso = pendiente.minutosAntes > 0
          ? 'En ${pendiente.minutosAntes} minutos: ${pendiente.titulo}'
          : '¡Es hora de: ${pendiente.titulo}!';

      await programarRecordatorio(
        notificacionId: notifId,
        titulo: '🔔 Recordatorio de Pendiente',
        cuerpo: aviso,
        cuando: scheduledDate,
        payload: pendiente.id,
      );
    } catch (e) {
      debugPrint('⚠️ Error al programar recordatorio para pendiente ${pendiente.id}: $e');
    }
  }

  Future<void> _agendarZoned({
    required int id,
    required String titulo,
    required String cuerpo,
    required tz.TZDateTime date,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: titulo,
        body: cuerpo,
        scheduledDate: date,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('📅 Recordatorio programado para: $date (ID: $id)');
    } catch (exactError) {
      debugPrint('⚠️ Intento con inexactAllowWhileIdle por: $exactError');
      await _plugin.zonedSchedule(
        id: id,
        title: titulo,
        body: cuerpo,
        scheduledDate: date,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

  static const int idResumenMatutino = 8888;

  @override
  Future<void> programarResumenDiario({
    required int notificacionId,
    required String titulo,
    required String cuerpo,
    required int hora,
    required int minuto,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hora,
        minuto,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _plugin.zonedSchedule(
        id: notificacionId,
        title: titulo,
        body: cuerpo,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'resumen_matutino',
      );
      debugPrint('🌅 Resumen matutino agendado para $hora:${minuto.toString().padLeft(2, '0')} (ID: $notificacionId)');
    } catch (e) {
      debugPrint('⚠️ Error al programar resumen diario: $e');
    }
  }

  @override
  Future<void> cancelarRecordatorio(int notificacionId) async {
    try {
      await _plugin.cancel(id: notificacionId);
      debugPrint('🗑️ Recordatorio cancelado para notificacionId: $notificacionId');
    } catch (e) {
      debugPrint('⚠️ Error al cancelar recordatorio: $e');
    }
  }

  @override
  Future<void> cancelarRecordatorioPorIdString(String pendienteId) async {
    final int notifId = pendienteId.hashCode & 0x7fffffff;
    await cancelarRecordatorio(notifId);
  }

  @override
  Future<void> cancelarTodas() async {
    try {
      await _plugin.cancelAll();
      debugPrint('🗑️ Todas las notificaciones fueron canceladas');
    } catch (e) {
      debugPrint('⚠️ Error al cancelar todas las notificaciones: $e');
    }
  }
}

// Alias para retrocompatibilidad
typedef NotificationService = NotificationServiceImpl;
