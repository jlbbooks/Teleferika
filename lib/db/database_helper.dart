// database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/image_model.dart';
import 'models/point_model.dart';
import 'models/project_model.dart';

class DatabaseHelper {
  static const _databaseName = "Projects.db";
  static const _databaseVersion = 1;

  // Table names
  static const tableProjects = 'projects';
  static const tablePoints = 'points';
  static const tableImages = 'images';

  // Column names (optional, but good for avoiding typos)
  // Projects
  static const columnId = 'id';
  static const columnName = 'name';
  static const columnStartingPointId = 'starting_point_id';
  static const columnEndingPointId = 'ending_point_id';
  static const columnAzimuth = 'azimuth';

  // Points
  static const columnProjectId = 'project_id';
  static const columnLatitude = 'latitude';
  static const columnLongitude = 'longitude';
  static const columnOrdinalNumber =
      'ordinal_number'; // Used in multiple tables
  static const columnNote = 'note';

  // Images
  static const columnPointId = 'point_id';
  static const columnImagePath = 'image_path';

  // Make this a singleton class.
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only have a single app-wide reference to the database.
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Lazily instantiate the db the first time it is accessed.
    _database = await _initDatabase();
    return _database!;
  }

  // This opens the database (and creates it if it doesn't exist).
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure, // For foreign keys
    );
  }

  // Enable foreign key support
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // SQL code to create the database tables.
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableProjects (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnStartingPointId INTEGER,
        $columnEndingPointId INTEGER,
        $columnAzimuth REAL
      )
    ''');

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

  // Helper methods

  // --- Project Methods ---
  Future<int> insertProject(ProjectModel project) async {
    Database db = await instance.database;
    return await db.insert(tableProjects, project.toMap());
  }

  Future<List<ProjectModel>> getAllProjects() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableProjects,
      orderBy: '$columnName ASC',
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
    return await db.update(
      tableProjects,
      project.toMap(),
      where: '$columnId = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> setProjectStartingPoint(int projectId, int? pointId) async {
    Database db = await instance.database;
    return await db.update(
      tableProjects,
      {columnStartingPointId: pointId},
      where: '$columnId = ?',
      whereArgs: [projectId],
    );
  }

  Future<int> setProjectEndingPoint(int projectId, int? pointId) async {
    Database db = await instance.database;
    return await db.update(
      tableProjects,
      {columnEndingPointId: pointId},
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

  // --- Point Methods ---
  Future<int> insertPoint(PointModel point) async {
    Database db = await instance.database;
    return await db.insert(tablePoints, point.toMap());
  }

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

  Future<int> updatePoint(PointModel point) async {
    Database db = await instance.database;
    return await db.update(
      tablePoints,
      point.toMap(),
      where: '$columnId = ?',
      whereArgs: [point.id],
    );
  }

  Future<int> deletePoint(int id) async {
    Database db = await instance.database;
    return await db.delete(
      tablePoints,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // --- Image Methods ---
  Future<int> insertImage(ImageModel image) async {
    Database db = await instance.database;
    return await db.insert(tableImages, image.toMap());
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

  Future<int> updateImage(ImageModel image) async {
    Database db = await instance.database;
    return await db.update(
      tableImages,
      image.toMap(),
      where: '$columnId = ?',
      whereArgs: [image.id],
    );
  }

  Future<int> deleteImage(int id) async {
    Database db = await instance.database;
    return await db.delete(
      tableImages,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Close the database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
