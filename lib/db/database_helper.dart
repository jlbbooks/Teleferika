// database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../logger.dart';
import 'models/image_model.dart';
import 'models/point_model.dart';
import 'models/project_model.dart';

class DatabaseHelper {
  static const _databaseName = "Photogrammetry.db";

  static const _databaseVersion = 5; // Incremented due to schema change

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Called when the database is created for the first time
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${ProjectModel.tableName} (
        ${ProjectModel.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${ProjectModel.columnName} TEXT NOT NULL,
        ${ProjectModel.columnStartingPointId} INTEGER,
        ${ProjectModel.columnEndingPointId} INTEGER,
        ${ProjectModel.columnAzimuth} REAL,
        ${ProjectModel.columnNote} TEXT,
        ${ProjectModel.columnLastUpdate} TEXT,
        ${ProjectModel.columnDate} TEXT,
        FOREIGN KEY (${ProjectModel.columnStartingPointId}) REFERENCES ${PointModel.tableName} (${PointModel.columnId}) ON DELETE SET NULL,
        FOREIGN KEY (${ProjectModel.columnEndingPointId}) REFERENCES ${PointModel.tableName} (${PointModel.columnId}) ON DELETE SET NULL
      )
    '''); // TEXT for ISO8601 DateTime string

    await db.execute('''
    CREATE TABLE ${PointModel.tableName} (
      ${PointModel.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${PointModel.columnProjectId} INTEGER NOT NULL,
      ${PointModel.columnLatitude} REAL NOT NULL,
      ${PointModel.columnLongitude} REAL NOT NULL,
      ${PointModel.columnOrdinalNumber} INTEGER NOT NULL,
      ${PointModel.columnNote} TEXT,
      ${PointModel.columnHeading} REAL,         
      ${PointModel.columnTimestamp} TEXT,       
    FOREIGN KEY (${PointModel.columnProjectId}) REFERENCES ${ProjectModel.tableName} (${ProjectModel.columnId}) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
      CREATE TABLE ${ImageModel.tableName} (
        ${ImageModel.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${ImageModel.columnPointId} INTEGER NOT NULL,
        ${ImageModel.columnOrdinalNumber} INTEGER NOT NULL,
        ${ImageModel.columnImagePath} TEXT NOT NULL,
        FOREIGN KEY (${ImageModel.columnPointId}) REFERENCES ${PointModel.tableName} (${PointModel.columnId}) ON DELETE CASCADE
      )
    ''');
  }

  // Called when the database needs to be upgraded
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add last_update column to projects table if upgrading from version 1
      await db.execute(
        'ALTER TABLE ${ProjectModel.tableName} ADD COLUMN $ProjectModel.columnLastUpdate TEXT',
      );
      // You might want to populate existing rows with a default last_update value here
      // For example, setting it to the current time for existing projects:
      String now = DateTime.now().toIso8601String();
      await db.rawUpdate(
        'UPDATE ${ProjectModel.tableName} SET $ProjectModel.columnLastUpdate = ? WHERE $ProjectModel.columnLastUpdate IS NULL',
        [now],
      );
      logger.info("Applied migrations for version 2");
    }
    // Add more migration steps here for future versions
    if (oldVersion < 3) {
      // Add note column to projects table if upgrading from version 2
      await db.execute(
        'ALTER TABLE ${ProjectModel.tableName} ADD COLUMN ${ProjectModel.columnNote} TEXT',
      );
      logger.info(
        "Applied migrations for version 3: Added ${ProjectModel.columnNote} column",
      );
    }
    if (oldVersion < 4) {
      // Add note column to projects table if upgrading from version 2
      await db.execute(
        'ALTER TABLE ${ProjectModel.tableName} ADD COLUMN $ProjectModel.columnDate TEXT',
      );
      logger.info(
        "Applied migrations for version 4: Added $ProjectModel.columnDate column",
      );
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
          'ALTER TABLE ${PointModel.tableName} ADD COLUMN ${PointModel.columnHeading} REAL;',
        );
        logger.info(
          "Applied migration for version 5: Added ${PointModel.columnHeading} REAL to ${PointModel.tableName}",
        );
      } catch (e) {
        // Log error but continue, column might exist if migration was partially run before
        logger.warning(
          "Could not add ${PointModel.columnHeading} to ${PointModel.tableName} (may already exist): $e",
        );
      }
      try {
        await db.execute(
          'ALTER TABLE ${PointModel.tableName} ADD COLUMN ${PointModel.columnTimestamp} TEXT;',
        );
        logger.info(
          "Applied migration for version 5: Added ${PointModel.columnTimestamp} TEXT to ${PointModel.tableName}",
        );
      } catch (e) {
        logger.warning(
          "Could not add ${PointModel.columnTimestamp} to ${PointModel.tableName} (may already exist): $e",
        );
      }
    }
    logger.info("Database upgrade process complete.");
  }

  // --- Project Methods ---
  Future<int> insertProject(ProjectModel project) async {
    Database db = await instance.database;
    // Set lastUpdate to now before inserting
    project.lastUpdate = DateTime.now();
    return await db.insert(ProjectModel.tableName, project.toMap());
  }

  Future<List<ProjectModel>> getAllProjects() async {
    Database db = await instance.database;
    // Order by last_update DESC
    final List<Map<String, dynamic>> maps = await db.query(
      ProjectModel.tableName,
      orderBy:
          '${ProjectModel.columnLastUpdate} DESC', // Sort by last update, newest first
    );
    return List.generate(maps.length, (i) {
      return ProjectModel.fromMap(maps[i]);
    });
  }

  Future<ProjectModel?> getProjectById(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      ProjectModel.tableName,
      where: '${ProjectModel.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ProjectModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProject(ProjectModel project) async {
    Database db = await instance.database;
    // Update lastUpdate to now before updating
    project.lastUpdate = DateTime.now();
    return await db.update(
      ProjectModel.tableName,
      project.toMap(),
      where: '${ProjectModel.columnId} = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> setProjectStartingPoint(int projectId, int? pointId) async {
    Database db = await instance.database;
    // Also update last_update for the project
    String now = DateTime.now().toIso8601String();
    return await db.update(
      ProjectModel.tableName,
      {
        ProjectModel.columnStartingPointId: pointId,
        ProjectModel.columnLastUpdate: now,
      },
      where: '${ProjectModel.columnId} = ?',
      whereArgs: [projectId],
    );
  }

  /// Fetches all points for a project, sorted by ordinal,
  /// and updates the project's starting_point_id and ending_point_id.
  /// Can be called within a transaction by passing the txn object.
  Future<void> updateProjectStartEndPoints(
    int projectId, {
    Transaction? txn,
  }) async {
    final dbOrTxn =
        txn ?? await instance.database; // Use transaction if provided

    final List<Map<String, dynamic>> pointsMaps = await dbOrTxn.query(
      PointModel.tableName,
      columns: [
        PointModel.columnId,
        PointModel.columnOrdinalNumber,
      ], // Only need ID and ordinal
      where: '${PointModel.columnProjectId} = ?',
      whereArgs: [projectId],
      orderBy: '${PointModel.columnOrdinalNumber} ASC',
    );

    int? newStartingPointId;
    int? newEndingPointId;

    if (pointsMaps.isNotEmpty) {
      newStartingPointId =
          pointsMaps.first[PointModel.columnId]
              as int?; // First point (ordinal 0)
      newEndingPointId =
          pointsMaps.last[PointModel.columnId]
              as int?; // Last point (highest ordinal)
    }
    // If pointsMaps is empty, both will remain null, effectively clearing them.

    // Get current project's start/end to avoid unnecessary updates
    final List<Map<String, dynamic>> currentProjectMaps = await dbOrTxn.query(
      ProjectModel.tableName,
      columns: [
        ProjectModel.columnStartingPointId,
        ProjectModel.columnEndingPointId,
      ],
      where: '${ProjectModel.columnId} = ?',
      whereArgs: [projectId],
    );

    bool needsUpdate = false;
    if (currentProjectMaps.isNotEmpty) {
      final currentStartId =
          currentProjectMaps.first[ProjectModel.columnStartingPointId] as int?;
      final currentEndId =
          currentProjectMaps.first[ProjectModel.columnEndingPointId] as int?;
      if (currentStartId != newStartingPointId ||
          currentEndId != newEndingPointId) {
        needsUpdate = true;
      }
    } else {
      // Project not found, should not happen if projectId is valid
      logger.warning(
        "Project ID $projectId not found while trying to update start/end points.",
      );
      return;
    }

    if (needsUpdate) {
      logger.info(
        "Updating start/end points for project $projectId: StartID: $newStartingPointId, EndID: $newEndingPointId",
      );
      await dbOrTxn.update(
        ProjectModel.tableName,
        {
          ProjectModel.columnStartingPointId: newStartingPointId,
          ProjectModel.columnEndingPointId: newEndingPointId,
          // Also update the last_update timestamp for the project
          ProjectModel.columnLastUpdate: DateTime.now().toIso8601String(),
        },
        where: '${ProjectModel.columnId} = ?',
        whereArgs: [projectId],
      );
    } else {
      logger.fine(
        "No change needed for start/end points of project $projectId.",
      );
    }
  }

  Future<int> setProjectEndingPoint(int projectId, int? pointId) async {
    Database db = await instance.database;
    String now = DateTime.now().toIso8601String();
    return await db.update(
      ProjectModel.tableName,
      {
        ProjectModel.columnEndingPointId: pointId,
        ProjectModel.columnLastUpdate: now,
      },
      where: '${ProjectModel.columnId} = ?',
      whereArgs: [projectId],
    );
  }

  Future<int> deleteProject(int id) async {
    Database db = await instance.database;
    return await db.delete(
      ProjectModel.tableName,
      where: '${ProjectModel.columnId} = ?',
      whereArgs: [id],
    );
  }
  // --- End Project Methods ---

  // --- Point Methods ---
  Future<int> insertPoint(PointModel point) async {
    Database db = await instance.database;
    await _updateProjectTimestamp(point.projectId);
    return await db.insert(PointModel.tableName, point.toMap());
  }

  Future<int> updatePoint(PointModel point) async {
    Database db = await instance.database;
    await _updateProjectTimestamp(point.projectId);
    return await db.update(
      PointModel.tableName,
      point.toMap(),
      where: '${PointModel.columnId} = ?',
      whereArgs: [point.id],
    );
  }

  /// Deletes a single point and re-sequences the ordinal numbers of subsequent points.
  Future<int> deletePoint(int pointIdToDelete) async {
    Database db = await instance.database;
    int count = 0;

    // Use a transaction to ensure atomicity
    await db.transaction((txn) async {
      // 1. Get the point's details BEFORE deleting
      PointModel? pointToDelete = await _getPointByIdWithTransaction(
        txn,
        pointIdToDelete,
      );

      if (pointToDelete == null) {
        logger.warning(
          "Point with ID $pointIdToDelete not found for deletion.",
        );
        return; // Exit transaction if point not found
      }

      int projectId = pointToDelete.projectId;
      int deletedOrdinal = pointToDelete.ordinalNumber;

      // 2. Delete the point
      count = await txn.delete(
        PointModel.tableName,
        where: '${PointModel.columnId} = ?',
        whereArgs: [pointIdToDelete],
      );

      if (count > 0) {
        // 3. Decrement ordinal numbers of subsequent points in the same project
        await txn.rawUpdate(
          '''
        UPDATE ${PointModel.tableName}
        SET ${PointModel.columnOrdinalNumber} = ${PointModel.columnOrdinalNumber} - 1
        WHERE ${PointModel.columnProjectId} = ? AND ${PointModel.columnOrdinalNumber} > ?
        ''',
          [projectId, deletedOrdinal],
        );
        logger.info(
          "Point ID $pointIdToDelete (Ordinal $deletedOrdinal, Project $projectId) deleted and ordinals re-sequenced.",
        );
        // AFTER re-sequencing, update the project's start and end points
        await updateProjectStartEndPoints(projectId, txn: txn);
      }
    });
    return count;
  }

  /// Helper to get a point by ID within a transaction.
  Future<PointModel?> _getPointByIdWithTransaction(
    Transaction txn,
    int id,
  ) async {
    final List<Map<String, dynamic>> maps = await txn.query(
      PointModel.tableName,
      where: '${PointModel.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PointModel.fromMap(maps.first);
    }
    return null;
  }

  // getPointById without transaction (for external use)
  Future<PointModel?> getPointById(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      PointModel.tableName,
      where: '${PointModel.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PointModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int?> getLastPointOrdinal(int projectId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      PointModel.tableName,
      columns: [
        'MAX(${PointModel.columnOrdinalNumber}) as max_ordinal',
      ], // Use constant
      where: '${PointModel.columnProjectId} = ?', // Use constant
      whereArgs: [projectId],
    );

    if (result.isNotEmpty && result.first['max_ordinal'] != null) {
      return result.first['max_ordinal'] as int?;
    }
    return null;
  }
  // --- End Point Methods ---

  // --- Image Methods ---
  Future<int> insertImage(ImageModel image) async {
    Database db = await instance.database;
    // Potentially update the parent project's last_update timestamp
    PointModel? point = await getPointById(image.pointId);
    if (point != null) {
      await _updateProjectTimestamp(point.projectId);
    }
    return await db.insert(ImageModel.tableName, image.toMap());
  }

  Future<int> updateImage(ImageModel image) async {
    Database db = await instance.database;
    PointModel? point = await getPointById(image.pointId);
    if (point != null) {
      await _updateProjectTimestamp(point.projectId);
    }
    return await db.update(
      ImageModel.tableName,
      image.toMap(),
      where: '${ImageModel.columnId} = ?',
      whereArgs: [image.id],
    );
  }

  Future<int> deleteImage(int id) async {
    Database db = await instance.database;
    // TODO: Potentially re-sequence image ordinals if they have their own sequence per point
    // For now, simple delete
    // ImageModel? image = await getImageById(id); // You'd need a getImageById
    // if (image != null) {
    //   PointModel? point = await getPointById(image.pointId);
    //   if (point != null) {
    //     await _updateProjectTimestamp(point.projectId);
    //   }
    // }
    return await db.delete(
      ImageModel.tableName,
      where: '${ImageModel.columnId} = ?',
      whereArgs: [id],
    );
  }

  // --- Helper Methods ---
  Future<void> _updateProjectTimestamp(int projectId) async {
    Database db = await instance.database;
    String now = DateTime.now().toIso8601String();
    await db.update(
      ProjectModel.tableName,
      {ProjectModel.columnLastUpdate: now},
      where: '${ProjectModel.columnId} = ?',
      whereArgs: [projectId],
    );
  }

  Future<List<PointModel>> getPointsForProject(int projectId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      PointModel.tableName,
      where: '${PointModel.columnProjectId} = ?',
      whereArgs: [projectId],
      orderBy: '${PointModel.columnOrdinalNumber} ASC',
    );
    return List.generate(maps.length, (i) {
      return PointModel.fromMap(maps[i]);
    });
  }

  /// Deletes multiple points and re-sequences ordinal numbers for each affected project.
  Future<int> deletePointsByIds(List<int> ids) async {
    if (ids.isEmpty) return 0;
    Database db = await instance.database;
    int totalDeletedCount = 0;

    // Use a transaction for the overall operation
    await db.transaction((txn) async {
      // 1. Collect all points to be deleted to find affected project IDs
      List<PointModel> pointsToDelete = [];
      for (int id in ids) {
        PointModel? p = await _getPointByIdWithTransaction(txn, id);
        if (p != null) {
          pointsToDelete.add(p);
        }
      }
      if (pointsToDelete.isEmpty) {
        logger.info("No valid points found for deletion from IDs: $ids");
        return;
      }

      // 2. Group points by project ID
      Map<int, List<PointModel>> pointsByProject = {};
      for (var p in pointsToDelete) {
        pointsByProject.putIfAbsent(p.projectId, () => []).add(p);
      }

      // 3. Delete the points
      final String placeholders = ids.map((_) => '?').join(',');
      totalDeletedCount = await txn.delete(
        PointModel.tableName,
        where: '${PointModel.columnId} IN ($placeholders)',
        whereArgs: ids,
      );
      logger.info(
        "Attempted to delete $totalDeletedCount points with IDs: $ids",
      );

      if (totalDeletedCount > 0) {
        // 4. For each affected project, re-sequence the remaining points
        for (int projectId in pointsByProject.keys) {
          final List<Map<String, dynamic>>
          remainingPointsMaps = await txn.query(
            PointModel.tableName,
            where: '${PointModel.columnProjectId} = ?',
            whereArgs: [projectId],
            orderBy:
                '${PointModel.columnOrdinalNumber} ASC', // Order by current (potentially gappy) ordinal
          );

          List<PointModel> remainingPoints = remainingPointsMaps
              .map((map) => PointModel.fromMap(map))
              .toList();

          // Re-assign ordinal numbers
          for (int i = 0; i < remainingPoints.length; i++) {
            if (remainingPoints[i].ordinalNumber != i) {
              // Only update if necessary
              await txn.update(
                PointModel.tableName,
                {PointModel.columnOrdinalNumber: i},
                where: '${PointModel.columnId} = ?',
                whereArgs: [remainingPoints[i].id],
              );
            }
          }
          logger.info("Re-sequenced ordinals for project ID $projectId.");
          // AFTER re-sequencing for this project, update its start and end points
          await updateProjectStartEndPoints(projectId, txn: txn);
        }
      }
    });
    return totalDeletedCount;
  }

  Future<List<ImageModel>> getImagesForPoint(int pointId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      ImageModel.tableName,
      where: '${ImageModel.columnPointId} = ?',
      whereArgs: [pointId],
      orderBy: '${ImageModel.columnOrdinalNumber} ASC',
    );
    return List.generate(maps.length, (i) {
      return ImageModel.fromMap(maps[i]);
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
