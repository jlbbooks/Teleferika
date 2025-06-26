// map_tool_view.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logger.dart';
import '../point_details_page.dart';

class MapToolView extends StatefulWidget {
  final ProjectModel project;
  final String? selectedPointId; // From project_page
  final VoidCallback? onNavigateToCompassTab;
  final Function(BuildContext, double, {bool? setAsEndPoint})?
  onAddPointFromCompass;

  const MapToolView({
    super.key,
    required this.project,
    this.selectedPointId,
    this.onNavigateToCompassTab,
    this.onAddPointFromCompass,
  });

  @override
  State<MapToolView> createState() => MapToolViewState();
}

class MapToolViewState extends State<MapToolView> {
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

  @override
  void initState() {
    super.initState();
    _loadProjectPoints();
    _checkAndRequestPermissions();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    s?.mapErrorGettingLocationUpdates(error.toString()) ??
                        'Error getting location updates: $error',
                  ),
                ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s?.mapErrorGettingCompassUpdates(error.toString()) ??
                    'Error getting compass updates: $error',
              ),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s?.mapErrorLoadingPoints(e.toString()) ??
                  "Error loading points for map: $e",
            ),
          ),
        );
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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                S
                        .of(context)
                        ?.mapPointMovedSuccessfully(
                          updatedPoint.ordinalNumber.toString(),
                        ) ??
                    'Point P${updatedPoint.ordinalNumber} moved successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                S
                        .of(context)
                        ?.mapErrorMovingPoint(
                          pointToMove.ordinalNumber.toString(),
                        ) ??
                    'Error: Could not move point P${pointToMove.ordinalNumber}. Point not found or not updated.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        // TODO: Optional: Revert optimistic UI update if you did one
      }
    } catch (e) {
      logger.severe('Failed to move point P${pointToMove.ordinalNumber}: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              S
                      .of(context)
                      ?.mapErrorMovingPointGeneric(
                        pointToMove.ordinalNumber.toString(),
                        e.toString(),
                      ) ??
                  'Error moving point P${pointToMove.ordinalNumber}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      // Optional: Revert optimistic UI update
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
    if (_projectPoints.isEmpty || !mounted) {
      // Optionally move to a default location or the project's starting point if available
      // For now, if no points, map stays at its initial or default view
      _mapController.move(_getInitialCenter(), _getInitialZoom());
      return;
    }

    if (_projectPoints.length == 1) {
      _mapController.move(
        LatLng(_projectPoints.first.latitude, _projectPoints.first.longitude),
        15.0, // Zoom in on a single point
      );
      return;
    }

    // Calculate bounds for multiple points
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
  }

  LatLng _getInitialCenter() {
    if (_projectPoints.isNotEmpty) {
      return LatLng(
        _projectPoints.first.latitude,
        _projectPoints.first.longitude,
      );
    }
    // You could also try to get a starting point from widget.project if available
    return _defaultCenter;
  }

  double _getInitialZoom() {
    return _projectPoints.isNotEmpty ? 14.0 : _defaultZoom;
  }

  @override
  void didUpdateWidget(covariant MapToolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.project.id != oldWidget.project.id) {
      _loadProjectPoints(); // This will also recalculate lines
    } else if (widget.project.azimuth != oldWidget.project.azimuth) {
      // If only the heading changed, just recalculate lines
      _recalculateAndDrawLines();
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
      child: Column(
        children: [
          Icon(
            Icons.location_pin,
            color: isSelected && !_isMovePointMode
                ? Colors.blueAccent
                : (_isMovePointMode && _selectedPointId == point.id
                      ? Colors.orangeAccent
                      : Colors.red),
            size: 30.0,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected && !_isMovePointMode
                  ? Colors.blue.withAlpha((0.8 * 255).round())
                  : Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(3),
              border: isSelected && !_isMovePointMode
                  ? Border.all(color: Colors.blueAccent, width: 1.5)
                  : null,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              "P${point.ordinalNumber}",
              style: TextStyle(
                fontSize: 10,
                color: isSelected && !_isMovePointMode
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrosshairMarker() {
    if (_currentPosition == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: Icon(
        Icons.gps_fixed,
        color: Colors.blueAccent.withOpacity(0.8),
        size: 24,
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
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s?.mapPermissionsRequiredTitle ?? "Permissions Required",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (!_hasLocationPermission)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        s?.mapLocationPermissionInfoText ??
                            "Location permission is needed to show your current position and for some map features.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  if (!_hasSensorPermission)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        s?.mapSensorPermissionInfoText ??
                            "Sensor (compass) permission is needed for direction-based features.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings),
                    label: Text(
                      s?.mapButtonOpenAppSettings ?? "Open App Settings",
                    ),
                    onPressed: () async {
                      openAppSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _checkAndRequestPermissions,
                    child: Text(
                      s?.mapButtonRetryPermissions ?? "Retry Permissions",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointDetailsPanel() {
    if (_selectedPointInstance == null) return const SizedBox.shrink();

    return Positioned(
      top: 10,
      right: 10,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected: P${_selectedPointInstance!.ordinalNumber}',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedPointInstance!.note?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: Text(
                        _selectedPointInstance!.note!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'Lat: ${_selectedPointInstance!.latitude.toStringAsFixed(6)}, Lon: ${_selectedPointInstance!.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.start,
                  ),
                ),
                if (_isMovePointMode &&
                    _selectedPointInstance!.id == _selectedPointId)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Tap on the map to set new location.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Divider(height: 16),
                _buildPointActionButtons(),
                if (_isMovingPointLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Center(child: LinearProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.edit, color: Colors.blue),
          label: const Text('Edit'),
          onPressed: _isMovePointMode ? null : _handleEditPoint,
        ),
        TextButton.icon(
          icon: Icon(
            _isMovePointMode && _selectedPointInstance!.id == _selectedPointId
                ? Icons.cancel_outlined
                : Icons.open_with,
            color:
                _isMovePointMode &&
                    _selectedPointInstance!.id == _selectedPointId
                ? Colors.orangeAccent
                : Colors.teal,
          ),
          label: Text(
            _isMovePointMode && _selectedPointInstance!.id == _selectedPointId
                ? 'Cancel'
                : 'Move',
          ),
          onPressed: _isMovingPointLoading ? null : _handleMovePointAction,
        ),
        TextButton.icon(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          label: const Text('Delete'),
          onPressed: (_isMovePointMode || _isMovingPointLoading)
              ? null
              : _handleDeletePoint,
        ),
      ],
    );
  }

  Widget _buildFloatingActionButtons() {
    final bool isLocationLoading = _hasLocationPermission && _currentPosition == null;
    final s = S.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Center on current location button
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: FloatingActionButton(
            heroTag: 'center_on_location',
            onPressed: isLocationLoading ? null : _centerOnCurrentLocation,
            tooltip: isLocationLoading 
                ? (s?.mapAcquiringLocation ?? 'Acquiring location...')
                : (s?.mapCenterOnLocation ?? 'Center on my location'),
            child: isLocationLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.my_location),
          ),
        ),
        // Add new point button
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: FloatingActionButton(
            heroTag: 'add_new_point',
            onPressed: isLocationLoading ? null : _handleAddPointButtonPressed,
            tooltip: isLocationLoading 
                ? (s?.mapAcquiringLocation ?? 'Acquiring location...')
                : (s?.mapAddNewPoint ?? 'Add New Point'),
            child: isLocationLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.add_location_alt_outlined),
          ),
        ),
        // Center on Project points button
        FloatingActionButton(
          heroTag: 'center_on_points',
          onPressed: _fitMapToPoints,
          tooltip: s?.mapCenterOnPoints ?? 'Center on points',
          child: const Icon(Icons.center_focus_strong),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPoints) {
      return Center(
        child: CircularProgressIndicator(
          key: ValueKey(
            S.of(context)?.mapLoadingPointsIndicator ?? "Loading points...",
          ),
        ),
      );
    }

    // Prepare data for the map
    _updateSelectedPointInstance(); // Helper to encapsulate selected point logic
    final List<Marker> allMapMarkers = _buildAllMapMarkers();
    final List<LatLng> polylinePathPoints = _buildPolylinePathPoints();
    _updateHeadingLine(); // Helper to encapsulate heading line creation logic

    return Scaffold(
      body: Stack(
        children: [
          _buildFlutterMapWidget(allMapMarkers, polylinePathPoints),
          _buildPermissionOverlay(),
          _buildPointDetailsPanel(),
          // Floating action buttons positioned on the left
          Positioned(
            bottom: 24,
            left: 24,
            child: _buildFloatingActionButtons(),
          ),
        ],
      ),
    );
  }

  // Helper to update _selectedPointInstance
  void _updateSelectedPointInstance() {
    _selectedPointInstance = null; // Reset before trying
    if (_selectedPointId != null) {
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
        width: 60,
        height: 58,
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
        angle: angleForRotation - (3.1415926535 / 2), // math.pi / 2
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
    return Marker(
      width: 30,
      height: 30,
      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      child:
          _buildCrosshairMarker(), // Assuming _buildCrosshairMarker() returns the crosshair Icon/Widget
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
    List<LatLng> polylinePathPoints,
  ) {
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
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Error: Selected point not found. Please select again.",
                      ),
                    ),
                  );
                setState(() {
                  // Exit move mode if selected point is lost
                  _isMovePointMode = false;
                  _selectedPointId = null;
                  _selectedPointInstance = null;
                });
              }
            } else {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      "No point selected to move. Tap a point first, then activate 'Move Point' mode.",
                    ),
                  ),
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
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.jlbbooks.teleferika', // Recommended for OSM tile usage policy
          // Add any other TileLayer options you had, like tms, additionalOptions etc.
        ),
        RichAttributionWidget(
          // Include a stylish prebuilt attribution widget that meets all requirments
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () => launchUrl(
                Uri.parse('https://openstreetmap.org/copyright'),
              ), // (external)
            ),
            // Also add images...
          ],
        ),
        if (polylinePathPoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePathPoints,
                // color: Colors.black.withAlpha(
                //   150,
                // ), // Your original color and stroke
                gradientColors: [
                  // TODO: Example: From green to red
                  Colors.green,
                  Colors.yellow,
                  Colors.red,
                ],
                colorsStop: [
                  // Defines where each color transition happens
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
          ), // _headingLine is already a Polyline
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
      if (mounted) setState(() => _projectHeadingLine = null);
      return;
    }

    final firstPoint = LatLng(
      _projectPoints.first.latitude,
      _projectPoints.first.longitude,
    );
    final projectHeading = widget.project.azimuth!;

    // Define a length for the heading line (e.g., 1 km, adjust as needed)
    // You might want to make this dynamic based on zoom level or map bounds later
    const lineLengthKm = 1.0; // Example length: 500 meters

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

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Point P${updatedPoint.ordinalNumber} details updated!',
                ),
                backgroundColor: Colors.green,
              ),
            );
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

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Point deleted.'),
                backgroundColor: Colors.orange,
              ),
            );
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Move mode activated. Tap map to relocate point.'),
            backgroundColor: Colors.blueGrey,
          ),
        );
    }
  }

  Future<void> _handleDeletePoint() async {
    logger.info(
      "Delete tapped for point P${_selectedPointInstance!.ordinalNumber}",
    );
    await _handleDeletePointFromPanel(_selectedPointInstance!);
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  void _handleAddPointButtonPressed() {
    // For now, just show a message that this would navigate to compass tab
    // In the future, this could add a point directly from the map
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add point functionality would navigate to compass tab'),
        backgroundColor: Colors.blue,
      ),
    );
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
              _selectedPointInstance = null;
            }
            _recalculateHeadingLine();
          });

          final s = S.of(context);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  s?.mapPointDeletedSuccessSnackbar(
                        pointToDelete.ordinalNumber.toString(),
                      ) ??
                      'Point P${pointToDelete.ordinalNumber} deleted.',
                ),
                backgroundColor: Colors.green,
              ),
            );
        } else {
          final s = S.of(context);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  s?.mapErrorPointNotFoundOrDeletedSnackbar(
                        pointToDelete.ordinalNumber.toString(),
                      ) ??
                      'Error: Point P${pointToDelete.ordinalNumber} could not be found or deleted from map view.',
                ),
                backgroundColor: Colors.red,
              ),
            );
        }
      } catch (e) {
        if (!mounted) return;
        logger.severe(
          'Failed to delete point P${pointToDelete.ordinalNumber} from panel: $e',
        );

        final s = S.of(context);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                s?.mapErrorDeletingPointSnackbar(
                      pointToDelete.ordinalNumber.toString(),
                      e.toString(),
                    ) ??
                    'Error deleting point P${pointToDelete.ordinalNumber}: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
      }
    }
  }
}
