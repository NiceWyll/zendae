import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import 'package:mi_pendiente/core/constants/app_config.dart';
import 'package:mi_pendiente/features/racha/domain/entities/hito_racha.dart';
import 'package:mi_pendiente/features/racha/presentation/providers/racha_provider.dart';

class BotonMicrofono extends ConsumerStatefulWidget {
  final ValueChanged<String>? onTextoReconocido;

  const BotonMicrofono({
    super.key,
    this.onTextoReconocido,
  });

  @override
  ConsumerState<BotonMicrofono> createState() => _BotonMicrofonoState();
}

class _BotonMicrofonoState extends ConsumerState<BotonMicrofono> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechInicializado = false;

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rachaAsync = ref.watch(rachaNotifierProvider);
    final racha = rachaAsync.valueOrNull;

    final dias = racha?.diasActuales ?? 0;
    final primaryColor = Theme.of(context).primaryColor;
    final vozDesbloqueada = AppConfig.todoDesbloqueado ||
        dias >= 15 ||
        (racha?.logrosDesbloqueados.contains(HitoRacha.dias15.name) ?? false);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          if (vozDesbloqueada) {
            _iniciarDictadoVoz();
          } else {
            _mostrarDialogoBloqueo(context, dias);
          }
        },
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: vozDesbloqueada
                ? primaryColor.withValues(alpha: 0.12)
                : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(
              color: vozDesbloqueada
                  ? primaryColor.withValues(alpha: 0.35)
                  : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
          ),
          child: vozDesbloqueada
              ? Icon(
                  Icons.mic_rounded,
                  color: primaryColor,
                  size: 20,
                )
              : Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.mic_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64748B),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _mostrarDialogoBloqueo(BuildContext context, int diasLlevados) {
    final faltan = 15 - diasLlevados;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          title: const Row(
            children: [
              Text('🎙️', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Asistente por Voz',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Row(
                  children: [
                    Text('⏰', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Desbloquea el micrófono al llegar a 15 días de racha consecutiva.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Llevas $diasLlevados de 15 días (${faltan > 0 ? 'te faltan $faltan' : '¡casi listo!'}).\n\n'
                '¡Completa tus pendientes cada día para mantener encendida la llama y desbloquear el comando por voz!',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('¡Entendido! 💪', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _iniciarDictadoVoz() async {
    // 1. Solicitar y verificar permisos de micrófono nativos
    bool permisoConcedido = false;
    try {
      final estadoPermiso = await Permission.microphone.status;
      if (estadoPermiso.isGranted) {
        permisoConcedido = true;
      } else if (estadoPermiso.isPermanentlyDenied) {
        if (!mounted) return;
        _mostrarDialogoPermisoDenegado();
        return;
      } else {
        final solicitud = await Permission.microphone.request();
        if (solicitud.isGranted) {
          permisoConcedido = true;
        } else {
          if (!mounted) return;
          _mostrarDialogoPermisoDenegado();
          return;
        }
      }
    } catch (_) {
      // Fallback seguro para pruebas o entornos sin canal nativo
      permisoConcedido = true;
    }

    if (!permisoConcedido || !mounted) return;

    // 2. Abrir modal de escucha con animación y detección de silencio
    _mostrarModalEscucha();
  }

  void _mostrarModalEscucha() {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return _ModalEscuchaVoz(
          speechToText: _speechToText,
          speechInicializado: _speechInicializado,
          primaryColor: primaryColor,
          isDark: isDark,
          onInicializado: (val) => _speechInicializado = val,
          onFinalizado: (textoReconocido) {
            Navigator.of(modalContext).pop();
            final clean = textoReconocido.trim();
            if (clean.isNotEmpty) {
              widget.onTextoReconocido?.call(clean);
            }
          },
        );
      },
    );
  }

  void _mostrarDialogoPermisoDenegado() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          title: const Row(
            children: [
              Icon(Icons.mic_off_rounded, color: AppColors.priorityAlta, size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Permiso de Micrófono',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Text(
            'Sin el permiso de micrófono no es posible utilizar el dictado por voz para registrar tus tareas.\n\n'
            'Para habilitarlo, pulsa en "Abrir Ajustes", busca Permisos y activa el acceso al Micrófono.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Abrir Ajustes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModalEscuchaVoz extends StatefulWidget {
  final SpeechToText speechToText;
  final bool speechInicializado;
  final Color primaryColor;
  final bool isDark;
  final ValueChanged<bool> onInicializado;
  final ValueChanged<String> onFinalizado;

  const _ModalEscuchaVoz({
    required this.speechToText,
    required this.speechInicializado,
    required this.primaryColor,
    required this.isDark,
    required this.onInicializado,
    required this.onFinalizado,
  });

  @override
  State<_ModalEscuchaVoz> createState() => _ModalEscuchaVozState();
}

class _ModalEscuchaVozState extends State<_ModalEscuchaVoz>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _palabrasReconocidas = '';
  bool _estaEscuchando = false;
  bool _procesando = false;
  String? _mensajeError;
  Timer? _silencioTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _iniciarReconocimiento();
  }

  Future<void> _iniciarReconocimiento() async {
    try {
      bool disponible = widget.speechInicializado;
      if (!disponible) {
        disponible = await widget.speechToText.initialize(
          onError: (val) {
            debugPrint('Speech error: ${val.errorMsg}');
            if (mounted && _estaEscuchando) {
              _concluirYEnviar();
            }
          },
          onStatus: (status) {
            debugPrint('Speech status: $status');
            // Detección automática de silencio: cuando el motor detiene la escucha
            if (status == 'done' || status == 'notListening') {
              if (mounted && _estaEscuchando && !_procesando) {
                if (_palabrasReconocidas.trim().isNotEmpty) {
                  _concluirYEnviar();
                } else {
                  setState(() => _estaEscuchando = false);
                }
              }
            }
          },
        );
        widget.onInicializado(disponible);
      }

      if (!disponible) {
        if (mounted) {
          setState(() {
            _mensajeError = 'El servicio de reconocimiento de voz no está disponible en este dispositivo.';
          });
        }
        return;
      }

      if (!mounted) return;

      setState(() {
        _estaEscuchando = true;
      });

      // Obtener el idioma del sistema si está disponible
      String? localeId;
      try {
        final locales = await widget.speechToText.locales();
        final espanol = locales.firstWhere(
          (l) => l.localeId.toLowerCase().startsWith('es'),
          orElse: () => locales.first,
        );
        localeId = espanol.localeId;
      } catch (_) {
        localeId = null;
      }

      await widget.speechToText.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _palabrasReconocidas = result.recognizedWords;
            });

            // Reiniciar el temporizador de 5 segundos de silencio tras cada palabra detectada
            _reiniciarTemporizadorSilencio();

            // Si el motor ya finalizó por completo y no está escuchando
            if (result.finalResult &&
                !widget.speechToText.isListening &&
                _palabrasReconocidas.trim().isNotEmpty) {
              _concluirYEnviar();
            }
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5), // Detiene automáticamente tras al menos 5 segundos de silencio
        partialResults: true,
        localeId: localeId,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _mensajeError = 'Inconveniente al iniciar el micrófono: $e';
        });
      }
    }
  }

  void _reiniciarTemporizadorSilencio() {
    _silencioTimer?.cancel();
    if (_palabrasReconocidas.trim().isNotEmpty) {
      _silencioTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _estaEscuchando && !_procesando) {
          _concluirYEnviar();
        }
      });
    }
  }

  Future<void> _concluirYEnviar() async {
    _silencioTimer?.cancel();
    if (_procesando) return;
    _procesando = true;

    try {
      if (widget.speechToText.isListening) {
        await widget.speechToText.stop();
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _estaEscuchando = false);
      widget.onFinalizado(_palabrasReconocidas);
    }
  }

  @override
  void dispose() {
    _silencioTimer?.cancel();
    _pulseController.dispose();
    if (widget.speechToText.isListening) {
      widget.speechToText.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador visual con onda pulsante
          ScaleTransition(
            scale: _estaEscuchando ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _estaEscuchando
                    ? widget.primaryColor.withValues(alpha: 0.15)
                    : const Color(0xFFE2E8F0),
                border: Border.all(
                  color: _estaEscuchando ? widget.primaryColor : const Color(0xFFCBD5E1),
                  width: 2.5,
                ),
                boxShadow: _estaEscuchando
                    ? [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.25),
                          blurRadius: 18,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _estaEscuchando ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _estaEscuchando ? widget.primaryColor : const Color(0xFF64748B),
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Título del estado
          Text(
            _mensajeError != null
                ? 'Atención'
                : (_estaEscuchando ? 'Te estoy escuchando...' : 'Procesando tu voz...'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: widget.isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Subtítulo con transcripción en vivo o instrucción
          if (_mensajeError != null)
            Text(
              _mensajeError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.priorityAlta),
            )
          else if (_palabrasReconocidas.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                '«$_palabrasReconocidas»',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: widget.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                ),
              ),
            )
          else
            Text(
              'Habla con naturalidad. Tras 5 segundos de silencio o tocando "Enviar ahora", tu mensaje se enviará.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: widget.isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),

          const SizedBox(height: 20),

          // Botones de acción manual por conveniencia
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: widget.isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_palabrasReconocidas.isNotEmpty) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _concluirYEnviar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Enviar ahora', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
