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
import 'package:url_launcher/url_launcher.dart';

enum MapType { openStreetMap, satellite, terrain }

class MapControllerLogic {
  final ProjectModel project;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // Default center if no points are available (e.g., Rome)
  final LatLng _defaultCenter = const LatLng(41.9028, 12.4964);
  final double _defaultZoom = 6.0;
  
  // Stream subscriptions
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  
  // Animation timer
  Timer? _glowAnimationTimer;
  double _glowAnimationValue = 0.0;
  Function(double)? _glowAnimationCallback;

  MapControllerLogic({required this.project});

  void dispose() {
    _positionStreamSubscription?.cancel();
    _compassSubscription?.cancel();
    _glowAnimationTimer?.cancel();
  }

  // Permission handling
  Future<Map<String, bool>> checkAndRequestPermissions() async {
    // Location Permission
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    // Sensor (Compass) Permission
    PermissionStatus sensorStatus = await Permission.sensors.status;
    if (sensorStatus.isDenied) {
      sensorStatus = await Permission.sensors.request();
    }

    return {
      'location': locationPermission == LocationPermission.whileInUse ||
          locationPermission == LocationPermission.always,
      'sensor': sensorStatus.isGranted,
    };
  }

  // Location listening
  void startListeningToLocation(
    Function(Position) onPositionUpdate,
    Function(Object, [StackTrace?]) onError,
  ) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      onPositionUpdate,
      onError: onError,
    );
  }

  // Compass listening
  void startListeningToCompass(
    Function(double) onHeadingUpdate,
    Function(Object, [StackTrace?]) onError,
  ) {
    if (FlutterCompass.events == null) {
      logger.warning("Compass events stream is null. Cannot listen to compass.");
      onError("Compass not available");
      return;
    }

    _compassSubscription = FlutterCompass.events!.listen(
      (CompassEvent event) {
        onHeadingUpdate(event.heading ?? 0.0);
      },
      onError: onError,
    );
  }

  // Point operations
  Future<List<PointModel>> loadProjectPoints() async {
    return await _dbHelper.getPointsForProject(project.id);
  }

  /// Loads project points with optional control over automatic map fitting
  Future<List<PointModel>> loadProjectPointsWithFitting({
    required bool skipNextFitToPoints,
    required Function(List<PointModel>) onPointsLoaded,
    required Function() onPointsChanged,
    required Function() recalculateAndDrawLines,
    required Function() fitMapToPoints,
    required bool isMapReady,
  }) async {
    try {
      final points = await loadProjectPoints();
      
      onPointsLoaded(points);
      recalculateAndDrawLines();
      onPointsChanged();
      
      if (isMapReady && !skipNextFitToPoints) {
        fitMapToPoints();
      }
      
      return points;
    } catch (e, stackTrace) {
      logger.severe("MapControllerLogic: Error loading points for map", e, stackTrace);
      rethrow;
    }
  }

  Future<int> movePoint(PointModel pointToMove, LatLng newPosition) async {
    final updatedPoint = pointToMove.copyWith(
      latitude: newPosition.latitude,
      longitude: newPosition.longitude,
    );
    return await _dbHelper.updatePoint(updatedPoint);
  }

  Future<int> deletePoint(String pointId) async {
    return await _dbHelper.deletePointById(pointId);
  }

  // Map calculations
  double? recalculateHeadingLine(List<PointModel> projectPoints) {
    if (projectPoints.length >= 2) {
      return calculateBearing(
        LatLng(projectPoints.first.latitude, projectPoints.first.longitude),
        LatLng(projectPoints.last.latitude, projectPoints.last.longitude),
      );
    }
    return null;
  }

  Polyline? recalculateProjectHeadingLine(List<PointModel> projectPoints) {
    if (projectPoints.isEmpty || project.azimuth == null) {
      return null;
    }

    try {
      final firstPoint = LatLng(
        projectPoints.first.latitude,
        projectPoints.first.longitude,
      );
      final projectHeading = project.azimuth!;

      // Use presumed total length from project, default to 500m if not provided
      final lineLengthKm = (project.presumedTotalLength ?? 500.0) / 1000.0; // Convert meters to kilometers

      final endPoint = _calculateDestinationPoint(
        firstPoint,
        projectHeading,
        lineLengthKm,
      );

      return Polyline(
        points: [firstPoint, endPoint],
        strokeWidth: 2.0,
        color: Colors.black, // Choose a distinct color
        pattern: StrokePattern.dotted(),
      );
    } catch (e) {
      logger.warning('Error calculating project heading line: $e');
      return null;
    }
  }

  LatLng getInitialCenter(List<PointModel> projectPoints, Position? currentPosition) {
    if (projectPoints.isNotEmpty) {
      return LatLng(
        projectPoints.first.latitude,
        projectPoints.first.longitude,
      );
    }

    // Fallback to current position if available
    if (currentPosition != null) {
      return LatLng(currentPosition.latitude, currentPosition.longitude);
    }

    // Final fallback to default center
    return _defaultCenter;
  }

  double getInitialZoom(List<PointModel> projectPoints, Position? currentPosition) {
    if (projectPoints.isNotEmpty) {
      if (projectPoints.length == 1) {
        return 15.0; // Closer zoom for single point
      } else {
        return 14.0; // Medium zoom for multiple points
      }
    }

    // If no points but have current position, use medium zoom
    if (currentPosition != null) {
      return 12.0;
    }

    // Default zoom for no data
    return _defaultZoom;
  }

  // Tile layer management
  String getTileLayerUrl(MapType mapType) {
    switch (mapType) {
      case MapType.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapType.terrain:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';
    }
  }

  String getTileLayerAttribution(MapType mapType) {
    switch (mapType) {
      case MapType.openStreetMap:
        return '© OpenStreetMap contributors';
      case MapType.satellite:
        return '© Esri — Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community';
      case MapType.terrain:
        return '© Esri — Source: Esri, DeLorme, NAVTEQ, USGS, Intermap, iPC, NRCAN, Esri Japan, METI, Esri China (Hong Kong), Esri (Thailand), TomTom, 2012';
    }
  }

  String getAttributionUrl(MapType mapType) {
    switch (mapType) {
      case MapType.openStreetMap:
        return 'https://openstreetmap.org/copyright';
      case MapType.satellite:
      case MapType.terrain:
        return 'https://www.esri.com/en-us/home';
    }
  }

  // Glow animation
  void startGlowAnimation(Function(double) callback) {
    _glowAnimationTimer?.cancel();
    _glowAnimationValue = 0.0;
    _glowAnimationCallback = callback;
    
    _glowAnimationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _glowAnimationValue += 0.3; // Fast animation
      if (_glowAnimationValue >= 2 * math.pi) {
        _glowAnimationValue = 0.0; // Reset to start
      }
      
      // Calculate color interpolation between blue and purpleAccent
      final progress = (math.sin(_glowAnimationValue) + 1) / 2; // 0 to 1
      final animatedValue = progress;
      
      _glowAnimationCallback?.call(animatedValue);
    });
  }

  void stopGlowAnimation() {
    _glowAnimationTimer?.cancel();
    _glowAnimationTimer = null;
    _glowAnimationCallback = null;
  }

  // Helper functions
  double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;
  double _radiansToDegrees(double radians) => radians * 180.0 / math.pi;

  // Function to calculate initial bearing from point1 to point2
  double calculateBearing(LatLng point1, LatLng point2) {
    final lat1 = _degreesToRadians(point1.latitude);
    final lon1 = _degreesToRadians(point1.longitude);
    final lat2 = _degreesToRadians(point2.latitude);
    final lon2 = _degreesToRadians(point2.longitude);

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
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
    final lon2 = lon1 +
        math.atan2(
          math.sin(bearingRad) * math.sin(distanceKm / R) * math.cos(lat1),
          math.cos(distanceKm / R) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(_radiansToDegrees(lat2), _radiansToDegrees(lon2));
  }

  // Create a new point at the specified location
  Future<PointModel> createNewPoint(LatLng location) async {
    final nextOrdinal = await _dbHelper.ordinalManager.getNextOrdinal(project.id);
    
    return PointModel(
      projectId: project.id,
      latitude: location.latitude,
      longitude: location.longitude,
      ordinalNumber: nextOrdinal,
      timestamp: DateTime.now(),
      isUnsaved: true, // Mark as unsaved
    );
  }

  // Save a new point to the database
  Future<String> saveNewPoint(PointModel point) async {
    // Mark the point as saved before inserting
    final savedPoint = point.copyWith(isUnsaved: false);
    return await _dbHelper.insertPoint(savedPoint);
  }

  /// Saves a new point and returns the saved point with proper state management
  Future<PointModel> saveNewPointWithStateManagement(PointModel point) async {
    // Save the point to database
    final pointId = await saveNewPoint(point);
    
    // Create a new instance with isUnsaved: false for the saved point
    final savedPoint = point.copyWith(isUnsaved: false);
    
    // Update project start/end points in the database
    await updateProjectStartEndPoints();
    
    return savedPoint;
  }

  // Update project start/end points
  Future<void> updateProjectStartEndPoints() async {
    await _dbHelper.updateProjectStartEndPoints(project.id);
  }
} 