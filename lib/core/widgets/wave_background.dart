import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class WaveBackgroundPainter extends CustomPainter {
  final bool isDark;

  WaveBackgroundPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = isDark
          ? const Color(0xFF1E293B).withOpacity(0.5)
          : const Color(0xFFE0ECFD).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = isDark
          ? AppColors.primaryDark.withOpacity(0.3)
          : AppColors.primary.withOpacity(0.35)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WaveBackground extends StatelessWidget {
  final double height;
  final bool isDark;

  const WaveBackground({
    super.key,
    this.height = 160,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: WaveBackgroundPainter(isDark: isDark),
      ),
    );
  }
}
