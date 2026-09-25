import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Personaje animado de la Racha: "Zendy, el Reloj con ojos".
/// Reemplaza el ícono de fuego 🔥 con movimiento continuo, parpadeo y ropa intercambiable.
class ZendyPersonajeWidget extends StatefulWidget {
  final double size;
  final String prendaId;
  final bool animado;
  final VoidCallback? onTap;

  const ZendyPersonajeWidget({
    super.key,
    double? size,
    double? tamano,
    this.prendaId = 'ninguno',
    bool? animado,
    bool? animar,
    this.onTap,
  })  : size = tamano ?? size ?? 64,
        animado = animar ?? animado ?? true;

  @override
  State<ZendyPersonajeWidget> createState() => _ZendyPersonajeWidgetState();
}

class _ZendyPersonajeWidgetState extends State<ZendyPersonajeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flotacionAnim;
  late Animation<double> _parpadeoAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Animación suave de flotación / respiración
    _flotacionAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -4.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -4.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Parpadeo periódico en el último 10% del ciclo
    _parpadeoAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 88),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.1).chain(CurveTween(curve: Curves.easeIn)),
        weight: 4,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 4,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 4),
    ]).animate(_controller);

    final bool esTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (widget.animado && !esTest) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ZendyPersonajeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animado != oldWidget.animado) {
      final bool esTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
      if (widget.animado && !esTest) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dy = widget.animado ? _flotacionAnim.value : 0.0;
        final blinkScale = widget.animado ? _parpadeoAnim.value : 1.0;

        return Transform.translate(
          offset: Offset(0, dy),
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _ZendyPainter(
              prendaId: widget.prendaId,
              blinkScale: blinkScale,
              animationValue: _controller.value,
            ),
          ),
        );
      },
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: content,
      );
    }

    return content;
  }
}

class _ZendyPainter extends CustomPainter {
  final String prendaId;
  final double blinkScale;
  final double animationValue;

  _ZendyPainter({
    required this.prendaId,
    required this.blinkScale,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2 + h * 0.04);
    final radio = w * 0.38;

    // 0. CAPA DE SUPERHÉROE (Si está equipada va DETRÁS del cuerpo)
    if (prendaId == 'capa_heroe') {
      _dibujarCapaHeroe(canvas, center, radio, w, h);
    }

    // 1. PATITAS DEL RELOJ (Base)
    final paintPata = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;

    // Pata izquierda
    canvas.save();
    canvas.translate(center.dx - radio * 0.55, center.dy + radio * 0.85);
    canvas.rotate(-0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: radio * 0.22, height: radio * 0.38),
        Radius.circular(radio * 0.1),
      ),
      paintPata,
    );
    canvas.restore();

    // Pata derecha
    canvas.save();
    canvas.translate(center.dx + radio * 0.55, center.dy + radio * 0.85);
    canvas.rotate(0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: radio * 0.22, height: radio * 0.38),
        Radius.circular(radio * 0.1),
      ),
      paintPata,
    );
    canvas.restore();

    // 2. CAMPANITAS SUPERIORES (Orejas de despertador)
    final bellPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
      ).createShader(Rect.fromCircle(center: center, radius: radio));

    // Campanita izquierda
    final bellOffsetL = Offset(center.dx - radio * 0.72, center.dy - radio * 0.72);
    canvas.drawCircle(bellOffsetL, radio * 0.28, bellPaint);
    canvas.drawCircle(
      bellOffsetL,
      radio * 0.28,
      Paint()
        ..color = const Color(0xFFB45309)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * 0.06,
    );

    // Campanita derecha
    final bellOffsetR = Offset(center.dx + radio * 0.72, center.dy - radio * 0.72);
    canvas.drawCircle(bellOffsetR, radio * 0.28, bellPaint);
    canvas.drawCircle(
      bellOffsetR,
      radio * 0.28,
      Paint()
        ..color = const Color(0xFFB45309)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * 0.06,
    );

    // Asa central superior
    final handlePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radio * 0.1
      ..strokeCap = StrokeCap.round;

    final handlePath = Path()
      ..moveTo(center.dx - radio * 0.35, center.dy - radio * 0.88)
      ..quadraticBezierTo(
        center.dx,
        center.dy - radio * 1.15,
        center.dx + radio * 0.35,
        center.dy - radio * 0.88,
      );
    canvas.drawPath(handlePath, handlePaint);

    // 3. CUERPO PRINCIPAL DEL RELOJ (Esfera con degradado vibrante y borde brillante)
    final cuerpoShader = const LinearGradient(
      colors: [
        Color(0xFFFFFBEB),
        Color(0xFFFEF3C7),
        Color(0xFFFDE68A),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromCircle(center: center, radius: radio));

    final cuerpoPaint = Paint()..shader = cuerpoShader;

    // Sombra suave del cuerpo
    canvas.drawCircle(
      center.translate(0, radio * 0.06),
      radio,
      Paint()..color = Colors.black.withOpacity(0.12),
    );

    // Borde exterior metálico / dorado
    canvas.drawCircle(
      center,
      radio,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromCircle(center: center, radius: radio)),
    );

    // Interior de la carátula
    canvas.drawCircle(center, radio * 0.88, cuerpoPaint);

    // Borde fino interior
    canvas.drawCircle(
      center,
      radio * 0.88,
      Paint()
        ..color = const Color(0xFFF59E0B).withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * 0.04,
    );

    // 4. MANECILLAS DEL RELOJ (Posición de sonrisa feliz 10:10)
    final manecillaPaint = Paint()
      ..color = const Color(0xFF78350F).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radio * 0.06
      ..strokeCap = StrokeCap.round;

    // Manecilla minutero (hacia arriba a la derecha)
    canvas.drawLine(
      center,
      Offset(center.dx + radio * 0.35, center.dy - radio * 0.32),
      manecillaPaint,
    );
    // Manecilla horaria (hacia arriba a la izquierda)
    canvas.drawLine(
      center,
      Offset(center.dx - radio * 0.3, center.dy - radio * 0.25),
      manecillaPaint,
    );
    // Perno central
    canvas.drawCircle(
      center,
      radio * 0.07,
      Paint()..color = const Color(0xFF78350F).withOpacity(0.45),
    );

    // 5. CARA: OJOS EXPRESIVOS Y MEJILLAS SONROJADAS
    final eyeY = center.dy - radio * 0.15;
    final eyeDistance = radio * 0.36;
    final eyeRadius = radio * 0.22;

    // Mejillas rosaditas
    final cheekPaint = Paint()
      ..color = const Color(0xFFFB7185).withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - eyeDistance * 1.25, center.dy + radio * 0.22),
        width: radio * 0.26,
        height: radio * 0.15,
      ),
      cheekPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + eyeDistance * 1.25, center.dy + radio * 0.22),
        width: radio * 0.26,
        height: radio * 0.15,
      ),
      cheekPaint,
    );

    // Dibujar Ojos (con escala de parpadeo)
    canvas.save();
    canvas.translate(0, eyeY);
    canvas.scale(1.0, blinkScale);
    canvas.translate(0, -eyeY);

    final eyePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    // Ojo Izquierdo
    final eyeLeft = Offset(center.dx - eyeDistance, eyeY);
    canvas.drawOval(
      Rect.fromCenter(center: eyeLeft, width: eyeRadius * 1.3, height: eyeRadius * 1.7),
      eyePaint,
    );
    // Brillo principal blanco
    canvas.drawCircle(
      Offset(eyeLeft.dx - eyeRadius * 0.25, eyeLeft.dy - eyeRadius * 0.35),
      eyeRadius * 0.42,
      Paint()..color = Colors.white,
    );
    // Brillo secundario blanco
    canvas.drawCircle(
      Offset(eyeLeft.dx + eyeRadius * 0.3, eyeLeft.dy + eyeRadius * 0.3),
      eyeRadius * 0.2,
      Paint()..color = Colors.white.withOpacity(0.85),
    );

    // Ojo Derecho
    final eyeRight = Offset(center.dx + eyeDistance, eyeY);
    canvas.drawOval(
      Rect.fromCenter(center: eyeRight, width: eyeRadius * 1.3, height: eyeRadius * 1.7),
      eyePaint,
    );
    // Brillo principal blanco
    canvas.drawCircle(
      Offset(eyeRight.dx - eyeRadius * 0.25, eyeRight.dy - eyeRadius * 0.35),
      eyeRadius * 0.42,
      Paint()..color = Colors.white,
    );
    // Brillo secundario blanco
    canvas.drawCircle(
      Offset(eyeRight.dx + eyeRadius * 0.3, eyeRight.dy + eyeRadius * 0.3),
      eyeRadius * 0.2,
      Paint()..color = Colors.white.withOpacity(0.85),
    );
    canvas.restore();

    // 6. SONRISA CONTENTA
    final mouthPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radio * 0.075
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(center.dx - radio * 0.22, center.dy + radio * 0.28)
      ..quadraticBezierTo(
        center.dx,
        center.dy + radio * 0.48,
        center.dx + radio * 0.22,
        center.dy + radio * 0.28,
      );
    canvas.drawPath(mouthPath, mouthPaint);

    // 7. CAPA DE ACCESORIOS / PRENDAS DESBLOQUEADAS
    _dibujarPrendaEquipada(canvas, center, radio, w, h);
  }

  void _dibujarCapaHeroe(Canvas canvas, Offset center, double radio, double w, double h) {
    final wave = math.sin(animationValue * 2 * math.pi) * radio * 0.08;
    final capaPath = Path()
      ..moveTo(center.dx - radio * 0.7, center.dy + radio * 0.2)
      ..quadraticBezierTo(
        center.dx - radio * 1.1,
        center.dy + radio * 0.9 + wave,
        center.dx - radio * 0.8,
        center.dy + radio * 1.25,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + radio * 1.1 + wave,
        center.dx + radio * 0.8,
        center.dy + radio * 1.25,
      )
      ..quadraticBezierTo(
        center.dx + radio * 1.1,
        center.dy + radio * 0.9 - wave,
        center.dx + radio * 0.7,
        center.dy + radio * 0.2,
      )
      ..close();

    final capaShader = const LinearGradient(
      colors: [Color(0xFFDC2626), Color(0xFFEA580C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromCenter(center: center, width: radio * 2, height: radio * 2));

    canvas.drawPath(capaPath, Paint()..shader = capaShader);
    canvas.drawPath(
      capaPath,
      Paint()
        ..color = const Color(0xFF991B1B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * 0.05,
    );
  }

  void _dibujarPrendaEquipada(Canvas canvas, Offset center, double radio, double w, double h) {
    switch (prendaId) {
      case 'gorra_deportiva':
        _dibujarGorra(canvas, center, radio);
        break;
      case 'gafas_sol':
        _dibujarGafasSol(canvas, center, radio);
        break;
      case 'bufanda_cozy':
        _dibujarBufanda(canvas, center, radio);
        break;
      case 'auriculares_gamer':
        _dibujarAuriculares(canvas, center, radio);
        break;
      case 'corbata_gala':
        _dibujarCorbata(canvas, center, radio);
        break;
      case 'corona_dorada':
        _dibujarCorona(canvas, center, radio);
        break;
      case 'casco_astronauta':
        _dibujarCascoAstronauta(canvas, center, radio);
        break;
      case 'halo_celestial':
        _dibujarHalo(canvas, center, radio);
        break;
      case 'ninguno':
      default:
        break;
    }
  }

  // 1. Gorra Deportiva
  void _dibujarGorra(Canvas canvas, Offset center, double radio) {
    final capPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      ).createShader(Rect.fromCircle(center: center, radius: radio));

    // Copa de la gorra inclinada
    final capPath = Path()
      ..moveTo(center.dx - radio * 0.8, center.dy - radio * 0.55)
      ..quadraticBezierTo(
        center.dx,
        center.dy - radio * 1.35,
        center.dx + radio * 0.8,
        center.dy - radio * 0.55,
      )
      ..close();
    canvas.drawPath(capPath, capPaint);

    // Visera hacia la derecha
    final visorPath = Path()
      ..moveTo(center.dx - radio * 0.2, center.dy - radio * 0.55)
      ..quadraticBezierTo(
        center.dx + radio * 1.25,
        center.dy - radio * 0.7,
        center.dx + radio * 1.1,
        center.dy - radio * 0.35,
      )
      ..quadraticBezierTo(
        center.dx + radio * 0.5,
        center.dy - radio * 0.45,
        center.dx - radio * 0.2,
        center.dy - radio * 0.55,
      );
    canvas.drawPath(
      visorPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF172554)],
        ).createShader(Rect.fromCircle(center: center, radius: radio)),
    );

    // Botón superior de la gorra
    canvas.drawCircle(
      Offset(center.dx, center.dy - radio * 1.05),
      radio * 0.1,
      Paint()..color = const Color(0xFFFBBF24),
    );
  }

  // 2. Gafas de Sol
  void _dibujarGafasSol(Canvas canvas, Offset center, double radio) {
    final eyeY = center.dy - radio * 0.15;
    final glassPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radio));

    final glassBorder = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radio * 0.06;

    // Lente izquierdo
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx - radio * 0.38, eyeY),
        width: radio * 0.62,
        height: radio * 0.45,
      ),
      Radius.circular(radio * 0.14),
    );
    canvas.drawRRect(leftRect, glassPaint);
    canvas.drawRRect(leftRect, glassBorder);

    // Lente derecho
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx + radio * 0.38, eyeY),
        width: radio * 0.62,
        height: radio * 0.45,
      ),
      Radius.circular(radio * 0.14),
    );
    canvas.drawRRect(rightRect, glassPaint);
    canvas.drawRRect(rightRect, glassBorder);

    // Puente de las gafas
    canvas.drawLine(
      Offset(center.dx - radio * 0.1, eyeY - radio * 0.05),
      Offset(center.dx + radio * 0.1, eyeY - radio * 0.05),
      Paint()
        ..color = const Color(0xFF0284C7)
        ..strokeWidth = radio * 0.08
        ..strokeCap = StrokeCap.round,
    );

    // Reflejo blanco diagonal en las gafas
    final reflejoPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = radio * 0.04
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - radio * 0.55, eyeY - radio * 0.12),
      Offset(center.dx - radio * 0.35, eyeY + radio * 0.12),
      reflejoPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radio * 0.2, eyeY - radio * 0.12),
      Offset(center.dx + radio * 0.4, eyeY + radio * 0.12),
      reflejoPaint,
    );
  }

  // 3. Bufanda Abrigada
  void _dibujarBufanda(Canvas canvas, Offset center, double radio) {
    final scarfShader = const LinearGradient(
      colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
    ).createShader(Rect.fromCircle(center: center, radius: radio));

    final scarfPaint = Paint()..shader = scarfShader;

    // Cuello de la bufanda
    final scarfNeck = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radio * 0.72),
        width: radio * 1.5,
        height: radio * 0.38,
      ),
      Radius.circular(radio * 0.18),
    );
    canvas.drawRRect(scarfNeck, scarfPaint);
    canvas.drawRRect(
      scarfNeck,
      Paint()
        ..color = const Color(0xFF991B1B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * 0.05,
    );

    // Extremo colgante de la bufanda
    final tailPath = Path()
      ..moveTo(center.dx + radio * 0.3, center.dy + radio * 0.8)
      ..lineTo(center.dx + radio * 0.65, center.dy + radio * 1.35)
      ..lineTo(center.dx + radio * 0.35, center.dy + radio * 1.4)
      ..lineTo(center.dx + radio * 0.1, center.dy + radio * 0.85)
      ..close();
    canvas.drawPath(tailPath, scarfPaint);

    // Flecos dorados
    for (int i = 0; i < 4; i++) {
      final fx = center.dx + radio * (0.38 + i * 0.08);
      canvas.drawLine(
        Offset(fx, center.dy + radio * 1.35),
        Offset(fx, center.dy + radio * 1.48),
        Paint()
          ..color = const Color(0xFFFBBF24)
          ..strokeWidth = radio * 0.04,
      );
    }
  }

  // 4. Auriculares Gamer
  void _dibujarAuriculares(Canvas canvas, Offset center, double radio) {
    // Diadema superior
    final bandPath = Path()
      ..moveTo(center.dx - radio * 0.95, center.dy)
      ..quadraticBezierTo(
        center.dx,
        center.dy - radio * 1.45,
        center.dx + radio * 0.95,
        center.dy,
      );
    canvas.drawPath(
      bandPath,
      Paint()
        ..color = const Color(0xFF1E1B4B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * 0.15
        ..strokeCap = StrokeCap.round,
    );

    // Almohadilla izquierda con luz neón
    final earL = Offset(center.dx - radio * 0.92, center.dy);
    canvas.drawOval(
      Rect.fromCenter(center: earL, width: radio * 0.32, height: radio * 0.65),
      Paint()..color = const Color(0xFF4338CA),
    );
    canvas.drawOval(
      Rect.fromCenter(center: earL, width: radio * 0.18, height: radio * 0.45),
      Paint()..color = const Color(0xFF06B6D4), // Luz neón cian
    );

    // Almohadilla derecha con luz neón
    final earR = Offset(center.dx + radio * 0.92, center.dy);
    canvas.drawOval(
      Rect.fromCenter(center: earR, width: radio * 0.32, height: radio * 0.65),
      Paint()..color = const Color(0xFF4338CA),
    );
    canvas.drawOval(
      Rect.fromCenter(center: earR, width: radio * 0.18, height: radio * 0.45),
      Paint()..color = const Color(0xFF06B6D4),
    );
  }

  // 5. Corbata / Pajarita de Gala
  void _dibujarCorbata(Canvas canvas, Offset center, double radio) {
    final bowY = center.dy + radio * 0.72;
    final tieShader = const LinearGradient(
      colors: [Color(0xFF0F172A), Color(0xFF334155)],
    ).createShader(Rect.fromCircle(center: center, radius: radio));

    final bowPaint = Paint()..shader = tieShader;

    // Ala izquierda de la pajarita
    final pathL = Path()
      ..moveTo(center.dx, bowY)
      ..lineTo(center.dx - radio * 0.42, bowY - radio * 0.18)
      ..lineTo(center.dx - radio * 0.42, bowY + radio * 0.18)
      ..close();
    canvas.drawPath(pathL, bowPaint);

    // Ala derecha de la pajarita
    final pathR = Path()
      ..moveTo(center.dx, bowY)
      ..lineTo(center.dx + radio * 0.42, bowY - radio * 0.18)
      ..lineTo(center.dx + radio * 0.42, bowY + radio * 0.18)
      ..close();
    canvas.drawPath(pathR, bowPaint);

    // Nudo central dorado
    canvas.drawCircle(
      Offset(center.dx, bowY),
      radio * 0.11,
      Paint()..color = const Color(0xFFF59E0B),
    );
  }

  // 6. Corona Real Dorada
  void _dibujarCorona(Canvas canvas, Offset center, double radio) {
    final crownY = center.dy - radio * 0.9;
    final crownShader = const LinearGradient(
      colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
    ).createShader(Rect.fromCircle(center: center, radius: radio));

    final crownPath = Path()
      ..moveTo(center.dx - radio * 0.55, crownY)
      ..lineTo(center.dx - radio * 0.65, crownY - radio * 0.45)
      ..lineTo(center.dx - radio * 0.25, crownY - radio * 0.2)
      ..lineTo(center.dx, crownY - radio * 0.6) // Pico central más alto
      ..lineTo(center.dx + radio * 0.25, crownY - radio * 0.2)
      ..lineTo(center.dx + radio * 0.65, crownY - radio * 0.45)
      ..lineTo(center.dx + radio * 0.55, crownY)
      ..close();

    canvas.drawPath(crownPath, Paint()..shader = crownShader);
    canvas.drawPath(
      crownPath,
      Paint()
        ..color = const Color(0xFFB45309)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * 0.05,
    );

    // Joyas brillantes
    canvas.drawCircle(Offset(center.dx, crownY - radio * 0.55), radio * 0.06, Paint()..color = const Color(0xFFEF4444)); // Rubí central
    canvas.drawCircle(Offset(center.dx - radio * 0.58, crownY - radio * 0.4), radio * 0.05, Paint()..color = const Color(0xFF3B82F6)); // Zafiro izq
    canvas.drawCircle(Offset(center.dx + radio * 0.58, crownY - radio * 0.4), radio * 0.05, Paint()..color = const Color(0xFF10B981)); // Esmeralda der
  }

  // 7. Casco Espacial de Astronauta
  void _dibujarCascoAstronauta(Canvas canvas, Offset center, double radio) {
    // Burbuja transparente con reflejos
    canvas.drawCircle(
      center,
      radio * 1.05,
      Paint()
        ..color = const Color(0xFF38BDF8).withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * 0.08,
    );

    // Reflejo curvo del cristal
    final glassShine = Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: radio * 0.95),
        -math.pi * 0.75,
        math.pi * 0.5,
        false,
      );
    canvas.drawPath(
      glassShine,
      Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * 0.08
        ..strokeCap = StrokeCap.round,
    );

    // Antena con luz roja
    canvas.drawLine(
      Offset(center.dx, center.dy - radio * 1.05),
      Offset(center.dx, center.dy - radio * 1.35),
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = radio * 0.06,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - radio * 1.38),
      radio * 0.08,
      Paint()..color = const Color(0xFFEF4444),
    );
  }

  // 8. Halo Celestial Legendario
  void _dibujarHalo(Canvas canvas, Offset center, double radio) {
    final haloCenter = Offset(center.dx, center.dy - radio * 1.15);
    final haloRect = Rect.fromCenter(
      center: haloCenter,
      width: radio * 1.25,
      height: radio * 0.35,
    );

    // Resplandor exterior
    canvas.drawOval(
      haloRect,
      Paint()
        ..color = const Color(0xFFFBBF24).withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * 0.16
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Anillo dorado
    canvas.drawOval(
      haloRect,
      Paint()
        ..color = const Color(0xFFFDE047)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * 0.08,
    );
  }

  @override
  bool shouldRepaint(covariant _ZendyPainter oldDelegate) {
    return oldDelegate.prendaId != prendaId ||
        oldDelegate.blinkScale != blinkScale ||
        oldDelegate.animationValue != animationValue;
  }
}
