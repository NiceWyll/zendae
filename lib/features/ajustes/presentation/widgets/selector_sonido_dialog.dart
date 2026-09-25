import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/constants/app_sounds.dart';
import 'package:mi_pendiente/core/services/android_ringtone_service.dart';
import 'package:mi_pendiente/core/services/notification_service.dart';

typedef OnSonidoSeleccionado = void Function(String id, [String? nombre]);

class SelectorSonidoDialog extends StatefulWidget {
  final String sonidoActualId;
  final String tipo; // 'pendiente' o 'clase'
  final bool vibracionActiva;
  final OnSonidoSeleccionado onSonidoSeleccionado;

  const SelectorSonidoDialog({
    super.key,
    required this.sonidoActualId,
    required this.tipo,
    required this.vibracionActiva,
    required this.onSonidoSeleccionado,
  });

  static Future<void> mostrar({
    required BuildContext context,
    required String sonidoActualId,
    required String tipo,
    required bool vibracionActiva,
    required OnSonidoSeleccionado onSonidoSeleccionado,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => SelectorSonidoDialog(
        sonidoActualId: sonidoActualId,
        tipo: tipo,
        vibracionActiva: vibracionActiva,
        onSonidoSeleccionado: onSonidoSeleccionado,
      ),
    );
  }

  @override
  State<SelectorSonidoDialog> createState() => _SelectorSonidoDialogState();
}

class _SelectorSonidoDialogState extends State<SelectorSonidoDialog> {
  List<SystemRingtone> _tonosDelSistema = [];
  bool _cargandoTonos = false;
  String? _sonidoEnReproduccion;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _cargarTonosDeAndroid();
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid) {
      AndroidRingtoneService.stopRingtone();
    }
    super.dispose();
  }

  Future<void> _cargarTonosDeAndroid() async {
    setState(() => _cargandoTonos = true);
    final tonos = await AndroidRingtoneService.getSystemRingtones();
    if (mounted) {
      setState(() {
        _tonosDelSistema = tonos;
        _cargandoTonos = false;
      });
    }
  }

  Future<void> _abrirSelectorNativoAndroid() async {
    final picked = await AndroidRingtoneService.openRingtonePicker(
      currentUri: widget.sonidoActualId.startsWith('content://') ? widget.sonidoActualId : null,
    );
    if (picked != null && mounted) {
      widget.onSonidoSeleccionado(picked.uri, picked.title);
      await AndroidRingtoneService.playRingtone(picked.uri);
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _probarTono(String id, {String? uri}) {
    if (Platform.isAndroid && uri != null && uri.startsWith('content://')) {
      setState(() => _sonidoEnReproduccion = id);
      AndroidRingtoneService.playRingtone(uri);
    } else {
      setState(() => _sonidoEnReproduccion = id);
      NotificationServiceImpl.instance.probarSonido(
        soundId: id,
        tipo: widget.tipo,
        vibracion: widget.vibracionActiva,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final esClase = widget.tipo == 'clase';

    return AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: esClase
                  ? const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.15)
                  : primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              esClase ? Icons.school_rounded : Icons.notifications_active_rounded,
              color: esClase ? const Color(0xFF8B5CF6) : primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esClase ? 'Sonido de Clases' : 'Sonido de Pendientes',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Platform.isAndroid
                      ? 'Tonos de tu teléfono y de la aplicación'
                      : 'Elige un tono distintivo para esta alerta',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.65,
        child: ListView(
          shrinkWrap: true,
          children: [
            // Botón destacado en Android para abrir el selector nativo del teléfono
            if (Platform.isAndroid) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.12),
                      primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.phonelink_ring_rounded,
                    color: Color(0xFF10B981),
                    size: 26,
                  ),
                  title: const Text(
                    'Explorar tonos de tu celular',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Abre el selector nativo de Android (Samsung, Xiaomi, Motorola...)',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _abrirSelectorNativoAndroid,
                ),
              ),
            ],

            if (Platform.isAndroid && _cargandoTonos) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ],

            // SECCIÓN 1: Tonos del sistema de Android si están detectados
            if (Platform.isAndroid && _tonosDelSistema.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.smartphone_rounded, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      'TONOS DE TU TELÉFONO (${_tonosDelSistema.length})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              ..._tonosDelSistema.map((ringtone) {
                final esSeleccionado = ringtone.uri == widget.sonidoActualId;
                final estaSonando = _sonidoEnReproduccion == ringtone.uri;

                return InkWell(
                  onTap: () {
                    widget.onSonidoSeleccionado(ringtone.uri, ringtone.title);
                    _probarTono(ringtone.uri, uri: ringtone.uri);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          esSeleccionado
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: esSeleccionado ? primaryColor : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ringtone.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: esSeleccionado ? FontWeight.w700 : FontWeight.w500,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            estaSonando ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                            size: 20,
                          ),
                          color: estaSonando
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                          tooltip: 'Probar tono',
                          onPressed: () {
                            if (estaSonando) {
                              AndroidRingtoneService.stopRingtone();
                              setState(() => _sonidoEnReproduccion = null);
                            } else {
                              _probarTono(ringtone.uri, uri: ringtone.uri);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Divider(
                height: 20,
                color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
              ),
            ],

            // SECCIÓN 2: Tonos integrados de la aplicación
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.library_music_rounded, size: 16, color: primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'TONOS DE LA APLICACIÓN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            ...SonidosDisponibles.lista.map((sonido) {
              final esSeleccionado = sonido.id == widget.sonidoActualId;

              return InkWell(
                onTap: () {
                  widget.onSonidoSeleccionado(sonido.id, sonido.nombre);
                  _probarTono(sonido.id);
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        esSeleccionado
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: esSeleccionado ? primaryColor : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: esSeleccionado
                              ? primaryColor.withValues(alpha: 0.15)
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          sonido.icono,
                          color: esSeleccionado ? primaryColor : const Color(0xFF64748B),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sonido.nombre,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: esSeleccionado ? FontWeight.w700 : FontWeight.w500,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              sonido.descripcion,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, size: 20),
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        tooltip: 'Escuchar prueba',
                        onPressed: () => _probarTono(sonido.id),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (Platform.isAndroid) {
              AndroidRingtoneService.stopRingtone();
            }
            Navigator.of(context).pop();
          },
          child: Text(
            'Cerrar',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
