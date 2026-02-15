// drift_database_helper.dart
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';

import 'package:teleferika/core/utils/uuid_generator.dart';

import 'converters/drift_converters.dart';
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

  late final ImageConverter _imageConverter;
  late final PointConverter _pointConverter;
  late final ProjectConverter _projectConverter;

  DriftDatabaseHelper._privateConstructor() {
    _logger.info('DriftDatabaseHelper instance created');
    _imageConverter = ImageConverter(logger: _logger);
    _pointConverter = PointConverter(
      logger: _logger,
      imageConverter: _imageConverter,
    );
    _projectConverter = ProjectConverter(logger: _logger);
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
      // Single join query for projects + points (avoids N+1)
      final projectsWithPoints = await db.getAllProjectsWithPointsJoined();

      // Batch-load all images for all points in one query
      final allPointIds = projectsWithPoints
          .expand((p) => p.points.map((pt) => pt.id))
          .toList();
      final imagesByPointId = await db.getImagesForPointIds(allPointIds);

      final List<ProjectModel> projectModels = [];
      for (final row in projectsWithPoints) {
        final pointModels = row.points
            .map((point) => _pointConverter.fromDrift(
                  point,
                  imagesByPointId[point.id] ?? [],
                ))
            .toList();
        projectModels.add(_projectConverter.fromDrift(row.project, pointModels));
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
      final result = _projectConverter.fromDrift(project, points);
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
      _logger.fine(
        'Database instance obtained, preparing project for insertion',
      );
      final projectToInsert = project.copyWith(lastUpdate: DateTime.now());
      _logger.fine(
        'Project prepared with lastUpdate: ${projectToInsert.lastUpdate}',
      );
      final companion = _projectConverter.toCompanion(projectToInsert);
      _logger.fine('ProjectCompanion created, calling db.insertProject');
      final id = await db.insertProject(companion);
      _logger.info('Project inserted successfully with ID: $id');
      return id;
    } catch (e, stackTrace) {
      _logger.severe('Error inserting project: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<int> updateProject(ProjectModel project) async {
    _logger.info('Updating project: ${project.name} (${project.id})');
    try {
      final db = await database;
      final projectToUpdate = project.copyWith(lastUpdate: DateTime.now());
      final companion = _projectConverter.toCompanion(projectToUpdate);
      final success = await db.updateProject(companion);
      final result = success ? 1 : 0;
      _logger.info('Project update ${success ? 'succeeded' : 'failed'}');
      return result;
    } catch (e) {
      _logger.severe('Error updating project: $e');
      rethrow;
    }
  }

  /// Updates only the profile chart height for a project (does not set lastUpdate or dirty state).
  Future<void> updateProjectProfileChartHeight(
    String projectId,
    double? height,
  ) async {
    _logger.fine('Updating project $projectId profileChartHeight: $height');
    try {
      final db = await database;
      await db.updateProjectProfileChartHeight(projectId, height);
      _logger.fine('Project profileChartHeight updated');
    } catch (e) {
      _logger.severe(
        'Error updating project profileChartHeight $projectId: $e',
      );
      rethrow;
    }
  }

  /// Updates only the plan profile chart height (does not set lastUpdate or dirty state).
  Future<void> updateProjectPlanProfileChartHeight(
    String projectId,
    double? height,
  ) async {
    _logger.fine('Updating project $projectId planProfileChartHeight: $height');
    try {
      final db = await database;
      await db.updateProjectPlanProfileChartHeight(projectId, height);
      _logger.fine('Project planProfileChartHeight updated');
    } catch (e) {
      _logger.severe(
        'Error updating project planProfileChartHeight $projectId: $e',
      );
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

  // Cable type methods
  Future<List<CableType>> getAllCableTypes() async {
    _logger.info('Getting all cable types');
    try {
      final db = await database;
      return await db.getAllCableTypes();
    } catch (e) {
      _logger.severe('Error getting cable types: $e');
      rethrow;
    }
  }

  Future<CableType?> getCableTypeById(String id) async {
    _logger.info('Getting cable type by ID: $id');
    try {
      final db = await database;
      return await db.getCableTypeById(id);
    } catch (e) {
      _logger.severe('Error getting cable type $id: $e');
      rethrow;
    }
  }

  Future<String> insertCableType({
    required String name,
    required double diameterMm,
    required double weightPerMeterKg,
    required double breakingLoadKn,
    double? elasticModulusGPa,
    int sortOrder = 1000,
  }) async {
    _logger.info('Inserting cable type: $name');
    try {
      final db = await database;
      final id = generateUuid();
      final companion = CableTypeCompanion.insert(
        id: id,
        name: name,
        diameterMm: diameterMm,
        weightPerMeterKg: weightPerMeterKg,
        breakingLoadKn: breakingLoadKn,
        elasticModulusGPa: elasticModulusGPa != null
            ? Value(elasticModulusGPa)
            : const Value.absent(),
        sortOrder: Value(sortOrder),
      );
      await db.insertCableType(companion);
      _logger.info('Cable type inserted with ID: $id');
      return id;
    } catch (e, stackTrace) {
      _logger.severe('Error inserting cable type: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> updateCableType(CableType cableType) async {
    _logger.info('Updating cable type: ${cableType.id}');
    try {
      final db = await database;
      final companion = CableTypeCompanion(
        id: Value(cableType.id),
        name: Value(cableType.name),
        diameterMm: Value(cableType.diameterMm),
        weightPerMeterKg: Value(cableType.weightPerMeterKg),
        breakingLoadKn: Value(cableType.breakingLoadKn),
        elasticModulusGPa: Value(cableType.elasticModulusGPa),
        sortOrder: Value(cableType.sortOrder),
      );
      return await db.updateCableType(companion);
    } catch (e) {
      _logger.severe('Error updating cable type: $e');
      rethrow;
    }
  }

  Future<List<Project>> getProjectsUsingCableType(String cableTypeId) async {
    try {
      final db = await database;
      return await db.getProjectsUsingCableType(cableTypeId);
    } catch (e) {
      _logger.severe('Error getting projects using cable type: $e');
      rethrow;
    }
  }

  Future<int> deleteCableType(String id) async {
    _logger.info('Deleting cable type: $id');
    try {
      final db = await database;
      await db.clearCableTypeFromProjects(id);
      return await db.deleteCableType(id);
    } catch (e) {
      _logger.severe('Error deleting cable type $id: $e');
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
        final pointCompanion = _pointConverter.toCompanion(point);
        await db.insertPoint(pointCompanion);
        _logger.fine('Point inserted successfully');

        // Batch insert associated images (more efficient than individual inserts)
        if (point.images.isNotEmpty) {
          _logger.fine(
            'Batch inserting ${point.images.length} images for point',
          );
          final imageCompanions = point.images
              .map((image) => _imageConverter.toCompanion(image))
              .toList();
          await db.insertImages(imageCompanions);
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
      final pointCompanion = _pointConverter.toCompanion(point);
      final success = await db.updatePoint(pointCompanion);

      if (success) {
        _logger.fine('Point updated successfully, now updating images');

        // Batch delete existing images for this point (more efficient)
        final existingImages = await db.getImagesForPoint(point.id);
        _logger.fine(
          'Found ${existingImages.length} existing images to delete',
        );
        if (existingImages.isNotEmpty) {
          final imageIds = existingImages.map((img) => img.id).toList();
          await db.deleteImagesByIds(imageIds);
        }

        // Batch insert new images (more efficient than individual inserts)
        if (point.images.isNotEmpty) {
          _logger.fine('Batch inserting ${point.images.length} new images');
          final imageCompanions = point.images
              .map((image) => _imageConverter.toCompanion(image))
              .toList();
          await db.insertImages(imageCompanions);
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

      final result = _pointConverter.fromDrift(
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
      final companion = _imageConverter.toCompanion(image);
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
      final companion = _imageConverter.toCompanion(image);
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

      final result = _imageConverter.fromDrift(image);
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
        pointModels.add(_pointConverter.fromDrift(point, images));
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
      final result = images.map(_imageConverter.fromDrift).toList();
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

        // Batch delete images first (cascade should handle this, but explicit for safety)
        final images = await db.getImagesForPoint(pointId);
        _logger.fine('Found ${images.length} images to delete');
        if (images.isNotEmpty) {
          final imageIds = images.map((img) => img.id).toList();
          await db.deleteImagesByIds(imageIds);
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

  /// Closes the database connection. Call on app termination to release resources.
  /// After calling, [database] will create a new connection if accessed again.
  Future close() async {
    _logger.info('Closing database connection');
    try {
      final db = _database;
      _database = null;
      if (db != null) {
        await db.close();
        _logger.info('Database connection closed successfully');
      }
    } catch (e) {
      _logger.severe('Error closing database connection: $e');
      rethrow;
    }
  }

  // NTRIP Methods
  Future<List<NtripSetting>> getAllNtripSettings() async {
    _logger.info('Getting all NTRIP settings');
    try {
      final db = await database;
      final settings = await db.getAllNtripSettings();
      _logger.info('Retrieved ${settings.length} NTRIP settings');
      return settings;
    } catch (e) {
      _logger.severe('Error getting all NTRIP settings: $e');
      rethrow;
    }
  }

  Future<List<NtripSetting>> getNtripSettingsByCountry(String country) async {
    _logger.info('Getting NTRIP settings for country: $country');
    try {
      final db = await database;
      final settings = await db.getNtripSettingsByCountry(country);
      _logger.info('Retrieved ${settings.length} NTRIP settings for $country');
      return settings;
    } catch (e) {
      _logger.severe('Error getting NTRIP settings by country: $e');
      rethrow;
    }
  }

  Future<List<NtripSetting>> getNtripSettingsByCountryAndState(
    String country,
    String? state,
  ) async {
    _logger.info('Getting NTRIP settings for country: $country, state: $state');
    try {
      final db = await database;
      final settings = await db.getNtripSettingsByCountryAndState(
        country,
        state,
      );
      _logger.info(
        'Retrieved ${settings.length} NTRIP settings for $country, $state',
      );
      return settings;
    } catch (e) {
      _logger.severe('Error getting NTRIP settings by country and state: $e');
      rethrow;
    }
  }

  Future<NtripSetting?> getNtripSettingById(int id) async {
    _logger.info('Getting NTRIP setting by ID: $id');
    try {
      final db = await database;
      final settings = await db.getNtripSettingById(id);
      _logger.info('Retrieved NTRIP setting');
      return settings;
    } catch (e) {
      _logger.severe('Error getting NTRIP setting by ID: $e');
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Future<NtripSetting?> getNtripSettings() async {
    _logger.info('Getting first NTRIP settings (legacy method)');
    try {
      final db = await database;
      final settings = await db.getNtripSettings();
      _logger.info('Retrieved NTRIP settings');
      return settings;
    } catch (e) {
      _logger.severe('Error getting NTRIP settings: $e');
      rethrow;
    }
  }

  Future<int> insertNtripSetting(NtripSettingCompanion settings) async {
    _logger.info('Inserting NTRIP setting: ${settings.name.value}');
    try {
      final db = await database;
      final id = await db.insertNtripSetting(settings);
      _logger.info('Inserted NTRIP setting with ID: $id');
      return id;
    } catch (e) {
      _logger.severe('Error inserting NTRIP setting: $e');
      rethrow;
    }
  }

  Future<bool> updateNtripSetting(NtripSettingCompanion settings) async {
    _logger.info('Updating NTRIP setting: ${settings.id.value}');
    try {
      final db = await database;
      final success = await db.updateNtripSetting(settings);
      _logger.info('NTRIP setting update ${success ? 'succeeded' : 'failed'}');
      return success;
    } catch (e) {
      _logger.severe('Error updating NTRIP setting: $e');
      rethrow;
    }
  }

  Future<int> deleteNtripSetting(int id) async {
    _logger.info('Deleting NTRIP setting: $id');
    try {
      final db = await database;
      final deleted = await db.deleteNtripSetting(id);
      _logger.info('Deleted $deleted NTRIP setting(s)');
      return deleted;
    } catch (e) {
      _logger.severe('Error deleting NTRIP setting: $e');
      rethrow;
    }
  }

  Future<int> deleteAllNtripSettings() async {
    _logger.info('Deleting all NTRIP settings');
    try {
      final db = await database;
      final deleted = await db.deleteAllNtripSettings();
      _logger.info('Deleted $deleted NTRIP setting(s)');
      return deleted;
    } catch (e) {
      _logger.severe('Error deleting all NTRIP settings: $e');
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Future<void> saveNtripSettings(NtripSettingCompanion settings) async {
    _logger.info('Saving NTRIP settings (legacy method)');
    try {
      final db = await database;
      await db.saveNtripSettings(settings);
      _logger.info('Saved NTRIP settings');
    } catch (e) {
      _logger.severe('Error saving NTRIP settings: $e');
      rethrow;
    }
  }
}
