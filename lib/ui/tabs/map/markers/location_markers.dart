import 'package:flutter/material.dart';

// Custom marker: red transparent accuracy circle with current location icon
class CurrentLocationAccuracyMarker extends StatelessWidget {
  final double? accuracy;

  const CurrentLocationAccuracyMarker({super.key, this.accuracy});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(60, 60),
          painter: AccuracyCirclePainter(accuracy: accuracy),
        ),
        const Icon(Icons.my_location, color: Colors.black, size: 20),
      ],
    );
  }
}

class AccuracyCirclePainter extends CustomPainter {
  final double? accuracy;

  AccuracyCirclePainter({this.accuracy});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double accuracyRadius = (accuracy != null)
        ? (accuracy!.clamp(5, 50) / 50.0) * (size.width / 2)
        : size.width / 2;
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, accuracyRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
