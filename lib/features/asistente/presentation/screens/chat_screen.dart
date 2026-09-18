import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import '../providers/chat_notifier.dart';
import '../widgets/barra_limite_chat.dart';
import '../widgets/boton_microfono.dart';
import '../widgets/burbuja_mensaje.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).enviarMensaje(texto);
    _scrollAlFondo();
  }

  void _scrollAlFondo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(chatProvider);

    // Auto-scroll cuando llega un nuevo mensaje
    ref.listen(chatProvider, (prev, next) {
      if (prev?.mensajes.length != next.mensajes.length || next.estaEscribiendo) {
        _scrollAlFondo();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Asistente IA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'En línea',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Limpiar conversación',
            onPressed: () {
              ref.read(chatProvider.notifier).limpiarConversacion();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de límite de mensajes diarios
            BarraLimiteChat(limite: chatState.limite),

            // Lista de mensajes
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: chatState.mensajes.length,
                itemBuilder: (context, index) {
                  final mensaje = chatState.mensajes[index];
                  return BurbujaMensaje(mensaje: mensaje);
                },
              ),
            ),

            // Indicador de "Escribiendo..."
            if (chatState.estaEscribiendo)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Interpretando tarea...',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Sugerencias rápidas en chips
            _buildSugerenciasRapidas(isDark),

            // Barra inferior de entrada de texto
            _buildBarraEntrada(isDark, chatState.limite.puedeEnviar),
          ],
        ),
      ),
    );
  }

  Widget _buildSugerenciasRapidas(bool isDark) {
    const sugerencias = [
      'Llamar al dentista mañana 3pm',
      'Pagar la luz el viernes a las 10am',
      'Estudiar hoy 6pm prioridad alta',
      'Hacer compras sábado 9am',
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sugerencias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sug = sugerencias[index];
          return ActionChip(
            label: Text(
              sug,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            backgroundColor: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () {
              _controller.text = sug;
              _enviar();
            },
          );
        },
      ),
    );
  }

  Widget _buildBarraEntrada(bool isDark, bool puedeEnviar) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Botón de micrófono con candado reactivo a racha
          BotonMicrofono(
            onTextoReconocido: (textoDictado) {
              _controller.text = textoDictado;
              _enviar();
            },
          ),
          const SizedBox(width: 8),

          // Campo de texto
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                ),
              ),
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: puedeEnviar ? 'Escribe o dicta tu pendiente...' : 'Límite diario alcanzado',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _enviar(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botón de enviar
          Container(
            decoration: BoxDecoration(
              color: puedeEnviar ? AppColors.primary : const Color(0xFF94A3B8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: puedeEnviar ? _enviar : null,
              tooltip: 'Enviar mensaje',
            ),
          ),
        ],
      ),
    );
  }
}
