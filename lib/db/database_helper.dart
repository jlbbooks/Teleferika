// database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/image_model.dart';
import 'models/point_model.dart';
import 'models/project_model.dart';

class DatabaseHelper {
  static const _databaseName = "Photogrammetry.db";

  static const _databaseVersion = 2; // Incremented due to schema change

  static const tableProjects = 'projects';
  static const tablePoints = 'points';
  static const tableImages = 'images';

  static const columnId = 'id';
  static const columnName = 'name';
  static const columnStartingPointId = 'starting_point_id';
  static const columnEndingPointId = 'ending_point_id';
  static const columnAzimuth = 'azimuth';
  static const columnLastUpdate = 'last_update'; // New column

  static const columnProjectId = 'project_id';
  static const columnLatitude = 'latitude';
  static const columnLongitude = 'longitude';
  static const columnOrdinalNumber = 'ordinal_number';
  static const columnNote = 'note';

  static const columnPointId = 'point_id';
  static const columnImagePath = 'image_path';

  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add onUpgrade callback
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Called when the database is created for the first time
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableProjects (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnStartingPointId INTEGER,
        $columnEndingPointId INTEGER,
        $columnAzimuth REAL,
        $columnLastUpdate TEXT 
      )
    '''); // TEXT for ISO8601 DateTime string

    await db.execute('''
      CREATE TABLE $tablePoints (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnProjectId INTEGER NOT NULL,
        $columnLatitude REAL NOT NULL,
        $columnLongitude REAL NOT NULL,
        $columnOrdinalNumber INTEGER NOT NULL,
        $columnNote TEXT,
        FOREIGN KEY ($columnProjectId) REFERENCES $tableProjects ($columnId) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableImages (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnPointId INTEGER NOT NULL,
        $columnOrdinalNumber INTEGER NOT NULL,
        $columnImagePath TEXT NOT NULL,
        FOREIGN KEY ($columnPointId) REFERENCES $tablePoints ($columnId) ON DELETE CASCADE
      )
    ''');
  }

  // Called when the database needs to be upgraded
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add last_update column to projects table if upgrading from version 1
      await db.execute(
        'ALTER TABLE $tableProjects ADD COLUMN $columnLastUpdate TEXT',
      );
      // You might want to populate existing rows with a default last_update value here
      // For example, setting it to the current time for existing projects:
      String now = DateTime.now().toIso8601String();
      await db.rawUpdate(
        'UPDATE $tableProjects SET $columnLastUpdate = ? WHERE $columnLastUpdate IS NULL',
        [now],
      );
    }
    // Add more migration steps here for future versions
    // if (oldVersion < 3) { ... }
  }

  // --- Project Methods ---
  Future<int> insertProject(ProjectModel project) async {
    Database db = await instance.database;
    // Set lastUpdate to now before inserting
    project.lastUpdate = DateTime.now();
    return await db.insert(tableProjects, project.toMap());
  }

  Future<List<ProjectModel>> getAllProjects() async {
    Database db = await instance.database;
    // Order by last_update DESC
    final List<Map<String, dynamic>> maps = await db.query(
      tableProjects,
      orderBy: '$columnLastUpdate DESC', // Sort by last update, newest first
    );
    return List.generate(maps.length, (i) {
      return ProjectModel.fromMap(maps[i]);
    });
  }

  Future<ProjectModel?> getProjectById(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableProjects,
      where: '$columnId = ?',
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
      tableProjects,
      project.toMap(),
      where: '$columnId = ?',
      whereArgs: [project.id],
    );
  }

  // ... (setProjectStartingPoint, setProjectEndingPoint - consider if these should also update last_update)
  Future<int> setProjectStartingPoint(int projectId, int? pointId) async {
    Database db = await instance.database;
    // Also update last_update for the project
    String now = DateTime.now().toIso8601String();
    return await db.update(
      tableProjects,
      {columnStartingPointId: pointId, columnLastUpdate: now},
      where: '$columnId = ?',
      whereArgs: [projectId],
    );
  }

  Future<int> setProjectEndingPoint(int projectId, int? pointId) async {
    Database db = await instance.database;
    String now = DateTime.now().toIso8601String();
    return await db.update(
      tableProjects,
      {columnEndingPointId: pointId, columnLastUpdate: now},
      where: '$columnId = ?',
      whereArgs: [projectId],
    );
  }

  Future<int> deleteProject(int id) async {
    Database db = await instance.database;
    return await db.delete(
      tableProjects,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // --- Point Methods --- (No changes needed here for this step)
  Future<int> insertPoint(PointModel point) async {
    Database db = await instance.database;
    // Potentially update the parent project's last_update timestamp
    // This requires fetching the project, updating its timestamp, and saving it
    // Or, more simply, pass the project to an updateProjectLastUpdate method
    await _updateProjectTimestamp(point.projectId);
    return await db.insert(tablePoints, point.toMap());
  }

  Future<int> updatePoint(PointModel point) async {
    Database db = await instance.database;
    await _updateProjectTimestamp(point.projectId);
    return await db.update(
      tablePoints,
      point.toMap(),
      where: '$columnId = ?',
      whereArgs: [point.id],
    );
  }

  Future<int> deletePoint(int id) async {
    Database db = await instance.database;
    // If you delete a point, you might want to update the parent project's last_update
    // This requires first fetching the point to get its projectId, then updating the project.
    PointModel? point = await getPointById(id);
    if (point != null) {
      await _updateProjectTimestamp(point.projectId);
    }
    return await db.delete(
      tablePoints,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // --- Image Methods --- (No changes needed here for this step)
  Future<int> insertImage(ImageModel image) async {
    Database db = await instance.database;
    // Potentially update the parent project's last_update timestamp
    PointModel? point = await getPointById(image.pointId);
    if (point != null) {
      await _updateProjectTimestamp(point.projectId);
    }
    return await db.insert(tableImages, image.toMap());
  }

  Future<int> updateImage(ImageModel image) async {
    Database db = await instance.database;
    PointModel? point = await getPointById(image.pointId);
    if (point != null) {
      await _updateProjectTimestamp(point.projectId);
    }
    return await db.update(
      tableImages,
      image.toMap(),
      where: '$columnId = ?',
      whereArgs: [image.id],
    );
  }

  Future<int> deleteImage(int id) async {
    Database db = await instance.database;
    // If you delete an image, you might want to update the parent project's last_update
    // This requires fetching the image, then the point, then the project.
    // Simpler: find the image, get pointId, then call _updateProjectTimestampForPoint(pointId)
    // For now, let's keep it simpler or handle in UI logic if complex.
    // A direct update if you had the pointId readily:
    // ImageModel? image = await getImageById(id); // You'd need a getImageById
    // if (image != null) {
    //   PointModel? point = await getPointById(image.pointId);
    //   if (point != null) {
    //     await _updateProjectTimestamp(point.projectId);
    //   }
    // }
    return await db.delete(
      tableImages,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Helper to update project's last_update timestamp
  Future<void> _updateProjectTimestamp(int projectId) async {
    Database db = await instance.database;
    String now = DateTime.now().toIso8601String();
    await db.update(
      tableProjects,
      {columnLastUpdate: now},
      where: '$columnId = ?',
      whereArgs: [projectId],
    );
  }

  // ... (getPointsForProject, getPointById, getImagesForPoint as before)
  Future<List<PointModel>> getPointsForProject(int projectId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePoints,
      where: '$columnProjectId = ?',
      whereArgs: [projectId],
      orderBy: '$columnOrdinalNumber ASC',
    );
    return List.generate(maps.length, (i) {
      return PointModel.fromMap(maps[i]);
    });
  }

  Future<PointModel?> getPointById(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePoints,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PointModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ImageModel>> getImagesForPoint(int pointId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableImages,
      where: '$columnPointId = ?',
      whereArgs: [pointId],
      orderBy: '$columnOrdinalNumber ASC',
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
