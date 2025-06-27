import 'dart:math' as math;

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
      allMarkers.add(_buildHeadingLabelMarker(projectPoints, headingFromFirstToLast));
    }

    // Add current position crosshair marker
    if (currentPosition != null && hasLocationPermission) {
      allMarkers.add(_buildCurrentPositionMarker(currentPosition));
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

    return GestureDetector(
      onTap: () => onTap(point),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Marker icon
          Icon(
            Icons.location_pin,
            color: isInMoveMode
                ? glowColor ?? Colors.purpleAccent
                : (isSelected ? Colors.blue : Colors.red),
            size: 30.0,
          ),
          const SizedBox(height: 4),
          // Point label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              point.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Marker _buildHeadingLabelMarker(List<PointModel> points, double heading) {
    if (points.length < 2) {
      throw StateError('Cannot build heading label marker with less than 2 points');
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