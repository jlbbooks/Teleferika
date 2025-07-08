import 'package:teleferika/core/logger.dart';
import 'package:teleferika/core/utils/ordinal_manager.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';

class PointService {
  final ProjectModel project;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  PointService({required this.project});

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
      logger.severe(
        "PointService: Error loading points for map",
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<int> movePoint(
    PointModel pointToMove,
    double newLatitude,
    double newLongitude,
  ) async {
    final updatedPoint = pointToMove.copyWith(
      latitude: newLatitude,
      longitude: newLongitude,
    );
    return await _dbHelper.updatePoint(updatedPoint);
  }

  Future<int> deletePoint(String pointId) async {
    return await _dbHelper.deletePointById(pointId);
  }

  // Create a new point at the specified location
  Future<PointModel> createNewPoint(
    double latitude,
    double longitude, {
    double? altitude,
  }) async {
    final points = await _dbHelper.getPointsForProject(project.id);
    final nextOrdinal = OrdinalManager.getNextOrdinal(points);
    return PointModel(
      projectId: project.id,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      // Always include altitude if available
      ordinalNumber: nextOrdinal,
      note: 'Point added from map',
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
