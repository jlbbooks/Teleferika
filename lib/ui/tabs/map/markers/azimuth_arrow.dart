import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// Azimuth arrow widget for project azimuth
class AzimuthArrow extends StatelessWidget {
  final double azimuth;

  const AzimuthArrow({super.key, required this.azimuth});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: (azimuth - 90) * 3.141592653589793 / 180.0,
      child: CustomPaint(
        size: const Size(32, 32),
        painter: StaticArrowPainter(),
      ),
    );
  }
}

class StaticArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double arrowLength = 20;
    final double baseRadius = 4;
    final double angle = 0.0; // Upwards

    // Tip of the arrow
    final tip = Offset(
      center.dx + arrowLength * math.cos(angle),
      center.dy + arrowLength * math.sin(angle),
    );
    // Base left/right (flat base at baseRadius from center)
    final left = Offset(
      center.dx + baseRadius * math.cos(angle + 2.5),
      center.dy + baseRadius * math.sin(angle + 2.5),
    );
    final right = Offset(
      center.dx + baseRadius * math.cos(angle - 2.5),
      center.dy + baseRadius * math.sin(angle - 2.5),
    );

    final path = ui.Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    final paint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
