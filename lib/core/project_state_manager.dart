import 'package:flutter/foundation.dart';
import 'package:teleferika/core/logger.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';

/// Global state manager for the current project being edited.
/// This ensures all widgets have access to the same project data
/// and are automatically notified when changes occur.
class ProjectStateManager extends ChangeNotifier {
  static final ProjectStateManager _instance = ProjectStateManager._internal();
  factory ProjectStateManager() => _instance;
  ProjectStateManager._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  ProjectModel? _currentProject;
  List<PointModel> _currentPoints = [];
  bool _isLoading = false;

  // Getters
  ProjectModel? get currentProject => _currentProject;
  List<PointModel> get currentPoints => List.unmodifiable(_currentPoints);
  bool get isLoading => _isLoading;
  bool get hasProject => _currentProject != null;

  /// Load a project and its points into global state
  Future<void> loadProject(String projectId) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final project = await _dbHelper.getProjectById(projectId);
      if (project != null) {
        _currentProject = project;
        _currentPoints = project.points;
        logger.info("ProjectStateManager: Loaded project ${project.name} with ${_currentPoints.length} points");
        notifyListeners();
      } else {
        logger.warning("ProjectStateManager: Project with ID $projectId not found");
      }
    } catch (e, stackTrace) {
      logger.severe("ProjectStateManager: Error loading project $projectId", e, stackTrace);
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Clear the current project (when switching projects or closing)
  void clearProject() {
    _currentProject = null;
    _currentPoints = [];
    logger.info("ProjectStateManager: Cleared current project");
    notifyListeners();
  }

  /// Refresh points from database
  Future<void> refreshPoints() async {
    if (_currentProject == null) return;
    
    try {
      // Refresh both points and project data to get updated start/end point IDs
      final points = await _dbHelper.getPointsForProject(_currentProject!.id);
      final project = await _dbHelper.getProjectById(_currentProject!.id);
      
      _currentPoints = points;
      if (project != null) {
        _currentProject = project;
      }
      
      logger.info("ProjectStateManager: Refreshed ${points.length} points and project data");
      notifyListeners();
    } catch (e, stackTrace) {
      logger.severe("ProjectStateManager: Error refreshing points", e, stackTrace);
      rethrow;
    }
  }

  /// Add a new point to the current project
  Future<void> addPoint(PointModel point) async {
    if (_currentProject == null) return;
    
    try {
      final pointId = await _dbHelper.insertPoint(point);
      final savedPoint = point.copyWith(id: pointId, isUnsaved: false);
      _currentPoints.add(savedPoint);
      await _updateProjectStartEndPoints();
      logger.info("ProjectStateManager: Added point ${savedPoint.name}");
      notifyListeners();
    } catch (e, stackTrace) {
      logger.severe("ProjectStateManager: Error adding point", e, stackTrace);
      rethrow;
    }
  }

  /// Update an existing point
  Future<void> updatePoint(PointModel point) async {
    if (_currentProject == null) return;
    
    try {
      final result = await _dbHelper.updatePoint(point);
      if (result > 0) {
        final index = _currentPoints.indexWhere((p) => p.id == point.id);
        if (index != -1) {
          _currentPoints[index] = point;
          await _updateProjectStartEndPoints();
          logger.info("ProjectStateManager: Updated point ${point.name}");
          notifyListeners();
        }
      }
    } catch (e, stackTrace) {
      logger.severe("ProjectStateManager: Error updating point", e, stackTrace);
      rethrow;
    }
  }

  /// Delete a point from the current project
  Future<void> deletePoint(String pointId) async {
    if (_currentProject == null) return;
    
    try {
      final result = await _dbHelper.deletePointById(pointId);
      if (result > 0) {
        _currentPoints.removeWhere((p) => p.id == pointId);
        await _updateProjectStartEndPoints();
        logger.info("ProjectStateManager: Deleted point with ID $pointId");
        notifyListeners();
      }
    } catch (e, stackTrace) {
      logger.severe("ProjectStateManager: Error deleting point", e, stackTrace);
      rethrow;
    }
  }

  /// Move a point to a new location
  Future<void> movePoint(PointModel point, double newLatitude, double newLongitude) async {
    if (_currentProject == null) return;
    
    try {
      final updatedPoint = point.copyWith(
        latitude: newLatitude,
        longitude: newLongitude,
      );
      final result = await _dbHelper.updatePoint(updatedPoint);
      if (result > 0) {
        final index = _currentPoints.indexWhere((p) => p.id == point.id);
        if (index != -1) {
          _currentPoints[index] = updatedPoint;
          await _updateProjectStartEndPoints();
          logger.info("ProjectStateManager: Moved point ${point.name}");
          notifyListeners();
        }
      }
    } catch (e, stackTrace) {
      logger.severe("ProjectStateManager: Error moving point", e, stackTrace);
      rethrow;
    }
  }

  /// Update project details
  Future<void> updateProject(ProjectModel project) async {
    try {
      final result = await _dbHelper.updateProject(project);
      if (result > 0) {
        _currentProject = project;
        logger.info("ProjectStateManager: Updated project ${project.name}");
        notifyListeners();
      }
    } catch (e, stackTrace) {
      logger.severe("ProjectStateManager: Error updating project", e, stackTrace);
      rethrow;
    }
  }

  /// Get a specific point by ID
  PointModel? getPointById(String pointId) {
    try {
      return _currentPoints.firstWhere((p) => p.id == pointId);
    } catch (e) {
      return null;
    }
  }

  /// Get points sorted by ordinal number
  List<PointModel> get sortedPoints {
    final sorted = List<PointModel>.from(_currentPoints);
    sorted.sort((a, b) => a.ordinalNumber.compareTo(b.ordinalNumber));
    return sorted;
  }

  /// Update project start/end points in database
  Future<void> _updateProjectStartEndPoints() async {
    if (_currentProject == null) return;
    
    try {
      await _dbHelper.updateProjectStartEndPoints(_currentProject!.id);
      
      // Refresh project data to get updated start/end point IDs
      final project = await _dbHelper.getProjectById(_currentProject!.id);
      if (project != null) {
        _currentProject = project;
        logger.info("ProjectStateManager: Updated project start/end points and refreshed project data");
      }
    } catch (e, stackTrace) {
      logger.severe("ProjectStateManager: Error updating project start/end points", e, stackTrace);
    }
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
} 