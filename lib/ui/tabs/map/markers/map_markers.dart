import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class MapMarkers {
  static List<Marker> buildAllMapMarkers({
    required BuildContext context,
    required List<PointModel> projectPoints,
    required String? selectedPointId,
    required bool isMovePointMode,
    required double glowAnimationValue,
    required Position? currentPosition,
    required bool hasLocationPermission,
    required double? headingFromFirstToLast,
    required Function(PointModel) onPointTap,
    double? currentDeviceHeading,
  }) {
    List<Marker> projectPointMarkers = projectPoints.map((point) {
      return Marker(
        width: 60,
        height: 58,
        point: LatLng(point.latitude, point.longitude),
        child: _buildProjectPointMarker(
          point: point,
          isSelected: point.id == selectedPointId,
          isInMoveMode: isMovePointMode && point.id == selectedPointId,
          glowAnimationValue: glowAnimationValue,
          onTap: onPointTap,
        ),
      );
    }).toList();

    List<Marker> allMarkers = [];

    // Add angle arc markers for intermediate points FIRST
    if (projectPoints.length > 2) {
      for (int i = 1; i < projectPoints.length - 1; i++) {
        final prev = projectPoints[i - 1];
        final curr = projectPoints[i];
        final next = projectPoints[i + 1];
        allMarkers.add(
          Marker(
            width: 80,
            height: 80,
            point: LatLng(curr.latitude, curr.longitude),
            child: AngleArcWidget(
              prev: LatLng(prev.latitude, prev.longitude),
              curr: LatLng(curr.latitude, curr.longitude),
              next: LatLng(next.latitude, next.longitude),
              radius: 36,
              arcWidth: 2,
            ),
          ),
        );
      }
    }

    // THEN add the point markers
    allMarkers.addAll(projectPointMarkers);

    // Add heading label marker
    if (headingFromFirstToLast != null && projectPoints.length >= 2) {
      allMarkers.add(
        _buildHeadingLabelMarker(
          context,
          projectPoints,
          headingFromFirstToLast,
        ),
      );
    }

    return allMarkers;
  }

  static Widget _buildProjectPointMarker({
    required PointModel point,
    required bool isSelected,
    required bool isInMoveMode,
    required double glowAnimationValue,
    required Function(PointModel) onTap,
  }) {
    // Calculate glow color for move mode
    Color? glowColor;
    if (isInMoveMode) {
      final intensity = (math.sin(glowAnimationValue) + 1) / 2; // 0 to 1
      glowColor = Color.lerp(
        Colors.blue, // Selection color
        Colors.purpleAccent, // Move mode color - more vibrant
        intensity,
      );
    }

    // Determine marker color based on point state
    Color markerColor;
    if (point.isUnsaved) {
      markerColor = Colors.orange; // Orange for new unsaved points
    } else if (isInMoveMode) {
      markerColor = glowColor ?? Colors.purpleAccent;
    } else if (isSelected) {
      markerColor = Colors.blue;
    } else {
      markerColor = Colors.red;
    }

    return GestureDetector(
      onTap: () => onTap(point),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Marker icon
          Icon(Icons.location_pin, color: markerColor, size: 30.0),
          const SizedBox(height: 4),
          // Point label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: point.isUnsaved
                  ? Colors.orange
                  : (isSelected ? Colors.blue : Colors.white),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: point.isUnsaved
                    ? Colors.orange
                    : (isSelected ? Colors.blue : Colors.grey.shade300),
                width: point.isUnsaved ? 2 : 1, // Thicker border for new points
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: (point.isUnsaved ? 0.2 : 0.1),
                  ),
                  blurRadius: point.isUnsaved ? 4 : 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              point.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: point.isUnsaved
                    ? Colors.white
                    : (isSelected ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Marker _buildHeadingLabelMarker(
    BuildContext context,
    List<PointModel> points,
    double heading,
  ) {
    if (points.length < 2) {
      throw StateError(
        'Cannot build heading label marker with fewer than 2 points',
      );
    }

    final firstP = points.first;
    final lastP = points.last;
    final midLat = (firstP.latitude + lastP.latitude) / 2;
    final midLon = (firstP.longitude + lastP.longitude) / 2;
    // No rotation for the label itself

    return Marker(
      point: LatLng(midLat, midLon),
      width: 120,
      height: 30,
      child: Center(
        child: Text(
          S.of(context)?.headingLabel(heading.toStringAsFixed(1)) ??
              'Heading: ${heading.toStringAsFixed(1)}°',
          style: const TextStyle(color: Colors.black, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class AngleArcWidget extends StatelessWidget {
  final LatLng prev;
  final LatLng curr;
  final LatLng next;
  final double radius;
  final double arcWidth;

  const AngleArcWidget({
    super.key,
    required this.prev,
    required this.curr,
    required this.next,
    this.radius = 40,
    this.arcWidth = 4,
  });

  // Simple conversion for demo: treat lat/lon as y/x (not for production, but works for small areas)
  Offset _latLngToOffset(LatLng base, LatLng p) {
    // 1 deg lat ~ 111km, 1 deg lon ~ 111km * cos(lat)
    const scale = 100000.0; // exaggerate for demo
    final dx =
        (p.longitude - base.longitude) *
        scale *
        math.cos(base.latitude * math.pi / 180);
    final dy = (p.latitude - base.latitude) * scale;
    return Offset(dx, -dy); // -dy so north is up
  }

  @override
  Widget build(BuildContext context) {
    // Center the widget at curr
    final base = curr;
    final prevOffset = _latLngToOffset(base, prev);
    final currOffset = Offset.zero;
    final nextOffset = _latLngToOffset(base, next);
    return CustomPaint(
      size: Size(radius * 2, radius * 2),
      painter: _AngleArcPainter(
        prev: prevOffset,
        curr: currOffset,
        next: nextOffset,
        radius: radius,
        arcWidth: arcWidth,
      ),
    );
  }
}

class _AngleArcPainter extends CustomPainter {
  final Offset prev;
  final Offset curr;
  final Offset next;
  final double radius;
  final double arcWidth;

  _AngleArcPainter({
    required this.prev,
    required this.curr,
    required this.next,
    required this.radius,
    required this.arcWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Vectors from current to previous and next
    final v1 = prev - curr;
    final v2 = next - curr;

    // Angles of the vectors
    double angle1 = math.atan2(v1.dy, v1.dx);
    double angle2 = math.atan2(v2.dy, v2.dx);

    // Sweep angle (convex)
    double sweep = angle2 - angle1;
    if (sweep <= -math.pi) sweep += 2 * math.pi;
    if (sweep > math.pi) sweep -= 2 * math.pi;
    if (sweep < 0) {
      // Always draw positive sweep (convex)
      final tmp = angle1;
      angle1 = angle2;
      angle2 = tmp;
      sweep = -sweep;
    }

    // Draw arc
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = arcWidth;
    canvas.drawArc(arcRect, angle1, sweep, false, paint);

    // Draw angle label
    final midAngle = angle1 + sweep / 2;
    final labelPos = Offset(
      center.dx + (radius + 16) * math.cos(midAngle),
      center.dy + (radius + 16) * math.sin(midAngle),
    );
    final angleDeg = (180.0 - (sweep * 180 / math.pi).abs()).abs();
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${angleDeg.toStringAsFixed(1)}°',
        style: TextStyle(
          color: _labelColor(angleDeg),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      labelPos - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // Helper to interpolate label color from black (0°) to red (20° or more)
  Color _labelColor(double angleDeg) {
    if (angleDeg <= 0) return Colors.black;
    if (angleDeg >= 20) return Colors.red;
    final t = (angleDeg / 20).clamp(0.0, 1.0);
    return Color.lerp(Colors.black, Colors.red, t)!;
  }
}
