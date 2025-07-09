import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/core/utils/ordinal_manager.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';

/// Global state manager for the current project being edited.
/// This ensures all widgets have access to the same project data
/// and are automatically notified when changes occur.
class ProjectStateManager extends ChangeNotifier {
  final Logger logger = Logger('ProjectStateManager');
  static final ProjectStateManager _instance = ProjectStateManager._internal();

  factory ProjectStateManager() => _instance;

  ProjectStateManager._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  ProjectModel? _currentProject;
  List<PointModel> _currentPoints = [];
  bool _isLoading = false;

  // Project editing state
  bool _hasUnsavedChanges = false;
  // Removed: ProjectModel? _editingProject; // Working copy for editing

  // Track if there is an unsaved new point (e.g., in MapToolView)
  bool _hasUnsavedNewPoint = false;

  bool get hasUnsavedNewPoint => _hasUnsavedNewPoint;

  void setHasUnsavedNewPoint(bool value) {
    if (_hasUnsavedNewPoint != value) {
      _hasUnsavedNewPoint = value;
      notifyListeners();
    }
  }

  // Getters
  ProjectModel? get currentProject => _currentProject;

  List<PointModel> get currentPoints => List.unmodifiable(_currentPoints);

  bool get isLoading => _isLoading;

  bool get hasProject => _currentProject != null;

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  // Removed: ProjectModel? get editingProject => _editingProject;

  /// Load a project and its points into global state
  Future<void> loadProject(String projectId) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final project = await _dbHelper.getProjectById(projectId);
      if (project != null) {
        _currentProject = project;
        _currentPoints = project.points;
        // Removed: _editingProject = project; // Initialize editing copy
        _hasUnsavedChanges = false;
        _hasUnsavedNewPoint = false;
        notifyListeners();
        logger.info(
          "ProjectStateManager: Loaded project  ${project.name} with ${_currentPoints.length} points",
        );
      } else {
        logger.warning(
          "ProjectStateManager: Project with ID $projectId not found",
        );
      }
    } catch (e, stackTrace) {
      logger.severe(
        "ProjectStateManager: Error loading project $projectId",
        e,
        stackTrace,
      );
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Clear the current project (when switching projects or closing)
  void clearProject() {
    _currentProject = null;
    _currentPoints = [];
    // Removed: _editingProject = null;
    _hasUnsavedChanges = false;
    _hasUnsavedNewPoint = false;
    notifyListeners();
    logger.info("ProjectStateManager: Cleared current project");
  }

  /// Save the current project to database
  Future<bool> saveProject() async {
    if (_currentProject == null) return false;

    try {
      final projectToSave = _currentProject!.copyWith(
        lastUpdate: DateTime.now(),
      );
      // 1. Update all points first
      final dbPoints = await _dbHelper.getPointsForProject(projectToSave.id);
      final dbPointIds = dbPoints.map((p) => p.id).toSet();
      final memPoints = _currentProject!.points;
      final memPointIds = memPoints.map((p) => p.id).toSet();
      for (final point in memPoints) {
        if (dbPointIds.contains(point.id)) {
          await _dbHelper.updatePoint(point);
        } else {
          await _dbHelper.insertPoint(point);
        }
      }
      // 2. Delete any DB points not present in memory
      final pointsToDelete = dbPointIds.difference(memPointIds);
      for (final pointId in pointsToDelete) {
        await _dbHelper.deletePointById(pointId);
      }
      // 3. Now update the project (with valid start/end point IDs)
      await updateProject(projectToSave);
      // 4. Reload project and points from DB to ensure state is up to date
      await loadProject(projectToSave.id);
      _hasUnsavedChanges = false;
      logger.info("ProjectStateManager: Project and points saved successfully");
      return true;
    } catch (e, stackTrace) {
      logger.severe("ProjectStateManager: Error saving project", e, stackTrace);
      return false;
    }
  }

  /// Undo changes by reloading the project and points from the DB
  Future<void> undoChanges() async {
    if (_currentProject?.id == null) return;
    await loadProject(_currentProject!.id);
    logger.info("ProjectStateManager: Changes undone by reloading from DB");
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

      logger.info(
        "ProjectStateManager: Refreshed ${points.length} points and project data",
      );
      notifyListeners();
    } catch (e, stackTrace) {
      logger.severe(
        "ProjectStateManager: Error refreshing points",
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Add a new point to the current project (in-memory only, not DB)
  void addPointInEditingState(PointModel point) {
    if (_currentProject == null) return;
    final points = List<PointModel>.from(_currentProject!.points);
    final nextOrdinal = OrdinalManager.getNextOrdinal(points);
    final pointWithOrdinal = point.copyWith(ordinalNumber: nextOrdinal);
    points.add(pointWithOrdinal);
    final resequenced = OrdinalManager.resequence(points);
    _currentProject = _currentProject!.copyWith(points: resequenced);
    _currentPoints = resequenced;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Update an existing point in the current project (in-memory only, not DB)
  void updatePointInEditingState(PointModel updatedPoint) {
    if (_currentProject == null) return;
    final points = List<PointModel>.from(_currentProject!.points);
    final index = points.indexWhere((p) => p.id == updatedPoint.id);
    if (index != -1) {
      points[index] = updatedPoint;
      final resequenced = OrdinalManager.resequence(points);
      _currentProject = _currentProject!.copyWith(points: resequenced);
      _currentPoints = resequenced;
      _hasUnsavedChanges = true;
      notifyListeners();
    } else {
      logger.warning(
        '[updatePointInEditingState] Point with id= ${updatedPoint.id} not found in current project.',
      );
    }
  }

  /// Delete a point from the current project (in-memory only, not DB)
  void deletePointInEditingState(String pointId) {
    if (_currentProject == null) return;
    final points = List<PointModel>.from(_currentProject!.points);
    final resequenced = OrdinalManager.removeById(points, pointId);
    _currentProject = _currentProject!.copyWith(points: resequenced);
    _currentPoints = resequenced;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Reorder points in the current project (in-memory only, not DB)
  void reorderPointsInEditingState(List<PointModel> newOrder) {
    if (_currentProject == null) return;
    final resequenced = OrdinalManager.resequence(newOrder);
    _currentProject = _currentProject!.copyWith(points: resequenced);
    _currentPoints = resequenced;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Update project details in DB
  Future<void> updateProject(ProjectModel project) async {
    try {
      final result = await _dbHelper.updateProject(project);
      if (result > 0) {
        _currentProject = project;
        logger.info("ProjectStateManager: Updated project ${project.name}");
        notifyListeners();
      }
    } catch (e, stackTrace) {
      logger.severe(
        "ProjectStateManager: Error updating project",
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Set the current project and unsaved state (used by UI forms)
  void setProjectEditState(ProjectModel project, bool hasUnsavedChanges) {
    _currentProject = project;
    _hasUnsavedChanges = hasUnsavedChanges;
    notifyListeners();
  }

  /// Create a new project in the database
  Future<bool> createProject(ProjectModel project) async {
    try {
      await _dbHelper.insertProject(project);
      logger.info("ProjectStateManager: Created project ${project.name}");
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      logger.severe(
        "ProjectStateManager: Error creating project",
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Delete a project from the database
  Future<bool> deleteProject(String projectId) async {
    try {
      await _dbHelper.deleteProject(projectId);
      // Clear current project if it's the one being deleted
      if (_currentProject?.id == projectId) {
        clearProject();
      }
      logger.info("ProjectStateManager: Deleted project $projectId");
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      logger.severe(
        "ProjectStateManager: Error deleting project",
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Get all projects from the database (read-only operation)
  Future<List<ProjectModel>> getAllProjects() async {
    try {
      final projects = await _dbHelper.getAllProjects();
      logger.info("ProjectStateManager: Retrieved ${projects.length} projects");
      return projects;
    } catch (e, stackTrace) {
      logger.severe(
        "ProjectStateManager: Error getting all projects",
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Create a new point in the current project (in-memory only, not DB)
  Future<bool> createPoint(PointModel point) async {
    if (_currentProject == null) {
      logger.warning(
        "ProjectStateManager: Cannot create point - no current project",
      );
      return false;
    }
    addPointInEditingState(point);
    logger.info(
      "ProjectStateManager: Created point ${point.id} in project ${_currentProject!.name}",
    );
    return true;
  }

  /// Update a point in the current project (in-memory only, not DB)
  Future<bool> updatePoint(PointModel point) async {
    if (_currentProject == null) {
      logger.warning(
        "ProjectStateManager: Cannot update point - no current project",
      );
      return false;
    }
    updatePointInEditingState(point);
    logger.info(
      "ProjectStateManager: Updated point ${point.id} in project ${_currentProject!.name}",
    );
    return true;
  }

  /// Delete a point from the current project (in-memory only, not DB)
  Future<bool> deletePoint(String pointId) async {
    if (_currentProject == null) {
      logger.warning(
        "ProjectStateManager: Cannot delete point - no current project",
      );
      return false;
    }
    deletePointInEditingState(pointId);
    logger.info(
      "ProjectStateManager: Deleted point $pointId from project ${_currentProject!.name}",
    );
    return true;
  }

  /// Move a point to new coordinates (in-memory only, not DB)
  Future<bool> movePoint(
    PointModel point,
    double newLatitude,
    double newLongitude,
  ) async {
    if (_currentProject == null) {
      logger.warning(
        "ProjectStateManager: Cannot move point - no current project",
      );
      return false;
    }
    final updatedPoint = point.copyWith(
      latitude: newLatitude,
      longitude: newLongitude,
    );
    updatePointInEditingState(updatedPoint);
    logger.info(
      "ProjectStateManager: Moved point ${point.id} to ($newLatitude, $newLongitude)",
    );
    return true;
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

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}
