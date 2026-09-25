import 'package:flutter/material.dart';

class SonidoNotificacion {
  final String id;
  final String nombre;
  final String descripcion;
  final IconData icono;

  const SonidoNotificacion({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
  });
}

class SonidosDisponibles {
  SonidosDisponibles._();

  static const List<SonidoNotificacion> lista = [
    SonidoNotificacion(
      id: 'campana',
      nombre: 'Campana Clásica',
      descripcion: 'Chime nítido y brillante de dos tonos',
      icono: Icons.notifications_active_rounded,
    ),
    SonidoNotificacion(
      id: 'digital',
      nombre: 'Bip Digital',
      descripcion: 'Tono rápido, moderno y futurista',
      icono: Icons.graphic_eq_rounded,
    ),
    SonidoNotificacion(
      id: 'zen',
      nombre: 'Zen Armónico',
      descripcion: 'Campana tibetana suave y relajante',
      icono: Icons.spa_rounded,
    ),
    SonidoNotificacion(
      id: 'suave',
      nombre: 'Arpa Suave',
      descripcion: 'Acorde ascendente delicado y melódico',
      icono: Icons.music_note_rounded,
    ),
    SonidoNotificacion(
      id: 'alerta',
      nombre: 'Alerta Enérgica',
      descripcion: 'Doble pulsación de máxima atención',
      icono: Icons.bolt_rounded,
    ),
    SonidoNotificacion(
      id: 'default',
      nombre: 'Predeterminado del Sistema',
      descripcion: 'Tono por defecto de tu dispositivo',
      icono: Icons.phone_android_rounded,
    ),
  ];

  static SonidoNotificacion obtenerPorId(String id, [String? nombrePersonalizado]) {
    if (id.startsWith('content://')) {
      return SonidoNotificacion(
        id: id,
        nombre: nombrePersonalizado ?? 'Tono del teléfono',
        descripcion: 'Tono nativo seleccionado de tu dispositivo Android',
        icono: Icons.phonelink_ring_rounded,
      );
    }
    return lista.firstWhere(
      (s) => s.id == id,
      orElse: () => lista.first,
    );
  }
}
