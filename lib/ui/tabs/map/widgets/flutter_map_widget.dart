import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_compass/flutter_map_compass.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/db/models/point_model.dart';

import 'package:teleferika/ui/tabs/map/markers/map_markers.dart';
import 'package:teleferika/ui/tabs/map/markers/azimuth_arrow.dart';
import 'package:teleferika/ui/tabs/map/markers/location_markers.dart';
import 'package:teleferika/ui/tabs/map/markers/polyline_arrowhead.dart';
import 'package:teleferika/ui/tabs/map/services/geometry_service.dart';
import 'package:url_launcher/url_launcher.dart';

class FlutterMapWidget extends StatelessWidget {
  final List<LatLng> polylinePathPoints;
  final Polyline? connectingLine;
  final Polyline? projectHeadingLine;
  final LatLng initialMapCenter;
  final double initialMapZoom;
  final String tileLayerUrl;
  final String tileLayerAttribution;
  final String attributionUrl;
  final MapController mapController;
  final bool isMapReady;
  final bool isLoadingPoints;
  final bool isMovePointMode;
  final String? selectedPointId;
  final Position? currentPosition;
  final bool hasLocationPermission;
  final double? connectingLineFromFirstToLast;
  final double glowAnimationValue;
  final double? currentDeviceHeading;
  final StreamController<LocationMarkerPosition> locationStreamController;
  final Animation<double>? arrowheadAnimation;
  final Function(PointModel) onPointTap;
  final Function(PointModel, LatLng) onMovePoint;
  final VoidCallback onMapReady;
  final VoidCallback onDeselectPoint;

  const FlutterMapWidget({
    super.key,
    required this.polylinePathPoints,
    required this.connectingLine,
    required this.projectHeadingLine,
    required this.initialMapCenter,
    required this.initialMapZoom,
    required this.tileLayerUrl,
    required this.tileLayerAttribution,
    required this.attributionUrl,
    required this.mapController,
    required this.isMapReady,
    required this.isLoadingPoints,
    required this.isMovePointMode,
    required this.selectedPointId,
    required this.currentPosition,
    required this.hasLocationPermission,
    required this.connectingLineFromFirstToLast,
    required this.glowAnimationValue,
    required this.currentDeviceHeading,
    required this.locationStreamController,
    required this.arrowheadAnimation,
    required this.onPointTap,
    required this.onMovePoint,
    required this.onMapReady,
    required this.onDeselectPoint,
  });

  @override
  Widget build(BuildContext context) {
    final logger = Logger('FlutterMapWidget');

    try {
      return Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: initialMapCenter,
              initialZoom: initialMapZoom,
              keepAlive: true,
              onTap: (tapPosition, latlng) {
                if (isMovePointMode) {
                  if (selectedPointId != null) {
                    try {
                      final projectState = Provider.of<ProjectStateManager>(
                        context,
                        listen: false,
                      );
                      final points = projectState.currentPoints;
                      final pointToMove = points.firstWhere(
                        (p) => p.id == selectedPointId,
                      );
                      onMovePoint(pointToMove, latlng);
                    } catch (e) {
                      logger.warning(
                        "Error finding point to move in onTap: $selectedPointId. $e",
                      );
                      // This will be handled by the parent component
                    }
                  }
                } else {
                  // Only deselect if we're not dealing with a new point
                  if (selectedPointId != null) {
                    onDeselectPoint();
                  }
                }
              },
              onMapReady: () {
                logger.info(
                  "FlutterMapWidget: Map is ready (onMapReady called).",
                );
                onMapReady();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileLayerUrl,
                userAgentPackageName: 'com.jlbbooks.teleferika',
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    tileLayerAttribution,
                    onTap: () {
                      if (attributionUrl.isNotEmpty) {
                        launchUrl(Uri.parse(attributionUrl));
                      }
                    },
                  ),
                ],
              ),
              const MapCompass.cupertino(hideIfRotatedNorth: true),
              // Add azimuth arrow marker on top of current location (drawn first, so it's below the location marker)
              if (currentPosition != null &&
                  Provider.of<ProjectStateManager>(
                        context,
                        listen: false,
                      ).currentProject?.azimuth !=
                      null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(
                        currentPosition!.latitude,
                        currentPosition!.longitude,
                      ),
                      child: AzimuthArrow(
                        azimuth: Provider.of<ProjectStateManager>(
                          context,
                          listen: false,
                        ).currentProject!.azimuth!,
                      ),
                      alignment: Alignment.center,
                    ),
                  ],
                ),

              CurrentLocationLayer(
                style: LocationMarkerStyle(
                  marker: CurrentLocationAccuracyMarker(
                    accuracy: currentPosition?.accuracy,
                  ),
                  markerSize: const Size.square(60),
                  markerDirection: MarkerDirection.heading,
                  showAccuracyCircle: false,
                  headingSectorRadius: 40,
                ),
                positionStream: locationStreamController.stream,
              ),
              ...(_isValidPolyline(polylinePathPoints)
                  ? () {
                      // Get points from global state to match MapMarkers
                      final projectPoints =
                          context.projectStateListen.currentPoints;

                      // Compute color for each point
                      final List<Color> pointColors = [
                        for (int i = 0; i < projectPoints.length; i++)
                          _pointColor(context, i, projectPoints),
                      ];
                      return [
                        PolylineLayer(
                          polylines: [
                            for (
                              int i = 0;
                              i < polylinePathPoints.length - 1;
                              i++
                            )
                              Polyline(
                                points: [
                                  polylinePathPoints[i],
                                  polylinePathPoints[i + 1],
                                ],
                                gradientColors: [
                                  pointColors[i],
                                  pointColors[i + 1],
                                ],
                                colorsStop: [0.0, 1.0],
                                strokeWidth: 3.0,
                              ),
                          ],
                        ),
                      ];
                    }()
                  : []),
              if (connectingLine != null &&
                  _isValidPolyline(connectingLine!.points))
                PolylineLayer(polylines: [connectingLine!]),
              if (projectHeadingLine != null &&
                  _isValidPolyline(projectHeadingLine!.points))
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: projectHeadingLine!.points,
                      color: projectHeadingLine!.color,
                      gradientColors: projectHeadingLine!.gradientColors,
                      colorsStop: projectHeadingLine!.colorsStop,
                      strokeWidth: projectHeadingLine!.strokeWidth,
                      borderColor: projectHeadingLine!.borderColor,
                      borderStrokeWidth: projectHeadingLine!.borderStrokeWidth,
                      pattern: StrokePattern.dotted(),
                    ),
                  ],
                ),
              // Angle arcs as polylines (so they rotate with the map)
              if (_isValidPolyline(polylinePathPoints) &&
                  polylinePathPoints.length > 2)
                PolylineLayer(polylines: _buildAngleArcPolylines(context)),
              MarkerLayer(
                markers: [
                  ...MapMarkers.buildAllMapMarkers(
                    context: context,
                    selectedPointId: selectedPointId,
                    isMovePointMode: isMovePointMode,
                    glowAnimationValue: glowAnimationValue,
                    currentPosition: currentPosition,
                    hasLocationPermission: hasLocationPermission,
                    headingFromFirstToLast: connectingLineFromFirstToLast,
                    onPointTap: onPointTap,
                    currentDeviceHeading: currentDeviceHeading,
                  ),
                  // Angle labels as markers (don't rotate with the map)
                  if (_isValidPolyline(polylinePathPoints) &&
                      polylinePathPoints.length > 2)
                    ..._buildAngleLabelMarkers(context),
                ],
                rotate: true,
              ),
              if (_isValidPolyline(polylinePathPoints) &&
                  polylinePathPoints.length >= 2 &&
                  arrowheadAnimation != null)
                AnimatedBuilder(
                  animation: arrowheadAnimation!,
                  builder: (context, child) {
                    // Get points from global state to match polyline colors
                    final projectPoints =
                        context.projectStateListen.currentPoints;

                    // Compute color for each point (same as polyline segments)
                    final List<Color> pointColors = [
                      for (int i = 0; i < projectPoints.length; i++)
                        _pointColor(context, i, projectPoints),
                    ];

                    // Find which segment the arrowhead is on and calculate local position
                    final t = arrowheadAnimation!.value;
                    final n = polylinePathPoints.length;
                    double totalLength = 0.0;
                    final List<double> segmentLengths = [];
                    for (int i = 0; i < n - 1; i++) {
                      final a = polylinePathPoints[i];
                      final b = polylinePathPoints[i + 1];
                      final d = math.sqrt(
                        math.pow(b.latitude - a.latitude, 2) +
                            math.pow(b.longitude - a.longitude, 2),
                      );
                      segmentLengths.add(d);
                      totalLength += d;
                    }

                    // Calculate target distance along the path
                    // Note: PolylinePathArrowheadMarker uses (1.0 - t), so we need to match that
                    double target = (1.0 - t) * totalLength;
                    double acc = 0.0;
                    int segIdx = 0;
                    double localT = 0.0;
                    for (int i = 0; i < segmentLengths.length; i++) {
                      if (acc + segmentLengths[i] >= target) {
                        segIdx = i;
                        localT = (target - acc) / segmentLengths[i];
                        break;
                      }
                      acc += segmentLengths[i];
                    }

                    // Use the same color interpolation as the polyline segment
                    final colorStart = pointColors[segIdx];
                    final colorEnd = pointColors[segIdx + 1];
                    final markerColor =
                        Color.lerp(colorStart, colorEnd, localT) ?? colorStart;

                    return MarkerLayer(
                      markers: [
                        PolylinePathArrowheadMarker(
                          pathPoints: polylinePathPoints,
                          t: arrowheadAnimation!.value,
                          color: markerColor,
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ],
      );
    } catch (e, st) {
      logger.severe('FlutterMapWidget: Exception building FlutterMap: $e\n$st');
      return Stack(
        children: [const Center(child: Text('Error building map. See logs.'))],
      );
    }
  }

  // Helper to check if a polyline has at least two distinct points
  bool _isValidPolyline(List<LatLng> points) {
    if (points.length < 2) return false;
    final first = points.first;
    return points.any(
      (p) => p.latitude != first.latitude || p.longitude != first.longitude,
    );
  }

  Color _pointColor(BuildContext context, int i, List<PointModel> points) {
    final geometryService = GeometryService(
      project: context.projectStateListen.currentProject!,
    );
    return geometryService.getPointColor(points[i], points);
  }

  List<Polyline> _buildAngleArcPolylines(BuildContext context) {
    final projectPoints = context.projectStateListen.currentPoints;
    final List<Polyline> angleArcs = [];

    // Generate angle arcs for intermediate points
    for (int i = 1; i < projectPoints.length - 1; i++) {
      final prev = projectPoints[i - 1];
      final curr = projectPoints[i];
      final next = projectPoints[i + 1];

      // Calculate the angle at this point
      final angleDeg = _calculateAngleAtPoint(prev, curr, next);
      if (angleDeg != null) {
        // Generate arc points
        final arcPoints = _generateArcPoints(prev, curr, next, 36.0);
        if (arcPoints.isNotEmpty) {
          angleArcs.add(
            Polyline(
              points: arcPoints,
              color: angleColor(angleDeg).withValues(alpha: 0.4),
              strokeWidth: 2.0,
            ),
          );
        }
      }
    }

    return angleArcs;
  }

  double? _calculateAngleAtPoint(
    PointModel prev,
    PointModel curr,
    PointModel next,
  ) {
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

  List<LatLng> _generateArcPoints(
    PointModel prev,
    PointModel curr,
    PointModel next,
    double radius,
  ) {
    // Calculate bearings from current point to previous and next points
    final bearingToPrev = _calculateBearing(curr, prev);
    final bearingToNext = _calculateBearing(curr, next);

    // Determine the sweep direction (convex)
    double startAngle = bearingToPrev;
    double endAngle = bearingToNext;
    double sweep = endAngle - startAngle;

    // Normalize sweep to be positive and convex
    if (sweep <= -180) sweep += 360;
    if (sweep > 180) sweep -= 360;
    if (sweep < 0) {
      final temp = startAngle;
      startAngle = endAngle;
      endAngle = temp;
      sweep = -sweep;
    }

    // Generate arc points
    final List<LatLng> arcPoints = [];
    const int numPoints = 20; // Number of points to approximate the arc

    for (int i = 0; i <= numPoints; i++) {
      final t = i / numPoints;
      final angle = startAngle + sweep * t;
      final point = _calculateDestinationPoint(
        LatLng(curr.latitude, curr.longitude),
        angle,
        radius / 1000.0, // Convert meters to kilometers
      );
      arcPoints.add(point);
    }

    return arcPoints;
  }

  double _calculateBearing(PointModel from, PointModel to) {
    final lat1 = from.latitude * math.pi / 180;
    final lon1 = from.longitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final lon2 = to.longitude * math.pi / 180;

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    var bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360; // Normalize to 0-360
  }

  LatLng _calculateDestinationPoint(
    LatLng start,
    double bearingDegrees,
    double distanceKm,
  ) {
    const R = 6371.0; // Earth's radius in kilometers
    final lat1 = start.latitude * math.pi / 180;
    final lon1 = start.longitude * math.pi / 180;
    final bearingRad = bearingDegrees * math.pi / 180;

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

    return LatLng(lat2 * 180 / math.pi, lon2 * 180 / math.pi);
  }

  List<Marker> _buildAngleLabelMarkers(BuildContext context) {
    final projectPoints = context.projectStateListen.currentPoints;
    final List<Marker> angleLabels = [];

    // Get current zoom level for scaling with safety check
    double currentZoom;
    try {
      currentZoom = mapController.camera.zoom;
    } catch (e) {
      // Fallback to initial zoom if map controller is not ready
      currentZoom = initialMapZoom;
    }
    final baseZoom = 14.0; // Base zoom level for normal size
    final zoomFactor = (currentZoom / baseZoom).clamp(
      0.5,
      2.0,
    ); // Scale between 0.5x and 2x

    // Generate angle labels for intermediate points
    for (int i = 1; i < projectPoints.length - 1; i++) {
      final prev = projectPoints[i - 1];
      final curr = projectPoints[i];
      final next = projectPoints[i + 1];

      // Calculate the angle at this point
      final angleDeg = _calculateAngleAtPoint(prev, curr, next);
      if (angleDeg != null) {
        // Calculate the position for the label (outside the arc)
        final labelPosition = _calculateAngleLabelPosition(
          prev,
          curr,
          next,
          52.0,
        ); // Slightly larger than arc radius

        // Scale dimensions based on zoom
        final markerWidth = (40 * zoomFactor).round();
        final markerHeight = (16 * zoomFactor).round();
        final fontSize = (8 * zoomFactor).clamp(6.0, 14.0);
        final padding = (2 * zoomFactor).clamp(1.0, 4.0);
        final borderRadius = (2 * zoomFactor).clamp(1.0, 4.0);
        final borderWidth = (0.5 * zoomFactor).clamp(0.5, 1.0);

        angleLabels.add(
          Marker(
            width: markerWidth.toDouble(),
            height: markerHeight.toDouble(),
            point: labelPosition,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding * 0.5,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: angleColor(angleDeg).withValues(alpha: 0.6),
                  width: borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: zoomFactor,
                    offset: Offset(0, zoomFactor * 0.5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${angleDeg.toStringAsFixed(1)}°',
                  style: TextStyle(
                    color: angleColor(angleDeg),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }
    }

    return angleLabels;
  }

  LatLng _calculateAngleLabelPosition(
    PointModel prev,
    PointModel curr,
    PointModel next,
    double radius,
  ) {
    // Calculate bearings from current point to previous and next points
    final bearingToPrev = _calculateBearing(curr, prev);
    final bearingToNext = _calculateBearing(curr, next);

    // Determine the sweep direction (convex)
    double startAngle = bearingToPrev;
    double endAngle = bearingToNext;
    double sweep = endAngle - startAngle;

    // Normalize sweep to be positive and convex
    if (sweep <= -180) sweep += 360;
    if (sweep > 180) sweep -= 360;
    if (sweep < 0) {
      final temp = startAngle;
      startAngle = endAngle;
      endAngle = temp;
      sweep = -sweep;
    }

    // Calculate the midpoint angle of the arc
    final midAngle = startAngle + sweep / 2;

    // Calculate the label position at the midpoint angle, outside the arc
    return _calculateDestinationPoint(
      LatLng(curr.latitude, curr.longitude),
      midAngle,
      radius / 1000.0, // Convert meters to kilometers
    );
  }
}
