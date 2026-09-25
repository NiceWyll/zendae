import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService instance = TtsService._();
  TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _inicializado = false;

  Future<void> inicializar() async {
    if (_inicializado) return;
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _inicializado = true;
    } catch (_) {
      try {
        await _tts.setLanguage('es');
        _inicializado = true;
      } catch (_) {}
    }
  }

  Future<void> hablar(String texto) async {
    await inicializar();
    try {
      // Limpiar formato markdown (asteriscos, viñetas, emojis) para que suene fluido
      final textoLimpio = texto
          .replaceAll('*', '')
          .replaceAll('#', '')
          .replaceAll('•', '')
          .replaceAll('👋', '')
          .replaceAll('✨', '')
          .replaceAll('📅', '')
          .replaceAll('🔔', '')
          .replaceAll('📝', '')
          .replaceAll('🎓', '')
          .replaceAll('\n', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      await _tts.stop();
      await _tts.speak(textoLimpio);
    } catch (_) {}
  }

  Future<void> detener() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
