import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:mi_pendiente/core/constants/app_sounds.dart';
import 'package:mi_pendiente/core/services/android_ringtone_service.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/horario/domain/entities/clase.dart';
import 'package:mi_pendiente/features/horario/domain/entities/examen.dart';
import 'package:mi_pendiente/features/pendientes/data/datasources/app_database.dart';
import 'package:mi_pendiente/features/pendientes/domain/services/notification_scheduler.dart';

class NotificationServiceImpl implements NotificationScheduler {
  NotificationServiceImpl();

  // Instancia singleton transitoria para retrocompatibilidad
  static final NotificationServiceImpl instance = NotificationServiceImpl();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String channelId = 'mi_pendiente_alarmas';
  static const String channelName = 'Recordatorios de Pendientes';
  static const String channelDesc = 'Alertas flotantes y recordatorios importantes de tus pendientes';

  static final Int64List _vibrationPattern = Int64List.fromList([0, 500, 250, 500]);

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

      // 4. Crear canales en Android con soporte explícito de sonido y vibración
      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          // Canal general de compatibilidad
          final defaultChannel = AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern: _vibrationPattern,
            showBadge: true,
          );
          await androidPlugin.createNotificationChannel(defaultChannel);

          // Canales dedicados por cada sonido disponible para Pendientes y Clases
          for (final s in SonidosDisponibles.lista) {
            final soundResource = s.id == 'default' ? null : RawResourceAndroidNotificationSound(s.id);

            // Canal para Pendientes
            await androidPlugin.createNotificationChannel(
              AndroidNotificationChannel(
                'canal_pendientes_${s.id}',
                'Pendientes - ${s.nombre}',
                description: 'Recordatorios de pendientes con tono ${s.nombre}',
                importance: Importance.max,
                playSound: true,
                sound: soundResource,
                enableVibration: true,
                vibrationPattern: _vibrationPattern,
                showBadge: true,
              ),
            );

            // Canal para Clases
            await androidPlugin.createNotificationChannel(
              AndroidNotificationChannel(
                'canal_clases_${s.id}',
                'Clases - ${s.nombre}',
                description: 'Avisos de horario de clases con tono ${s.nombre}',
                importance: Importance.max,
                playSound: true,
                sound: soundResource,
                enableVibration: true,
                vibrationPattern: _vibrationPattern,
                showBadge: true,
              ),
            );
          }
        }
      }

      _initialized = true;
      debugPrint('✅ NotificationService inicializado con canales de sonido y vibración');
      await programarAvisoRiesgoRacha();
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

  /// Dispara una notificación inmediata de alta prioridad con banner emergente, sonido y vibración
  @override
  Future<void> mostrarNotificacionInmediata({
    int id = 9999,
    required String titulo,
    required String cuerpo,
    String? payload,
    String? sonido,
    bool vibracion = true,
    String tipo = 'pendiente',
  }) async {
    try {
      final sId = sonido ?? (tipo == 'clase' ? 'zen' : 'campana');
      final bool esUri = sId.startsWith('content://');
      final chId = esUri
          ? (tipo == 'clase' ? 'canal_clases_uri' : 'canal_pendientes_uri')
          : (tipo == 'clase' ? 'canal_clases_$sId' : 'canal_pendientes_$sId');
      final chName = esUri
          ? (tipo == 'clase' ? 'Horario de Clases (Tono del celular)' : 'Recordatorios (Tono del celular)')
          : (tipo == 'clase' ? 'Horario de Clases' : 'Recordatorios de Pendientes');

      final AndroidNotificationSound? soundResource = esUri
          ? UriAndroidNotificationSound(sId)
          : (sId == 'default' ? null : RawResourceAndroidNotificationSound(sId));

      if (esUri && Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(
            AndroidNotificationChannel(
              chId,
              chName,
              description: 'Notificación con tono del celular Android',
              importance: Importance.max,
              playSound: true,
              sound: soundResource,
              enableVibration: vibracion,
              vibrationPattern: vibracion ? _vibrationPattern : null,
              showBadge: true,
            ),
          );
        }
      }

      final androidDetails = AndroidNotificationDetails(
        chId,
        chName,
        channelDescription: 'Notificación con sonido y vibración activa',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: soundResource,
        enableVibration: vibracion,
        vibrationPattern: vibracion ? _vibrationPattern : null,
        ticker: 'Zendae',
        category: AndroidNotificationCategory.reminder,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          cuerpo,
          contentTitle: titulo,
          summaryText: 'Zendae',
        ),
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: sId == 'default' ? null : '$sId.wav',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _plugin.show(
        id: id,
        title: titulo,
        body: cuerpo,
        notificationDetails: details,
        payload: payload,
      );
      debugPrint('🚀 Notificación inmediata lanzada exitosamente con sonido $sId');
    } catch (e) {
      debugPrint('⚠️ Error al mostrar notificación inmediata: $e');
    }
  }

  /// Permite al usuario probar el sonido y vibración desde Ajustes
  @override
  Future<void> probarSonido({
    required String soundId,
    required String tipo,
    bool vibracion = true,
  }) async {
    if (Platform.isAndroid && soundId.startsWith('content://')) {
      await AndroidRingtoneService.playRingtone(soundId);
    }
    final nombreSonido = SonidosDisponibles.obtenerPorId(soundId).nombre;
    final esClase = tipo == 'clase';
    await mostrarNotificacionInmediata(
      id: 7777,
      titulo: esClase ? '🎓 Tono de Clases: $nombreSonido' : '🔔 Tono de Pendientes: $nombreSonido',
      cuerpo: 'Esta es una vista previa del sonido y la vibración configurada.',
      sonido: soundId,
      vibracion: vibracion,
      tipo: tipo,
    );
  }

  /// Implementación del contrato NotificationScheduler
  @override
  Future<void> programarRecordatorio({
    required int notificacionId,
    required String titulo,
    required String cuerpo,
    required DateTime cuando,
    String? payload,
    String? sonido,
    bool vibracion = true,
    String tipo = 'pendiente',
  }) async {
    final tzDate = tz.TZDateTime.from(cuando, tz.local);
    final sId = sonido ?? (tipo == 'clase' ? 'zen' : 'campana');
    final bool esUri = sId.startsWith('content://');
    final chId = esUri
        ? (tipo == 'clase' ? 'canal_clases_uri' : 'canal_pendientes_uri')
        : (tipo == 'clase' ? 'canal_clases_$sId' : 'canal_pendientes_$sId');
    final chName = esUri
        ? (tipo == 'clase' ? 'Horario de Clases (Tono del celular)' : 'Recordatorios (Tono del celular)')
        : (tipo == 'clase' ? 'Horario de Clases' : 'Recordatorios de Pendientes');

    if (esUri && Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            chId,
            chName,
            description: 'Canal para tono del dispositivo Android',
            importance: Importance.max,
            playSound: true,
            sound: UriAndroidNotificationSound(sId),
            enableVibration: vibracion,
            vibrationPattern: vibracion ? _vibrationPattern : null,
            showBadge: true,
          ),
        );
      }
    }

    await _agendarZoned(
      id: notificacionId,
      titulo: titulo,
      cuerpo: cuerpo,
      date: tzDate,
      payload: payload,
      channelId: chId,
      channelName: chName,
      soundId: sId,
      vibracion: vibracion,
    );
  }

  /// Método para la entidad Pendiente con sonido y vibración configurables
  @override
  Future<void> programarRecordatorioPendiente(
    Pendiente pendiente, {
    String? sonido,
    bool vibracion = true,
  }) async {
    if (!pendiente.tieneRecordatorio) return;

    try {
      String soundId = sonido ?? 'campana';
      bool vibra = vibracion;
      try {
        final prefs = await SharedPreferences.getInstance();
        if (sonido == null) {
          soundId = prefs.getString('sonido_pendientes') ?? 'campana';
        }
        vibra = prefs.getBool('vibracion') ?? true;
      } catch (_) {}

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
            sonido: soundId,
            vibracion: vibra,
            tipo: 'pendiente',
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
        sonido: soundId,
        vibracion: vibra,
        tipo: 'pendiente',
      );
    } catch (e) {
      debugPrint('⚠️ Error al programar recordatorio para pendiente ${pendiente.id}: $e');
    }
  }

  /// Método para la entidad Clase (Horario) con sonido independiente y control estricto de vigencia
  @override
  Future<void> programarRecordatorioClase(
    dynamic claseObj, {
    String? sonido,
    bool vibracion = true,
  }) async {
    try {
      final Clase clase = claseObj is Clase
          ? claseObj
          : Clase.fromMap(claseObj as Map<String, dynamic>);

      final now = DateTime.now();
      final finDia = DateTime(clase.fechaFin.year, clase.fechaFin.month, clase.fechaFin.day, 23, 59, 59);

      // Fuera del rango de fecha de inicio/fin del curso, no debe llegar ninguna notificación
      if (now.isAfter(finDia)) {
        debugPrint('🚫 Clase ${clase.nombre} ya finalizó su periodo de vigencia. No se agenda notificación.');
        return;
      }

      String soundId = sonido ?? 'zen';
      bool vibra = vibracion;
      try {
        final prefs = await SharedPreferences.getInstance();
        if (sonido == null) {
          soundId = prefs.getString('sonido_clases') ?? 'zen';
        }
        vibra = prefs.getBool('vibracion') ?? true;
      } catch (_) {}

      // Encontrar la próxima ocurrencia de esta clase
      DateTime proximaSesion = DateTime(now.year, now.month, now.day);
      while (proximaSesion.weekday != clase.diaSemana) {
        proximaSesion = proximaSesion.add(const Duration(days: 1));
      }

      DateTime momentoClase = DateTime(
        proximaSesion.year,
        proximaSesion.month,
        proximaSesion.day,
        clase.horaInicio,
        clase.minutoInicio,
      );

      DateTime momentoAviso = momentoClase.subtract(Duration(minutes: clase.minutosAntes));

      // Si el aviso de hoy ya pasó, pasar a la próxima semana
      if (momentoAviso.isBefore(now)) {
        proximaSesion = proximaSesion.add(const Duration(days: 7));
        momentoClase = DateTime(
          proximaSesion.year,
          proximaSesion.month,
          proximaSesion.day,
          clase.horaInicio,
          clase.minutoInicio,
        );
        momentoAviso = momentoClase.subtract(Duration(minutes: clase.minutosAntes));
      }

      // Verificar que la fecha de la sesión no supere la fecha de fin de vigencia
      final fechaSesionPura = DateTime(proximaSesion.year, proximaSesion.month, proximaSesion.day);
      final iniPura = DateTime(clase.fechaInicio.year, clase.fechaInicio.month, clase.fechaInicio.day);
      final finPura = DateTime(clase.fechaFin.year, clase.fechaFin.month, clase.fechaFin.day);

      if (fechaSesionPura.isBefore(iniPura) || fechaSesionPura.isAfter(finPura)) {
        debugPrint('🚫 La próxima sesión cae fuera del rango (${clase.fechaInicio} a ${clase.fechaFin}). No se agenda.');
        return;
      }

      final notifId = clase.notificacionId ?? (clase.id.hashCode & 0x7fffffff);

      final String cuerpo = clase.minutosAntes > 0
          ? 'Empieza en ${clase.minutosAntes} min (${clase.horarioFormateado})${clase.aula != null ? " en ${clase.aula}" : ""}'
          : '¡Es hora de tu clase! (${clase.horarioFormateado})${clase.aula != null ? " en ${clase.aula}" : ""}';

      await programarRecordatorio(
        notificacionId: notifId,
        titulo: '🎓 Próxima clase: ${clase.nombre}',
        cuerpo: cuerpo,
        cuando: momentoAviso,
        payload: 'clase_${clase.id}',
        sonido: soundId,
        vibracion: vibra,
        tipo: 'clase',
      );
      debugPrint('📅 Clase ${clase.nombre} agendada para $momentoAviso con tono $soundId');

      // Punto 3: Resumen 5 minutos antes de la clase con pendientes pendientes de esa materia
      final momento5m = momentoClase.subtract(const Duration(minutes: 5));
      if (momento5m.isAfter(now)) {
        try {
          final db = await AppDatabase.instance.database;
          final List<Map<String, dynamic>> maps = await db.query(
            'pendientes',
            columns: ['titulo'],
            where: 'clase_id = ? AND esta_completado = 0',
            whereArgs: [clase.id],
          );
          final titulos = maps.map((m) => m['titulo'] as String).toList();
          final String aviso5m;
          if (titulos.isNotEmpty) {
            if (titulos.length == 1) {
              aviso5m = 'En 5 min: ${clase.nombre}. Tienes pendiente: \'${titulos.first}\'';
            } else {
              aviso5m = 'En 5 min: ${clase.nombre}. Tienes ${titulos.length} pendientes: \'${titulos.join("', '")}\'';
            }
          } else {
            aviso5m = 'En 5 min: ${clase.nombre}${clase.aula != null ? " en ${clase.aula}" : ""}. ¡Todo listo para tu clase!';
          }

          final int notif5mId = (clase.id.hashCode & 0x3fffffff) + 500000;
          await programarRecordatorio(
            notificacionId: notif5mId,
            titulo: '🎓 En 5 min: ${clase.nombre}',
            cuerpo: aviso5m,
            cuando: momento5m,
            payload: 'clase_5m_${clase.id}',
            sonido: soundId,
            vibracion: vibra,
            tipo: 'clase',
          );
          debugPrint('🔔 Aviso 5 min antes agendado para $momento5m');
        } catch (e) {
          debugPrint('⚠️ Error al agendar aviso 5 min de clase: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error al programar recordatorio de clase: $e');
    }
  }

  /// Punto 2: Notificaciones para Modo Examen (1 día antes Y 1 hora antes)
  @override
  Future<void> programarRecordatorioExamen(
    dynamic examenObj,
    String nombreClase, {
    String? sonido,
    bool vibracion = true,
  }) async {
    try {
      final Examen examen = examenObj is Examen
          ? examenObj
          : Examen.fromMap(examenObj as Map<String, dynamic>);

      final now = DateTime.now();
      final fechaHoraExamen = examen.fechaHoraCompleta;

      if (fechaHoraExamen.isBefore(now)) return;

      String soundId = sonido ?? 'alerta';
      bool vibra = vibracion;
      try {
        final prefs = await SharedPreferences.getInstance();
        if (sonido == null) {
          soundId = prefs.getString('sonido_clases') ?? 'alerta';
        }
        vibra = prefs.getBool('vibracion') ?? true;
      } catch (_) {}

      // 1. Notificación 1 DÍA ANTES
      final aviso1d = fechaHoraExamen.subtract(const Duration(days: 1));
      if (aviso1d.isAfter(now)) {
        final int notif1dId = examen.notificacion1dId ?? ((examen.id.hashCode & 0x3fffffff) + 100000);
        await programarRecordatorio(
          notificacionId: notif1dId,
          titulo: '📝 Mañana tienes Examen: ${examen.titulo}',
          cuerpo: 'Materia: $nombreClase a las ${examen.horaFormateada}${examen.aula != null ? " en ${examen.aula}" : ""}. ¡Repasa tus temas!',
          cuando: aviso1d,
          payload: 'examen_1d_${examen.id}',
          sonido: soundId,
          vibracion: vibra,
          tipo: 'clase',
        );
        debugPrint('📅 Examen 1 día antes agendado para $aviso1d');
      }

      // 2. Notificación 1 HORA ANTES
      final aviso1h = fechaHoraExamen.subtract(const Duration(hours: 1));
      if (aviso1h.isAfter(now)) {
        final int notif1hId = examen.notificacion1hId ?? ((examen.id.hashCode & 0x3fffffff) + 200000);
        await programarRecordatorio(
          notificacionId: notif1hId,
          titulo: '🚨 En 1 hora: Examen de ${examen.titulo}',
          cuerpo: 'Materia: $nombreClase a las ${examen.horaFormateada}${examen.aula != null ? " en ${examen.aula}" : ""}. ¡Mucho éxito!',
          cuando: aviso1h,
          payload: 'examen_1h_${examen.id}',
          sonido: soundId,
          vibracion: vibra,
          tipo: 'clase',
        );
        debugPrint('🚨 Examen 1 hora antes agendado para $aviso1h');
      }
    } catch (e) {
      debugPrint('⚠️ Error al programar recordatorio de examen: $e');
    }
  }

  @override
  Future<void> cancelarRecordatorioExamen(dynamic examenObj) async {
    try {
      final Examen examen = examenObj is Examen
          ? examenObj
          : Examen.fromMap(examenObj as Map<String, dynamic>);
      final int notif1dId = examen.notificacion1dId ?? ((examen.id.hashCode & 0x3fffffff) + 100000);
      final int notif1hId = examen.notificacion1hId ?? ((examen.id.hashCode & 0x3fffffff) + 200000);
      await cancelarRecordatorio(notif1dId);
      await cancelarRecordatorio(notif1hId);
    } catch (e) {
      debugPrint('⚠️ Error cancelando recordatorio de examen: $e');
    }
  }

  Future<void> _agendarZoned({
    required int id,
    required String titulo,
    required String cuerpo,
    required tz.TZDateTime date,
    String? payload,
    String channelId = channelId,
    String channelName = channelName,
    String channelDesc = channelDesc,
    String? soundId,
    bool vibracion = true,
  }) async {
    final sId = soundId ?? 'campana';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: sId.startsWith('content://')
          ? UriAndroidNotificationSound(sId)
          : (sId == 'default' ? null : RawResourceAndroidNotificationSound(sId)),
      enableVibration: vibracion,
      vibrationPattern: vibracion ? _vibrationPattern : null,
      category: AndroidNotificationCategory.reminder,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: sId == 'default' ? null : '$sId.wav',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
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
      debugPrint('📅 Recordatorio programado para: $date (ID: $id, Canal: $channelId, Sonido: $sId)');
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

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
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

  static const int idAvisoRiesgoRacha = 7788;

  @override
  Future<void> programarAvisoRiesgoRacha({
    int hora = 20,
    int minuto = 0,
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

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
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

      await _plugin.zonedSchedule(
        id: idAvisoRiesgoRacha,
        title: '⏰ ¡Zendy necesita tu ayuda!',
        body: 'Aún no has completado ningún pendiente hoy. ¡Completa uno antes de medianoche para salvar tu racha y la ropa de Zendy!',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'riesgo_racha',
      );
      debugPrint('⏰ Aviso preventivo de racha programado para las $hora:${minuto.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('⚠️ Error al programar aviso de riesgo de racha: $e');
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
  Future<void> cancelarRecordatorioClase(String claseId) async {
    final int notifId = claseId.hashCode & 0x7fffffff;
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
