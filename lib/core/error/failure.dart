sealed class Failure {
  const Failure(this.mensaje);
  final String mensaje;
}

class FallaBaseDeDatos extends Failure {
  const FallaBaseDeDatos([super.mensaje = 'No se pudieron cargar tus pendientes']);
}

class FallaNotificaciones extends Failure {
  const FallaNotificaciones([super.mensaje = 'No se pudo programar el recordatorio']);
}

class FallaPermisos extends Failure {
  const FallaPermisos([super.mensaje = 'Activa los permisos de notificación en Ajustes']);
}

class FallaNoEncontrado extends Failure {
  const FallaNoEncontrado([super.mensaje = 'Ese pendiente ya no existe']);
}

class FallaValidacion extends Failure {
  const FallaValidacion([super.mensaje = 'Datos del pendiente inválidos']);
}

class FallaPreferencias extends Failure {
  const FallaPreferencias([super.mensaje = 'Error al acceder a las preferencias']);
}
