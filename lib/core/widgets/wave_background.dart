import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class WaveBackgroundPainter extends CustomPainter {
  final bool isDark;
  final Color primaryColor;

  WaveBackgroundPainter({
    this.isDark = false,
    this.primaryColor = AppColors.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = isDark
          ? primaryColor.withValues(alpha: 0.12)
          : primaryColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = isDark
          ? primaryColor.withValues(alpha: 0.22)
          : primaryColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    // Wave 1 (Fondo)
    final path1 = Path();
    path1.moveTo(0, size.height * 0.55);
    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.40,
      size.width * 0.55,
      size.height * 0.60,
    );
    path1.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.78,
      size.width,
      size.height * 0.65,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Wave 2 (Frente)
    final path2 = Path();
    path2.moveTo(0, size.height * 0.72);
    path2.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.58,
      size.width * 0.70,
      size.height * 0.78,
    );
    path2.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.86,
      size.width,
      size.height * 0.75,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant WaveBackgroundPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.primaryColor != primaryColor;
}

class WaveBackground extends StatelessWidget {
  final double height;
  final bool isDark;
  final Color? color;

  const WaveBackground({
    super.key,
    this.height = 160,
    this.isDark = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).primaryColor;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: WaveBackgroundPainter(
          isDark: isDark,
          primaryColor: effectiveColor,
        ),
      ),
    );
  }
}
