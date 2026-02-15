import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/core/utils/ordinal_manager.dart';
import 'package:teleferika/db/drift_database_helper.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/core/app_config.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Global state manager for the current project being edited.
/// This ensures all widgets have access to the same project data
/// and are automatically notified when changes occur.
class ProjectStateManager extends ChangeNotifier {
  final Logger logger = Logger('ProjectStateManager');
  static final ProjectStateManager _instance = ProjectStateManager._internal();

  factory ProjectStateManager() => _instance;

  ProjectStateManager._internal();

  final DriftDatabaseHelper _dbHelper = DriftDatabaseHelper.instance;

  ProjectModel? _currentProject;
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

  List<PointModel> get currentPoints => _currentProject != null
      ? List.unmodifiable(_currentProject!.points)
      : <PointModel>[];

  bool get isLoading => _isLoading;

  bool get hasProject => _currentProject != null;

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  // Removed: ProjectModel? get editingProject => _editingProject;

  /// Load a project and its points into global state
  Future<void> loadProject(String projectId) async {
    if (_isLoading) return;

    _runAndNotify(() => _isLoading = true);

    try {
      final project = await _dbHelper.getProjectById(projectId);
      if (project != null) {
        _currentProject = project;
        _hasUnsavedChanges = false;
        _hasUnsavedNewPoint = false;
        notifyListeners();
        logger.info(
          'ProjectStateManager: Loaded project  ${project.name} with ${project.points.length} points',
        );
      } else {
        logger.warning(
          'ProjectStateManager: Project with ID $projectId not found',
        );
      }
    } catch (e, stackTrace) {
      logger.severe(
        'ProjectStateManager: Error loading project $projectId',
        e,
        stackTrace,
      );
      rethrow;
    } finally {
      _runAndNotify(() => _isLoading = false);
    }
  }

  /// Clear the current project (when switching projects or closing)
  void clearProject() {
    _isLoading = false;
    _currentProject = null;
    _hasUnsavedChanges = false;
    _hasUnsavedNewPoint = false;
    notifyListeners();
    logger.info('ProjectStateManager: Cleared current project');
  }

  /// Save the current project to database
  Future<bool> saveProject() async {
    if (_currentProject == null) return false;

    try {
      // Update lastUpdate directly
      _currentProject = _currentProject!.copyWith(lastUpdate: DateTime.now());
      // 1. Update all points first
      final dbPoints = await _dbHelper.getPointsForProject(_currentProject!.id);
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
      if (pointsToDelete.isNotEmpty) {
        await _dbHelper.deletePointsByIds(pointsToDelete.toList());
      }
      // 3. Now update the project (with valid start/end point IDs)
      await updateProjectInDB();
      // 4. Reload project and points from DB to ensure state is up to date
      await loadProject(_currentProject!.id);
      // 5. Cleanup orphaned image files if enabled
      if (AppConfig.cleanupOrphanedImageFiles) {
        await _cleanupOrphanedImageFilesForCurrentProject();
      }
      _hasUnsavedChanges = false;
      logger.info('ProjectStateManager: Project and points saved successfully');
      return true;
    } catch (e, stackTrace) {
      logger.severe('ProjectStateManager: Error saving project', e, stackTrace);
      return false;
    }
  }

  /// Delete any image files in the point photo directories that are not referenced by any image in the current project
  Future<void> _cleanupOrphanedImageFilesForCurrentProject() async {
    if (_currentProject == null) return;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final pointPhotosDir = Directory(p.join(appDocDir.path, 'point_photos'));
      if (!await pointPhotosDir.exists()) return;

      // Collect all referenced image file paths in the current project
      final referencedPaths = <String>{};
      for (final point in _currentProject!.points) {
        for (final image in point.images) {
          referencedPaths.add(image.imagePath);
        }
      }

      // For each point directory, delete files not referenced
      final pointDirs = pointPhotosDir.listSync().whereType<Directory>();
      for (final dir in pointDirs) {
        final files = dir.listSync().whereType<File>();
        for (final file in files) {
          if (!referencedPaths.contains(file.path)) {
            try {
              await file.delete();
              logger.info('Deleted orphaned image file: ${file.path}');
            } catch (e) {
              logger.warning(
                'Failed to delete orphaned image file: ${file.path} ($e)',
              );
            }
          }
        }
      }
    } catch (e, stackTrace) {
      logger.warning(
        'Error during orphaned image file cleanup: $e',
        e,
        stackTrace,
      );
    }
  }

  /// Undo changes by reloading the project and points from the DB
  Future<void> undoChanges() async {
    if (_currentProject?.id == null) return;
    await loadProject(_currentProject!.id);
    logger.info('ProjectStateManager: Changes undone by reloading from DB');
  }

  /// Refresh points from database
  Future<void> refreshPoints() async {
    if (_currentProject == null) return;

    try {
      final project = await _dbHelper.getProjectById(_currentProject!.id);
      if (project != null) {
        _currentProject = project;
      }
      logger.info(
        'ProjectStateManager: Refreshed ${project?.points.length ?? 0} points and project data',
      );
      notifyListeners();
    } catch (e, stackTrace) {
      logger.severe(
        'ProjectStateManager: Error refreshing points',
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
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Reorder points in the current project (in-memory only, not DB)
  void reorderPointsInEditingState(List<PointModel> newOrder) {
    if (_currentProject == null) return;
    final resequenced = OrdinalManager.resequence(newOrder);
    _currentProject = _currentProject!.copyWith(points: resequenced);
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Updates only the profile chart height: writes to DB and updates in-memory
  /// project without setting [hasUnsavedChanges].
  Future<void> updateProfileChartHeightOnly(String projectId, double height) async {
    if (_currentProject?.id != projectId) return;
    try {
      await _dbHelper.updateProjectProfileChartHeight(projectId, height);
      _currentProject = _currentProject!.copyWith(profileChartHeight: height);
      notifyListeners();
      logger.fine(
        'ProjectStateManager: Updated profileChartHeight to $height for $projectId',
      );
    } catch (e, stackTrace) {
      logger.severe(
        'ProjectStateManager: Error updating profileChartHeight',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Update project details in DB
  Future<void> updateProjectInDB() async {
    try {
      final result = await _dbHelper.updateProject(_currentProject!);
      if (result > 0) {
        logger.info(
          'ProjectStateManager: Updated project ${_currentProject!.name}',
        );
        notifyListeners();
      }
    } catch (e, stackTrace) {
      logger.severe(
        'ProjectStateManager: Error updating project',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Updates project metadata (name, note, azimuth, etc.) from the given [project]
  /// and sets unsaved state. Keeps the current points list so that form edits never
  /// overwrite points added/edited elsewhere (all editing is in memory until save;
  /// undo reloads from DB).
  void setProjectEditState(ProjectModel project, bool hasUnsavedChanges) {
    _currentProject = project.copyWith(points: _currentProject?.points ?? []);
    _hasUnsavedChanges = hasUnsavedChanges;
    notifyListeners();
  }

  /// Create a new project in the database and open it as the current project.
  Future<bool> createProject(ProjectModel project) async {
    try {
      await _dbHelper.insertProject(project);
      logger.info('ProjectStateManager: Created project ${project.name}');
      await loadProject(project.id);
      return true;
    } catch (e, stackTrace) {
      logger.severe(
        'ProjectStateManager: Error creating project',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Delete a project from the database
  Future<bool> deleteProject(String projectId) async {
    try {
      // Get project details before deletion for cleanup
      final projectToDelete = await _dbHelper.getProjectById(projectId);

      await _dbHelper.deleteProject(projectId);

      // Clear current project if it's the one being deleted
      if (_currentProject?.id == projectId) {
        clearProject();
      }

      // Cleanup project files and folders if enabled
      if (AppConfig.cleanupOrphanedImageFiles && projectToDelete != null) {
        await _cleanupProjectFiles(projectToDelete);
      }

      logger.info('ProjectStateManager: Deleted project $projectId');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      logger.severe(
        'ProjectStateManager: Error deleting project',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Delete all files and folders related to a project
  Future<void> _cleanupProjectFiles(ProjectModel project) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final pointPhotosDir = Directory(p.join(appDocDir.path, 'point_photos'));

      if (!await pointPhotosDir.exists()) return;

      // Delete point photo directories for all points in the project
      for (final point in project.points) {
        final pointDir = Directory(p.join(pointPhotosDir.path, point.id));
        if (await pointDir.exists()) {
          try {
            await pointDir.delete(recursive: true);
            logger.info('Deleted point photo directory: ${pointDir.path}');
          } catch (e) {
            logger.warning(
              'Failed to delete point photo directory: ${pointDir.path} ($e)',
            );
          }
        }
      }

      logger.info('Cleaned up files for project: ${project.name}');
    } catch (e, stackTrace) {
      logger.warning('Error during project file cleanup: $e', e, stackTrace);
    }
  }

  /// Get all projects from the database (read-only operation)
  Future<List<ProjectModel>> getAllProjects() async {
    try {
      final projects = await _dbHelper.getAllProjects();
      logger.info('ProjectStateManager: Retrieved ${projects.length} projects');
      return projects;
    } catch (e, stackTrace) {
      logger.severe(
        'ProjectStateManager: Error getting all projects',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Create a new point in the current project (in-memory only, not DB)
  bool createPoint(PointModel point) {
    if (_currentProject == null) {
      logger.warning(
        'ProjectStateManager: Cannot create point - no current project',
      );
      return false;
    }
    addPointInEditingState(point);
    logger.info(
      'ProjectStateManager: Created point ${point.id} in project ${_currentProject!.name}',
    );
    return true;
  }

  /// Update a point in the current project (in-memory only, not DB)
  bool updatePoint(PointModel point) {
    if (_currentProject == null) {
      logger.warning(
        'ProjectStateManager: Cannot update point - no current project',
      );
      return false;
    }
    updatePointInEditingState(point);
    logger.info(
      'ProjectStateManager: Updated point ${point.id} in project ${_currentProject!.name}',
    );
    return true;
  }

  /// Delete a point from the current project (in-memory only, not DB)
  bool deletePoint(String pointId) {
    if (_currentProject == null) {
      logger.warning(
        'ProjectStateManager: Cannot delete point - no current project',
      );
      return false;
    }
    deletePointInEditingState(pointId);
    logger.info(
      'ProjectStateManager: Deleted point $pointId from project ${_currentProject!.name}',
    );
    return true;
  }

  /// Move a point to new coordinates (in-memory only, not DB)
  bool movePoint(
    String pointId,
    double newLatitude,
    double newLongitude,
  ) {
    if (_currentProject == null) {
      logger.warning(
        'ProjectStateManager: Cannot move point - no current project',
      );
      return false;
    }
    final point = getPointById(pointId);
    if (point == null) {
      logger.warning(
        'ProjectStateManager: Cannot move point - point $pointId not found',
      );
      return false;
    }
    final updatedPoint = point.copyWith(
      latitude: newLatitude,
      longitude: newLongitude,
    );
    updatePointInEditingState(updatedPoint);
    logger.info(
      'ProjectStateManager: Moved point ${point.id} to ($newLatitude, $newLongitude)',
    );
    return true;
  }

  /// Get a specific point by ID
  PointModel? getPointById(String pointId) {
    final points = _currentProject?.points ?? [];
    for (final p in points) {
      if (p.id == pointId) return p;
    }
    return null;
  }

  /// Get points sorted by ordinal number
  List<PointModel> get sortedPoints {
    final points = _currentProject?.points ?? [];
    final sorted = List<PointModel>.from(points);
    sorted.sort((a, b) => a.ordinalNumber.compareTo(b.ordinalNumber));
    return sorted;
  }

  void _runAndNotify(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}
