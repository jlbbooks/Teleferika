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
import 'package:teleferika/db/models/point_model.dart';

import 'package:teleferika/ui/tabs/map/markers/map_markers.dart';
import 'package:teleferika/ui/tabs/map/markers/moving_marker.dart';
import 'package:teleferika/ui/tabs/map/markers/location_markers.dart';
import 'package:teleferika/ui/tabs/map/markers/polyline_arrowhead.dart';
import 'package:url_launcher/url_launcher.dart';

class FlutterMapWidget extends StatelessWidget {
  final List<PointModel> allPoints;
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
    required this.allPoints,
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
                      child: MovingMarker(
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
                      // Compute color for each point
                      final List<Color> pointColors = [
                        for (int i = 0; i < allPoints.length; i++)
                          _pointColor(i, allPoints),
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
              MarkerLayer(
                markers: MapMarkers.buildAllMapMarkers(
                  context: context,
                  projectPoints: allPoints,
                  selectedPointId: selectedPointId,
                  isMovePointMode: isMovePointMode,
                  glowAnimationValue: glowAnimationValue,
                  currentPosition: currentPosition,
                  hasLocationPermission: hasLocationPermission,
                  headingFromFirstToLast: connectingLineFromFirstToLast,
                  onPointTap: onPointTap,
                  currentDeviceHeading: currentDeviceHeading,
                ),
                rotate: true,
              ),
              if (_isValidPolyline(polylinePathPoints) &&
                  polylinePathPoints.length >= 2 &&
                  arrowheadAnimation != null)
                AnimatedBuilder(
                  animation: arrowheadAnimation!,
                  builder: (context, child) {
                    // Compute color for each point
                    final List<Color> pointColors = [
                      for (int i = 0; i < allPoints.length; i++)
                        _pointColor(i, allPoints),
                    ];
                    // Find which segment the marker is on and local t
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
                    double target = t * totalLength;
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

  Color _pointColor(int i, List<PointModel> points) {
    if (i == 0 || i == points.length - 1) {
      return Colors.green;
    }
    // Calculate angle at points[i]
    final prev = points[i - 1];
    final curr = points[i];
    final next = points[i + 1];
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
    return angleColor(angleDeg);
  }
}
