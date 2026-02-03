import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:teleferika/map/markers/azimuth_arrow.dart';

// Custom marker: red transparent accuracy circle with current location icon
class CurrentLocationAccuracyMarker extends StatelessWidget {
  final double? accuracy;
  final double zoomLevel;

  const CurrentLocationAccuracyMarker({
    super.key,
    this.accuracy,
    required this.zoomLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(60, 60),
          painter: AccuracyCirclePainter(
            accuracy: accuracy,
            zoomLevel: zoomLevel,
          ),
        ),
        const Icon(Icons.my_location, color: Colors.black, size: 20),
      ],
    );
  }
}

class AccuracyCirclePainter extends CustomPainter {
  final double? accuracy;
  final double zoomLevel;

  AccuracyCirclePainter({this.accuracy, required this.zoomLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Calculate the actual radius in pixels based on GPS accuracy and zoom level
    // Accuracy is in meters (from Position.accuracy for internal GPS or calculated from HDOP for BLE GPS)
    double accuracyRadius;

    if (accuracy != null && accuracy! > 0) {
      // Convert meters to pixels at the current zoom level
      // At zoom level 0, 1 pixel = ~156543 meters (at equator)
      // Each zoom level doubles the resolution
      // Note: This calculation assumes equator; at higher latitudes, meters per pixel is smaller
      // (by factor of cos(latitude)), but this approximation is acceptable for visualization
      final metersPerPixelAtZoom0 =
          156543.0; // meters per pixel at zoom 0 (at equator)
      final metersPerPixel = metersPerPixelAtZoom0 / (1 << zoomLevel.round());

      // Calculate radius in pixels from accuracy in meters
      // The accuracy value represents the radius of uncertainty in meters
      final radiusInPixels = accuracy! / metersPerPixel;

      // Clamp the radius to reasonable bounds (5 to 50 pixels) for visibility
      // Very small accuracy values (< 5 pixels) would be hard to see
      // Very large accuracy values (> 50 pixels) would dominate the marker
      accuracyRadius = radiusInPixels.clamp(5.0, 50.0);
    } else {
      // Default radius if no accuracy data (show full marker size)
      accuracyRadius = size.width / 2;
    }

    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, accuracyRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is AccuracyCirclePainter) {
      return oldDelegate.accuracy != accuracy ||
          oldDelegate.zoomLevel != zoomLevel;
    }
    return true;
  }
}

// Custom marker: current location with azimuth arrow overlay
class CurrentLocationWithAzimuthMarker extends StatelessWidget {
  final double? accuracy;
  final double zoomLevel;
  final double? azimuth;
  final double? deviceHeading; // Add device heading to compensate for rotation
  final double?
  mapRotation; // Add map rotation to compensate for map orientation

  const CurrentLocationWithAzimuthMarker({
    super.key,
    this.accuracy,
    required this.zoomLevel,
    this.azimuth,
    this.deviceHeading,
    this.mapRotation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Current location accuracy circle
        CustomPaint(
          size: const Size(60, 60),
          painter: AccuracyCirclePainter(
            accuracy: accuracy,
            zoomLevel: zoomLevel,
          ),
        ),
        // Current location icon
        const Icon(Icons.my_location, color: Colors.black, size: 20),
        // Azimuth arrow overlay (if azimuth is provided)
        if (azimuth != null)
          Positioned(
            top: 0,
            child: Transform.rotate(
              // Compensate for device rotation and map rotation to keep azimuth arrow pointing in true direction
              angle: mapRotation != null ? mapRotation! * math.pi / 180.0 : 0,
              child: AzimuthArrow(
                azimuth: azimuth!,
              ), // Pass the actual azimuth, let AzimuthArrow handle its own rotation
            ),
          ),
      ],
    );
  }
}
