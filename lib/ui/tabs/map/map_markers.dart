import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/db/models/point_model.dart';

class MapMarkers {
  static List<Marker> buildAllMapMarkers({
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

    List<Marker> allMarkers = [...projectPointMarkers];

    // Add heading label marker
    if (headingFromFirstToLast != null && projectPoints.length >= 2) {
      allMarkers.add(
        _buildHeadingLabelMarker(projectPoints, headingFromFirstToLast),
      );
    }

    // Add current position crosshair marker
    if (currentPosition != null && hasLocationPermission) {
      allMarkers.add(_buildCurrentPositionMarker(currentPosition));

      // Add compass direction marker if heading is available
      if (currentDeviceHeading != null) {
        final compassMarker = _buildCompassDirectionMarker(
          currentPosition,
          currentDeviceHeading,
        );
        if (compassMarker != null) {
          allMarkers.add(compassMarker);
        }
      }
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
                  color: Colors.black.withOpacity(point.isUnsaved ? 0.2 : 0.1),
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
    List<PointModel> points,
    double heading,
  ) {
    if (points.length < 2) {
      throw StateError(
        'Cannot build heading label marker with less than 2 points',
      );
    }

    final firstP = points.first;
    final lastP = points.last;
    final midLat = (firstP.latitude + lastP.latitude) / 2;
    final midLon = (firstP.longitude + lastP.longitude) / 2;
    final angleForRotation = _degreesToRadians(heading);

    return Marker(
      point: LatLng(midLat, midLon),
      width: 120,
      height: 30,
      child: Transform.rotate(
        angle: angleForRotation - (math.pi / 2),
        alignment: Alignment.center,
        child: Card(
          elevation: 2.0,
          color: Colors.white.withAlpha((0.9 * 255).round()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
            side: BorderSide(
              color: Colors.purple.withAlpha((0.7 * 255).round()),
              width: 1,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(3, 1, 3, 0),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Heading: ${heading.toStringAsFixed(1)}°',
              style: const TextStyle(color: Colors.black, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  static Marker _buildCurrentPositionMarker(Position position) {
    return Marker(
      width: 30,
      height: 30,
      point: LatLng(position.latitude, position.longitude),
      child: _buildCrosshairMarker(),
    );
  }

  static Marker? _buildCompassDirectionMarker(
    Position position,
    double heading,
  ) {
    return Marker(
      width: 40,
      height: 40,
      point: LatLng(position.latitude, position.longitude),
      child: _buildCompassArrow(heading),
    );
  }

  static Widget _buildCompassArrow(double heading) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: _degreesToRadians(-heading),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade600.withOpacity(0.1),
            border: Border.all(color: Colors.blue.shade600, width: 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // North indicator (red arrow)
              Container(
                width: 0,
                height: 0,
                decoration: const BoxDecoration(color: Colors.transparent),
                child: CustomPaint(
                  painter: CompassArrowPainter(),
                  size: const Size(40, 40),
                ),
              ),
              // Center dot
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade600,
                ),
              ),
              // North label
              Positioned(
                top: 2,
                left: 0,
                right: 0,
                child: Text(
                  'N',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildCrosshairMarker() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.shade600.withOpacity(0.1),
          border: Border.all(color: Colors.blue.shade600, width: 2),
        ),
        child: const Icon(Icons.gps_fixed, color: Colors.blue, size: 20),
      ),
    );
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;
}

// Custom painter for the compass arrow
class CompassArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final path = ui.Path();

    // Draw a north-pointing arrow
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final arrowLength = size.width * 0.35;
    final arrowWidth = size.width * 0.15;

    // Arrow head (pointing north)
    path.moveTo(centerX, centerY - arrowLength);
    path.lineTo(centerX - arrowWidth, centerY - arrowLength * 0.3);
    path.lineTo(centerX + arrowWidth, centerY - arrowLength * 0.3);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
