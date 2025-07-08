import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/map/services/geometry_service.dart';
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
    // New slide functionality parameters
    required Function(PointModel, LongPressStartDetails) onLongPressStart,
    required Function(PointModel, LongPressMoveUpdateDetails)
    onLongPressMoveUpdate,
    required Function(PointModel, LongPressEndDetails) onLongPressEnd,
    required bool isSlidingMarker,
    required String? slidingPointId,
  }) {
    // Get points from global state
    final projectPoints = context.projectStateListen.currentPoints;

    List<Marker> projectPointMarkers = projectPoints.map((point) {
      return Marker(
        width: 60,
        height: 70,
        point: LatLng(point.latitude, point.longitude),
        child: _buildProjectPointMarker(
          context: context,
          point: point,
          isSelected: point.id == selectedPointId,
          isInMoveMode: isMovePointMode && point.id == selectedPointId,
          glowAnimationValue: glowAnimationValue,
          onTap: onPointTap,
          allPoints: projectPoints,
          // Slide functionality parameters
          onLongPressStart: onLongPressStart,
          onLongPressMoveUpdate: onLongPressMoveUpdate,
          onLongPressEnd: onLongPressEnd,
          isSlidingMarker: isSlidingMarker,
          slidingPointId: slidingPointId,
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
    // Slide functionality parameters
    required Function(PointModel, LongPressStartDetails) onLongPressStart,
    required Function(PointModel, LongPressMoveUpdateDetails)
    onLongPressMoveUpdate,
    required Function(PointModel, LongPressEndDetails) onLongPressEnd,
    required bool isSlidingMarker,
    required String? slidingPointId,
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
    } else if (isSlidingMarker && point.id == slidingPointId) {
      markerColor = Colors.purple; // Purple for sliding marker
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

    // Visual appearance variables - experiment with these values
    const double iconSize = 30.0;
    const double iconToLabelSpacing = 18.0; // Space between icon and label
    const double labelBottomOffset =
        14.0; // Distance from icon tip to label bottom

    return GestureDetector(
      onTap: () => onTap(point),
      onLongPressStart: (details) => onLongPressStart(point, details),
      onLongPressMoveUpdate: (details) => onLongPressMoveUpdate(point, details),
      onLongPressEnd: (details) => onLongPressEnd(point, details),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Marker icon - positioned so tip points to exact coordinates
          Positioned(
            bottom: labelBottomOffset + iconToLabelSpacing,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Black border icon (slightly larger)
                Icon(
                  Icons.location_pin,
                  color: Colors.black.withValues(alpha: 0.7),
                  size: iconSize + 2.0,
                ),
                // Colored icon on top
                Icon(Icons.location_pin, color: markerColor, size: iconSize),
              ],
            ),
          ),
          // Point label - positioned below the icon
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: point.isUnsaved
                    ? Colors.orange.withValues(alpha: 0.9)
                    : (isSelected
                          ? Colors.blue.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.85)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: point.isUnsaved
                      ? Colors.orange.shade700
                      : (isSelected
                            ? Colors.blue.shade700
                            : Colors.grey.shade400),
                  width: point.isUnsaved ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: (point.isUnsaved ? 0.3 : 0.15),
                    ),
                    blurRadius: point.isUnsaved ? 6 : 4,
                    offset: const Offset(0, 2),
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Text(
                point.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: point.isUnsaved
                      ? Colors.white
                      : (isSelected ? Colors.white : Colors.grey.shade800),
                  letterSpacing: 0.3,
                ),
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
