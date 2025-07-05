import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/tabs/map/services/geometry_service.dart';
import 'package:teleferika/core/project_provider.dart';

class MapMarkers {
  static List<Marker> buildAllMapMarkers({
    required BuildContext context,
    required String? selectedPointId,
    required bool isMovePointMode,
    required double glowAnimationValue,
    required Position? currentPosition,
    required bool hasLocationPermission,
    required double? headingFromFirstToLast,
    required Function(PointModel) onPointTap,
    double? currentDeviceHeading,
  }) {
    // Get points from global state
    final projectPoints = context.projectStateListen.currentPoints;

    List<Marker> projectPointMarkers = projectPoints.map((point) {
      return Marker(
        width: 60,
        height: 58,
        point: LatLng(point.latitude, point.longitude),
        child: _buildProjectPointMarker(
          context: context,
          point: point,
          isSelected: point.id == selectedPointId,
          isInMoveMode: isMovePointMode && point.id == selectedPointId,
          glowAnimationValue: glowAnimationValue,
          onTap: onPointTap,
          allPoints: projectPoints,
        ),
      );
    }).toList();

    List<Marker> allMarkers = [];

    // Angle arcs are now handled as polylines in FlutterMapWidget
    // No need to add them as markers here

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
    required BuildContext context,
    required PointModel point,
    required bool isSelected,
    required bool isInMoveMode,
    required double glowAnimationValue,
    required Function(PointModel) onTap,
    required List<PointModel> allPoints,
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
      // Use angle-based color for regular points
      final geometryService = GeometryService(
        project: context.projectStateListen.currentProject!,
      );
      markerColor = geometryService.getPointColor(point, allPoints);
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
