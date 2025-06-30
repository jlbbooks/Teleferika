import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:teleferika/core/logger.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/core/utils/ordinal_manager.dart';

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
  ProjectModel? _editingProject; // Working copy for editing

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
  ProjectModel? get editingProject => _editingProject;

  /// Load a project and its points into global state
  Future<void> loadProject(String projectId) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final project = await _dbHelper.getProjectById(projectId);
      if (project != null) {
        _currentProject = project;
        _currentPoints = project.points;
        _editingProject = project; // Initialize editing copy
        _hasUnsavedChanges = false;
        _hasUnsavedNewPoint = false;
        notifyListeners();
        logger.info("ProjectStateManager: Loaded project ${project.name} with ${_currentPoints.length} points");
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
    _editingProject = null;
    _hasUnsavedChanges = false;
    _hasUnsavedNewPoint = false;
    notifyListeners();
    logger.info("ProjectStateManager: Cleared current project");
   }

  /// Update the editing project (for form changes)
  void updateEditingProject(ProjectModel project, {bool hasUnsavedChanges = false}) {
    _editingProject = project;
    _hasUnsavedChanges = hasUnsavedChanges;
    logger.info("ProjectStateManager: Updated editing project, hasUnsavedChanges: $hasUnsavedChanges");
    notifyListeners();
  }

  /// Save the current editing project to database
  Future<bool> saveProject() async {
    if (_editingProject == null) return false;
    
    try {
      final projectToSave = _editingProject!.copyWith(
        lastUpdate: DateTime.now(),
      );
      // 1. Update all points first
      final dbPoints = await _dbHelper.getPointsForProject(projectToSave.id);
      final dbPointIds = dbPoints.map((p) => p.id).toSet();
      final memPoints = _editingProject!.points ?? [];
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

  /// Undo changes by reloading the project and points from the DB into the editing state
  Future<void> undoChanges() async {
    if (_editingProject?.id == null) return;
    await loadProject(_editingProject!.id!);
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
      
      logger.info("ProjectStateManager: Refreshed ${points.length} points and project data");
      notifyListeners();
    } catch (e, stackTrace) {
      logger.severe("ProjectStateManager: Error refreshing points", e, stackTrace);
      rethrow;
    }
  }

  /// Add a new point to the editing project (in-memory only, not DB)
  void addPointInEditingState(PointModel point) {
    if (_editingProject == null) return;
    final points = List<PointModel>.from(_editingProject!.points ?? _currentPoints);
    final nextOrdinal = OrdinalManager.getNextOrdinal(points);
    final pointWithOrdinal = point.copyWith(ordinalNumber: nextOrdinal);
    points.add(pointWithOrdinal);
    final resequenced = OrdinalManager.resequence(points);
    _editingProject = _editingProject!.copyWith(points: resequenced);
    _currentPoints = resequenced;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Update an existing point in the editing project (in-memory only, not DB)
  void updatePointInEditingState(PointModel updatedPoint) {
    if (_editingProject == null) return;
    final points = List<PointModel>.from(_editingProject!.points ?? _currentPoints);
    final index = points.indexWhere((p) => p.id == updatedPoint.id);
    if (index != -1) {
      points[index] = updatedPoint;
      final resequenced = OrdinalManager.resequence(points);
      _editingProject = _editingProject!.copyWith(points: resequenced);
      _currentPoints = resequenced;
      _hasUnsavedChanges = true;
      notifyListeners();
    } else {
      logger.warning('[updatePointInEditingState] Point with id=${updatedPoint.id} not found in editing project.');
    }
  }

  /// Delete a point from the editing project (in-memory only, not DB)
  void deletePointInEditingState(String pointId) {
    if (_editingProject == null) return;
    final points = List<PointModel>.from(_editingProject!.points ?? _currentPoints);
    final resequenced = OrdinalManager.removeById(points, pointId);

    // Determine new starting/ending point IDs
    String? newStartingPointId = _editingProject!.startingPointId;
    String? newEndingPointId = _editingProject!.endingPointId;
    if (newStartingPointId == pointId || resequenced.isEmpty) {
      newStartingPointId = resequenced.isNotEmpty ? resequenced.first.id : null;
    }
    if (newEndingPointId == pointId || resequenced.isEmpty) {
      newEndingPointId = resequenced.isNotEmpty ? resequenced.last.id : null;
    }

    _editingProject = _editingProject!.copyWith(
      points: resequenced,
      startingPointId: newStartingPointId,
      endingPointId: newEndingPointId,
    );
    _currentPoints = resequenced;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Reorder points in the editing project (in-memory only, not DB)
  void reorderPointsInEditingState(List<PointModel> newOrder) {
    if (_editingProject == null) return;
    final resequenced = OrdinalManager.resequence(newOrder);
    _editingProject = _editingProject!.copyWith(points: resequenced);
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