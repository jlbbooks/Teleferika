import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:teleferika/map/markers/azimuth_arrow.dart';

/// Current-location icon with optional project azimuth arrow.
///
/// GPS accuracy is drawn by [CurrentLocationLayer] via flutter_map's
/// [CircleLayer] (`showAccuracyCircle: true`), not inside this widget.
class CurrentLocationWithAzimuthMarker extends StatelessWidget {
  final double? azimuth;
  final double? deviceHeading; // Add device heading to compensate for rotation
  final double?
  mapRotation; // Add map rotation to compensate for map orientation

  const CurrentLocationWithAzimuthMarker({
    super.key,
    this.azimuth,
    this.deviceHeading,
    this.mapRotation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
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
