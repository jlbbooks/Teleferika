// sqlite_migration_helper.dart
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models/image_model.dart';
import 'models/point_model.dart';
import 'models/project_model.dart';
import 'drift_database_helper.dart';

/// Helper class to migrate data from the old sqflite database to the new drift database.
///
/// This class handles the migration of existing user data when upgrading from
/// the old sqflite implementation to the new drift implementation.
class SqliteMigrationHelper {
  static final Logger _logger = Logger('SqliteMigrationHelper');
  static const String _oldDatabaseName = "Photogrammetry.db";

  /// Checks if there's an old sqflite database that needs migration
  static Future<bool> hasOldDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final oldDbPath = join(databasesPath, _oldDatabaseName);
      final oldDbFile = File(oldDbPath);

      if (await oldDbFile.exists()) {
        _logger.info('Found old sqflite database at: $oldDbPath');
        return true;
      }

      _logger.info('No old sqflite database found');
      return false;
    } catch (e) {
      _logger.warning('Error checking for old database: $e');
      return false;
    }
  }

  /// Migrates data from the old sqflite database to the new drift database
  static Future<bool> migrateOldDatabase() async {
    if (!await hasOldDatabase()) {
      _logger.info('No old database to migrate');
      return true;
    }

    try {
      _logger.info('Starting migration from sqflite to drift');

      // Open the old database
      final databasesPath = await getDatabasesPath();
      final oldDbPath = join(databasesPath, _oldDatabaseName);
      final oldDb = await openDatabase(oldDbPath, readOnly: true);

      _logger.info('Opened old database for reading');

      // Migrate projects
      final projects = await _migrateProjects(oldDb);
      _logger.info('Migrated ${projects.length} projects');

      // Migrate points and images
      for (final project in projects) {
        final points = await _migratePointsForProject(oldDb, project.id);
        _logger.info(
          'Migrated ${points.length} points for project ${project.name}',
        );
      }

      await oldDb.close();
      _logger.info('Migration completed successfully');

      // Optionally, backup the old database
      await _backupOldDatabase(oldDbPath);

      return true;
    } catch (e) {
      _logger.severe('Migration failed: $e');
      return false;
    }
  }

  /// Migrates projects from the old database
  static Future<List<ProjectModel>> _migrateProjects(Database oldDb) async {
    final List<Map<String, dynamic>> projectMaps = await oldDb.query(
      ProjectModel.tableName,
      orderBy: '${ProjectModel.columnLastUpdate} DESC',
    );

    final List<ProjectModel> projects = [];
    final dbHelper = DriftDatabaseHelper.instance;

    for (final projectMap in projectMaps) {
      try {
        final project = ProjectModel.fromMap(projectMap);

        // Insert into new database
        await dbHelper.insertProject(project);
        projects.add(project);

        _logger.fine('Migrated project: ${project.name}');
      } catch (e) {
        _logger.warning(
          'Failed to migrate project ${projectMap[ProjectModel.columnName]}: $e',
        );
      }
    }

    return projects;
  }

  /// Migrates points and images for a specific project
  static Future<List<PointModel>> _migratePointsForProject(
    Database oldDb,
    String projectId,
  ) async {
    final List<Map<String, dynamic>> pointMaps = await oldDb.query(
      PointModel.tableName,
      where: '${PointModel.columnProjectId} = ?',
      whereArgs: [projectId],
      orderBy: '${PointModel.columnOrdinalNumber} ASC',
    );

    final List<PointModel> points = [];
    final dbHelper = DriftDatabaseHelper.instance;

    for (final pointMap in pointMaps) {
      try {
        // Get images for this point
        final List<Map<String, dynamic>> imageMaps = await oldDb.query(
          ImageModel.tableName,
          where: '${ImageModel.columnPointId} = ?',
          whereArgs: [pointMap[PointModel.columnId]],
          orderBy: '${ImageModel.columnOrdinalNumber} ASC',
        );

        final List<ImageModel> images = imageMaps.map((imageMap) {
          return ImageModel.fromMap(imageMap);
        }).toList();

        // Create point with images
        final point = PointModel.fromMap(pointMap, images: images);

        // Insert into new database
        await dbHelper.insertPoint(point);
        points.add(point);

        _logger.fine('Migrated point ${point.id} with ${images.length} images');
      } catch (e) {
        _logger.warning(
          'Failed to migrate point ${pointMap[PointModel.columnId]}: $e',
        );
      }
    }

    return points;
  }

  /// Creates a backup of the old database before migration
  static Future<void> _backupOldDatabase(String oldDbPath) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(join(appDocDir.path, 'database_backups'));

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = join(
        backupDir.path,
        'Photogrammetry_backup_$timestamp.db',
      );

      await File(oldDbPath).copy(backupPath);
      _logger.info('Created backup of old database at: $backupPath');
    } catch (e) {
      _logger.warning('Failed to create backup of old database: $e');
    }
  }

  /// Removes the old database after successful migration
  static Future<void> removeOldDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final oldDbPath = join(databasesPath, _oldDatabaseName);
      final oldDbFile = File(oldDbPath);

      if (await oldDbFile.exists()) {
        await oldDbFile.delete();
        _logger.info('Removed old sqflite database');
      }
    } catch (e) {
      _logger.warning('Failed to remove old database: $e');
    }
  }

  /// Gets migration statistics
  static Future<Map<String, int>> getMigrationStats() async {
    if (!await hasOldDatabase()) {
      return {'projects': 0, 'points': 0, 'images': 0};
    }

    try {
      final databasesPath = await getDatabasesPath();
      final oldDbPath = join(databasesPath, _oldDatabaseName);
      final oldDb = await openDatabase(oldDbPath, readOnly: true);

      final projectCount =
          Sqflite.firstIntValue(
            await oldDb.rawQuery(
              'SELECT COUNT(*) FROM ${ProjectModel.tableName}',
            ),
          ) ??
          0;

      final pointCount =
          Sqflite.firstIntValue(
            await oldDb.rawQuery(
              'SELECT COUNT(*) FROM ${PointModel.tableName}',
            ),
          ) ??
          0;

      final imageCount =
          Sqflite.firstIntValue(
            await oldDb.rawQuery(
              'SELECT COUNT(*) FROM ${ImageModel.tableName}',
            ),
          ) ??
          0;

      await oldDb.close();

      return {
        'projects': projectCount,
        'points': pointCount,
        'images': imageCount,
      };
    } catch (e) {
      _logger.warning('Failed to get migration stats: $e');
      return {'projects': 0, 'points': 0, 'images': 0};
    }
  }
}
