// map_tool_view.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:teleferika/core/logger.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/pages/point_details_page.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

enum MapType { openStreetMap, satellite, terrain }

class MapToolView extends StatefulWidget {
  final ProjectModel project;
  final String? selectedPointId; // From project_page
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
  List<PointModel> _projectPoints = [];
  bool _isLoadingPoints = true;
  final MapController _mapController = MapController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Default center if no points are available (e.g., Rome)
  final LatLng _defaultCenter = const LatLng(41.9028, 12.4964);
  final double _defaultZoom = 6.0;

  Polyline? _headingLine;

  bool _isMapReady = false;
  String? _selectedPointId;
  bool _isMovePointMode = false; // For activating point move mode
  bool _isMovingPointLoading =
      false; // Optional: For loading state during DB update
  double? _headingFromFirstToLast;

  // --- New state variables for current position and permissions ---
  Position? _currentPosition; // From geolocator (lat, lng, alt)
  double? _currentDeviceHeading; // From flutter_compass
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasLocationPermission = false;
  bool _hasSensorPermission = false; // For compass

  PointModel? _selectedPointInstance; // For the panel

  Polyline?
  _projectHeadingLine; // New state variable for the project heading line

  // Map type selection
  MapType _currentMapType = MapType.openStreetMap;

  @override
  void initState() {
    super.initState();
    // Initialize selectedPointId from widget
    _selectedPointId = widget.selectedPointId;
    _loadProjectPoints();
    _checkAndRequestPermissions();
  }

  @override
  void didUpdateWidget(covariant MapToolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle project changes
    // this will never happen with the current implementation, but you never know!
    if (widget.project.id != oldWidget.project.id) {
      _loadProjectPoints(); // This will also recalculate lines
    } else if (widget.project.azimuth != oldWidget.project.azimuth) {
      // If only the heading changed, just recalculate lines
      _recalculateAndDrawLines();
    }
    
    // Handle selectedPointId changes from parent
    if (widget.selectedPointId != oldWidget.selectedPointId) {
      setState(() {
        _selectedPointId = widget.selectedPointId;
        _updateSelectedPointInstance();
      });
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _compassSubscription?.cancel();
    _mapController.dispose(); // Ensure map controller is disposed
    super.dispose();
  }

  // --- Permission Handling ---
  Future<void> _checkAndRequestPermissions() async {
    try {
      // Location Permission
      LocationPermission locationPermission =
          await Geolocator.checkPermission();
      if (locationPermission == LocationPermission.denied) {
        locationPermission = await Geolocator.requestPermission();
      }

      // Sensor (Compass) Permission
      PermissionStatus sensorStatus = await Permission.sensors.status;
      if (sensorStatus.isDenied) {
        sensorStatus = await Permission.sensors.request();
      }

      if (mounted) {
        setState(() {
          _hasLocationPermission =
              locationPermission == LocationPermission.whileInUse ||
              locationPermission == LocationPermission.always;
          _hasSensorPermission = sensorStatus.isGranted;
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
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (mounted) {
              setState(() {
                _currentPosition = position;
              });
            }
          },
          onError: (error) {
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
    if (FlutterCompass.events == null) {
      logger.warning(
        "Compass events stream is null. Cannot listen to compass.",
      );
      if (mounted) {
        setState(() => _hasSensorPermission = false);
      }
      return;
    }

    _compassSubscription = FlutterCompass.events!.listen(
      (CompassEvent event) {
        if (mounted) {
          setState(() {
            _currentDeviceHeading = event.heading;
          });
        }
      },
      onError: (error) {
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

  // Helper function to convert degrees to radians (already exists)
  double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;
  // Helper function to convert radians to degrees (already exists)
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

  Future<void> _loadProjectPoints() async {
    setState(() {
      _isLoadingPoints = true;
    });

    try {
      final points = await _dbHelper.getPointsForProject(widget.project.id);

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
    _recalculateHeadingLine();
    _recalculateProjectHeadingLine(); // New method for the project heading
    // _recalculateDeviceHeadingLine(); // If you still have this separately
  }

  Future<void> _handleMovePoint(
    PointModel pointToMove,
    LatLng newPosition,
  ) async {
    if (_isMovingPointLoading) return;

    setState(() {
      _isMovingPointLoading = true;
      // Provide immediate visual feedback by updating local list first
      // This can make the UI feel snappier, but handle potential DB errors.
      final index = _projectPoints.indexWhere((p) => p.id == pointToMove.id);
      if (index != -1) {
        _projectPoints[index] = pointToMove.copyWith(
          latitude: newPosition.latitude,
          longitude: newPosition.longitude,
          // lastUpdated: DateTime.now(), // Consider if your PointModel tracks this
        );
      }
    });

    try {
      // Create the updated point model for the database
      final updatedPoint = pointToMove.copyWith(
        latitude: newPosition.latitude,
        longitude: newPosition.longitude,
        // lastUpdated: DateTime.now(), // If your model has this
      );

      // Or more specific: updatePointCoordinates(String id, double lat, double lon)
      int result = await _dbHelper.updatePoint(updatedPoint);

      if (!mounted) return;

      if (result > 0) {
        // Successfully updated in DB, now update the main list for sure
        setState(() {
          final index = _projectPoints.indexWhere(
            (p) => p.id == updatedPoint.id,
          );
          if (index != -1) {
            _projectPoints[index] = updatedPoint;
          }
          _isMovePointMode = false; // Exit move mode
          // _selectedPointId remains the same, panel will update with new coords if shown
          // recalculate heading line
          // _recalculateHeadingLine();
          _recalculateAndDrawLines();
        });
        showSuccessStatus('Point P${updatedPoint.ordinalNumber} moved successfully!');
        widget.onPointsChanged?.call();
      } else {
        showErrorStatus(
          'Error: Could not move point P${pointToMove.ordinalNumber}. Point not found or not updated.',
        );
        // TODO: Optional: Revert optimistic UI update if you did one
        widget.onPointsChanged?.call();
      }
    } catch (e) {
      logger.severe('Failed to move point P${pointToMove.ordinalNumber}: $e');
      if (!mounted) return;
      showErrorStatus(
        'Error moving point P${pointToMove.ordinalNumber}: ${e.toString()}',
      );
      // Optional: Revert optimistic UI update
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
      // Optionally move to a default location or the project's starting point if available
      // For now, if no points, map stays at its initial or default view
      try {
        _mapController.move(_getInitialCenter(), _getInitialZoom());
      } catch (e) {
        logger.warning('Error moving map to default center: $e');
      }
      return;
    }

    if (_projectPoints.length == 1) {
      try {
        _mapController.move(
          LatLng(_projectPoints.first.latitude, _projectPoints.first.longitude),
          15.0, // Zoom in on a single point
        );
      } catch (e) {
        logger.warning('Error moving map to single point: $e');
      }
      return;
    }

    // Calculate bounds for multiple points
    try {
      final List<LatLng> pointCoords = _projectPoints
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      final bounds = LatLngBounds.fromPoints(pointCoords);

      // Add some padding to the bounds
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50.0), // Adjust padding as needed
        ),
      );
    } catch (e) {
      logger.warning('Error fitting map to points: $e');
      // Fallback to moving to first point
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

  LatLng _getInitialCenter() {
    if (_projectPoints.isNotEmpty) {
      return LatLng(
        _projectPoints.first.latitude,
        _projectPoints.first.longitude,
      );
    }
    
    // Fallback to current position if available
    if (_currentPosition != null) {
      return LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }
    
    // Final fallback to default center
    return _defaultCenter;
  }

  double _getInitialZoom() {
    if (_projectPoints.isNotEmpty) {
      if (_projectPoints.length == 1) {
        return 15.0; // Closer zoom for single point
      } else {
        return 14.0; // Medium zoom for multiple points
      }
    }
    
    // If no points but have current position, use medium zoom
    if (_currentPosition != null) {
      return 12.0;
    }
    
    // Default zoom for no data
    return _defaultZoom;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPoints) {
      return Stack(
        children: [
          // Background with subtle pattern
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
          // Loading content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated loading icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                // Loading text
                Text(
                  S.of(context)?.mapLoadingPointsIndicator ?? "Loading points...",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please wait while we load your project data",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // Status indicator
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

    // Prepare data for the map
    _updateSelectedPointInstance(); // Helper to encapsulate selected point logic
    final List<Marker> allMapMarkers = _buildAllMapMarkers();
    final List<LatLng> polylinePathPoints = _buildPolylinePathPoints();
    _updateHeadingLine(); // Helper to encapsulate heading line creation logic

    // Defensive: Ensure initial center/zoom are valid
    LatLng initialMapCenter = _defaultCenter;
    double initialMapZoom = _defaultZoom;

    if (_projectPoints.isNotEmpty) {
      initialMapCenter = _getInitialCenter();
      initialMapZoom = _getInitialZoom();
    } else if (_currentPosition != null && _hasLocationPermission) {
      initialMapCenter = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      initialMapZoom = _defaultZoom;
    }

    // Check for NaN or infinite values
    if (initialMapCenter.latitude.isNaN ||
        initialMapCenter.longitude.isNaN ||
        initialMapZoom.isNaN ||
        initialMapZoom.isInfinite) {
      return Stack(
        children: [
          Center(
            child: Text('Waiting for valid map data...'),
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

    return Stack(
      children: [
        Scaffold(
          body: Stack(
            children: [
              _buildFlutterMapWidget(allMapMarkers, polylinePathPoints,
                  initialMapCenter: initialMapCenter, initialMapZoom: initialMapZoom),
              _buildPermissionOverlay(),
              _buildPointDetailsPanel(),
              // Floating action buttons positioned on the left
              Positioned(
                bottom: 24,
                left: 24,
                child: _buildFloatingActionButtons(),
              ),
              _buildMapTypeSelector(),
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

  // Helper to update _selectedPointInstance
  void _updateSelectedPointInstance() {
    _selectedPointInstance = null; // Reset before trying
    if (_selectedPointId != null && _projectPoints.isNotEmpty) {
      try {
        _selectedPointInstance = _projectPoints.firstWhere(
          (p) => p.id == _selectedPointId,
        );
      } catch (e) {
        logger.warning(
          "Selected point ID $_selectedPointId not found in project points. Deselecting.",
        );
        // Using Future.microtask to avoid calling setState during build
        Future.microtask(() {
          if (mounted) {
            setState(() {
              _selectedPointId = null;
              _selectedPointInstance = null; // Ensure it's null in state too
            });
          }
        });
      }
    }
  }

  // Helper to build the list of all markers for the map
  List<Marker> _buildAllMapMarkers() {
    List<Marker> projectPointMarkers = _projectPoints.map((point) {
      final bool isSelected = point.id == _selectedPointId;
      return Marker(
        width: 70, // Increased from 60 to accommodate larger selected markers
        height: 70, // Increased from 58 to accommodate larger selected markers
        point: LatLng(point.latitude, point.longitude),
        child: _buildStandardMarkerView(context, point, isSelected: isSelected),
      );
    }).toList();

    List<Marker> allMarkers = [...projectPointMarkers];

    // Add heading label marker
    if (_headingFromFirstToLast != null && _projectPoints.length >= 2) {
      allMarkers.add(_buildHeadingLabelMarker());
    }

    // Add current position crosshair marker
    if (_currentPosition != null && _hasLocationPermission) {
      allMarkers.add(_buildCurrentPositionMarker());
    }

    return allMarkers;
  }

  // Helper specifically for the heading label marker
  Marker _buildHeadingLabelMarker() {
    if (_projectPoints.length < 2) {
      throw StateError('Cannot build heading label marker with less than 2 points');
    }
    
    final firstP = _projectPoints.first;
    final lastP = _projectPoints.last;
    final midLat = (firstP.latitude + lastP.latitude) / 2;
    final midLon = (firstP.longitude + lastP.longitude) / 2;
    final angleForRotation = _degreesToRadians(_headingFromFirstToLast!);

    return Marker(
      point: LatLng(midLat, midLon),
      width: 120,
      height: 30,
      child: Transform.rotate(
        angle: angleForRotation - (math.pi / 2), // Use math.pi instead of hardcoded value
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
              'Heading: ${_headingFromFirstToLast!.toStringAsFixed(1)}°',
              style: const TextStyle(color: Colors.black, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  // Helper specifically for the current position marker (crosshair)
  Marker _buildCurrentPositionMarker() {
    if (_currentPosition == null) {
      throw StateError('Cannot build current position marker with null position');
    }
    
    return Marker(
      width: 30,
      height: 30,
      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      child: _buildCrosshairMarker(),
    );
  }

  // Helper to prepare points for the main polyline connecting project points
  List<LatLng> _buildPolylinePathPoints() {
    if (!_isLoadingPoints && _projectPoints.length >= 2) {
      return _projectPoints
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
    }
    return []; // Return empty list if conditions not met
  }

  // Helper to update/create the _headingLine Polyline
  void _updateHeadingLine() {
    if (_headingFromFirstToLast != null && _projectPoints.length >= 2) {
      _headingLine = Polyline(
        points: [
          LatLng(_projectPoints.first.latitude, _projectPoints.first.longitude),
          LatLng(_projectPoints.last.latitude, _projectPoints.last.longitude),
        ],
        color: Colors.purple.withAlpha((0.7 * 255).round()),
        strokeWidth: 3.0,
        pattern: StrokePattern.dotted(),
      );
    } else {
      _headingLine = null; // Ensure it's null if conditions aren't met
    }
  }

  // Helper to build the core FlutterMap widget
  Widget _buildFlutterMapWidget(
    List<Marker> allMapMarkers,
    List<LatLng> polylinePathPoints, {
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
                  // Exit move mode if selected point is lost
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
            // If not in move mode, tapping the map deselects any selected point
            if (_selectedPointId != null) {
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
            // Ensure widget is still mounted
            setState(() {
              _isMapReady = true;
            });
            // Now that map is ready, try to fit points (they might have loaded already)
            _fitMapToPoints();
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: _getTileLayerUrl(),
          userAgentPackageName:
              'com.jlbbooks.teleferika', // Recommended for OSM tile usage policy
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              _getTileLayerAttribution(),
              onTap: () {
                final url = _getAttributionUrl();
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
                gradientColors: [
                  Colors.green,
                  Colors.yellow,
                  Colors.red,
                ],
                colorsStop: [
                  0.0, // Start with green
                  0.5, // Transition to yellow by the midpoint
                  1.0, // End with red
                ],
                strokeWidth: 3.0,
              ),
            ],
          ),
        if (_headingLine != null)
          PolylineLayer(
            polylines: [_headingLine!],
          ),
        if (_projectHeadingLine != null)
          PolylineLayer(polylines: [_projectHeadingLine!]),
        MarkerLayer(markers: allMapMarkers),
      ],
    );
  }

  void _recalculateHeadingLine() {
    if (_projectPoints.length >= 2) {
      _headingFromFirstToLast = calculateBearing(
        LatLng(_projectPoints.first.latitude, _projectPoints.first.longitude),
        LatLng(_projectPoints.last.latitude, _projectPoints.last.longitude),
      );
    } else {
      _headingFromFirstToLast = null;
    }
  }

  void _recalculateProjectHeadingLine() {
    if (_projectPoints.isEmpty || widget.project.azimuth == null) {
      if (mounted) {
        setState(() => _projectHeadingLine = null);
      }
      return;
    }

    try {
      final firstPoint = LatLng(
        _projectPoints.first.latitude,
        _projectPoints.first.longitude,
      );
      final projectHeading = widget.project.azimuth!;

      // Define a length for the heading line (e.g., 1 km, adjust as needed)
      // You might want to make this dynamic based on zoom level or map bounds later
      const lineLengthKm = 1.0; // Example length: 1 kilometer

      final endPoint = _calculateDestinationPoint(
        firstPoint,
        projectHeading,
        lineLengthKm,
      );

      if (mounted) {
        setState(() {
          _projectHeadingLine = Polyline(
            points: [firstPoint, endPoint],
            strokeWidth: 2.0,
            color: Colors.black, // Choose a distinct color
            pattern: StrokePattern.dotted(),
          );
        });
      }
    } catch (e) {
      logger.warning('Error calculating project heading line: $e');
      if (mounted) {
        setState(() => _projectHeadingLine = null);
      }
    }
  }

  // --- UI Components ---
  Widget _buildStandardMarkerView(
    BuildContext context,
    PointModel point, {
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedPointId == point.id) {
            _selectedPointId = null;
          } else {
            _selectedPointId = point.id;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space
          children: [
            // Main pin icon
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.location_pin,
                color: _getMarkerColor(isSelected),
                size: isSelected ? 32.0 : 28.0, // Slightly reduced sizes
              ),
            ),
            const SizedBox(height: 2), // Reduced spacing
            // Point label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Reduced padding
              decoration: BoxDecoration(
                color: _getLabelBackgroundColor(isSelected),
                borderRadius: BorderRadius.circular(4), // Reduced radius
                border: _getLabelBorder(isSelected),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                "P${point.ordinalNumber}",
                style: TextStyle(
                  fontSize: 10, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color: _getLabelTextColor(isSelected),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMarkerColor(bool isSelected) {
    if (isSelected && !_isMovePointMode) {
      return Colors.blue.shade600;
    } else if (_isMovePointMode && _selectedPointId == _selectedPointInstance?.id) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade600;
    }
  }

  Color _getLabelBackgroundColor(bool isSelected) {
    if (isSelected && !_isMovePointMode) {
      return Colors.blue.shade600;
    } else {
      return Colors.white;
    }
  }

  Border? _getLabelBorder(bool isSelected) {
    if (isSelected && !_isMovePointMode) {
      return Border.all(color: Colors.blue.shade600, width: 1.5);
    } else if (_isMovePointMode && _selectedPointId == _selectedPointInstance?.id) {
      return Border.all(color: Colors.orange.shade600, width: 1.5);
    }
    return null;
  }

  Color _getLabelTextColor(bool isSelected) {
    if (isSelected && !_isMovePointMode) {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }

  Widget _buildCrosshairMarker() {
    if (_currentPosition == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.shade600.withOpacity(0.1),
          border: Border.all(
            color: Colors.blue.shade600,
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.gps_fixed,
          color: Colors.blue,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPermissionOverlay() {
    if (_hasLocationPermission && _hasSensorPermission) {
      return const SizedBox.shrink();
    }

    final s = S.of(context);
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            child: Card(
              elevation: 16,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      s?.mapPermissionsRequiredTitle ?? "Permissions Required",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Permission details
                    if (!_hasLocationPermission) ...[
                      _buildPermissionItem(
                        icon: Icons.location_on_outlined,
                        title: 'Location Permission',
                        description: s?.mapLocationPermissionInfoText ??
                            "Location permission is needed to show your current position and for some map features.",
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!_hasSensorPermission) ...[
                      _buildPermissionItem(
                        icon: Icons.compass_calibration_outlined,
                        title: 'Sensor Permission',
                        description: s?.mapSensorPermissionInfoText ??
                            "Sensor (compass) permission is needed for direction-based features.",
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.settings),
                            label: Text(
                              s?.mapButtonOpenAppSettings ?? "Open App Settings",
                            ),
                            onPressed: () async {
                              openAppSettings();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _checkAndRequestPermissions,
                          child: Text(
                            s?.mapButtonRetryPermissions ?? "Retry Permissions",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointDetailsPanel() {
    if (_selectedPointInstance == null) return const SizedBox.shrink();

    // Determine if the panel should appear at the bottom
    final bool shouldShowAtBottom = _shouldShowPanelAtBottom();

    return Positioned(
      top: shouldShowAtBottom ? null : 16,
      bottom: shouldShowAtBottom ? 16 : null,
      right: 16,
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(12.0),
        shadowColor: Colors.black26,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with point number and close button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'P${_selectedPointInstance!.ordinalNumber}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedPointId = null;
                        _selectedPointInstance = null;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Coordinates
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedPointInstance!.latitude.toStringAsFixed(6)}, ${_selectedPointInstance!.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Note section
              if (_selectedPointInstance!.note?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedPointInstance!.note!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Move mode indicator
              if (_isMovePointMode && _selectedPointInstance!.id == _selectedPointId) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap on the map to set new location',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Action buttons
              _buildPointActionButtons(),
              
              // Loading indicator
              if (_isMovingPointLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: Center(child: LinearProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowPanelAtBottom() {
    if (_selectedPointInstance == null || !_isMapReady) return false;
    
    try {
      // Get the current map bounds
      final bounds = _mapController.camera.visibleBounds;
      if (bounds == null) return false;
      
      // Get the selected point's position
      final pointLatLng = LatLng(
        _selectedPointInstance!.latitude,
        _selectedPointInstance!.longitude,
      );
      
      // Calculate the midpoint of the visible map
      final mapMidpoint = (bounds.northEast.latitude + bounds.southWest.latitude) / 2;
      
      // If the point is in the upper half of the map, show panel at bottom
      return pointLatLng.latitude > mapMidpoint;
    } catch (e) {
      // Fallback to showing at top if there's any error
      logger.warning('Error determining panel position: $e');
      return false;
    }
  }

  Widget _buildPointActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: Colors.blue,
            onPressed: _isMovePointMode ? null : _handleEditPoint,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: _isMovePointMode && _selectedPointInstance!.id == _selectedPointId
                ? Icons.cancel_outlined
                : Icons.open_with,
            label: _isMovePointMode && _selectedPointInstance!.id == _selectedPointId
                ? 'Cancel'
                : 'Move',
            color: _isMovePointMode && _selectedPointInstance!.id == _selectedPointId
                ? Colors.orange
                : Colors.teal,
            onPressed: _isMovingPointLoading ? null : _handleMovePointAction,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: Colors.red,
            onPressed: (_isMovePointMode || _isMovingPointLoading)
                ? null
                : _handleDeletePoint,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: onPressed != null 
                ? color.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: onPressed != null 
                  ? color.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: onPressed != null ? color : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: onPressed != null ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    final bool isLocationLoading =
        _hasLocationPermission && _currentPosition == null;
    final s = S.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Center on current location button
          _buildFloatingActionButton(
            heroTag: 'center_on_location',
            icon: Icons.my_location,
            tooltip: isLocationLoading
                ? (s?.mapAcquiringLocation ?? 'Acquiring location...')
                : (s?.mapCenterOnLocation ?? 'Center on my location'),
            onPressed: isLocationLoading ? null : _centerOnCurrentLocation,
            isLoading: isLocationLoading,
            color: Colors.blue,
          ),
          
          // Add new point button
          _buildFloatingActionButton(
            heroTag: 'add_new_point',
            icon: Icons.add_location_alt_outlined,
            tooltip: isLocationLoading
                ? (s?.mapAcquiringLocation ?? 'Acquiring location...')
                : (s?.mapAddNewPoint ?? 'Add New Point'),
            onPressed: isLocationLoading ? null : _handleAddPointButtonPressed,
            isLoading: isLocationLoading,
            color: Colors.green,
          ),
          
          // Center on Project points button
          _buildFloatingActionButton(
            heroTag: 'center_on_points',
            icon: Icons.center_focus_strong,
            tooltip: s?.mapCenterOnPoints ?? 'Center on points',
            onPressed: _fitMapToPoints,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required String heroTag,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        mini: true,
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, size: 20),
      ),
    );
  }

  // --- Action Handlers ---
  Future<void> _handleEditPoint() async {
    if (_selectedPointInstance == null) return;

    logger.info(
      "Navigating to edit point P${_selectedPointInstance!.ordinalNumber}",
    );

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PointDetailsPage(point: _selectedPointInstance!),
      ),
    );

    if (result != null) {
      final String? action = result['action'] as String?;
      logger.info("Returned from PointDetailsPage with action: $action");

      if (action == 'updated') {
        final PointModel? updatedPoint = result['point'] as PointModel?;
        if (updatedPoint != null) {
          setState(() {
            final index = _projectPoints.indexWhere(
              (p) => p.id == updatedPoint.id,
            );
            if (index != -1) {
              _projectPoints[index] = updatedPoint;
              logger.info(
                "Point P${updatedPoint.ordinalNumber} updated in MapToolView.",
              );
            }
          });
          showSuccessStatus('Point P${updatedPoint.ordinalNumber} details updated!');
          widget.onPointsChanged?.call();
        }
      } else if (action == 'deleted') {
        final String? deletedPointId = result['pointId'] as String?;
        if (deletedPointId != null) {
          setState(() {
            _projectPoints.removeWhere((p) => p.id == deletedPointId);
            logger.info("Point ID $deletedPointId removed from MapToolView.");
            if (_selectedPointId == deletedPointId) {
              _selectedPointId = null;
            }
          });
          showSuccessStatus('Point deleted.');
          widget.onPointsChanged?.call();
        }
      }
    } else {
      logger.info(
        "PointDetailsPage popped without a result (e.g., back button pressed).",
      );
    }
  }

  void _handleMovePointAction() {
    if (_isMovePointMode && _selectedPointInstance?.id == _selectedPointId) {
      // Cancel move mode
      setState(() {
        _isMovePointMode = false;
      });
    } else if (!_isMovePointMode) {
      // Activate move mode for this point
      setState(() {
        _isMovePointMode = true;
      });
      showInfoStatus('Move mode activated. Tap map to relocate point.');
    }
  }

  Future<void> _handleDeletePoint() async {
    if (_selectedPointInstance == null) {
      showErrorStatus('No point selected to delete.');
      return;
    }
    
    logger.info(
      "Delete tapped for point P${_selectedPointInstance!.ordinalNumber}",
    );
    await _handleDeletePointFromPanel(_selectedPointInstance!);
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition == null) {
      showInfoStatus('Current location not available. Please wait for GPS signal.');
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

  void _handleAddPointButtonPressed() {
    if (widget.onNavigateToCompassTab != null) {
      widget.onNavigateToCompassTab!();
      showInfoStatus('Navigating to compass tab to add new point.');
    } else {
      showInfoStatus('Add point functionality not available. Please use compass tab.');
    }
  }

  // Method to handle deletion triggered from the side panel
  Future<void> _handleDeletePointFromPanel(PointModel pointToDelete) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final s = S.of(context);
        return AlertDialog(
          title: Text(s?.mapDeletePointDialogTitle ?? 'Confirm Deletion'),
          content: Text(
            s?.mapDeletePointDialogContent(
                  pointToDelete.ordinalNumber.toString(),
                ) ??
                'Are you sure you want to delete point P${pointToDelete.ordinalNumber}?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(s?.mapDeletePointDialogCancelButton ?? 'Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                s?.mapDeletePointDialogDeleteButton ?? 'Delete',
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final int count = await _dbHelper.deletePointById(pointToDelete.id);

        if (!mounted) return;

        if (count > 0) {
          setState(() {
            _projectPoints.removeWhere((p) => p.id == pointToDelete.id);
            logger.info(
              "Point P${pointToDelete.ordinalNumber} (ID: ${pointToDelete.id}) removed from MapToolView after panel delete.",
            );
            if (_selectedPointId == pointToDelete.id) {
              _selectedPointId = null;
            }
            _recalculateHeadingLine();
          });

          showSuccessStatus(
            'Point P${pointToDelete.ordinalNumber} deleted.',
          );
          widget.onPointsChanged?.call();
        } else {
          showErrorStatus(
            'Error: Point P${pointToDelete.ordinalNumber} could not be found or deleted from map view.',
          );
        }
      } catch (e) {
        if (!mounted) return;
        logger.severe(
          'Failed to delete point P${pointToDelete.ordinalNumber} from panel: $e',
        );

        showErrorStatus(
          'Error deleting point P${pointToDelete.ordinalNumber}: $e',
        );
      }
    }
  }

  // --- Map Type Methods ---
  String _getTileLayerUrl() {
    switch (_currentMapType) {
      case MapType.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapType.terrain:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';
    }
  }

  String _getTileLayerAttribution() {
    switch (_currentMapType) {
      case MapType.openStreetMap:
        return '© OpenStreetMap contributors';
      case MapType.satellite:
        return '© Esri — Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community';
      case MapType.terrain:
        return '© Esri — Source: Esri, DeLorme, NAVTEQ, USGS, Intermap, iPC, NRCAN, Esri Japan, METI, Esri China (Hong Kong), Esri (Thailand), TomTom, 2012';
    }
  }

  String _getAttributionUrl() {
    switch (_currentMapType) {
      case MapType.openStreetMap:
        return 'https://openstreetmap.org/copyright';
      case MapType.satellite:
      case MapType.terrain:
        return 'https://www.esri.com/en-us/home';
    }
  }

  String _getMapTypeDisplayName() {
    final s = S.of(context);
    switch (_currentMapType) {
      case MapType.openStreetMap:
        return s?.mapTypeStreet ?? 'Street';
      case MapType.satellite:
        return s?.mapTypeSatellite ?? 'Satellite';
      case MapType.terrain:
        return s?.mapTypeTerrain ?? 'Terrain';
    }
  }

  Widget _buildMapTypeSelector() {
    final s = S.of(context);
    return Positioned(
      top: 16,
      left: 16,
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(12.0),
        shadowColor: Colors.black26,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: PopupMenuButton<MapType>(
            onSelected: (MapType mapType) {
              setState(() {
                _currentMapType = mapType;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getMapTypeIcon(),
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getMapTypeDisplayName(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            itemBuilder: (BuildContext context) => [
              _buildMapTypeMenuItem(
                MapType.openStreetMap,
                s?.mapTypeStreet ?? 'Street',
                Icons.map,
              ),
              _buildMapTypeMenuItem(
                MapType.satellite,
                s?.mapTypeSatellite ?? 'Satellite',
                Icons.satellite_alt,
              ),
              _buildMapTypeMenuItem(
                MapType.terrain,
                s?.mapTypeTerrain ?? 'Terrain',
                Icons.terrain,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<MapType> _buildMapTypeMenuItem(
    MapType mapType,
    String label,
    IconData icon,
  ) {
    final isSelected = _currentMapType == mapType;
    return PopupMenuItem<MapType>(
      value: mapType,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getMapTypeIcon() {
    switch (_currentMapType) {
      case MapType.openStreetMap:
        return Icons.map;
      case MapType.satellite:
        return Icons.satellite_alt;
      case MapType.terrain:
        return Icons.terrain;
    }
  }
}
