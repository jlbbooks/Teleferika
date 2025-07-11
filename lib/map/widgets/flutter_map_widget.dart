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

import 'package:teleferika/map/markers/map_markers.dart';
import 'package:teleferika/map/markers/azimuth_arrow.dart';
import 'package:teleferika/map/markers/location_markers.dart';
import 'package:teleferika/map/markers/polyline_arrowhead.dart';
import 'package:teleferika/map/services/geometry_service.dart';
import 'package:teleferika/map/services/map_cache_manager.dart';
import 'package:teleferika/map/map_type.dart';
import 'package:teleferika/map/state/map_state_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class FlutterMapWidget extends StatefulWidget {
  final List<LatLng> polylinePathPoints;
  final Polyline? connectingLine;
  final Polyline? projectHeadingLine;
  final LatLng initialMapCenter;
  final double initialMapZoom;
  final String tileLayerUrl;
  final String tileLayerAttribution;
  final String attributionUrl;
  final MapController mapController;
  final MapType currentMapType;
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
  // Slide functionality callbacks
  final Function(PointModel, LongPressStartDetails) onLongPressStart;
  final Function(PointModel, LongPressMoveUpdateDetails) onLongPressMoveUpdate;
  final Function(PointModel, LongPressEndDetails) onLongPressEnd;
  final bool isSlidingMarker;
  final String? slidingPointId;
  final LatLng? currentSlidePosition;
  final List<Widget>? additionalLayers;

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
    required this.currentMapType,
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
    // Slide functionality parameters
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
    required this.isSlidingMarker,
    required this.slidingPointId,
    required this.currentSlidePosition,
    this.additionalLayers,
  });

  @override
  State<FlutterMapWidget> createState() => _FlutterMapWidgetState();
}

class _FlutterMapWidgetState extends State<FlutterMapWidget> {
  double _currentZoom = 14.0; // Default zoom level

  // Get the appropriate tile provider based on the current map type
  TileProvider? _getTileProvider(MapType mapType) {
    final logger = Logger('FlutterMapWidget');
    logger.info(
      'Getting tile provider for ${mapType.name} with cache store: ${MapType.of(mapType.id).cacheStoreName ?? 'mapStore_${mapType.id}'}',
    );

    try {
      final tileProvider = MapCacheManager.getTileProviderWithFallback(mapType);
      logger.info('Created cached tile provider for ${mapType.name}');
      return tileProvider;
    } catch (e) {
      logger.warning(
        'Failed to create cached tile provider, using default provider: $e',
      );
      // Fallback to default tile provider (supports aborting requests natively in flutter_map 8.2.0)
      return NetworkTileProvider(
        cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
          maxCacheSize: 1_000_000_000, // 1 GB is the default
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.initialMapZoom;

    // Add listener to map controller to catch all zoom changes
    widget.mapController.mapEventStream.listen((MapEvent event) {
      // Handle all map events that might change zoom level
      if (event is MapEventMove ||
          event is MapEventRotate ||
          event is MapEventFlingAnimation ||
          event is MapEventDoubleTapZoom ||
          event is MapEventScrollWheelZoom ||
          event is MapEventNonRotatedSizeChange) {
        final newZoom = event.camera.zoom;
        if (_currentZoom != newZoom) {
          final logger = Logger('FlutterMapWidget');
          logger.info(
            'FlutterMapWidget: Zoom changed from $_currentZoom to $newZoom via controller stream (event: ${event.runtimeType})',
          );
          if (mounted) {
            setState(() {
              _currentZoom = newZoom;
            });
          }
        }
      }
    });
  }

  // Zoom in function with bounds checking
  void _zoomIn() {
    final newZoom = _currentZoom + 1.0;
    if (newZoom <= widget.currentMapType.maxZoom) {
      widget.mapController.move(widget.mapController.camera.center, newZoom);
    } else {
      // Set to maximum zoom if out of bounds
      widget.mapController.move(
        widget.mapController.camera.center,
        widget.currentMapType.maxZoom.toDouble(),
      );
    }
  }

  // Zoom out function with bounds checking
  void _zoomOut() {
    final newZoom = _currentZoom - 1.0;
    if (newZoom >= widget.currentMapType.minZoom) {
      widget.mapController.move(widget.mapController.camera.center, newZoom);
    } else {
      // Set to minimum zoom if out of bounds
      widget.mapController.move(
        widget.mapController.camera.center,
        widget.currentMapType.minZoom.toDouble(),
      );
    }
  }

  @override
  void dispose() {
    // Clean up any listeners if needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logger = Logger('FlutterMapWidget');

    try {
      return Stack(
        children: [
          FlutterMap(
            mapController: widget.mapController,
            options: MapOptions(
              initialCenter: widget.initialMapCenter,
              initialZoom: widget.initialMapZoom,
              keepAlive: true,
              minZoom: widget.currentMapType.minZoom.toDouble(),
              maxZoom: widget.currentMapType.maxZoom.toDouble(),
              onMapEvent: (MapEvent event) {
                // Handle all map events that might change zoom
                if (event is MapEventMove ||
                    event is MapEventRotate ||
                    event is MapEventFlingAnimation ||
                    event is MapEventDoubleTapZoom ||
                    event is MapEventScrollWheelZoom ||
                    event is MapEventNonRotatedSizeChange) {
                  final newZoom = event.camera.zoom;
                  if (_currentZoom != newZoom) {
                    logger.info(
                      'FlutterMapWidget: Zoom changed from $_currentZoom to $newZoom (event: ${event.runtimeType})',
                    );
                    setState(() {
                      _currentZoom = newZoom;
                    });
                  }
                }
              },
              onTap: (tapPosition, latlng) {
                if (widget.isMovePointMode) {
                  if (widget.selectedPointId != null) {
                    try {
                      final projectState = Provider.of<ProjectStateManager>(
                        context,
                        listen: false,
                      );
                      final points = projectState.currentPoints;
                      final pointToMove = points.firstWhere(
                        (p) => p.id == widget.selectedPointId,
                      );
                      widget.onMovePoint(pointToMove, latlng);
                    } catch (e) {
                      logger.warning(
                        "Error finding point to move in onTap: ${widget.selectedPointId}. $e",
                      );
                      // This will be handled by the parent component
                    }
                  }
                } else {
                  // Only deselect if we're not dealing with a new point
                  if (widget.selectedPointId != null) {
                    widget.onDeselectPoint();
                  }
                }
              },
              onMapReady: () {
                logger.info(
                  "FlutterMapWidget: Map is ready (onMapReady called).",
                );
                widget.onMapReady();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _getTileLayerUrlWithApiKey(widget.currentMapType),
                userAgentPackageName: 'com.jlbbooks.teleferika',
                tileProvider: _getTileProvider(widget.currentMapType),
                retinaMode: widget.currentMapType.supportsRetina
                    ? RetinaMode.isHighDensity(context)
                    : null,
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    widget.tileLayerAttribution,
                    onTap: () {
                      if (widget.attributionUrl.isNotEmpty) {
                        launchUrl(Uri.parse(widget.attributionUrl));
                      }
                    },
                  ),
                ],
                alignment: AttributionAlignment.bottomLeft,
              ),
              const MapCompass.cupertino(hideIfRotatedNorth: true),
              // Add azimuth arrow marker on top of current location (drawn first, so it's below the location marker)
              if (widget.currentPosition != null &&
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
                        widget.currentPosition!.latitude,
                        widget.currentPosition!.longitude,
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
                    accuracy: widget.currentPosition?.accuracy,
                    zoomLevel: _currentZoom,
                  ),
                  markerSize: const Size.square(60),
                  markerDirection: MarkerDirection.heading,
                  showAccuracyCircle: false,
                  headingSectorRadius: 40,
                ),
                positionStream: widget.locationStreamController.stream,
              ),
              ...(_isValidPolyline(widget.polylinePathPoints)
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
                              i < widget.polylinePathPoints.length - 1;
                              i++
                            )
                              Polyline(
                                points: [
                                  widget.polylinePathPoints[i],
                                  widget.polylinePathPoints[i + 1],
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
              if (widget.connectingLine != null &&
                  _isValidPolyline(widget.connectingLine!.points))
                PolylineLayer(polylines: [widget.connectingLine!]),
              if (widget.projectHeadingLine != null &&
                  _isValidPolyline(widget.projectHeadingLine!.points))
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.projectHeadingLine!.points,
                      color: widget.projectHeadingLine!.color,
                      gradientColors: widget.projectHeadingLine!.gradientColors,
                      colorsStop: widget.projectHeadingLine!.colorsStop,
                      strokeWidth: widget.projectHeadingLine!.strokeWidth,
                      borderColor: widget.projectHeadingLine!.borderColor,
                      borderStrokeWidth:
                          widget.projectHeadingLine!.borderStrokeWidth,
                      pattern: StrokePattern.dotted(),
                    ),
                  ],
                ),
              // Angle arcs as polylines (so they rotate with the map)
              if (_isValidPolyline(widget.polylinePathPoints) &&
                  widget.polylinePathPoints.length > 2)
                PolylineLayer(polylines: _buildAngleArcPolylines(context)),
              // Angle labels as markers (don't rotate with the map) - rendered first (bottom layer)
              if (_isValidPolyline(widget.polylinePathPoints) &&
                  widget.polylinePathPoints.length > 2)
                MarkerLayer(
                  markers: _buildAngleLabelMarkers(context),
                  rotate: true,
                ),
              // Point markers - rendered second (top layer)
              MarkerLayer(
                markers: () {
                  // Get points from global state
                  final projectState = context.projectStateListen;
                  List<PointModel> points = List.from(
                    projectState.currentPoints,
                  );
                  // Get MapStateManager from Provider
                  final mapStateManager = Provider.of<MapStateManager>(
                    context,
                    listen: false,
                  );
                  final newPoint = mapStateManager.newPoint;
                  if (newPoint != null &&
                      !points.any((p) => p.id == newPoint.id)) {
                    points.add(newPoint);
                  }
                  return MapMarkers.buildAllMapMarkers(
                    context: context,
                    selectedPointId: widget.selectedPointId,
                    isMovePointMode: widget.isMovePointMode,
                    glowAnimationValue: widget.glowAnimationValue,
                    currentPosition: widget.currentPosition,
                    hasLocationPermission: widget.hasLocationPermission,
                    headingFromFirstToLast:
                        widget.connectingLineFromFirstToLast,
                    onPointTap: widget.onPointTap,
                    currentDeviceHeading: widget.currentDeviceHeading,
                    // Slide functionality parameters
                    onLongPressStart: widget.onLongPressStart,
                    onLongPressMoveUpdate: widget.onLongPressMoveUpdate,
                    onLongPressEnd: widget.onLongPressEnd,
                    isSlidingMarker: widget.isSlidingMarker,
                    slidingPointId: widget.slidingPointId,
                    points: points, // <-- pass custom points list
                  );
                }(),
                rotate: true,
              ),
              // Sliding indicator - shows where the marker will be placed during sliding
              if (widget.isSlidingMarker && widget.slidingPointId != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      point: _getSlidingIndicatorPosition(context),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withValues(alpha: 0.3),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.7),
                            width: 2.0,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.close,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                  rotate: true,
                ),
              if (_isValidPolyline(widget.polylinePathPoints) &&
                  widget.polylinePathPoints.length >= 2 &&
                  widget.arrowheadAnimation != null)
                AnimatedBuilder(
                  animation: widget.arrowheadAnimation!,
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
                    final t = widget.arrowheadAnimation!.value;
                    final n = widget.polylinePathPoints.length;
                    double totalLength = 0.0;
                    final List<double> segmentLengths = [];
                    for (int i = 0; i < n - 1; i++) {
                      final a = widget.polylinePathPoints[i];
                      final b = widget.polylinePathPoints[i + 1];
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
                          pathPoints: widget.polylinePathPoints,
                          t: widget.arrowheadAnimation!.value,
                          color: markerColor,
                        ),
                      ],
                    );
                  },
                ),
              // Add additional layers if provided
              if (widget.additionalLayers != null) ...widget.additionalLayers!,
            ],
          ),

          // Zoom controls overlay - bottom right corner
          Positioned(
            right: 16.0,
            bottom: 16.0,
            child: Column(
              children: [
                // Zoom in button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _currentZoom >= widget.currentMapType.maxZoom
                        ? null
                        : _zoomIn,
                    icon: Icon(
                      Icons.add,
                      color: _currentZoom >= widget.currentMapType.maxZoom
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.black87,
                    ),
                    iconSize: 20.0,
                    padding: const EdgeInsets.all(8.0),
                    constraints: const BoxConstraints(
                      minWidth: 40.0,
                      minHeight: 40.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                // Zoom level indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _currentZoom.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                // Zoom out button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _currentZoom <= widget.currentMapType.minZoom
                        ? null
                        : _zoomOut,
                    icon: Icon(
                      Icons.remove,
                      color: _currentZoom <= widget.currentMapType.minZoom
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.black87,
                    ),
                    iconSize: 20.0,
                    padding: const EdgeInsets.all(8.0),
                    constraints: const BoxConstraints(
                      minWidth: 40.0,
                      minHeight: 40.0,
                    ),
                  ),
                ),
              ],
            ),
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

  // Get the position for the sliding indicator
  LatLng _getSlidingIndicatorPosition(BuildContext context) {
    // Use the current slide position if available, otherwise fall back to the original point position
    if (widget.currentSlidePosition != null) {
      return widget.currentSlidePosition!;
    }

    // Fallback: get the original point position
    if (widget.slidingPointId != null) {
      try {
        final projectState = Provider.of<ProjectStateManager>(
          context,
          listen: false,
        );
        final points = projectState.currentPoints;
        final slidingPoint = points.firstWhere(
          (p) => p.id == widget.slidingPointId,
        );
        return LatLng(slidingPoint.latitude, slidingPoint.longitude);
      } catch (e) {
        // If we can't find the point, return a default position
        return widget.initialMapCenter;
      }
    }

    return widget.initialMapCenter;
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

    // Use the current zoom from state (updated via onMapEvent)
    final baseZoom =
        15.0; // Base zoom level for normal size (zoom 15 = normal size)
    final zoomFactor = (_currentZoom / baseZoom).clamp(
      0.5,
      2.0,
    ); // Scale between 0.5x and 2x

    final logger = Logger('FlutterMapWidget');
    logger.info(
      'FlutterMapWidget: Building angle labels with zoom: $_currentZoom, factor: $zoomFactor',
    );

    // Generate angle labels for intermediate points
    for (int i = 1; i < projectPoints.length - 1; i++) {
      final prev = projectPoints[i - 1];
      final curr = projectPoints[i];
      final next = projectPoints[i + 1];

      // Calculate the angle at this point
      final angleDeg = _calculateAngleAtPoint(prev, curr, next);
      if (angleDeg != null) {
        // Calculate the position for the label (outside the arc)
        // Adjust radius based on zoom level - closer at higher zoom
        final baseRadius = 52.0; // Base radius at zoom 15
        final zoomRadiusFactor = (_currentZoom / 15.0).clamp(
          0.5,
          3.0,
        ); // Scale radius between 0.5x and 3.0x (more aggressive)
        final dynamicRadius =
            baseRadius /
            zoomRadiusFactor; // Inverse relationship - higher zoom = smaller radius

        final labelPosition = _calculateAngleLabelPosition(
          prev,
          curr,
          next,
          dynamicRadius,
        );

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

  String _getTileLayerUrlWithApiKey(MapType mapType) {
    final url = mapType.tileLayerUrl;
    final apiKey = mapType.apiKey;
    final apiKeyParam = mapType.apiKeyParameterName;
    if (apiKey != null && apiKeyParam != null) {
      // If the URL already has query params, append with &param=...
      if (url.contains('?')) {
        return '$url&$apiKeyParam=$apiKey';
      } else {
        return '$url?$apiKeyParam=$apiKey';
      }
    }
    return url;
  }
}
