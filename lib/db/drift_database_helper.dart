// drift_database_helper.dart
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';

import 'models/image_model.dart';
import 'models/point_model.dart';
import 'models/project_model.dart';

// Import the generated Drift database
import 'database.dart';

/// Drift-based database helper that provides a similar interface to the original DatabaseHelper
/// but uses Drift for type-safe database operations.
///
/// ## Database Versioning
/// Drift handles database versioning through the `schemaVersion` property in `TeleferikaDatabase`.
/// Schema migrations are managed in the `MigrationStrategy` in the database class.
/// This helper class doesn't need to track version numbers as Drift handles this automatically.
class DriftDatabaseHelper {
  static final Logger _logger = Logger('DriftDatabaseHelper');

  DriftDatabaseHelper._privateConstructor() {
    _logger.info('DriftDatabaseHelper instance created');
  }

  static final DriftDatabaseHelper instance =
      DriftDatabaseHelper._privateConstructor();
  static TeleferikaDatabase? _database;

  Future<TeleferikaDatabase> get database async {
    if (_database != null) {
      _logger.fine('Returning existing database instance');
      return _database!;
    }
    _logger.info('Creating new database instance');
    _database = TeleferikaDatabase();
    return _database!;
  }

  // Project Methods
  Future<List<ProjectModel>> getAllProjects() async {
    _logger.info('Getting all projects');
    try {
      final db = await database;
      final projects = await db.getAllProjects();

      List<ProjectModel> projectModels = [];
      for (final project in projects) {
        _logger.fine('Loading points for project: ${project.name}');
        final points = await getPointsForProject(project.id);
        projectModels.add(_projectFromDrift(project, points));
      }

      // Sort by last update, newest first
      projectModels.sort(
        (a, b) => (b.lastUpdate ?? DateTime(1900)).compareTo(
          a.lastUpdate ?? DateTime(1900),
        ),
      );

      _logger.info(
        'Retrieved ${projectModels.length} projects with their points',
      );
      return projectModels;
    } catch (e) {
      _logger.severe('Error getting all projects: $e');
      rethrow;
    }
  }

  Future<ProjectModel?> getProjectById(String id) async {
    _logger.info('Getting project by ID: $id');
    try {
      final db = await database;
      final project = await db.getProjectById(id);
      if (project == null) {
        _logger.warning('Project not found with ID: $id');
        return null;
      }

      final points = await getPointsForProject(id);
      final result = _projectFromDrift(project, points);
      _logger.info(
        'Retrieved project: ${result.name} with ${points.length} points',
      );
      return result;
    } catch (e) {
      _logger.severe('Error getting project by ID $id: $e');
      rethrow;
    }
  }

  Future<int> insertProject(ProjectModel project) async {
    _logger.info('Inserting project: ${project.name}');
    try {
      final db = await database;
      final projectToInsert = project.copyWith(lastUpdate: DateTime.now());
      final companion = _projectToDriftCompanion(projectToInsert);
      final id = await db.insertProject(companion);
      _logger.info('Project inserted successfully with ID: $id');
      return id;
    } catch (e) {
      _logger.severe('Error inserting project: $e');
      rethrow;
    }
  }

  Future<int> updateProject(ProjectModel project) async {
    _logger.info('Updating project: ${project.name} (${project.id})');
    try {
      final db = await database;
      final projectToUpdate = project.copyWith(lastUpdate: DateTime.now());
      final companion = _projectToDriftCompanion(projectToUpdate);
      final success = await db.updateProject(companion);
      final result = success ? 1 : 0;
      _logger.info('Project update ${success ? 'succeeded' : 'failed'}');
      return result;
    } catch (e) {
      _logger.severe('Error updating project: $e');
      rethrow;
    }
  }

  Future<int> deleteProject(String id) async {
    _logger.info('Deleting project: $id');
    try {
      final db = await database;
      final deleted = await db.deleteProject(id);
      _logger.info('Project deleted successfully. Deleted $deleted record(s)');
      return deleted;
    } catch (e) {
      _logger.severe('Error deleting project $id: $e');
      rethrow;
    }
  }

  // Point Methods
  Future<String> insertPoint(PointModel point) async {
    _logger.info(
      'Inserting point: ${point.id} for project: ${point.projectId}',
    );
    try {
      final db = await database;

      await db.transaction(() async {
        _logger.fine('Starting transaction for point insertion');

        // Insert the point
        final pointCompanion = _pointToDriftCompanion(point);
        await db.insertPoint(pointCompanion);
        _logger.fine('Point inserted successfully');

        // Insert associated images
        if (point.images.isNotEmpty) {
          _logger.fine('Inserting ${point.images.length} images for point');
          for (final image in point.images) {
            final imageCompanion = _imageToDriftCompanion(image);
            await db.insertImage(imageCompanion);
          }
          _logger.fine('All images inserted successfully');
        }

        _logger.fine('Transaction completed successfully');
      });

      // Update project timestamp
      await _updateProjectTimestamp(point.projectId);
      _logger.info('Point insertion completed successfully');
      return point.id;
    } catch (e) {
      _logger.severe('Error inserting point: $e');
      rethrow;
    }
  }

  Future<int> updatePoint(PointModel point) async {
    _logger.info('Updating point: ${point.id}');
    try {
      final db = await database;

      // Update the point
      final pointCompanion = _pointToDriftCompanion(point);
      final success = await db.updatePoint(pointCompanion);

      if (success) {
        _logger.fine('Point updated successfully, now updating images');

        // Delete existing images for this point
        final existingImages = await db.getImagesForPoint(point.id);
        _logger.fine(
          'Found ${existingImages.length} existing images to delete',
        );
        for (final image in existingImages) {
          await db.deleteImage(image.id);
        }

        // Insert new images
        if (point.images.isNotEmpty) {
          _logger.fine('Inserting ${point.images.length} new images');
          for (final image in point.images) {
            final imageCompanion = _imageToDriftCompanion(image);
            await db.insertImage(imageCompanion);
          }
        }

        await _updateProjectTimestamp(point.projectId);
        _logger.info('Point update completed successfully');
      } else {
        _logger.warning('Point update failed - point not found');
      }

      return success ? 1 : 0;
    } catch (e) {
      _logger.severe('Error updating point: $e');
      rethrow;
    }
  }

  Future<int> deletePointById(String pointIdToDelete) async {
    _logger.info('Deleting point by ID: $pointIdToDelete');
    try {
      final db = await database;
      final deleted = await db.deletePoint(pointIdToDelete);
      _logger.info('Point deleted successfully. Deleted $deleted record(s)');
      return deleted;
    } catch (e) {
      _logger.severe('Error deleting point $pointIdToDelete: $e');
      rethrow;
    }
  }

  Future<PointModel?> getPointById(String id) async {
    _logger.info('Getting point by ID: $id');
    try {
      final db = await database;
      final pointWithImages = await db.getPointWithImages(id);
      if (pointWithImages == null) {
        _logger.warning('Point not found with ID: $id');
        return null;
      }

      final result = _pointFromDrift(
        pointWithImages.point,
        pointWithImages.images,
      );
      _logger.info(
        'Retrieved point with ${pointWithImages.images.length} images',
      );
      return result;
    } catch (e) {
      _logger.severe('Error getting point by ID $id: $e');
      rethrow;
    }
  }

  Future<int?> getLastPointOrdinal(String projectId) async {
    _logger.fine('Getting last point ordinal for project: $projectId');
    // No ordinal management in the new DB
    return null;
  }

  // Image Methods
  Future<String> insertImage(ImageModel image) async {
    _logger.info('Inserting image: ${image.id} for point: ${image.pointId}');
    try {
      final db = await database;
      final companion = _imageToDriftCompanion(image);
      await db.insertImage(companion);

      // Update project timestamp
      PointModel? point = await getPointById(image.pointId);
      if (point != null) {
        await _updateProjectTimestamp(point.projectId);
      }

      _logger.info('Image inserted successfully');
      return image.id;
    } catch (e) {
      _logger.severe('Error inserting image: $e');
      rethrow;
    }
  }

  Future<int> updateImage(ImageModel image) async {
    _logger.info('Updating image: ${image.id}');
    try {
      final db = await database;
      final companion = _imageToDriftCompanion(image);
      final success = await db.updateImage(companion);

      if (success) {
        PointModel? point = await getPointById(image.pointId);
        if (point != null) {
          await _updateProjectTimestamp(point.projectId);
        }
        _logger.info('Image updated successfully');
      } else {
        _logger.warning('Image update failed - image not found');
      }

      return success ? 1 : 0;
    } catch (e) {
      _logger.severe('Error updating image: $e');
      rethrow;
    }
  }

  Future<int> deleteImage(String id) async {
    _logger.info('Deleting image: $id');
    try {
      final db = await database;
      ImageModel? image = await getImageById(id);
      final result = await db.deleteImage(id);

      if (result > 0 && image != null) {
        PointModel? point = await getPointById(image.pointId);
        if (point != null) {
          await _updateProjectTimestamp(point.projectId);
        }
        _logger.info('Image deleted successfully');
      } else {
        _logger.warning('Image not found or already deleted');
      }

      return result;
    } catch (e) {
      _logger.severe('Error deleting image $id: $e');
      rethrow;
    }
  }

  Future<ImageModel?> getImageById(String id) async {
    _logger.fine('Getting image by ID: $id');
    try {
      final db = await database;
      final image = await db.getImageById(id);
      if (image == null) {
        _logger.fine('Image not found with ID: $id');
        return null;
      }

      final result = _imageFromDrift(image);
      _logger.fine('Image found: ${result.imagePath}');
      return result;
    } catch (e) {
      _logger.severe('Error getting image by ID $id: $e');
      rethrow;
    }
  }

  // Helper Methods
  Future<void> _updateProjectTimestamp(String projectId) async {
    _logger.fine('Updating project timestamp: $projectId');
    try {
      final db = await database;
      await db.updateProjectTimestamp(projectId);
      _logger.fine('Project timestamp updated successfully');
    } catch (e) {
      _logger.severe('Error updating project timestamp $projectId: $e');
      rethrow;
    }
  }

  Future<List<PointModel>> getPointsForProject(String projectId) async {
    _logger.fine('Getting points for project: $projectId');
    try {
      final db = await database;
      final points = await db.getPointsForProject(projectId);

      List<PointModel> pointModels = [];
      for (final point in points) {
        final images = await db.getImagesForPoint(point.id);
        pointModels.add(_pointFromDrift(point, images));
      }

      _logger.fine(
        'Retrieved ${pointModels.length} points for project $projectId',
      );
      return pointModels;
    } catch (e) {
      _logger.severe('Error getting points for project $projectId: $e');
      rethrow;
    }
  }

  Future<int> deletePointsByIds(List<String> ids) async {
    if (ids.isEmpty) {
      _logger.fine('No points to delete - empty list provided');
      return 0;
    }

    _logger.info('Deleting ${ids.length} points: ${ids.join(', ')}');
    try {
      final db = await database;
      int totalDeleted = 0;

      for (final id in ids) {
        final deleted = await db.deletePoint(id);
        totalDeleted += deleted;
      }

      _logger.info('Successfully deleted $totalDeleted points');
      return totalDeleted;
    } catch (e) {
      _logger.severe('Error deleting points: $e');
      rethrow;
    }
  }

  Future<List<ImageModel>> getImagesForPoint(String pointId) async {
    _logger.fine('Getting images for point: $pointId');
    try {
      final db = await database;
      final images = await db.getImagesForPoint(pointId);
      final result = images.map(_imageFromDrift).toList();
      _logger.fine('Retrieved ${result.length} images for point $pointId');
      return result;
    } catch (e) {
      _logger.severe('Error getting images for point $pointId: $e');
      rethrow;
    }
  }

  Future<void> deletePointAndAssociatedData(String pointId) async {
    _logger.info('Deleting point and associated data: $pointId');
    try {
      final db = await database;

      await db.transaction(() async {
        _logger.fine('Starting transaction for point deletion');

        // Delete images first (cascade should handle this, but explicit for safety)
        final images = await db.getImagesForPoint(pointId);
        _logger.fine('Found ${images.length} images to delete');
        for (final image in images) {
          await db.deleteImage(image.id);
        }

        // Delete the point
        await db.deletePoint(pointId);
        _logger.fine('Point deleted successfully');

        _logger.fine('Transaction completed successfully');
      });

      // Also delete the physical photo directory
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final pointPhotosDir = Directory(
          join(appDocDir.path, 'point_photos', pointId),
        );
        if (await pointPhotosDir.exists()) {
          await pointPhotosDir.delete(recursive: true);
          _logger.fine('Deleted photo directory for point $pointId');
        } else {
          _logger.fine('Photo directory does not exist for point $pointId');
        }
      } catch (e) {
        _logger.severe('Error deleting photo directory for point $pointId: $e');
      }

      _logger.info('Point and associated data deleted successfully');
    } catch (e) {
      _logger.severe('Error deleting point and associated data $pointId: $e');
      rethrow;
    }
  }

  Future close() async {
    _logger.info('Closing database connection');
    try {
      final db = await database;
      await db.close();
      _logger.info('Database connection closed successfully');
    } catch (e) {
      _logger.severe('Error closing database connection: $e');
      rethrow;
    }
  }

  // Conversion methods between Drift and Model classes
  ProjectModel _projectFromDrift(Project project, List<PointModel> points) {
    _logger.fine('Converting Drift Project to ProjectModel: ${project.name}');
    return ProjectModel(
      id: project.id,
      name: project.name,
      note: project.note ?? '',
      azimuth: project.azimuth,
      lastUpdate: project.lastUpdate != null
          ? DateTime.tryParse(project.lastUpdate!)
          : null,
      date: project.date != null ? DateTime.tryParse(project.date!) : null,
      points: points,
      presumedTotalLength: project.presumedTotalLength,
    );
  }

  ProjectCompanion _projectToDriftCompanion(ProjectModel project) {
    _logger.fine(
      'Converting ProjectModel to ProjectCompanion: ${project.name}',
    );
    return ProjectCompanion(
      id: Value(project.id),
      name: Value(project.name),
      note: Value(project.note.isEmpty ? null : project.note),
      azimuth: Value(project.azimuth),
      lastUpdate: Value(project.lastUpdate?.toIso8601String()),
      date: Value(project.date?.toIso8601String()),
      presumedTotalLength: Value(project.presumedTotalLength),
    );
  }

  PointModel _pointFromDrift(Point point, List<Image> images) {
    _logger.fine('Converting Drift Point to PointModel: ${point.id}');
    return PointModel(
      id: point.id,
      projectId: point.projectId,
      latitude: point.latitude,
      longitude: point.longitude,
      altitude: point.altitude,
      gpsPrecision: point.gpsPrecision,
      ordinalNumber: point.ordinalNumber,
      note: point.note ?? '',
      timestamp: point.timestamp != null
          ? DateTime.tryParse(point.timestamp!)
          : null,
      images: images.map(_imageFromDrift).toList(),
    );
  }

  PointCompanion _pointToDriftCompanion(PointModel point) {
    _logger.fine('Converting PointModel to PointCompanion: ${point.id}');
    return PointCompanion(
      id: Value(point.id),
      projectId: Value(point.projectId),
      latitude: Value(point.latitude),
      longitude: Value(point.longitude),
      altitude: Value(point.altitude),
      gpsPrecision: Value(point.gpsPrecision),
      ordinalNumber: Value(point.ordinalNumber),
      note: Value(point.note.isEmpty ? null : point.note),
      timestamp: Value(point.timestamp?.toIso8601String()),
    );
  }

  ImageModel _imageFromDrift(Image image) {
    _logger.fine('Converting Drift Image to ImageModel: ${image.id}');
    return ImageModel(
      id: image.id,
      pointId: image.pointId,
      ordinalNumber: image.ordinalNumber,
      imagePath: image.imagePath,
      note: image.note ?? '',
    );
  }

  ImageCompanion _imageToDriftCompanion(ImageModel image) {
    _logger.fine('Converting ImageModel to ImageCompanion: ${image.id}');
    return ImageCompanion(
      id: Value(image.id),
      pointId: Value(image.pointId),
      ordinalNumber: Value(image.ordinalNumber),
      imagePath: Value(image.imagePath),
      note: Value(image.note.isEmpty ? null : image.note),
    );
  }
}
