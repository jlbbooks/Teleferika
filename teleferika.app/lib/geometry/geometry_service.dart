import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/core/logger.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/core/app_config.dart';

// Shared color interpolation for angle-based coloring (black/green to red)
Color angleColor(double angleDeg) {
  if (angleDeg <= 0) return AppConfig.angleColorGood;
  if (angleDeg >= AppConfig.angleToRedThreshold) return AppConfig.angleColorBad;
  // Use a non-linear interpolation: ease-in (t^2)
  final t = (angleDeg / AppConfig.angleToRedThreshold).clamp(0.0, 1.0);
  final curvedT = t * t; // Quadratic ease-in
  return Color.lerp(
    AppConfig.angleColorGood,
    AppConfig.angleColorBad,
    curvedT,
  )!;
}

class GeometryService {
  final ProjectModel project;

  GeometryService({required this.project});

  // Map calculations
  double? recalculateConnectingLine(List<PointModel> projectPoints) {
    if (projectPoints.length >= 2) {
      return calculateBearing(
        LatLng(projectPoints.first.latitude, projectPoints.first.longitude),
        LatLng(projectPoints.last.latitude, projectPoints.last.longitude),
      );
    }
    return null;
  }

  Polyline? recalculateProjectHeadingLine(List<PointModel> projectPoints) {
    if (projectPoints.isEmpty || project.azimuth == null) {
      return null;
    }

    try {
      final firstPoint = LatLng(
        projectPoints.first.latitude,
        projectPoints.first.longitude,
      );
      final projectHeading = project.azimuth!;

      // Use presumed total length from project, default to 500m if not provided
      final lineLengthKm =
          (project.presumedTotalLength ?? 500.0) /
          1000.0; // Convert meters to kilometers

      final endPoint = _calculateDestinationPoint(
        firstPoint,
        projectHeading,
        lineLengthKm,
      );

      return Polyline(
        points: [firstPoint, endPoint],
        strokeWidth: 2.0,
        color: Colors.black, // Choose a distinct color
        pattern: const StrokePattern.dotted(),
      );
    } catch (e) {
      logger.warning('Error calculating project heading line: $e');
      return null;
    }
  }

  // Calculates the shortest distance (in meters) from a given point to the line segment from the first to last point in projectPoints.
  // Returns null if there are fewer than 2 points.
  double? distanceFromPointToFirstLastLine(
    PointModel point,
    List<PointModel> projectPoints,
  ) {
    if (projectPoints.length < 2) {
      return null;
    }
    final a = LatLng(
      projectPoints.first.latitude,
      projectPoints.first.longitude,
    );
    final b = LatLng(projectPoints.last.latitude, projectPoints.last.longitude);
    final p = LatLng(point.latitude, point.longitude);
    return _distanceToSegment(p, a, b);
  }

  // Helper functions
  double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;

  double _radiansToDegrees(double radians) => radians * 180.0 / math.pi;

  // Function to calculate initial bearing from point1 to point2
  double calculateBearing(LatLng point1, LatLng point2) {
    final lat1 = _degreesToRadians(point1.latitude);
    final lon1 = _degreesToRadians(point1.longitude);
    final lat2 = _degreesToRadians(point2.latitude);
    final lon2 = _degreesToRadians(point2.longitude);

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    var initialBearingRadians = math.atan2(y, x);
    var initialBearingDegrees = _radiansToDegrees(initialBearingRadians);

    // Normalize to 0-360 degrees
    return (initialBearingDegrees + 360) % 360;
  }

  // Helper function to calculate a destination point given a starting point, bearing, and distance
  LatLng _calculateDestinationPoint(
    LatLng startPoint,
    double bearingDegrees,
    double distanceKm,
  ) {
    const R = 6371.0; // Earth's radius in kilometers
    final lat1 = _degreesToRadians(startPoint.latitude);
    final lon1 = _degreesToRadians(startPoint.longitude);
    final bearingRad = _degreesToRadians(bearingDegrees);

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(distanceKm / R) +
          math.cos(lat1) * math.sin(distanceKm / R) * math.cos(bearingRad),
    );
    final lon2 =
        lon1 +
        math.atan2(
          math.sin(bearingRad) * math.sin(distanceKm / R) * math.cos(lat1),
          math.cos(distanceKm / R) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(_radiansToDegrees(lat2), _radiansToDegrees(lon2));
  }

  // Helper: Returns the shortest distance (in meters) from point P to segment AB (all LatLng)
  double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    // Convert to radians
    final lat1 = _degreesToRadians(a.latitude);
    final lon1 = _degreesToRadians(a.longitude);
    final lat2 = _degreesToRadians(b.latitude);
    final lon2 = _degreesToRadians(b.longitude);
    final latP = _degreesToRadians(p.latitude);
    final lonP = _degreesToRadians(p.longitude);

    // Convert to ECEF (Earth-Centered, Earth-Fixed) XYZ coordinates
    List<double> toEcef(double lat, double lon) {
      const R = 6371000.0; // meters
      final x = R * math.cos(lat) * math.cos(lon);
      final y = R * math.cos(lat) * math.sin(lon);
      final z = R * math.sin(lat);
      return [x, y, z];
    }

    final aEcef = toEcef(lat1, lon1);
    final bEcef = toEcef(lat2, lon2);
    final pEcef = toEcef(latP, lonP);

    // Vector math
    List<double> sub(List<double> u, List<double> v) => [
      u[0] - v[0],
      u[1] - v[1],
      u[2] - v[2],
    ];
    double dot(List<double> u, List<double> v) =>
        u[0] * v[0] + u[1] * v[1] + u[2] * v[2];
    double norm2(List<double> u) => dot(u, u);

    final ab = sub(bEcef, aEcef);
    final ap = sub(pEcef, aEcef);
    final ab2 = norm2(ab);
    final t = ab2 == 0 ? 0.0 : (dot(ap, ab) / ab2).clamp(0.0, 1.0);
    final closest = [
      aEcef[0] + ab[0] * t,
      aEcef[1] + ab[1] * t,
      aEcef[2] + ab[2] * t,
    ];
    final diff = sub(pEcef, closest);
    final distance = math.sqrt(norm2(diff));
    return distance;
  }

  /// Calculate the angle at a point between two connecting polylines
  /// Returns the angle in degrees (0-180, where 180 is a straight line)
  /// Returns null if the point is not an intermediate point (first or last)
  double? calculateAngleAtPoint(PointModel point, List<PointModel> allPoints) {
    final pointIndex = allPoints.indexWhere((p) => p.id == point.id);
    if (pointIndex <= 0 || pointIndex >= allPoints.length - 1) {
      return null; // First or last point
    }

    final prev = allPoints[pointIndex - 1];
    final curr = allPoints[pointIndex];
    final next = allPoints[pointIndex + 1];

    // Vector math (lat/lon as y/x)
    final v1x = prev.longitude - curr.longitude;
    final v1y = prev.latitude - curr.latitude;
    final v2x = next.longitude - curr.longitude;
    final v2y = next.latitude - curr.latitude;
    final angle1 = math.atan2(v1y, v1x);
    final angle2 = math.atan2(v2y, v2x);
    double sweep = angle2 - angle1;
    if (sweep <= -math.pi) sweep += 2 * math.pi;
    if (sweep > math.pi) sweep -= 2 * math.pi;
    if (sweep < 0) sweep = -sweep;
    final angleDeg = (180.0 - (sweep * 180 / math.pi).abs()).abs();
    return angleDeg;
  }

  /// Get the color for a point based on its angle
  /// Returns green for first/last points, angle-based color for intermediate points
  Color getPointColor(PointModel point, List<PointModel> allPoints) {
    final angleDeg = calculateAngleAtPoint(point, allPoints);
    if (angleDeg == null) {
      return AppConfig.angleColorGood; // First or last point
    }
    return angleColor(angleDeg);
  }
}
