class AppConfig {
  AppConfig._();

  /// Por defecto es FALSE para la versión oficial (retos, candados y
  /// progresión por días de racha para todos los usuarios y amigos).
  /// Solo se activa en builds personales de Williams cuando se solicita.
  static bool todoDesbloqueado = false;
}
