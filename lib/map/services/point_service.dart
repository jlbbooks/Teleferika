import 'package:teleferika/core/logger.dart';
import 'package:teleferika/core/utils/ordinal_manager.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';

class PointService {
  final ProjectModel project;
  final ProjectStateManager _projectState;

  PointService({
    required this.project,
    required ProjectStateManager projectState,
  }) : _projectState = projectState;

  // Point operations
  Future<List<PointModel>> loadProjectPoints() async {
    // Use the current points from the state manager
    return _projectState.currentPoints;
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
      logger.severe(
        "PointService: Error loading points for map",
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> movePoint(
    PointModel pointToMove,
    double newLatitude,
    double newLongitude,
  ) async {
    return await _projectState.movePoint(
      pointToMove,
      newLatitude,
      newLongitude,
    );
  }

  Future<bool> deletePoint(String pointId) async {
    return await _projectState.deletePoint(pointId);
  }

  // Create a new point at the specified location
  Future<PointModel> createNewPoint(
    double latitude,
    double longitude, {
    double? altitude,
    double? gpsPrecision,
  }) async {
    final points = _projectState.currentPoints;
    final nextOrdinal = OrdinalManager.getNextOrdinal(points);
    return PointModel(
      projectId: project.id,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      gpsPrecision: gpsPrecision,
      // Always include altitude and gpsPrecision if available
      ordinalNumber: nextOrdinal,
      note: null,
      timestamp: DateTime.now(),
      isUnsaved: true, // Mark as unsaved
    );
  }

  // Save a new point to the database
  Future<bool> saveNewPoint(PointModel point) async {
    // Mark the point as saved before inserting
    final savedPoint = point.copyWith(isUnsaved: false);
    return await _projectState.createPoint(savedPoint);
  }

  /// Saves a new point and returns the saved point with proper state management
  Future<PointModel> saveNewPointWithStateManagement(PointModel point) async {
    // Create a new instance with isUnsaved: false for the saved point
    final savedPoint = point.copyWith(isUnsaved: false);
    // No need to update project start/end points in DB anymore
    return savedPoint;
  }
}
