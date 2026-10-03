import 'dart:io';

class AppConfig {
  AppConfig._();

  static bool? _overrideTodoDesbloqueado;

  /// Permite sobrescribir el valor (por ejemplo en tests unitarios)
  static set todoDesbloqueado(bool value) => _overrideTodoDesbloqueado = value;

  /// En iOS (iPhone) está desbloqueado para pruebas; en Android (APK)
  /// está bloqueado para que el usuario avance y desbloquee día a día por racha.
  static bool get todoDesbloqueado {
    if (_overrideTodoDesbloqueado != null) return _overrideTodoDesbloqueado!;
    const bool forceUnlocked = bool.fromEnvironment('TODO_DESBLOQUEADO', defaultValue: false);
    if (forceUnlocked) return true;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }
}






