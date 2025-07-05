import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PolylinePathArrowheadMarker extends Marker {
  PolylinePathArrowheadMarker({
    required List<LatLng> pathPoints,
    required double t,
  }) : super(
         width: 16,
         height: 16,
         point: _interpolateAlongPath(pathPoints, t),
         child: PolylinePathArrowheadWidget(pathPoints: pathPoints, t: t),
       );

  static LatLng _interpolateAlongPath(List<LatLng> pathPoints, double t) {
    if (pathPoints.length < 2) {
      return pathPoints.first;
    }

    // Calculate total path length
    double totalLength = 0.0;
    for (int i = 0; i < pathPoints.length - 1; i++) {
      totalLength += _calculateDistance(pathPoints[i], pathPoints[i + 1]);
    }

    // Find the target distance along the path (reversed: start from end)
    double targetDistance = totalLength * (1.0 - t);

    // Find the segment and position within that segment
    double currentDistance = 0.0;
    for (int i = 0; i < pathPoints.length - 1; i++) {
      double segmentLength = _calculateDistance(
        pathPoints[i],
        pathPoints[i + 1],
      );

      if (currentDistance + segmentLength >= targetDistance) {
        // We're in this segment
        double segmentT = (targetDistance - currentDistance) / segmentLength;
        return _interpolateLatLng(pathPoints[i], pathPoints[i + 1], segmentT);
      }

      currentDistance += segmentLength;
    }

    // If we reach here, we're at the beginning of the path
    return pathPoints.first;
  }

  static double _calculateDistance(LatLng a, LatLng b) {
    const double earthRadius = 6371000; // meters
    final double lat1 = a.latitude * math.pi / 180;
    final double lat2 = b.latitude * math.pi / 180;
    final double deltaLat = (b.latitude - a.latitude) * math.pi / 180;
    final double deltaLon = (b.longitude - a.longitude) * math.pi / 180;

    final double a1 =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a1), math.sqrt(1 - a1));

    return earthRadius * c;
  }

  static LatLng _interpolateLatLng(LatLng a, LatLng b, double t) {
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }
}

class PolylinePathArrowheadWidget extends StatelessWidget {
  final List<LatLng> pathPoints;
  final double t;

  const PolylinePathArrowheadWidget({
    super.key,
    required this.pathPoints,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    // Find the current segment and calculate the direction
    final (currentPoint, nextPoint) = _getCurrentSegment();

    // Calculate angle for arrowhead
    final dx = nextPoint.longitude - currentPoint.longitude;
    final dy = nextPoint.latitude - currentPoint.latitude;
    final angle = math.atan2(dy, dx);

    return Transform.rotate(
      angle: angle + math.pi,
      child: CustomPaint(size: const Size(16, 16), painter: ArrowheadPainter()),
    );
  }

  (LatLng, LatLng) _getCurrentSegment() {
    if (pathPoints.length < 2) {
      return (pathPoints.first, pathPoints.first);
    }

    // Calculate total path length
    double totalLength = 0.0;
    for (int i = 0; i < pathPoints.length - 1; i++) {
      totalLength += _calculateDistance(pathPoints[i], pathPoints[i + 1]);
    }

    // Find the target distance along the path (reversed: start from end)
    double targetDistance = totalLength * (1.0 - t);

    // Find the segment and position within that segment
    double currentDistance = 0.0;
    for (int i = 0; i < pathPoints.length - 1; i++) {
      double segmentLength = _calculateDistance(
        pathPoints[i],
        pathPoints[i + 1],
      );

      if (currentDistance + segmentLength >= targetDistance) {
        // We're in this segment
        return (pathPoints[i], pathPoints[i + 1]);
      }

      currentDistance += segmentLength;
    }

    // If we reach here, we're at the beginning of the path
    return (pathPoints[0], pathPoints[1]);
  }

  double _calculateDistance(LatLng a, LatLng b) {
    const double earthRadius = 6371000; // meters
    final double lat1 = a.latitude * math.pi / 180;
    final double lat2 = b.latitude * math.pi / 180;
    final double deltaLat = (b.latitude - a.latitude) * math.pi / 180;
    final double deltaLon = (b.longitude - a.longitude) * math.pi / 180;

    final double a1 =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a1), math.sqrt(1 - a1));

    return earthRadius * c;
  }
}

class ArrowheadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const ui.Color.fromARGB(255, 41, 111, 114)
      ..style = PaintingStyle.fill;
    // Draw a filled circle instead of an arrowhead
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
