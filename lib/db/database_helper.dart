// database_helper.dart
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../logger.dart';
import '../utils/uuid_generator.dart';
import 'models/image_model.dart';
import 'models/point_model.dart';
import 'models/project_model.dart';

class DatabaseHelper {
  static const _databaseName = "Photogrammetry.db";

  static const _databaseVersion = 8; // Incremented due to schema change

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
        ${ProjectModel.columnId} TEXT PRIMARY KEY,
        ${ProjectModel.columnName} TEXT NOT NULL,
        ${ProjectModel.columnStartingPointId} TEXT,
        ${ProjectModel.columnEndingPointId} TEXT,
        ${ProjectModel.columnAzimuth} REAL,
        ${ProjectModel.columnNote} TEXT,
        ${ProjectModel.columnLastUpdate} TEXT,
        ${ProjectModel.columnDate} TEXT,
        FOREIGN KEY (${ProjectModel.columnStartingPointId}) REFERENCES ${PointModel.tableName} (${PointModel.columnId}) ON DELETE SET NULL,
        FOREIGN KEY (${ProjectModel.columnEndingPointId}) REFERENCES ${PointModel.tableName} (${PointModel.columnId}) ON DELETE SET NULL
      )
      '''); // TEXT for ISO8601 DateTime string
    // Add index for faster querying/sorting by last_update
    await db.execute(
      'CREATE INDEX idx_project_last_update ON ${ProjectModel.tableName} (${ProjectModel.columnLastUpdate})',
    );

    await db.execute('''
    CREATE TABLE ${PointModel.tableName} (
      ${PointModel.columnId} TEXT PRIMARY KEY,
      ${PointModel.columnProjectId} TEXT NOT NULL,
      ${PointModel.columnLatitude} REAL NOT NULL,
      ${PointModel.columnLongitude} REAL NOT NULL,
      ${PointModel.columnAltitude} REAL, -- Added new altitude column (nullable REAL)
      ${PointModel.columnOrdinalNumber} INTEGER NOT NULL,
      ${PointModel.columnNote} TEXT,
      ${PointModel.columnHeading} REAL,
      ${PointModel.columnTimestamp} TEXT,
      FOREIGN KEY (${PointModel.columnProjectId}) REFERENCES ${ProjectModel.tableName} (${ProjectModel.columnId}) ON DELETE CASCADE
    )
    ''');
    // Add index for faster querying by project_id and sorting by ordinal_number
    await db.execute(
      'CREATE INDEX idx_point_project_ordinal ON ${PointModel.tableName} (${PointModel.columnProjectId}, ${PointModel.columnOrdinalNumber})',
    );

    await db.execute('''
      CREATE TABLE ${ImageModel.tableName} (
        ${ImageModel.columnId} TEXT PRIMARY KEY,
        ${ImageModel.columnPointId} TEXT NOT NULL,
        ${ImageModel.columnOrdinalNumber} INTEGER NOT NULL,
        ${ImageModel.columnImagePath} TEXT NOT NULL,
        FOREIGN KEY (${ImageModel.columnPointId}) REFERENCES ${PointModel.tableName} (${PointModel.columnId}) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_image_point_id ON ${ImageModel.tableName} (${ImageModel.columnPointId})',
    );
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
    // ---- Migration to Version 6: INT IDs to UUID TEXT IDs ----
    if (oldVersion < 6) {
      logger.info(
        "Applying migration for version 6: Changing INT IDs to UUID TEXT IDs.",
      );
      await db.transaction((txn) async {
        Map<int, String> projectOldToNewIdMap = {};
        Map<int, String> pointOldToNewIdMap = {};

        // --- Step 1: Migrate Projects Table ---
        logger.info("Migrating ${ProjectModel.tableName} to UUIDs...");
        final projectsTempTableName = '${ProjectModel.tableName}_temp_v6';
        await txn.execute('''
      CREATE TABLE $projectsTempTableName (
        ${ProjectModel.columnId} TEXT PRIMARY KEY, ${ProjectModel.columnName} TEXT NOT NULL,
        ${ProjectModel.columnNote} TEXT, ${ProjectModel.columnStartingPointId} TEXT,
        ${ProjectModel.columnEndingPointId} TEXT, ${ProjectModel.columnAzimuth} REAL,
        ${ProjectModel.columnLastUpdate} TEXT, ${ProjectModel.columnDate} TEXT
      )
      ''');
        List<Map<String, dynamic>> oldProjects = await txn.query(
          ProjectModel.tableName,
        );
        for (var oldProject in oldProjects) {
          int oldId = oldProject[ProjectModel.columnId] as int;
          String newProjectId = generateUuid();
          projectOldToNewIdMap[oldId] = newProjectId;
          await txn.insert(projectsTempTableName, {
            ProjectModel.columnId: newProjectId,
            ProjectModel.columnName: oldProject[ProjectModel.columnName],
            ProjectModel.columnNote: oldProject[ProjectModel.columnNote],
            ProjectModel.columnAzimuth: oldProject[ProjectModel.columnAzimuth],
            ProjectModel.columnLastUpdate:
                oldProject[ProjectModel.columnLastUpdate],
            ProjectModel.columnDate: oldProject[ProjectModel.columnDate],
            // starting_point_id and ending_point_id will be updated later
          });
        }
        logger.info(
          "Generated UUIDs for ${projectOldToNewIdMap.length} projects.",
        );

        // --- Step 2: Migrate Points Table ---
        logger.info("Migrating ${PointModel.tableName} to UUIDs...");
        final pointsTempTableName = '${PointModel.tableName}_temp_v6';
        await txn.execute('''
      CREATE TABLE $pointsTempTableName (
        ${PointModel.columnId} TEXT PRIMARY KEY, ${PointModel.columnProjectId} TEXT NOT NULL,
        ${PointModel.columnLatitude} REAL NOT NULL, ${PointModel.columnLongitude} REAL NOT NULL,
        ${PointModel.columnOrdinalNumber} INTEGER NOT NULL, ${PointModel.columnNote} TEXT,
        ${PointModel.columnHeading} REAL, ${PointModel.columnTimestamp} TEXT
      )
      ''');
        List<Map<String, dynamic>> oldPoints = await txn.query(
          PointModel.tableName,
        );
        for (var oldPoint in oldPoints) {
          int oldId = oldPoint[PointModel.columnId] as int;
          String newPointId = generateUuid();
          pointOldToNewIdMap[oldId] = newPointId;
          String? newProjectUUID =
              projectOldToNewIdMap[oldPoint[PointModel.columnProjectId] as int];
          await txn.insert(pointsTempTableName, {
            PointModel.columnId: newPointId,
            PointModel.columnProjectId: newProjectUUID,
            PointModel.columnLatitude: oldPoint[PointModel.columnLatitude],
            PointModel.columnLongitude: oldPoint[PointModel.columnLongitude],
            PointModel.columnOrdinalNumber:
                oldPoint[PointModel.columnOrdinalNumber],
            PointModel.columnNote: oldPoint[PointModel.columnNote],
            PointModel.columnHeading: oldPoint[PointModel.columnHeading],
            PointModel.columnTimestamp: oldPoint[PointModel.columnTimestamp],
          });
        }
        logger.info("Generated UUIDs for ${pointOldToNewIdMap.length} points.");

        // --- Step 3: Migrate Images Table ---
        logger.info("Migrating ${ImageModel.tableName} to UUIDs...");
        final imagesTempTableName = '${ImageModel.tableName}_temp_v6';
        await txn.execute('''
      CREATE TABLE $imagesTempTableName (
        ${ImageModel.columnId} TEXT PRIMARY KEY, ${ImageModel.columnPointId} TEXT NOT NULL,
        ${ImageModel.columnOrdinalNumber} INTEGER NOT NULL, ${ImageModel.columnImagePath} TEXT NOT NULL
      )
      ''');
        List<Map<String, dynamic>> oldImages = await txn.query(
          ImageModel.tableName,
        );
        for (var oldImage in oldImages) {
          String newImageId = generateUuid();
          String? newPointUUID =
              pointOldToNewIdMap[oldImage[ImageModel.columnPointId] as int];
          await txn.insert(imagesTempTableName, {
            ImageModel.columnId: newImageId,
            ImageModel.columnPointId: newPointUUID,
            ImageModel.columnOrdinalNumber:
                oldImage[ImageModel.columnOrdinalNumber],
            ImageModel.columnImagePath: oldImage[ImageModel.columnImagePath],
          });
        }
        logger.info("Generated UUIDs for ${oldImages.length} images.");

        // --- Step 4: Update Project's starting_point_id and ending_point_id ---
        logger.info("Updating project start/end point UUIDs...");
        for (var oldProject in oldProjects) {
          int oldProjectId = oldProject[ProjectModel.columnId] as int;
          String? newProjectUUID = projectOldToNewIdMap[oldProjectId];
          int? oldStartingPointId =
              oldProject[ProjectModel.columnStartingPointId] as int?;
          int? oldEndingPointId =
              oldProject[ProjectModel.columnEndingPointId] as int?;
          String? newStartingPointUUID = oldStartingPointId != null
              ? pointOldToNewIdMap[oldStartingPointId]
              : null;
          String? newEndingPointUUID = oldEndingPointId != null
              ? pointOldToNewIdMap[oldEndingPointId]
              : null;
          if (newProjectUUID != null) {
            await txn.update(
              projectsTempTableName,
              {
                ProjectModel.columnStartingPointId: newStartingPointUUID,
                ProjectModel.columnEndingPointId: newEndingPointUUID,
              },
              where: '${ProjectModel.columnId} = ?',
              whereArgs: [newProjectUUID],
            );
          }
        }

        // --- Step 5: Drop Old Tables ---
        logger.info("Dropping old tables...");
        await txn.execute('DROP TABLE ${ProjectModel.tableName}');
        await txn.execute('DROP TABLE ${PointModel.tableName}');
        await txn.execute('DROP TABLE ${ImageModel.tableName}');

        // --- Step 6: Rename New Tables ---
        logger.info("Renaming new tables...");
        await txn.execute(
          'ALTER TABLE $projectsTempTableName RENAME TO ${ProjectModel.tableName}',
        );
        await txn.execute(
          'ALTER TABLE $pointsTempTableName RENAME TO ${PointModel.tableName}',
        );
        await txn.execute(
          'ALTER TABLE $imagesTempTableName RENAME TO ${ImageModel.tableName}',
        );

        // --- Step 7: Recreate Indexes ---
        logger.info("Recreating indexes...");
        await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_point_project_ordinal ON ${PointModel.tableName} (${PointModel.columnProjectId}, ${PointModel.columnOrdinalNumber})',
        );
        await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_image_point_id ON ${ImageModel.tableName} (${ImageModel.columnPointId})',
        );

        // Note: Foreign keys are not explicitly recreated here on the renamed tables.
        // The new tables were created without them to avoid issues during data copy.
        // For new DBs, _onCreate defines them. For existing DBs after this migration,
        // they won't be enforced by SQLite unless a more complex migration re-creates tables with FKs.
        logger.info(
          "Migration to version 6 (UUIDs) completed successfully within transaction.",
        );
      }); // End transaction
    }
    if (oldVersion < 6) {
      throw UnimplementedError(
        'Migration to version 6 not supported. Reinstall.',
      );
    }
    // ---- Migration to Version 7: Add altitude to points table ----
    if (oldVersion < 7) {
      logger.info(
        "Applying migration for version 7: Adding ${PointModel.columnAltitude} to ${PointModel.tableName}",
      );
      try {
        await db.execute(
          'ALTER TABLE ${PointModel.tableName} ADD COLUMN ${PointModel.columnAltitude} REAL',
        );
        logger.info(
          "Successfully added ${PointModel.columnAltitude} column to ${PointModel.tableName}.",
        );
      } catch (e) {
        logger.severe(
          "Error adding ${PointModel.columnAltitude} column to ${PointModel.tableName}. "
          "This might happen if the column already exists due to a partial previous migration. Error: $e",
        );
        // Depending on your error handling strategy, you might re-throw or just log.
        // If the column already exists, this is often not a critical failure for this specific migration.
      }
    }
    if (oldVersion < 8) {
      // ---- Migration to Version 8: Remove heading from points table ----
      logger.info(
        "Applying migration for version 8: Removing ${PointModel.columnHeading} from ${PointModel.tableName}",
      );
      // The most straightforward way if supported by the underlying SQLite version.
      // `sqflite` on modern platforms usually bundles a SQLite version that supports DROP COLUMN.
      try {
        // Check if the column exists before trying to drop it, to make the migration idempotent.
        // This requires querying the table_info pragma.
        var tableInfo = await db.rawQuery(
          'PRAGMA table_info(${PointModel.tableName})',
        );
        bool headingColumnExists = tableInfo.any(
          (column) => column['name'] == PointModel.columnHeading,
        );

        if (headingColumnExists) {
          // Option 1: Recreate table (safer for older SQLite, more complex)
          // This is the most robust way if DROP COLUMN isn't universally available or if you want to be extra safe.
          await db.transaction((txn) async {
            // 1. Create a temporary table without the 'heading' column
            final tempPointTable = '${PointModel.tableName}_temp_v8_no_heading';
            await txn.execute('''
              CREATE TABLE $tempPointTable (
                ${PointModel.columnId} TEXT PRIMARY KEY,
                ${PointModel.columnProjectId} TEXT NOT NULL,
                ${PointModel.columnLatitude} REAL NOT NULL,
                ${PointModel.columnLongitude} REAL NOT NULL,
                ${PointModel.columnAltitude} REAL,
                ${PointModel.columnOrdinalNumber} INTEGER NOT NULL,
                ${PointModel.columnNote} TEXT,
                ${PointModel.columnTimestamp} TEXT,
                FOREIGN KEY (${PointModel.columnProjectId}) REFERENCES ${ProjectModel.tableName} (${ProjectModel.columnId}) ON DELETE CASCADE
              )
              ''');
            logger.info(
              "Created temporary table $tempPointTable for points migration.",
            );

            // 2. Copy data from the old table to the temporary table, excluding the 'heading' column
            await txn.execute('''
              INSERT INTO $tempPointTable (
                ${PointModel.columnId}, ${PointModel.columnProjectId}, ${PointModel.columnLatitude}, ${PointModel.columnLongitude},
                ${PointModel.columnAltitude}, ${PointModel.columnOrdinalNumber}, ${PointModel.columnNote}, ${PointModel.columnTimestamp}
              )
              SELECT
                ${PointModel.columnId}, ${PointModel.columnProjectId}, ${PointModel.columnLatitude}, ${PointModel.columnLongitude},
                ${PointModel.columnAltitude}, ${PointModel.columnOrdinalNumber}, ${PointModel.columnNote}, ${PointModel.columnTimestamp}
              FROM ${PointModel.tableName}
              ''');
            logger.info(
              "Copied data from ${PointModel.tableName} to $tempPointTable.",
            );

            // 3. Drop the old points table
            await txn.execute('DROP TABLE ${PointModel.tableName}');
            logger.info("Dropped old table ${PointModel.tableName}.");

            // 4. Rename the temporary table to the original table name
            await txn.execute(
              'ALTER TABLE $tempPointTable RENAME TO ${PointModel.tableName}',
            );
            logger.info("Renamed $tempPointTable to ${PointModel.tableName}.");

            // 5. Recreate indexes (if any were specific to the old table structure and not covered by general creation)
            // The index 'idx_point_project_ordinal' should still be valid as its columns haven't changed.
            // If you had an index specifically on 'heading', it would be gone, which is intended.
            await txn.execute(
              'CREATE INDEX IF NOT EXISTS idx_point_project_ordinal ON ${PointModel.tableName} (${PointModel.columnProjectId}, ${PointModel.columnOrdinalNumber})',
            );
            logger.info(
              "Recreated index idx_point_project_ordinal on ${PointModel.tableName} if it didn't exist.",
            );
          });
          logger.info(
            "Successfully removed ${PointModel.columnHeading} from ${PointModel.tableName} by recreating the table.",
          );
        } else {
          logger.info(
            "${PointModel.columnHeading} column does not exist in ${PointModel.tableName}. No action needed for version 8 migration regarding this column.",
          );
        }
      } catch (e) {
        logger.severe(
          "Error removing ${PointModel.columnHeading} column from ${PointModel.tableName} for version 8. Error: $e",
        );
        // Depending on your error handling strategy, you might re-throw.
        // If the column was already removed or the table was already in the new state, this might not be critical.
      }
    }
    logger.info("Database upgrade process complete.");
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

  Future<ProjectModel?> getProjectById(String id) async {
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
    final projectToUpdate = project.copyWith(lastUpdate: DateTime.now());
    return await db.update(
      ProjectModel.tableName,
      projectToUpdate.toMap(),
      where: '${ProjectModel.columnId} = ?',
      whereArgs: [projectToUpdate.id],
    );
  }

  Future<int> setProjectStartingPoint(String projectId, String? pointId) async {
    Database db = await instance.database;
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
    String projectId, {
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

    String? newStartingPointId;
    String? newEndingPointId;

    if (pointsMaps.isNotEmpty) {
      newStartingPointId =
          pointsMaps.first[PointModel.columnId]
              as String?; // First point (ordinal 0)
      newEndingPointId =
          pointsMaps.last[PointModel.columnId]
              as String?; // Last point (highest ordinal)
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
          currentProjectMaps.first[ProjectModel.columnStartingPointId]
              as String?;
      final currentEndId =
          currentProjectMaps.first[ProjectModel.columnEndingPointId] as String?;
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

  Future<int> setProjectEndingPoint(String projectId, String? pointId) async {
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

  Future<int> deleteProject(String id) async {
    Database db = await instance.database;
    return await db.delete(
      ProjectModel.tableName,
      where: '${ProjectModel.columnId} = ?',
      whereArgs: [id],
    );
  }
  // --- End Project Methods ---

  // --- Point Methods ---

  Future<String> insertPoint(PointModel point) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. Insert the PointModel (point.toMap() does not include images)
      point.id = point.id;

      await txn.insert(
        PointModel.tableName,
        point.toMap(), // This map is for the 'points' table
        conflictAlgorithm: ConflictAlgorithm.replace, // Or as per your needs
      );

      // 2. Insert associated images
      for (final image in point.images) {
        // Ensure image.pointId matches the point.id if it wasn't already set
        // (though it should be if created correctly in PhotoManagerWidget)
        final imageToInsert = image.pointId == point.id
            ? image
            : image.copyWith(pointId: point.id);
        await txn.insert(
          ImageModel.tableName,
          imageToInsert.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    // After inserting, update the project's lastUpdate timestamp
    await _updateProjectTimestamp(point.projectId);
    return point.id; // Return the generated or existing point ID
  }

  // You might deprecate or rename the old insertPoint if all new points should handle images.
  // Future<String> insertPoint(PointModel point) async { ... OLD ... }
  // Similarly for ProjectModel and ImageModel
  Future<String> insertProject(ProjectModel project) async {
    Database db = await instance.database;
    final projectToInsert = project.copyWith(lastUpdate: DateTime.now());
    // projectToInsert.id is already a UUID string
    await db.insert(ProjectModel.tableName, projectToInsert.toMap());
    return projectToInsert.id;
  }

  Future<int> updatePoint(PointModel point) async {
    final db = await database;
    int result = 0;
    final a = await db.transaction((txn) async {
      // 1. Update the PointModel itself
      result = await txn.update(
        PointModel.tableName,
        point.toMap(),
        where: '${PointModel.columnId} = ?',
        whereArgs: [point.id],
      );

      // 2. Delete existing images for this point
      await txn.delete(
        ImageModel.tableName,
        where: '${ImageModel.columnPointId} = ?',
        whereArgs: [point.id],
      );

      // 3. Insert new/updated list of images
      for (final image in point.images) {
        // Ensure the image.pointId is correctly set if it wasn't before
        // ImageModel currentImage = image.pointId == point.id ? image : image.copyWith(pointId: point.id);
        await txn.insert(ImageModel.tableName, image.toMap());
      }
    });
    if (result > 0) {
      await _updateProjectTimestamp(point.projectId);
    }
    logger.info("Updated $result points. (a=$a)");
    return result;
  }

  /// Deletes a single point and re-sequences the ordinal numbers of subsequent points.
  Future<int> deletePointById(String pointIdToDelete) async {
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

      String projectId = pointToDelete.projectId;
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
    String id,
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
  Future<PointModel?> getPointById(String id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      PointModel.tableName,
      where: '${PointModel.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      // Fetch associated images
      final List<ImageModel> images = await getImagesForPoint(id);
      return PointModel.fromMap(maps.first, images: images);
    }
    return null;
  }

  Future<int?> getLastPointOrdinal(String projectId) async {
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
  Future<String> insertImage(ImageModel image) async {
    Database db = await instance.database;
    // image.id is already a UUID string
    if (image.id == null) {
      throw ArgumentError("ImageModel must have a UUID id before insertion.");
    }
    PointModel? point = await getPointById(
      image.pointId,
    ); // pointId is now String
    if (point != null) {
      // Assuming _updateProjectTimestamp takes String projectId
      await _updateProjectTimestamp(point.projectId);
    } else {
      logger.warning(
        "Attempted to insert image for non-existent pointId: ${image.pointId}",
      );
      // Consider throwing an error if a point MUST exist for an image
      // For now, we'll allow it but log a warning.
    }

    await db.insert(
      ImageModel.tableName,
      image.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return image.id!;
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

  Future<int> deleteImage(String id) async {
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
    ImageModel? image = await getImageById(
      id,
    ); // getImageById would need to be created

    final result = await db.delete(
      ImageModel.tableName,
      where: '${ImageModel.columnId} = ?',
      whereArgs: [id],
    );

    if (result > 0 && image != null) {
      PointModel? point = await getPointById(image.pointId);
      if (point != null) {
        await _updateProjectTimestamp(point.projectId);
      }
    }
    return result;
  }

  Future<ImageModel?> getImageById(String id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      ImageModel.tableName,
      where: '${ImageModel.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ImageModel.fromMap(maps.first);
    }
    return null;
  }

  // --- Helper Methods ---
  Future<void> _updateProjectTimestamp(String projectId) async {
    Database db = await instance.database;
    String now = DateTime.now().toIso8601String();
    await db.update(
      ProjectModel.tableName,
      {ProjectModel.columnLastUpdate: now},
      where: '${ProjectModel.columnId} = ?',
      whereArgs: [projectId],
    );
  }

  Future<List<PointModel>> getPointsForProject(String projectId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> pointMaps = await db.query(
      PointModel.tableName,
      where: '${PointModel.columnProjectId} = ?',
      whereArgs: [projectId],
      orderBy: '${PointModel.columnOrdinalNumber} ASC',
    );
    // In DatabaseHelper

    List<PointModel> points = [];
    for (var pMap in pointMaps) {
      final String pointId = pMap[PointModel.columnId] as String;
      final List<ImageModel> images = await getImagesForPoint(pointId);
      points.add(PointModel.fromMap(pMap, images: images));
    }
    return points;
  }

  /// Deletes multiple points and re-sequences ordinal numbers for each affected project.
  Future<int> deletePointsByIds(List<String> ids) async {
    if (ids.isEmpty) return 0;
    Database db = await instance.database;
    int totalDeletedCount = 0;

    // Use a transaction for the overall operation
    await db.transaction((txn) async {
      // 1. Collect all points to be deleted to find affected project IDs
      List<PointModel> pointsToDelete = [];
      for (String id in ids) {
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
      Map<String, List<PointModel>> pointsByProject = {};
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
        for (String projectId in pointsByProject.keys) {
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

  Future<List<ImageModel>> getImagesForPoint(String pointId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      ImageModel.tableName,
      where: '${ImageModel.columnPointId} = ?',
      whereArgs: [pointId],
      orderBy: '${ImageModel.columnOrdinalNumber} ASC',
    );
    return List.generate(maps.length, (i) => ImageModel.fromMap(maps[i]));
  }

  // When deleting a point, also delete its images and the photo directory
  Future<void> deletePointAndAssociatedData(String pointId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        ImageModel.tableName,
        where: '${ImageModel.columnPointId} = ?',
        whereArgs: [pointId],
      );
      await txn.delete(
        PointModel.tableName,
        where: '${PointModel.columnId} = ?',
        whereArgs: [pointId],
      );
    });

    // Also delete the physical photo directory
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final pointPhotosDir = Directory(
        join(appDocDir.path, 'point_photos', pointId),
      );
      if (await pointPhotosDir.exists()) {
        await pointPhotosDir.delete(recursive: true);
        logger.fine('Deleted photo directory for point $pointId');
      }
    } catch (e) {
      logger.severe('Error deleting photo directory for point $pointId: $e');
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
