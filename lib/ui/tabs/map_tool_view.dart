// map_tool_view.dart

// ignore_for_file: unused_field

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_compass/flutter_map_compass.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/pages/point_details_page.dart';
import 'package:teleferika/ui/widgets/compass_calibration_panel.dart';
import 'package:teleferika/ui/widgets/permission_handler_widget.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'map/map_controller.dart';
import 'map/map_controls.dart';
import 'map/map_markers.dart';
import 'map/point_details_panel.dart';

class MapToolView extends StatefulWidget {
  final ProjectModel project;
  final String? selectedPointId;
  final VoidCallback? onNavigateToCompassTab;

  const MapToolView({
    super.key,
    required this.project,
    this.selectedPointId,
    this.onNavigateToCompassTab,
  });

  @override
  State<MapToolView> createState() => MapToolViewState();
}

class MapToolViewState extends State<MapToolView> with StatusMixin {
  final Logger logger = Logger('MapToolView');

  // Controller for business logic
  late MapControllerLogic _controller;

  // UI State
  final MapController _mapController = MapController();
  bool _isLoadingPoints = true;
  bool _isMapReady = false;
  String? _selectedPointId;
  bool _isMovePointMode = false;
  bool _isMovingPointLoading = false;
  PointModel? _newPoint; // The unsaved new point
  bool _isAddingNewPoint =
      false; // Whether we're in the process of adding a new point
  bool _skipNextFitToPoints =
      false; // Flag to skip automatic fitting after saving new point
  bool _isExternalRefresh =
      false; // Flag to prevent callback loops during external refresh

  // Data from global state and sensors
  Position? _currentPosition;
  double? _currentDeviceHeading;
  double? _currentCompassAccuracy;
  bool? _shouldCalibrateCompass;
  bool _hasLocationPermission = false;
  bool _hasSensorPermission = false;
  final bool _isCheckingPermissions = true; // Add loading state for permissions
  double? _headingFromFirstToLast;
  Polyline? _projectHeadingLine;
  MapType _currentMapType = MapType.openStreetMap;
  double _glowAnimationValue = 0.0;

  // Location stream for CurrentLocationLayer
  final StreamController<LocationMarkerPosition> _locationStreamController =
      StreamController<LocationMarkerPosition>.broadcast();

  bool _didInitialLoad = false;

  // Debug panel state
  bool _hasClosedDebugPanel = false;

  // Track if we've already shown the calibrate compass notice this session
  bool _hasShownCalibrateCompassNotice = false;

  // For testing: force show calibration panel
  bool _forceShowCalibrationPanel = false;

  @override
  void initState() {
    super.initState();
    _selectedPointId = widget.selectedPointId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize controller with current project from global state
    final currentProject =
        context.projectStateListen.currentProject ?? widget.project;
    _controller = MapControllerLogic(project: currentProject);

    // Reset debug panel closed state every time we re-enter
    _hasClosedDebugPanel = false;
    // Reset calibrate compass notice flag every time we re-enter
    _hasShownCalibrateCompassNotice = false;

    if (!_didInitialLoad) {
      _didInitialLoad = true;
      _loadProjectPoints();
    }
  }

  @override
  void didUpdateWidget(covariant MapToolView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Get current project from global state
    final currentProject =
        context.projectStateListen.currentProject ?? widget.project;
    final oldProject = oldWidget.project;

    if (currentProject.id != oldProject.id && !_isLoadingPoints) {
      _loadProjectPoints();
    } else if (currentProject.startingPointId != oldProject.startingPointId ||
        currentProject.endingPointId != oldProject.endingPointId) {
      // Project start/end points changed, reload points to get updated data
      // But skip if we're in the middle of saving a new point
      if (!_skipNextFitToPoints && !_isLoadingPoints) {
        _loadProjectPoints();
      }
    }

    if (widget.selectedPointId != oldWidget.selectedPointId) {
      _selectedPointId = widget.selectedPointId;
      setState(() {}); // Only call setState once after updating state
    }
  }

  @override
  void dispose() {
    _locationStreamController.close();
    _controller.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Handle permission results from the PermissionHandlerWidget
  void _handlePermissionResults(Map<PermissionType, bool> permissions) {
    final hasLocation = permissions[PermissionType.location] ?? false;
    final hasSensor = permissions[PermissionType.sensor] ?? false;

    setState(() {
      _hasLocationPermission = hasLocation;
      _hasSensorPermission = hasSensor;
    });

    if (hasLocation) {
      _startListeningToLocation();
    } else {
      showInfoStatus(
        'Location permission denied. Map features requiring location will be limited.',
      );
    }

    if (hasSensor) {
      _startListeningToCompass();
    } else {
      showInfoStatus(
        'Sensor permission denied. Device orientation features will be unavailable.',
      );
    }
  }

  void _startListeningToLocation() {
    _controller.startListeningToLocation(
      (position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });

          // Send location data to CurrentLocationLayer
          _locationStreamController.add(
            LocationMarkerPosition(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
            ),
          );
        }
      },
      (error, [stackTrace]) {
        logger.severe("Error getting location updates: $error");
        if (mounted) {
          final s = S.of(context);
          showErrorStatus(
            s?.mapErrorGettingLocationUpdates(error.toString()) ??
                'Error getting location updates: $error',
          );
          setState(() {
            _currentPosition = null;
          });
        }
      },
    );
  }

  void _startListeningToCompass() {
    _controller.startListeningToCompass(
      (heading, accuracy, shouldCalibrate) {
        if (mounted) {
          final prevShouldCalibrate = _shouldCalibrateCompass;
          setState(() {
            _currentDeviceHeading = heading;
            _currentCompassAccuracy = accuracy;
            _shouldCalibrateCompass = shouldCalibrate;
          });

          // Show calibrate compass notice if it just became true
          if (shouldCalibrate == true &&
              prevShouldCalibrate != true &&
              !_hasShownCalibrateCompassNotice) {
            showErrorStatus(
              'Compass sensor needs calibration. Please move your device in a figure-8 motion.',
            );
            _hasShownCalibrateCompassNotice = true;
          }

          // Update location marker with new heading if we have a current position
          if (_currentPosition != null) {
            _locationStreamController.add(
              LocationMarkerPosition(
                latitude: _currentPosition!.latitude,
                longitude: _currentPosition!.longitude,
                accuracy: _currentPosition!.accuracy,
              ),
            );
          }
        }
      },
      (error, [stackTrace]) {
        logger.severe("Error getting compass updates: $error");
        if (mounted) {
          final s = S.of(context);
          showErrorStatus(
            s?.mapErrorGettingCompassUpdates(error.toString()) ??
                'Error getting compass updates: $error',
          );
          setState(() {
            _currentDeviceHeading = null;
            _currentCompassAccuracy = null;
            _shouldCalibrateCompass = null;
          });
        }
      },
    );
  }

  Future<void> _loadProjectPoints() async {
    setState(() {
      _isLoadingPoints = true;
    });

    try {
      if (mounted) {
        setState(() {
          _isLoadingPoints = false;
        });

        // Recalculate lines with current points
        _recalculateAndDrawLines();

        // Fit map to points if not skipping
        if (!_skipNextFitToPoints && _isMapReady) {
          _fitMapToPoints();
        }

        // Only call the callback if this is not an external refresh
        if (!_isExternalRefresh) {
          // No callback needed - global state will notify listeners automatically
        }
      }

      _skipNextFitToPoints = false; // Reset the flag
    } catch (e, stackTrace) {
      logger.severe("MapToolView: Error loading points for map", e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoadingPoints = false;
        });

        final s = S.of(context);
        showErrorStatus(
          s?.mapErrorLoadingPoints(e.toString()) ??
              "Error loading points for map: $e",
        );
      }
    }
  }

  void _recalculateAndDrawLines() {
    final projectState = Provider.of<ProjectStateManager>(
      context,
      listen: false,
    );
    final points = projectState.currentPoints;

    _headingFromFirstToLast = _controller.recalculateHeadingLine(points);
    _projectHeadingLine = _controller.recalculateProjectHeadingLine(points);
  }

  Future<void> _handleMovePoint(
    PointModel pointToMove,
    LatLng newPosition,
  ) async {
    if (_isMovingPointLoading) return;

    setState(() {
      _isMovingPointLoading = true;
    });

    try {
      // Set flag to skip automatic fitting after moving point
      _skipNextFitToPoints = true;

      // Use global state to move the point in memory (not DB)
      final projectState = Provider.of<ProjectStateManager>(
        context,
        listen: false,
      );
      final updatedPoint = pointToMove.copyWith(
        latitude: newPosition.latitude,
        longitude: newPosition.longitude,
      );
      projectState.updatePointInEditingState(updatedPoint);

      if (!mounted) return;

      setState(() {
        _isMovePointMode = false;
        _recalculateAndDrawLines();
      });

      showSuccessStatus('Point ${pointToMove.name} moved (pending save)!');
    } catch (e) {
      logger.severe('Failed to move point ${pointToMove.name}: $e');
      if (!mounted) return;
      showErrorStatus(
        'Error moving point ${pointToMove.name}: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMovingPointLoading = false;
        });
      }
    }
  }

  void _fitMapToPoints() {
    if (!_isMapReady || !mounted) {
      logger.info(
        "MapToolView: Attempted to fit map, but map not ready or widget unmounted.",
      );
      return;
    }

    final projectState = Provider.of<ProjectStateManager>(
      context,
      listen: false,
    );
    final points = projectState.currentPoints;

    if (points.isEmpty) {
      try {
        final center = _controller.getInitialCenter(points, _currentPosition);
        final zoom = _controller.getInitialZoom(points, _currentPosition);
        _mapController.move(center, zoom);
      } catch (e) {
        logger.warning('Error moving map to default center: $e');
      }
      return;
    }

    if (points.length == 1) {
      try {
        _mapController.move(
          LatLng(points.first.latitude, points.first.longitude),
          15.0,
        );
      } catch (e) {
        logger.warning('Error moving map to single point: $e');
      }
      return;
    }

    try {
      final List<LatLng> pointCoords = points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      final bounds = LatLngBounds.fromPoints(pointCoords);

      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)),
      );
    } catch (e) {
      logger.warning('Error fitting map to points: $e');
      try {
        _mapController.move(
          LatLng(points.first.latitude, points.first.longitude),
          14.0,
        );
      } catch (e2) {
        logger.warning('Error in fallback map move: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectStateManager>(
      builder: (context, projectState, child) {
        // Always recalculate lines when state changes
        _recalculateAndDrawLines();

        if (_isLoadingPoints) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      S.of(context)?.mapLoadingPointsIndicator ??
                          "Loading points...",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please wait while we load your project data",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: StatusIndicator(
                  status: currentStatus,
                  onDismiss: hideStatus,
                ),
              ),
            ],
          );
        }

        // Get points from global state
        final points = projectState.currentPoints;
        // Combine project points with new point if it exists
        final allPoints = [...points];
        if (_newPoint != null) {
          allPoints.add(_newPoint!);
        }

        final List<LatLng> polylinePathPoints = _buildPolylinePathPoints();
        final headingLine = _buildHeadingLine();

        LatLng initialMapCenter = _controller.getInitialCenter(
          points,
          _currentPosition,
        );
        double initialMapZoom = _controller.getInitialZoom(
          points,
          _currentPosition,
        );

        if (initialMapCenter.latitude.isNaN ||
            initialMapCenter.longitude.isNaN ||
            initialMapZoom.isNaN ||
            initialMapZoom.isInfinite) {
          return Stack(
            children: [
              const Center(child: Text('Waiting for valid map data...')),
              Positioned(
                top: 24,
                right: 24,
                child: StatusIndicator(
                  status: currentStatus,
                  onDismiss: hideStatus,
                ),
              ),
            ],
          );
        }

        // Get the selected point from the latest global state
        PointModel? selectedPoint;
        if (_selectedPointId != null) {
          if (_newPoint != null && _newPoint!.id == _selectedPointId) {
            selectedPoint = _newPoint;
          } else {
            try {
              selectedPoint = points.firstWhere(
                (p) => p.id == _selectedPointId,
              );
            } catch (_) {
              selectedPoint = null;
            }
          }
        }

        try {
          return PermissionHandlerWidget(
            requiredPermissions: [
              PermissionType.location,
              PermissionType.sensor,
            ],
            onPermissionsResult: _handlePermissionResults,
            showOverlay: true,
            child: Stack(
              children: [
                Scaffold(
                  body: Stack(
                    children: [
                      _buildFlutterMapWidget(
                        allPoints,
                        polylinePathPoints,
                        headingLine,
                        initialMapCenter: initialMapCenter,
                        initialMapZoom: initialMapZoom,
                        tileLayerUrl: _controller.getTileLayerUrl(
                          _currentMapType,
                        ),
                      ),
                      MapControls.buildMapTypeSelector(
                        currentMapType: _currentMapType,
                        onMapTypeChanged: (mapType) {
                          setState(() {
                            _currentMapType = mapType;
                          });
                        },
                        context: context,
                      ),
                      _buildPointDetailsPanel(selectedPoint),
                      Positioned(
                        bottom: 24,
                        left: 24,
                        child: MapControls.buildFloatingActionButtons(
                          context: context,
                          hasLocationPermission: _hasLocationPermission,
                          currentPosition: _currentPosition,
                          onCenterOnLocation: _centerOnCurrentLocation,
                          onAddPoint: _handleAddPointButtonPressed,
                          onCenterOnPoints: _fitMapToPoints,
                          isAddingNewPoint:
                              _isAddingNewPoint || _newPoint != null,
                        ),
                      ),
                      if (kDebugMode && !_hasClosedDebugPanel)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: _DebugPanel(
                            heading: _currentDeviceHeading,
                            compassAccuracy: _currentCompassAccuracy,
                            shouldCalibrate: _shouldCalibrateCompass,
                            position: _currentPosition,
                            onClose: () {
                              setState(() {
                                _hasClosedDebugPanel = true;
                              });
                            },
                            onTestCalibrationPanel: () {
                              setState(() {
                                _forceShowCalibrationPanel = true;
                              });
                            },
                          ),
                        ),
                      if (_shouldCalibrateCompass == true ||
                          _forceShowCalibrationPanel)
                        CompassCalibrationPanel(
                          onClose: _forceShowCalibrationPanel
                              ? () => setState(
                                  () => _forceShowCalibrationPanel = false,
                                )
                              : null,
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 24,
                  right: 24,
                  child: StatusIndicator(
                    status: currentStatus,
                    onDismiss: hideStatus,
                  ),
                ),
              ],
            ),
          );
        } catch (e, st) {
          logger.severe('MapToolView: Exception building FlutterMap: $e\n$st');
          return Stack(
            children: [
              const Center(child: Text('Error building map. See logs.')),
              Positioned(
                top: 24,
                right: 24,
                child: StatusIndicator(
                  status: currentStatus,
                  onDismiss: hideStatus,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  List<LatLng> _buildPolylinePathPoints() {
    if (!_isLoadingPoints) {
      final projectState = Provider.of<ProjectStateManager>(
        context,
        listen: false,
      );
      final points = projectState.currentPoints;

      if (points.length >= 2) {
        return points.map((p) => LatLng(p.latitude, p.longitude)).toList();
      }
    }
    return [];
  }

  Polyline? _buildHeadingLine() {
    if (_headingFromFirstToLast != null) {
      final projectState = Provider.of<ProjectStateManager>(
        context,
        listen: false,
      );
      final points = projectState.currentPoints;

      if (points.length >= 2) {
        return Polyline(
          points: [
            LatLng(points.first.latitude, points.first.longitude),
            LatLng(points.last.latitude, points.last.longitude),
          ],
          color: Colors.purple.withAlpha((0.7 * 255).round()),
          strokeWidth: 3.0,
          pattern: StrokePattern.dotted(),
        );
      }
    }
    return null;
  }

  // Helper to check if a polyline has at least two distinct points
  bool _isValidPolyline(List<LatLng> points) {
    if (points.length < 2) return false;
    final first = points.first;
    return points.any(
      (p) => p.latitude != first.latitude || p.longitude != first.longitude,
    );
  }

  Widget _buildFlutterMapWidget(
    List<PointModel> allPoints,
    List<LatLng> polylinePathPoints,
    Polyline? headingLine, {
    required LatLng initialMapCenter,
    required double initialMapZoom,
    required String tileLayerUrl,
  }) {
    try {
      return FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialMapCenter,
          initialZoom: initialMapZoom,
          keepAlive: true,
          onTap: (tapPosition, latlng) {
            if (_isMovePointMode) {
              if (_selectedPointId != null) {
                try {
                  final projectState = Provider.of<ProjectStateManager>(
                    context,
                    listen: false,
                  );
                  final points = projectState.currentPoints;
                  final pointToMove = points.firstWhere(
                    (p) => p.id == _selectedPointId,
                  );
                  _handleMovePoint(pointToMove, latlng);
                } catch (e) {
                  logger.warning(
                    "Error finding point to move in onTap: $_selectedPointId. $e",
                  );
                  showErrorStatus(
                    "Error: Selected point not found. Please select again.",
                  );
                  setState(() {
                    _isMovePointMode = false;
                    _selectedPointId = null;
                  });
                }
              } else {
                showErrorStatus(
                  "No point selected to move. Tap a point first, then activate 'Move Point' mode.",
                );
              }
            } else {
              // Only deselect if we're not dealing with a new point
              if (_selectedPointId != null) {
                setState(() {
                  _selectedPointId = null;
                });
              }
            }
          },
          onMapReady: () {
            logger.info("MapToolView: Map is ready (onMapReady called).");
            if (mounted) {
              setState(() {
                _isMapReady = true;
              });
              _fitMapToPoints();
            }
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
                _controller.getTileLayerAttribution(_currentMapType),
                onTap: () {
                  final url = _controller.getAttributionUrl(_currentMapType);
                  if (url.isNotEmpty) {
                    launchUrl(Uri.parse(url));
                  }
                },
              ),
            ],
          ),
          const MapCompass.cupertino(hideIfRotatedNorth: true),
          // Add azimuth arrow marker on top of current location (drawn first, so it's below the location marker)
          if (_currentPosition != null &&
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
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  child: _ProjectAzimuthArrow(
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
              marker: _CurrentLocationAccuracyMarker(
                accuracy: _currentPosition?.accuracy,
              ),
              markerSize: const Size.square(60),
              markerDirection: MarkerDirection.heading,
              showAccuracyCircle: false,
              headingSectorRadius: 40,
            ),
            positionStream: _locationStreamController.stream,
          ),
          if (_isValidPolyline(polylinePathPoints))
            PolylineLayer(
              polylines: [
                Polyline(
                  points: polylinePathPoints,
                  gradientColors: [Colors.green, Colors.yellow, Colors.red],
                  colorsStop: [0.0, 0.5, 1.0],
                  strokeWidth: 3.0,
                ),
              ],
            ),
          if (headingLine != null && _isValidPolyline(headingLine.points))
            PolylineLayer(polylines: [headingLine]),
          if (_projectHeadingLine != null &&
              _isValidPolyline(_projectHeadingLine!.points))
            PolylineLayer(polylines: [_projectHeadingLine!]),
          MarkerLayer(
            markers: MapMarkers.buildAllMapMarkers(
              context: context,
              projectPoints: allPoints,
              selectedPointId: _selectedPointId,
              isMovePointMode: _isMovePointMode,
              glowAnimationValue: _glowAnimationValue,
              currentPosition: _currentPosition,
              hasLocationPermission: _hasLocationPermission,
              headingFromFirstToLast: _headingFromFirstToLast,
              onPointTap: _handlePointTap,
              currentDeviceHeading: _currentDeviceHeading,
            ),
            rotate: true,
          ),
        ],
      );
    } catch (e, st) {
      logger.severe('MapToolView: Exception building FlutterMap: $e\n$st');
      return Stack(
        children: [
          const Center(child: Text('Error building map. See logs.')),
          Positioned(
            top: 24,
            right: 24,
            child: StatusIndicator(
              status: currentStatus,
              onDismiss: hideStatus,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildPointDetailsPanel(PointModel? selectedPoint) {
    return PointDetailsPanel(
      selectedPoint: selectedPoint,
      isMovePointMode: _isMovePointMode,
      isMovingPointLoading: _isMovingPointLoading,
      selectedPointId: _selectedPointId,
      isMapReady: _isMapReady,
      mapController: _mapController,
      onClose: () {
        setState(() {
          _selectedPointId = null;
        });
      },
      onEdit: () => _handleEditPoint(selectedPoint!),
      onMove: _handleMovePointAction,
      onDelete: () => _handleDeletePoint(selectedPoint!),
      onPointUpdated: _handlePointUpdated,
      onSaveNewPoint: _newPoint != null ? _handleSaveNewPoint : null,
      onDiscardNewPoint: _newPoint != null ? _handleDiscardNewPoint : null,
    );
  }

  Future<void> _handleEditPoint(PointModel point) async {
    logger.info("Navigating to edit point ${point.name}");

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => PointDetailsPage(point: point)),
    );

    if (result != null && mounted) {
      final action = result['action'] as String?;

      if (action == 'updated') {
        final updatedPoint = result['point'] as PointModel?;
        if (updatedPoint != null) {
          // Do NOT call updatePointInEditingState again; PointDetailsPage already did it and notified listeners
          setState(() {
            _recalculateAndDrawLines();
          });
          logger.info(
            "Point ${updatedPoint.name} details updated (pending save)!",
          );
          showSuccessStatus(
            'Point ${updatedPoint.name} details updated (pending save)!',
          );
        }
      } else if (action == 'deleted') {
        final pointId = result['pointId'] as String?;
        if (pointId != null) {
          // Use global state to delete the point in memory
          final projectState = Provider.of<ProjectStateManager>(
            context,
            listen: false,
          );
          projectState.deletePointInEditingState(pointId);
          setState(() {
            if (_selectedPointId == pointId) {
              _selectedPointId = null;
            }
            _recalculateAndDrawLines();
          });
          logger.info("Point deleted from MapToolView.");
          showSuccessStatus('Point deleted (pending save)!');
        }
      }
    }
  }

  void _handleMovePointAction() {
    setState(() {
      _isMovePointMode = !_isMovePointMode;
    });
    if (_isMovePointMode) {
      _startGlowAnimation();
      showInfoStatus('Move mode activated. Tap map to relocate point.');
    } else {
      _stopGlowAnimation();
    }
  }

  void _startGlowAnimation() {
    _controller.startGlowAnimation((value) {
      if (mounted && _isMovePointMode && _selectedPointId != null) {
        setState(() {
          _glowAnimationValue = value;
        });
      } else {
        _stopGlowAnimation();
      }
    });
  }

  void _stopGlowAnimation() {
    _controller.stopGlowAnimation();
    _glowAnimationValue = 0.0;
  }

  Future<void> _handleDeletePoint(PointModel point) async {
    logger.info("Delete tapped for point ${point.name}");
    await _handleDeletePointFromPanel(point);
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition == null) {
      showInfoStatus(
        'Current location not available. Please wait for GPS signal.',
      );
      return;
    }

    try {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        _mapController.camera.zoom,
      );
      showSuccessStatus('Centered on your current location.');
    } catch (e) {
      logger.warning('Error centering on current location: $e');
      showErrorStatus('Error centering on current location.');
    }
  }

  void _handleAddPointButtonPressed() async {
    // Check if there's already an unsaved point
    if (_newPoint != null) {
      final s = S.of(context);
      showInfoStatus(
        s?.mapUnsavedPointExists ??
            'You have an unsaved point. Please save or discard it before adding another.',
      );
      return;
    }

    setState(() {
      _isAddingNewPoint = true;
    });

    try {
      // Try to get current location with maximum accuracy
      LatLng newPointLocation;
      double? altitude;

      if (_hasLocationPermission && _currentPosition != null) {
        // Use current GPS location
        newPointLocation = LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        altitude = _currentPosition!.altitude;
      } else {
        // Use map center as fallback
        final mapCenter = _mapController.camera.center;
        newPointLocation = mapCenter;
        altitude = null;
      }

      // Create new point
      final newPoint = await _controller.createNewPoint(
        newPointLocation,
        altitude: altitude,
      );

      if (mounted) {
        setState(() {
          _newPoint = newPoint;
          _selectedPointId = newPoint.id;
          _isAddingNewPoint = false;
        });
        // Set global unsaved new point flag
        context.projectState.setHasUnsavedNewPoint(true);

        showInfoStatus(
          'New point created. Tap "Save" to add it to your project.',
        );
      }
    } catch (e) {
      logger.severe('Failed to create new point: $e');
      if (mounted) {
        setState(() {
          _isAddingNewPoint = false;
        });
        showErrorStatus('Error creating new point: ${e.toString()}');
      }
    }
  }

  Future<void> _handleSaveNewPoint() async {
    if (_newPoint == null) return;

    try {
      // Set flag to skip automatic fitting after saving new point
      _skipNextFitToPoints = true;

      // Use global state to add the new point in memory (not DB)
      final projectState = Provider.of<ProjectStateManager>(
        context,
        listen: false,
      );
      // Remove isUnsaved flag from the point before adding
      final savedPoint = _newPoint!.copyWith(isUnsaved: false);
      projectState.addPointInEditingState(savedPoint);

      if (mounted) {
        setState(() {
          _newPoint = null;
          _selectedPointId = null;
        });
        // Clear global unsaved new point flag
        context.projectState.setHasUnsavedNewPoint(false);

        final s = S.of(context);
        showSuccessStatus(
          s?.mapNewPointSaved ?? 'New point saved (pending save)!',
        );
      }
    } catch (e) {
      logger.severe('Failed to save new point: $e');
      if (mounted) {
        final s = S.of(context);
        showErrorStatus(
          s?.mapErrorSavingNewPoint(e.toString()) ??
              'Error saving new point: $e',
        );
      }
    }
  }

  void _handleDiscardNewPoint() {
    setState(() {
      _newPoint = null;
      _selectedPointId = null;
    });
    // Clear global unsaved new point flag
    context.projectState.setHasUnsavedNewPoint(false);

    showInfoStatus('New point discarded.');
  }

  Future<void> _handleDeletePointFromPanel(PointModel pointToDelete) async {
    final s = S.of(context);
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(s?.mapDeletePointDialogTitle ?? 'Delete Point'),
          content: Text(
            s?.mapDeletePointDialogContent(pointToDelete.name) ??
                'Are you sure you want to delete point ${pointToDelete.name}?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(s?.buttonCancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(s?.buttonDelete ?? 'Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      try {
        // Use global state to delete the point in memory (not DB)
        final projectState = Provider.of<ProjectStateManager>(
          context,
          listen: false,
        );
        projectState.deletePointInEditingState(pointToDelete.id);

        setState(() {
          logger.info(
            "Point ${pointToDelete.name} (ID: ${pointToDelete.id}) removed from MapToolView after panel delete.",
          );
          if (_selectedPointId == pointToDelete.id) {
            _selectedPointId = null;
          }
        });

        showSuccessStatus(
          'Point ${pointToDelete.name} deleted (pending save).',
        );
      } catch (e) {
        if (!mounted) return;
        logger.severe(
          'Failed to delete point ${pointToDelete.name} from panel: $e',
        );

        showErrorStatus('Error deleting point ${pointToDelete.name}: $e');
      }
    }
  }

  void _handlePointTap(PointModel point) {
    setState(() {
      if (_selectedPointId == point.id) {
        _selectedPointId = null;
      } else {
        _selectedPointId = point.id;
      }
    });
  }

  // Handle point updates from inline editing
  Future<void> _handlePointUpdated(PointModel updatedPoint) async {
    try {
      // Check if this is a new unsaved point
      if (updatedPoint.isUnsaved) {
        // Update the local new point instance
        setState(() {
          _newPoint = updatedPoint;
        });
        showSuccessStatus('Point ${updatedPoint.name} updated!');
      } else {
        // Use global state to update the point in memory and mark as dirty
        final projectState = Provider.of<ProjectStateManager>(
          context,
          listen: false,
        );
        projectState.updatePointInEditingState(updatedPoint);

        // Recalculate lines if needed
        setState(() {
          _recalculateAndDrawLines();
        });

        showSuccessStatus('Point ${updatedPoint.name} updated (pending save)!');
      }
    } catch (e) {
      logger.severe('Failed to update point ${updatedPoint.name}: $e');
      if (mounted) {
        showErrorStatus(
          'Error updating point ${updatedPoint.name}: ${e.toString()}',
        );
      }
    }
  }

  /// Public method to refresh points from the database
  /// This can be called from the parent component when points are reordered
  Future<void> refreshPoints() async {
    logger.info("MapToolView: External refresh requested.");
    _isExternalRefresh = true; // Set flag to prevent callback loops

    try {
      // Use global state to refresh points
      final projectState = Provider.of<ProjectStateManager>(
        context,
        listen: false,
      );
      if (!projectState.hasUnsavedChanges) {
        await projectState.refreshPoints();
      }

      if (mounted) {
        // Recalculate lines with current points
        _recalculateAndDrawLines();

        // Fit map to points if not skipping
        if (!_skipNextFitToPoints && _isMapReady) {
          _fitMapToPoints();
        }
      }

      _skipNextFitToPoints = false; // Reset the flag
    } catch (e, stackTrace) {
      logger.severe("MapToolView: Error refreshing points", e, stackTrace);
      if (mounted) {
        final s = S.of(context);
        showErrorStatus(
          s?.mapErrorLoadingPoints(e.toString()) ??
              "Error refreshing points: $e",
        );
      }
    } finally {
      _isExternalRefresh = false; // Reset flag after refresh
    }
  }

  /// Public method to undo changes (reload from DB)
  Future<void> undoChanges() async {
    await context.projectState.undoChanges();
  }
}

// Custom marker: red transparent accuracy circle with current location icon
class _CurrentLocationAccuracyMarker extends StatelessWidget {
  final double? accuracy;

  const _CurrentLocationAccuracyMarker({this.accuracy});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(60, 60),
          painter: _AccuracyCirclePainter(accuracy: accuracy),
        ),
        Icon(Icons.my_location, color: Colors.black, size: 20),
      ],
    );
  }
}

class _AccuracyCirclePainter extends CustomPainter {
  final double? accuracy;

  _AccuracyCirclePainter({this.accuracy});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double accuracyRadius = (accuracy != null)
        ? (accuracy!.clamp(5, 50) / 50.0) * (size.width / 2)
        : size.width / 2;
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, accuracyRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Arrow widget for project azimuth
class _ProjectAzimuthArrow extends StatelessWidget {
  final double azimuth;

  const _ProjectAzimuthArrow({required this.azimuth});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: (azimuth - 90) * 3.141592653589793 / 180.0,
      child: CustomPaint(
        size: const Size(32, 32),
        painter: _StaticArrowPainter(),
      ),
    );
  }
}

class _StaticArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double arrowLength = 20;
    final double baseRadius = 4;
    final double angle = 0.0; // Upwards

    // Tip of the arrow
    final tip = Offset(
      center.dx + arrowLength * cos(angle),
      center.dy + arrowLength * sin(angle),
    );
    // Base left/right (flat base at baseRadius from center)
    final left = Offset(
      center.dx + baseRadius * cos(angle + 2.5),
      center.dy + baseRadius * sin(angle + 2.5),
    );
    final right = Offset(
      center.dx + baseRadius * cos(angle - 2.5),
      center.dy + baseRadius * sin(angle - 2.5),
    );

    final path = ui.Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    final paint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Debug panel widget for kDebugMode
class _DebugPanel extends StatelessWidget {
  final double? heading;
  final double? compassAccuracy;
  final bool? shouldCalibrate;
  final Position? position;
  final VoidCallback? onClose;
  final VoidCallback? onTestCalibrationPanel;

  const _DebugPanel({
    this.heading,
    this.compassAccuracy,
    this.shouldCalibrate,
    this.position,
    this.onClose,
    this.onTestCalibrationPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DEBUG PANEL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.amber,
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onClose,
                      tooltip: 'Close debug panel',
                    ),
                  if (onTestCalibrationPanel != null)
                    TextButton(
                      onPressed: onTestCalibrationPanel,
                      child: const Text(
                        'Test Calibration Panel',
                        style: TextStyle(color: Colors.amber, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Heading: ${heading?.toStringAsFixed(2) ?? "-"}°'),
              Text(
                'Compass accuracy: ${compassAccuracy?.toStringAsFixed(2) ?? "-"}',
              ),
              Text(
                'Should calibrate: ${shouldCalibrate == true ? "YES" : "NO"}',
              ),
              if (position != null) ...[
                Text(
                  'Location: ${position!.latitude.toStringAsFixed(6)}, ${position!.longitude.toStringAsFixed(6)}',
                ),
                Text(
                  'Location accuracy: ${position!.accuracy.toStringAsFixed(2)} m',
                ),
                Text('Altitude: ${position!.altitude.toStringAsFixed(2)} m'),
                Text('Speed: ${position!.speed.toStringAsFixed(2)} m/s'),
                Text(
                  'Speed accuracy: ${position!.speedAccuracy.toStringAsFixed(2)} m/s',
                ),
                Text('Timestamp: ${position!.timestamp}'),
              ] else ...[
                const Text('Location: -'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
