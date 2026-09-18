import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../domain/entities/pendiente.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

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
  Future<bool> pedirPermisos() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestNotificationsPermission() ?? false;
          // Opcionalmente pedir permiso de alarmas exactas en Android 14+
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
        ticker: 'Recordatorio de Mi Pendiente',
        category: AndroidNotificationCategory.reminder,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          cuerpo,
          contentTitle: titulo,
          summaryText: 'Mi Pendiente',
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

  /// Agenda un recordatorio programado según la fecha y hora del pendiente
  Future<void> programarRecordatorio(Pendiente pendiente) async {
    if (!pendiente.tieneRecordatorio) return;

    try {
      final int notifId = pendiente.id.hashCode & 0x7fffffff;

      // Calcular fecha y hora de la alerta (restando minutosAntes)
      final scheduledDate = pendiente.fechaHoraCompleta.subtract(
        Duration(minutes: pendiente.minutosAntes),
      );

      final now = DateTime.now();
      if (scheduledDate.isBefore(now)) {
        // Si el tiempo del recordatorio ya pasó, pero la hora de la tarea aún está en el futuro
        if (pendiente.fechaHoraCompleta.isAfter(now)) {
          // Programar para la hora exacta
          await _agendarZoned(
            id: notifId,
            titulo: '⏰ ¡Tienes un pendiente ahora!',
            cuerpo: '${pendiente.titulo}${pendiente.descripcion != null ? ' - ${pendiente.descripcion}' : ''}',
            date: tz.TZDateTime.from(pendiente.fechaHoraCompleta, tz.local),
            payload: pendiente.id,
          );
        }
        return;
      }

      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
      final String aviso = pendiente.minutosAntes > 0
          ? 'En ${pendiente.minutosAntes} minutos: ${pendiente.titulo}'
          : '¡Es hora de: ${pendiente.titulo}!';

      await _agendarZoned(
        id: notifId,
        titulo: '🔔 Recordatorio de Pendiente',
        cuerpo: aviso,
        date: tzDate,
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

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
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
      // Si el sistema no permite alarmas exactas, programar con inexactAllowWhileIdle
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

  /// Cancela la notificación de un pendiente específico
  Future<void> cancelarRecordatorio(String pendienteId) async {
    try {
      final int notifId = pendienteId.hashCode & 0x7fffffff;
      await _plugin.cancel(id: notifId);
      debugPrint('🗑️ Recordatorio cancelado para ID: $pendienteId');
    } catch (e) {
      debugPrint('⚠️ Error al cancelar recordatorio: $e');
    }
  }

  /// Cancela todas las notificaciones pendientes
  Future<void> cancelarTodas() async {
    try {
      await _plugin.cancelAll();
      debugPrint('🗑️ Todas las notificaciones fueron canceladas');
    } catch (e) {
      debugPrint('⚠️ Error al cancelar todas las notificaciones: $e');
    }
  }
}
