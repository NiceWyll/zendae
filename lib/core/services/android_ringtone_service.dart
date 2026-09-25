import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SystemRingtone {
  final String title;
  final String uri;

  const SystemRingtone({
    required this.title,
    required this.uri,
  });
}

class AndroidRingtoneService {
  AndroidRingtoneService._();

  static const MethodChannel _channel = MethodChannel('com.mipendiente.app/ringtones');

  /// Obtiene los tonos de notificación nativos del sistema Android
  static Future<List<SystemRingtone>> getSystemRingtones() async {
    if (!Platform.isAndroid) return [];
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getSystemRingtones');
      if (result == null) return [];
      return result.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return SystemRingtone(
          title: (map['title'] ?? 'Tono del sistema').toString(),
          uri: (map['uri'] ?? '').toString(),
        );
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error obteniendo tonos del sistema: $e');
      return [];
    }
  }

  /// Abre el diálogo selector nativo de tonos de Android (RingtonePicker)
  static Future<SystemRingtone?> openRingtonePicker({String? currentUri}) async {
    if (!Platform.isAndroid) return null;
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('openRingtonePicker', {
        'currentUri': currentUri,
      });
      if (result == null) return null;
      final map = Map<String, dynamic>.from(result);
      return SystemRingtone(
        title: (map['title'] ?? 'Tono del teléfono').toString(),
        uri: (map['uri'] ?? '').toString(),
      );
    } catch (e) {
      debugPrint('⚠️ Error abriendo selector de tonos de Android: $e');
      return null;
    }
  }

  /// Reproduce el tono del sistema inmediatamente (vista previa)
  static Future<void> playRingtone(String uri) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('playRingtone', {'uri': uri});
    } catch (e) {
      debugPrint('⚠️ Error reproduciendo tono: $e');
    }
  }

  /// Detiene la reproducción del tono
  static Future<void> stopRingtone() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopRingtone');
    } catch (e) {
      debugPrint('⚠️ Error deteniendo tono: $e');
    }
  }
}
