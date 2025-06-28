// map_tool_view.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/core/logger.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/pages/point_details_page.dart';
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
  final Function(BuildContext, double, {bool? setAsEndPoint})?
  onAddPointFromCompass;
  final VoidCallback? onPointsChanged;

  const MapToolView({
    super.key,
    required this.project,
    this.selectedPointId,
    this.onNavigateToCompassTab,
    this.onAddPointFromCompass,
    this.onPointsChanged,
  });

  @override
  State<MapToolView> createState() => MapToolViewState();
}

class MapToolViewState extends State<MapToolView> with StatusMixin {
  // Controller for business logic
  late final MapControllerLogic _controller;

  // UI State
  final MapController _mapController = MapController();
  bool _isLoadingPoints = true;
  bool _isMapReady = false;
  String? _selectedPointId;
  bool _isMovePointMode = false;
  bool _isMovingPointLoading = false;
  PointModel? _selectedPointInstance;

  // New point functionality
  PointModel? _newPoint; // The unsaved new point
  bool _isAddingNewPoint = false; // Whether we're in the process of adding a new point

  // Data from controller
  List<PointModel> _projectPoints = [];
  Position? _currentPosition;
  double? _currentDeviceHeading;
  bool _hasLocationPermission = false;
  bool _hasSensorPermission = false;
  double? _headingFromFirstToLast;
  Polyline? _projectHeadingLine;
  MapType _currentMapType = MapType.openStreetMap;
  double _glowAnimationValue = 0.0;

  // Animation timer
  Timer? _glowAnimationTimer;

  @override
  void initState() {
    super.initState();
    _controller = MapControllerLogic(project: widget.project);
    _selectedPointId = widget.selectedPointId;
    _loadProjectPoints();
    _checkAndRequestPermissions();
  }

  @override
  void didUpdateWidget(covariant MapToolView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.project.id != oldWidget.project.id) {
      _loadProjectPoints();
    } else if (widget.project.azimuth != oldWidget.project.azimuth) {
      _recalculateAndDrawLines();
    } else if (widget.project.startingPointId != oldWidget.project.startingPointId ||
               widget.project.endingPointId != oldWidget.project.endingPointId) {
      // Project start/end points changed, reload points to get updated data
      _loadProjectPoints();
    }

    if (widget.selectedPointId != oldWidget.selectedPointId) {
      setState(() {
        _selectedPointId = widget.selectedPointId;
        _updateSelectedPointInstance();
      });
    }
  }

  @override
  void dispose() {
    _glowAnimationTimer?.cancel();
    _controller.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Permission handling
  Future<void> _checkAndRequestPermissions() async {
    try {
      final permissions = await _controller.checkAndRequestPermissions();

      if (mounted) {
        setState(() {
          _hasLocationPermission = permissions['location'] ?? false;
          _hasSensorPermission = permissions['sensor'] ?? false;
        });
      }

      if (_hasLocationPermission) {
        _startListeningToLocation();
      } else {
        _showPermissionWarning('location');
      }

      if (_hasSensorPermission) {
        _startListeningToCompass();
      } else {
        _showPermissionWarning('sensor');
      }
    } catch (e) {
      logger.severe("Error checking permissions", e);
      if (mounted) {
        showErrorStatus('Error checking permissions: $e');
      }
    }
  }

  void _showPermissionWarning(String permissionType) {
    final s = S.of(context);
    String message;

    switch (permissionType) {
      case 'location':
        message =
            s?.mapLocationPermissionDenied ??
            'Location permission denied. Map features requiring location will be limited.';
        break;
      case 'sensor':
        message =
            s?.mapSensorPermissionDenied ??
            'Sensor (compass) permission denied. Device orientation features will be unavailable.';
        break;
      default:
        message = 'Permission denied.';
    }

    if (mounted) {
      showInfoStatus(message);
    }
  }

  void _startListeningToLocation() {
    _controller.startListeningToLocation(
      (position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
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
      (heading) {
        if (mounted) {
          setState(() {
            _currentDeviceHeading = heading;
          });
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
      final points = await _controller.loadProjectPoints();

      if (mounted) {
        setState(() {
          _projectPoints = points;
          _isLoadingPoints = false;
          _recalculateAndDrawLines();
        });
        widget.onPointsChanged?.call();
      }
      if (_isMapReady) {
        _fitMapToPoints();
      }
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
        widget.onPointsChanged?.call();
      }
    }
  }

  void _recalculateAndDrawLines() {
    _headingFromFirstToLast = _controller.recalculateHeadingLine(
      _projectPoints,
    );
    _projectHeadingLine = _controller.recalculateProjectHeadingLine(
      _projectPoints,
    );
  }

  Future<void> _handleMovePoint(
    PointModel pointToMove,
    LatLng newPosition,
  ) async {
    if (_isMovingPointLoading) return;

    setState(() {
      _isMovingPointLoading = true;
      // Provide immediate visual feedback
      final index = _projectPoints.indexWhere((p) => p.id == pointToMove.id);
      if (index != -1) {
        _projectPoints[index] = pointToMove.copyWith(
          latitude: newPosition.latitude,
          longitude: newPosition.longitude,
        );
      }
    });

    try {
      int result = await _controller.movePoint(pointToMove, newPosition);

      if (!mounted) return;

      if (result > 0) {
        setState(() {
          final index = _projectPoints.indexWhere(
            (p) => p.id == pointToMove.id,
          );
          if (index != -1) {
            _projectPoints[index] = pointToMove.copyWith(
              latitude: newPosition.latitude,
              longitude: newPosition.longitude,
            );
          }
          _isMovePointMode = false;
          _recalculateAndDrawLines();
        });
        showSuccessStatus('Point ${pointToMove.name} moved successfully!');
        widget.onPointsChanged?.call();
      } else {
        showErrorStatus(
          'Error: Could not move point ${pointToMove.name}. Point not found or not updated.',
        );
        widget.onPointsChanged?.call();
      }
    } catch (e) {
      logger.severe('Failed to move point ${pointToMove.name}: $e');
      if (!mounted) return;
      showErrorStatus(
        'Error moving point ${pointToMove.name}: ${e.toString()}',
      );
      widget.onPointsChanged?.call();
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

    if (_projectPoints.isEmpty) {
      try {
        final center = _controller.getInitialCenter(
          _projectPoints,
          _currentPosition,
        );
        final zoom = _controller.getInitialZoom(
          _projectPoints,
          _currentPosition,
        );
        _mapController.move(center, zoom);
      } catch (e) {
        logger.warning('Error moving map to default center: $e');
      }
      return;
    }

    if (_projectPoints.length == 1) {
      try {
        _mapController.move(
          LatLng(_projectPoints.first.latitude, _projectPoints.first.longitude),
          15.0,
        );
      } catch (e) {
        logger.warning('Error moving map to single point: $e');
      }
      return;
    }

    try {
      final List<LatLng> pointCoords = _projectPoints
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
          LatLng(_projectPoints.first.latitude, _projectPoints.first.longitude),
          14.0,
        );
      } catch (e2) {
        logger.warning('Error in fallback map move: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                    ).colorScheme.primary.withOpacity(0.1),
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
                    ).colorScheme.onSurfaceVariant.withOpacity(0.7),
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

    _updateSelectedPointInstance();
    
    // Combine project points with new point if it exists
    final allPoints = [..._projectPoints];
    if (_newPoint != null) {
      allPoints.add(_newPoint!);
    }
    
    final List<Marker> allMapMarkers = MapMarkers.buildAllMapMarkers(
      projectPoints: allPoints,
      selectedPointId: _selectedPointId,
      isMovePointMode: _isMovePointMode,
      glowAnimationValue: _glowAnimationValue,
      currentPosition: _currentPosition,
      hasLocationPermission: _hasLocationPermission,
      headingFromFirstToLast: _headingFromFirstToLast,
      onPointTap: _handlePointTap,
    );
    final List<LatLng> polylinePathPoints = _buildPolylinePathPoints();
    final headingLine = _buildHeadingLine();

    LatLng initialMapCenter = _controller.getInitialCenter(
      _projectPoints,
      _currentPosition,
    );
    double initialMapZoom = _controller.getInitialZoom(
      _projectPoints,
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

    return Stack(
      children: [
        Scaffold(
          body: Stack(
            children: [
              _buildFlutterMapWidget(
                allMapMarkers,
                polylinePathPoints,
                headingLine,
                initialMapCenter: initialMapCenter,
                initialMapZoom: initialMapZoom,
              ),
              MapControls.buildPermissionOverlay(
                context: context,
                hasLocationPermission: _hasLocationPermission,
                hasSensorPermission: _hasSensorPermission,
                onRetryPermissions: _checkAndRequestPermissions,
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
              _buildPointDetailsPanel(),
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
                  isAddingNewPoint: _isAddingNewPoint,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 24,
          right: 24,
          child: StatusIndicator(status: currentStatus, onDismiss: hideStatus),
        ),
      ],
    );
  }

  void _updateSelectedPointInstance() {
    _selectedPointInstance = null;
    if (_selectedPointId != null) {
      // First check if it's the new point
      if (_newPoint != null && _newPoint!.id == _selectedPointId) {
        _selectedPointInstance = _newPoint;
        return;
      }
      
      // Then check in project points
      if (_projectPoints.isNotEmpty) {
        try {
          _selectedPointInstance = _projectPoints.firstWhere(
            (p) => p.id == _selectedPointId,
          );
        } catch (e) {
          logger.warning(
            "Selected point ID $_selectedPointId not found in project points. Deselecting.",
          );
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _selectedPointId = null;
                _selectedPointInstance = null;
              });
            }
          });
        }
      }
    }
  }

  List<LatLng> _buildPolylinePathPoints() {
    if (!_isLoadingPoints && _projectPoints.length >= 2) {
      return _projectPoints
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
    }
    return [];
  }

  Polyline? _buildHeadingLine() {
    if (_headingFromFirstToLast != null && _projectPoints.length >= 2) {
      return Polyline(
        points: [
          LatLng(_projectPoints.first.latitude, _projectPoints.first.longitude),
          LatLng(_projectPoints.last.latitude, _projectPoints.last.longitude),
        ],
        color: Colors.purple.withAlpha((0.7 * 255).round()),
        strokeWidth: 3.0,
        pattern: StrokePattern.dotted(),
      );
    }
    return null;
  }

  Widget _buildFlutterMapWidget(
    List<Marker> allMapMarkers,
    List<LatLng> polylinePathPoints,
    Polyline? headingLine, {
    required LatLng initialMapCenter,
    required double initialMapZoom,
  }) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialMapCenter,
        initialZoom: initialMapZoom,
        onTap: (tapPosition, latlng) {
          if (_isMovePointMode) {
            if (_selectedPointId != null) {
              try {
                final pointToMove = _projectPoints.firstWhere(
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
                  _selectedPointInstance = null;
                });
              }
            } else {
              showErrorStatus(
                "No point selected to move. Tap a point first, then activate 'Move Point' mode.",
              );
            }
          } else {
            // Only deselect if we're not dealing with a new point
            if (_selectedPointId != null && _newPoint == null) {
              setState(() {
                _selectedPointId = null;
                _selectedPointInstance = null;
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
          urlTemplate: _controller.getTileLayerUrl(_currentMapType),
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
        if (polylinePathPoints.isNotEmpty)
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
        if (headingLine != null) PolylineLayer(polylines: [headingLine]),
        if (_projectHeadingLine != null)
          PolylineLayer(polylines: [_projectHeadingLine!]),
        MarkerLayer(markers: allMapMarkers),
      ],
    );
  }

  Widget _buildPointDetailsPanel() {
    return PointDetailsPanel(
      selectedPoint: _selectedPointInstance,
      isMovePointMode: _isMovePointMode,
      isMovingPointLoading: _isMovingPointLoading,
      selectedPointId: _selectedPointId,
      isMapReady: _isMapReady,
      mapController: _mapController,
      onClose: () {
        setState(() {
          _selectedPointId = null;
          _selectedPointInstance = null;
        });
      },
      onEdit: _handleEditPoint,
      onMove: _handleMovePointAction,
      onDelete: _handleDeletePoint,
      onPointUpdated: _handlePointUpdated,
      onSaveNewPoint: _newPoint != null ? _handleSaveNewPoint : null,
      onDiscardNewPoint: _newPoint != null ? _handleDiscardNewPoint : null,
    );
  }

  // Action Handlers
  Future<void> _handleEditPoint() async {
    if (_selectedPointInstance == null) return;

    logger.info("Navigating to edit point ${_selectedPointInstance!.name}");

    final result = await Navigator.push<PointModel>(
      context,
      MaterialPageRoute(
        builder: (context) => PointDetailsPage(point: _selectedPointInstance!),
      ),
    );

    if (result != null && mounted) {
      final index = _projectPoints.indexWhere((p) => p.id == result.id);
      if (index != -1) {
        setState(() {
          _projectPoints[index] = result;
          logger.info("Point ${result.name} updated in MapToolView.");
        });
        showSuccessStatus('Point ${result.name} details updated!');
        widget.onPointsChanged?.call();
      }
    }
  }

  void _handleMovePointAction() {
    if (_isMovePointMode && _selectedPointInstance?.id == _selectedPointId) {
      setState(() {
        _isMovePointMode = false;
      });
      _stopGlowAnimation();
    } else if (!_isMovePointMode) {
      setState(() {
        _isMovePointMode = true;
      });
      _startGlowAnimation();
      showInfoStatus('Move mode activated. Tap map to relocate point.');
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

  Future<void> _handleDeletePoint() async {
    if (_selectedPointInstance == null) {
      showErrorStatus('No point selected to delete.');
      return;
    }

    logger.info("Delete tapped for point ${_selectedPointInstance!.name}");
    await _handleDeletePointFromPanel(_selectedPointInstance!);
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
      showInfoStatus(s?.mapUnsavedPointExists ?? 'You have an unsaved point. Please save or discard it before adding another.');
      return;
    }

    setState(() {
      _isAddingNewPoint = true;
    });

    try {
      // Try to get current location with maximum accuracy
      LatLng newPointLocation;
      
      if (_hasLocationPermission && _currentPosition != null) {
        // Use current GPS location
        newPointLocation = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      } else {
        // Use map center as fallback
        final mapCenter = _mapController.camera.center;
        newPointLocation = mapCenter;
      }

      // Create new point
      final newPoint = await _controller.createNewPoint(newPointLocation);
      
      if (mounted) {
        setState(() {
          _newPoint = newPoint;
          _selectedPointId = newPoint.id;
          _selectedPointInstance = newPoint;
          _isAddingNewPoint = false;
        });
        
        showInfoStatus('New point created. Tap "Save" to add it to your project.');
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
      // Save the point to database
      final pointId = await _controller.saveNewPoint(_newPoint!);
      
      if (mounted) {
        // Create a new instance with isUnsaved: false for the saved point
        final savedPoint = _newPoint!.copyWith(isUnsaved: false);
        
        // Add to project points list
        setState(() {
          _projectPoints.add(savedPoint);
          _newPoint = null;
          _selectedPointId = null;
          _selectedPointInstance = null;
          _recalculateAndDrawLines();
        });
        
        // Update project start/end points in the database
        await _controller.updateProjectStartEndPoints();
        
        final s = S.of(context);
        showSuccessStatus(s?.mapNewPointSaved ?? 'New point saved successfully!');
        widget.onPointsChanged?.call();
      }
    } catch (e) {
      logger.severe('Failed to save new point: $e');
      if (mounted) {
        final s = S.of(context);
        showErrorStatus(s?.mapErrorSavingNewPoint(e.toString()) ?? 'Error saving new point: $e');
      }
    }
  }

  void _handleDiscardNewPoint() {
    setState(() {
      _newPoint = null;
      _selectedPointId = null;
      _selectedPointInstance = null;
    });
    
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
        final int deletedCount = await _controller.deletePoint(
          pointToDelete.id,
        );
        if (deletedCount > 0) {
          setState(() {
            _projectPoints.removeWhere((p) => p.id == pointToDelete.id);
            logger.info(
              "Point ${pointToDelete.name} (ID: ${pointToDelete.id}) removed from MapToolView after panel delete.",
            );
            if (_selectedPointId == pointToDelete.id) {
              _selectedPointId = null;
              _selectedPointInstance = null;
            }
          });

          // Update project start/end points in the database
          await _controller.updateProjectStartEndPoints();

          showSuccessStatus('Point ${pointToDelete.name} deleted.');
          widget.onPointsChanged?.call();
        } else {
          showErrorStatus(
            'Error: Point ${pointToDelete.name} could not be found or deleted from map view.',
          );
        }
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
        _selectedPointInstance = null;
      } else {
        _selectedPointId = point.id;
        _selectedPointInstance = point;
      }
    });
  }

  // Handle point updates from inline editing
  Future<void> _handlePointUpdated(PointModel updatedPoint) async {
    try {
      // Save to database
      final result = await _controller.movePoint(updatedPoint, LatLng(updatedPoint.latitude, updatedPoint.longitude));
      
      if (result > 0) {
        // Update local state
        setState(() {
          final index = _projectPoints.indexWhere((p) => p.id == updatedPoint.id);
          if (index != -1) {
            _projectPoints[index] = updatedPoint;
            // Update selected point instance if it's the same point
            if (_selectedPointInstance?.id == updatedPoint.id) {
              _selectedPointInstance = updatedPoint;
            }
          }
          _recalculateAndDrawLines();
        });
        
        showSuccessStatus('Point ${updatedPoint.name} updated successfully!');
        widget.onPointsChanged?.call();
      } else {
        showErrorStatus('Error: Could not update point ${updatedPoint.name}.');
      }
    } catch (e) {
      logger.severe('Failed to update point ${updatedPoint.name}: $e');
      if (mounted) {
        showErrorStatus('Error updating point ${updatedPoint.name}: ${e.toString()}');
      }
    }
  }

  // Method to update the project model when it changes from parent
  void _updateProjectModel(ProjectModel updatedProject) {
    // Update the controller with the new project
    _controller = MapControllerLogic(project: updatedProject);
    
    // Reload points to get the latest data
    _loadProjectPoints();
  }
}
