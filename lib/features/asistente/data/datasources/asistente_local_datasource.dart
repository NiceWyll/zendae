import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/limite_chat.dart';
import '../../domain/entities/mensaje_chat.dart';

class AsistenteLocalDatasource {
  final SharedPreferences prefs;

  static const String _keyUsados = 'asistente_mensajes_usados';
  static const String _keyFecha = 'asistente_fecha_limite';
  static const String _keyHistorial = 'asistente_historial_mensajes';
  static const int _maxPorDia = 15;

  const AsistenteLocalDatasource({required this.prefs});

  Future<LimiteChat> obtenerLimite(DateTime ahora) async {
    final hoyStr = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';
    final fechaGuardada = prefs.getString(_keyFecha);

    if (fechaGuardada != hoyStr) {
      // Nuevo día natural: reiniciar contador
      await prefs.setString(_keyFecha, hoyStr);
      await prefs.setInt(_keyUsados, 0);
      return LimiteChat(
        mensajesUsadosHoy: 0,
        mensajesMaximosPorDia: _maxPorDia,
        fecha: ahora,
      );
    }

    final usados = prefs.getInt(_keyUsados) ?? 0;
    return LimiteChat(
      mensajesUsadosHoy: usados,
      mensajesMaximosPorDia: _maxPorDia,
      fecha: ahora,
    );
  }

  Future<void> registrarMensajeEnviado(DateTime ahora) async {
    final hoyStr = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';
    final fechaGuardada = prefs.getString(_keyFecha);

    int usados = 0;
    if (fechaGuardada == hoyStr) {
      usados = prefs.getInt(_keyUsados) ?? 0;
    } else {
      await prefs.setString(_keyFecha, hoyStr);
    }

    await prefs.setInt(_keyUsados, usados + 1);
  }

  Future<List<MensajeChat>> obtenerHistorial() async {
    final raw = prefs.getStringList(_keyHistorial);
    if (raw == null || raw.isEmpty) return [];

    final List<MensajeChat> mensajes = [];
    for (final item in raw) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        mensajes.add(MensajeChat(
          id: map['id'] as String,
          texto: map['texto'] as String,
          esUsuario: map['esUsuario'] as bool,
          fecha: DateTime.parse(map['fecha'] as String),
          pendienteCreadoId: map['pendienteCreadoId'] as String?,
          tituloPendienteCreado: map['tituloPendienteCreado'] as String?,
          esError: map['esError'] as bool? ?? false,
        ));
      } catch (_) {}
    }
    return mensajes;
  }

  Future<void> guardarMensaje(MensajeChat mensaje) async {
    final actuales = await obtenerHistorial();
    actuales.add(mensaje);

    // Guardar los últimos 50 mensajes
    final aGuardar = actuales.length > 50
        ? actuales.sublist(actuales.length - 50)
        : actuales;

    final listJson = aGuardar.map((m) {
      return jsonEncode({
        'id': m.id,
        'texto': m.texto,
        'esUsuario': m.esUsuario,
        'fecha': m.fecha.toIso8601String(),
        'pendienteCreadoId': m.pendienteCreadoId,
        'tituloPendienteCreado': m.tituloPendienteCreado,
        'esError': m.esError,
      });
    }).toList();

    await prefs.setStringList(_keyHistorial, listJson);
  }

  Future<void> limpiarHistorial() async {
    await prefs.remove(_keyHistorial);
  }
}
