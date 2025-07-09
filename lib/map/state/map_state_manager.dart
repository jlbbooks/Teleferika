import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/map/map_controller.dart';
import 'package:teleferika/map/map_type.dart';
import 'package:teleferika/map/services/map_preferences_service.dart';
import 'package:teleferika/map/services/map_cache_logger.dart';
import 'package:teleferika/ui/widgets/permission_handler_widget.dart';
import 'package:teleferika/core/app_config.dart';

class MapStateManager extends ChangeNotifier {
  final Logger logger = Logger('MapStateManager');

  // Controller for business logic
  late MapControllerLogic _controller;

  // UI State
  final MapController mapController = MapController();
  bool isLoadingPoints = true;
  bool isMapReady = false;
  String? selectedPointId;
  bool isMovePointMode = false;
  bool isMovingPointLoading = false;
  PointModel? newPoint; // The unsaved new point
  // Slide functionality state
  bool isSlidingMarker = false;
  String? slidingPointId;
  LatLng? originalPosition;
  LatLng? currentSlidePosition;
  bool isAddingNewPoint =
      false; // Whether we're in the process of adding a new point
  bool skipNextFitToPoints =
      false; // Flag to skip automatic fitting after saving new point
  bool isExternalRefresh =
      false; // Flag to prevent callback loops during external refresh

  // Data from global state and sensors
  Position? currentPosition;
  double? currentDeviceHeading;
  double? currentCompassAccuracy;
  bool? shouldCalibrateCompass;
  bool hasLocationPermission = false;
  double? connectingLineFromFirstToLast;
  Polyline? projectHeadingLine;
  MapType _currentMapType = MapType.all.first;
  double glowAnimationValue = 0.0;
  double mapCacheSize = 0.0;

  /// Get the current map type
  MapType get currentMapType => _currentMapType;

  /// Set the current map type and save to preferences
  set currentMapType(MapType value) {
    if (_currentMapType.id != value.id) {
      _currentMapType = value;
      // Save to SharedPreferences
      MapPreferencesService.saveMapType(value);
      // Log cache performance for the new map type
      MapCacheLogger.logCachePerformance(value);
      notifyListeners();
    }
  }

  // Location stream for CurrentLocationLayer
  final StreamController<LocationMarkerPosition> locationStreamController =
      StreamController<LocationMarkerPosition>.broadcast();

  bool didInitialLoad = false;

  // Debug panel state
  bool hasClosedDebugPanel = true;

  // Track if we've already shown the calibrate compass notice this session
  bool hasShownCalibrateCompassNotice = false;

  // For testing: force show calibration panel
  bool forceShowCalibrationPanel = false;

  AnimationController? arrowheadController;
  Animation<double>? arrowheadAnimation;

  // Timer for glow animation
  Timer? _glowAnimationTimer;

  // Track if already initialized to prevent multiple initializations
  bool _isInitialized = false;

  /// Load the saved map type from SharedPreferences
  Future<void> _loadSavedMapType() async {
    try {
      final savedMapType = await MapPreferencesService.loadMapType();
      if (currentMapType.id != savedMapType.id) {
        currentMapType = savedMapType;
        notifyListeners();
      }
    } catch (e) {
      logger.warning('Failed to load saved map type: $e');
      // Keep the default map type if loading fails
    }
  }

  void initialize(TickerProvider vsync, ProjectModel project) {
    // Prevent multiple initializations
    if (_isInitialized) {
      return;
    }

    _controller = MapControllerLogic(project: project);

    arrowheadController = AnimationController(
      vsync: vsync,
      duration: AppConfig.polylineArrowheadAnimationDuration,
    )..repeat();
    arrowheadAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(arrowheadController!);

    // Load saved map type preference
    _loadSavedMapType();

    // Log initial cache statistics
    MapCacheLogger.logAllCacheStats();

    _isInitialized = true;
  }

  @override
  void dispose() {
    locationStreamController.close();
    _controller.dispose();
    mapController.dispose();
    arrowheadController?.dispose();
    _glowAnimationTimer?.cancel();
    _isInitialized = false;
    super.dispose();
  }

  // Handle permission results from the PermissionHandlerWidget
  void handlePermissionResults(
    BuildContext context,
    Map<PermissionType, bool> permissions,
  ) {
    final hasLocation = permissions[PermissionType.location] ?? false;
    final hasSensor = permissions[PermissionType.sensor] ?? false;

    hasLocationPermission = hasLocation;

    if (hasLocation) {
      startListeningToLocation(context);
    }

    if (hasSensor) {
      startListeningToCompass(context);
    }
  }

  void startListeningToLocation(BuildContext context) {
    _controller.startListeningToLocation(
      (position) {
        currentPosition = position;
        notifyListeners();

        // Save the location to preferences for future use
        MapPreferencesService.saveLastLocation(
          LatLng(position.latitude, position.longitude),
        );

        // Send location data to CurrentLocationLayer
        locationStreamController.add(
          LocationMarkerPosition(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
          ),
        );
      },
      (error, [stackTrace]) {
        logger.severe("Error getting location updates: $error");
        S.of(context);
        // Status will be handled by the parent component
        currentPosition = null;
        notifyListeners();
      },
    );
  }

  void startListeningToCompass(BuildContext context) {
    _controller.startListeningToCompass(
      (heading, accuracy, shouldCalibrate) {
        final prevShouldCalibrate = shouldCalibrateCompass;
        currentDeviceHeading = heading;
        currentCompassAccuracy = accuracy;
        shouldCalibrateCompass = shouldCalibrate;
        notifyListeners();

        // Show calibrate compass notice if it just became true
        if (shouldCalibrate == true &&
            prevShouldCalibrate != true &&
            !hasShownCalibrateCompassNotice) {
          S.of(context);
          // Status will be handled by the parent component
          hasShownCalibrateCompassNotice = true;
        }

        // Update location marker with new heading if we have a current position
        if (currentPosition != null) {
          locationStreamController.add(
            LocationMarkerPosition(
              latitude: currentPosition!.latitude,
              longitude: currentPosition!.longitude,
              accuracy: currentPosition!.accuracy,
            ),
          );
        }
      },
      (error, [stackTrace]) {
        logger.severe("Error getting compass updates: $error");
        S.of(context);
        // Status will be handled by the parent component
        currentDeviceHeading = null;
        currentCompassAccuracy = null;
        shouldCalibrateCompass = null;
        notifyListeners();
      },
    );
  }

  Future<void> loadProjectPoints(BuildContext context) async {
    isLoadingPoints = true;

    try {
      isLoadingPoints = false;

      // Recalculate lines with current points
      recalculateAndDrawLines(context);

      // Fit map to points if not skipping
      if (!skipNextFitToPoints && isMapReady) {
        fitMapToPoints(context);
      }

      skipNextFitToPoints = false; // Reset the flag
    } catch (e, stackTrace) {
      logger.severe(
        "MapStateManager: Error loading points for map",
        e,
        stackTrace,
      );
      isLoadingPoints = false;
      S.of(context);
      // Status will be handled by the parent component
    }
  }

  void recalculateAndDrawLines(BuildContext context) {
    final projectState = Provider.of<ProjectStateManager>(
      context,
      listen: false,
    );
    final points = projectState.currentPoints;

    connectingLineFromFirstToLast = _controller.recalculateConnectingLine(
      points,
    );
    projectHeadingLine = _controller.recalculateProjectHeadingLine(points);
  }

  Future<void> handleMovePoint(
    BuildContext context,
    PointModel pointToMove,
    LatLng newPosition,
  ) async {
    if (isMovingPointLoading) return;

    isMovingPointLoading = true;

    try {
      // Set flag to skip automatic fitting after moving point
      skipNextFitToPoints = true;

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

      isMovePointMode = false;
      recalculateAndDrawLines(context);

      // Status will be handled by the parent component
    } catch (e) {
      logger.severe('Failed to move point ${pointToMove.name}: $e');
      S.of(context);
      // Status will be handled by the parent component
    } finally {
      isMovingPointLoading = false;
    }
  }

  void fitMapToPoints(BuildContext context) {
    if (!isMapReady) {
      logger.info("MapStateManager: Attempted to fit map, but map not ready.");
      return;
    }

    final projectState = Provider.of<ProjectStateManager>(
      context,
      listen: false,
    );
    final points = projectState.currentPoints;

    if (points.isEmpty) {
      try {
        final center = _controller.getInitialCenter(points, currentPosition);
        final zoom = _controller.getInitialZoom(points, currentPosition);
        mapController.move(center, zoom);
      } catch (e) {
        logger.warning('Error moving map to default center: $e');
      }
      return;
    }

    if (points.length == 1) {
      try {
        mapController.move(
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

      mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)),
      );
    } catch (e) {
      logger.warning('Error fitting map to points: $e');
      try {
        mapController.move(
          LatLng(points.first.latitude, points.first.longitude),
          14.0,
        );
      } catch (e2) {
        logger.warning('Error in fallback map move: $e2');
      }
    }
  }

  void centerOnCurrentLocation(BuildContext context) {
    if (currentPosition == null) {
      // Status will be handled by the parent component
      return;
    }

    try {
      mapController.move(
        LatLng(currentPosition!.latitude, currentPosition!.longitude),
        mapController.camera.zoom,
      );
      // Status will be handled by the parent component
    } catch (e) {
      logger.warning('Error centering on current location: $e');
      // Status will be handled by the parent component
    }
  }

  void handleMovePointAction(BuildContext context) {
    isMovePointMode = !isMovePointMode;
    if (isMovePointMode) {
      startGlowAnimation();
      // Status will be handled by the parent component
    } else {
      stopGlowAnimation();
    }
  }

  void startGlowAnimation() {
    _glowAnimationTimer?.cancel();
    glowAnimationValue = 0.0;

    _glowAnimationTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) {
      glowAnimationValue += 0.3; // Fast animation
      if (glowAnimationValue >= 2 * math.pi) {
        glowAnimationValue = 0.0; // Reset to start
      }

      // Calculate color interpolation between blue and purpleAccent
      // 0 to 1

      // The parent component will handle the state update
    });
  }

  void stopGlowAnimation() {
    _glowAnimationTimer?.cancel();
    _glowAnimationTimer = null;
    glowAnimationValue = 0.0;
  }

  Future<void> handleAddPointButtonPressed(BuildContext context) async {
    // Check if there's already an unsaved point
    if (newPoint != null) {
      S.of(context);
      // Status will be handled by the parent component
      return;
    }

    isAddingNewPoint = true;

    try {
      // Try to get current location with maximum accuracy
      LatLng newPointLocation;
      double? altitude;
      double? gpsPrecision;

      if (hasLocationPermission && currentPosition != null) {
        // Use current GPS location
        newPointLocation = LatLng(
          currentPosition!.latitude,
          currentPosition!.longitude,
        );
        altitude = currentPosition!.altitude;
        gpsPrecision = currentPosition!.accuracy;
      } else {
        // Use map center as fallback
        final mapCenter = mapController.camera.center;
        newPointLocation = mapCenter;
        altitude = null;
        gpsPrecision = null;
      }

      // Create new point
      final createdPoint = await _controller.createNewPoint(
        newPointLocation,
        altitude: altitude,
        gpsPrecision: gpsPrecision,
      );

      newPoint = createdPoint;
      selectedPointId = createdPoint.id;
      isAddingNewPoint = false;

      // Set global unsaved new point flag
      if (!context.mounted) return;

      final projectState = Provider.of<ProjectStateManager>(
        context,
        listen: false,
      );
      projectState.setHasUnsavedNewPoint(true);

      // Status will be handled by the parent component
    } catch (e) {
      logger.severe('Failed to create new point: $e');
      isAddingNewPoint = false;
      // Status will be handled by the parent component
    }
  }

  Future<void> handleSaveNewPoint(BuildContext context) async {
    if (newPoint == null) return;

    try {
      // Set flag to skip automatic fitting after saving new point
      skipNextFitToPoints = true;

      // Use global state to add the new point in memory (not DB)
      final projectState = Provider.of<ProjectStateManager>(
        context,
        listen: false,
      );
      // Remove isUnsaved flag from the point before adding
      final savedPoint = newPoint!.copyWith(isUnsaved: false);
      projectState.addPointInEditingState(savedPoint);

      newPoint = null;
      selectedPointId = null;

      // Clear global unsaved new point flag
      projectState.setHasUnsavedNewPoint(false);

      S.of(context);
      // Status will be handled by the parent component
    } catch (e) {
      logger.severe('Failed to save new point: $e');
      S.of(context);
      // Status will be handled by the parent component
    }
  }

  void handleDiscardNewPoint(BuildContext context) {
    newPoint = null;
    selectedPointId = null;

    // Clear global unsaved new point flag
    final projectState = Provider.of<ProjectStateManager>(
      context,
      listen: false,
    );
    projectState.setHasUnsavedNewPoint(false);

    // Status will be handled by the parent component
  }

  Future<void> handlePointUpdated(
    BuildContext context,
    PointModel updatedPoint,
  ) async {
    try {
      // Check if this is a new unsaved point
      if (updatedPoint.isUnsaved) {
        // Update the local new point instance
        newPoint = updatedPoint;
        // Status will be handled by the parent component
      } else {
        // Use global state to update the point in memory and mark as dirty
        final projectState = Provider.of<ProjectStateManager>(
          context,
          listen: false,
        );
        projectState.updatePointInEditingState(updatedPoint);

        // Recalculate lines if needed
        recalculateAndDrawLines(context);

        // Status will be handled by the parent component
      }
    } catch (e) {
      logger.severe('Failed to update point ${updatedPoint.name}: $e');
      // Status will be handled by the parent component
    }
  }

  /// Public method to refresh points from the database
  /// This can be called from the parent component when points are reordered
  Future<void> refreshPoints(BuildContext context) async {
    logger.info("MapStateManager: External refresh requested.");
    isExternalRefresh = true; // Set flag to prevent callback loops

    try {
      // Use global state to refresh points
      final projectState = Provider.of<ProjectStateManager>(
        context,
        listen: false,
      );
      if (!projectState.hasUnsavedChanges) {
        await projectState.refreshPoints();
      }

      // Recalculate lines with current points
      if (context.mounted) {
        recalculateAndDrawLines(context);
      }

      // Fit map to points if not skipping
      if (!skipNextFitToPoints && isMapReady && context.mounted) {
        fitMapToPoints(context);
      }

      skipNextFitToPoints = false; // Reset the flag
    } catch (e, stackTrace) {
      logger.severe("MapStateManager: Error refreshing points", e, stackTrace);
      // Status will be handled by the parent component
    } finally {
      isExternalRefresh = false; // Reset flag after refresh
    }
  }

  /// Public method to undo changes (reload from DB)
  Future<void> undoChanges(BuildContext context) async {
    final projectState = Provider.of<ProjectStateManager>(
      context,
      listen: false,
    );
    await projectState.undoChanges();
  }

  // Getters for the controller
  MapControllerLogic get controller => _controller;

  // Slide functionality methods
  void startSlidingMarker(PointModel point, LatLng originalPos) {
    isSlidingMarker = true;
    slidingPointId = point.id;
    originalPosition = originalPos;
    currentSlidePosition = originalPos;
    notifyListeners();
  }

  void updateSlidePosition(LatLng newPosition) {
    if (isSlidingMarker) {
      currentSlidePosition = newPosition;
      notifyListeners();
    }
  }

  void endSlidingMarker(BuildContext context) {
    if (!isSlidingMarker ||
        slidingPointId == null ||
        currentSlidePosition == null) {
      return;
    }

    try {
      // Get the point to update
      final projectState = Provider.of<ProjectStateManager>(
        context,
        listen: false,
      );
      final points = projectState.currentPoints;
      final pointToUpdate = points.firstWhere((p) => p.id == slidingPointId);

      // Create updated point with new coordinates
      final updatedPoint = pointToUpdate.copyWith(
        latitude: currentSlidePosition!.latitude,
        longitude: currentSlidePosition!.longitude,
      );

      // Update the point in global state
      projectState.updatePointInEditingState(updatedPoint);

      // Recalculate lines
      recalculateAndDrawLines(context);

      // Reset slide state
      isSlidingMarker = false;
      slidingPointId = null;
      originalPosition = null;
      currentSlidePosition = null;
      notifyListeners();

      // Status will be handled by the parent component
    } catch (e) {
      logger.severe('Failed to update point position from slide: $e');
      // Reset slide state on error
      isSlidingMarker = false;
      slidingPointId = null;
      originalPosition = null;
      currentSlidePosition = null;
      notifyListeners();
      // Status will be handled by the parent component
    }
  }
}
