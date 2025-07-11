// This is the database.dart file for Drift
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';

part 'database.g.dart';

// Table definitions
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get note => text().nullable()();
  RealColumn get azimuth => real().nullable()();
  TextColumn get lastUpdate => text().nullable()();
  TextColumn get date => text().nullable()();
  RealColumn get presumedTotalLength => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Points extends Table {
  TextColumn get id => text()();
  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get altitude => real().nullable()();
  RealColumn get gpsPrecision => real().nullable()();
  IntColumn get ordinalNumber => integer()();
  TextColumn get note => text().nullable()();
  TextColumn get timestamp => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Images extends Table {
  TextColumn get id => text()();
  TextColumn get pointId =>
      text().references(Points, #id, onDelete: KeyAction.cascade)();
  IntColumn get ordinalNumber => integer()();
  TextColumn get imagePath => text()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Data classes for type-safe queries
class ProjectWithPoints {
  final Project project;
  final List<PointWithImages> points;

  ProjectWithPoints({required this.project, required this.points});
}

class PointWithImages {
  final Point point;
  final List<Image> images;

  PointWithImages({required this.point, required this.images});
}

// Database class
@DriftDatabase(tables: [Projects, Points, Images])
class TeleferikaDatabase extends _$TeleferikaDatabase {
  static final Logger _logger = Logger('TeleferikaDatabase');

  TeleferikaDatabase() : super(_openConnection()) {
    _logger.info('TeleferikaDatabase initialized');
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        _logger.info('Creating database schema (version $schemaVersion)');
        await m.createAll();
        _logger.info('Database schema created successfully');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        _logger.info('Upgrading database from version $from to $to');
        // Handle migrations here if needed
        // For now, we'll start fresh with version 1
        _logger.info('Database upgrade completed');
      },
    );
  }

  // Project operations
  Future<List<Project>> getAllProjects() async {
    _logger.fine('Getting all projects');
    try {
      final projectList = await select(projects).get();
      _logger.fine('Retrieved ${projectList.length} projects');
      return projectList;
    } catch (e) {
      _logger.severe('Error getting all projects: $e');
      rethrow;
    }
  }

  Future<Project?> getProjectById(String id) async {
    _logger.fine('Getting project by ID: $id');
    try {
      final project = await (select(
        projects,
      )..where((p) => p.id.equals(id))).getSingleOrNull();
      if (project != null) {
        _logger.fine('Project found: ${project.name}');
      } else {
        _logger.fine('Project not found with ID: $id');
      }
      return project;
    } catch (e) {
      _logger.severe('Error getting project by ID $id: $e');
      rethrow;
    }
  }

  Future<int> insertProject(ProjectCompanion project) async {
    _logger.fine('Inserting project: ${project.name.value}');
    try {
      final id = await into(projects).insert(project);
      _logger.fine('Project inserted with ID: $id');
      return id;
    } catch (e) {
      _logger.severe('Error inserting project: $e');
      rethrow;
    }
  }

  Future<bool> updateProject(ProjectCompanion project) async {
    _logger.fine('Updating project: ${project.id.value}');
    try {
      final success = await update(projects).replace(project);
      _logger.fine('Project update ${success ? 'succeeded' : 'failed'}');
      return success;
    } catch (e) {
      _logger.severe('Error updating project: $e');
      rethrow;
    }
  }

  Future<int> deleteProject(String id) async {
    _logger.fine('Deleting project: $id');
    try {
      final deleted = await (delete(
        projects,
      )..where((p) => p.id.equals(id))).go();
      _logger.fine('Deleted $deleted project(s)');
      return deleted;
    } catch (e) {
      _logger.severe('Error deleting project $id: $e');
      rethrow;
    }
  }

  // Point operations
  Future<List<Point>> getPointsForProject(String projectId) async {
    _logger.fine('Getting points for project: $projectId');
    try {
      final pointList =
          await (select(points)
                ..where((p) => p.projectId.equals(projectId))
                ..orderBy([(p) => OrderingTerm(expression: p.ordinalNumber)]))
              .get();
      _logger.fine(
        'Retrieved ${pointList.length} points for project $projectId',
      );
      return pointList;
    } catch (e) {
      _logger.severe('Error getting points for project $projectId: $e');
      rethrow;
    }
  }

  Future<Point?> getPointById(String id) async {
    _logger.fine('Getting point by ID: $id');
    try {
      final point = await (select(
        points,
      )..where((p) => p.id.equals(id))).getSingleOrNull();
      if (point != null) {
        _logger.fine('Point found: ${point.latitude}, ${point.longitude}');
      } else {
        _logger.fine('Point not found with ID: $id');
      }
      return point;
    } catch (e) {
      _logger.severe('Error getting point by ID $id: $e');
      rethrow;
    }
  }

  Future<int> insertPoint(PointCompanion point) async {
    _logger.fine('Inserting point: ${point.id.value}');
    try {
      final id = await into(points).insert(point);
      _logger.fine('Point inserted with ID: $id');
      return id;
    } catch (e) {
      _logger.severe('Error inserting point: $e');
      rethrow;
    }
  }

  Future<bool> updatePoint(PointCompanion point) async {
    _logger.fine('Updating point: ${point.id.value}');
    try {
      final success = await update(points).replace(point);
      _logger.fine('Point update ${success ? 'succeeded' : 'failed'}');
      return success;
    } catch (e) {
      _logger.severe('Error updating point: $e');
      rethrow;
    }
  }

  Future<int> deletePoint(String id) async {
    _logger.fine('Deleting point: $id');
    try {
      final deleted = await (delete(
        points,
      )..where((p) => p.id.equals(id))).go();
      _logger.fine('Deleted $deleted point(s)');
      return deleted;
    } catch (e) {
      _logger.severe('Error deleting point $id: $e');
      rethrow;
    }
  }

  // Image operations
  Future<List<Image>> getImagesForPoint(String pointId) async {
    _logger.fine('Getting images for point: $pointId');
    try {
      final imageList =
          await (select(images)
                ..where((i) => i.pointId.equals(pointId))
                ..orderBy([(i) => OrderingTerm(expression: i.ordinalNumber)]))
              .get();
      _logger.fine('Retrieved ${imageList.length} images for point $pointId');
      return imageList;
    } catch (e) {
      _logger.severe('Error getting images for point $pointId: $e');
      rethrow;
    }
  }

  Future<Image?> getImageById(String id) async {
    _logger.fine('Getting image by ID: $id');
    try {
      final image = await (select(
        images,
      )..where((i) => i.id.equals(id))).getSingleOrNull();
      if (image != null) {
        _logger.fine('Image found: ${image.imagePath}');
      } else {
        _logger.fine('Image not found with ID: $id');
      }
      return image;
    } catch (e) {
      _logger.severe('Error getting image by ID $id: $e');
      rethrow;
    }
  }

  Future<int> insertImage(ImageCompanion image) async {
    _logger.fine('Inserting image: ${image.id.value}');
    try {
      final id = await into(images).insert(image);
      _logger.fine('Image inserted with ID: $id');
      return id;
    } catch (e) {
      _logger.severe('Error inserting image: $e');
      rethrow;
    }
  }

  Future<bool> updateImage(ImageCompanion image) async {
    _logger.fine('Updating image: ${image.id.value}');
    try {
      final success = await update(images).replace(image);
      _logger.fine('Image update ${success ? 'succeeded' : 'failed'}');
      return success;
    } catch (e) {
      _logger.severe('Error updating image: $e');
      rethrow;
    }
  }

  Future<int> deleteImage(String id) async {
    _logger.fine('Deleting image: $id');
    try {
      final deleted = await (delete(
        images,
      )..where((i) => i.id.equals(id))).go();
      _logger.fine('Deleted $deleted image(s)');
      return deleted;
    } catch (e) {
      _logger.severe('Error deleting image $id: $e');
      rethrow;
    }
  }

  // Complex queries
  Future<List<ProjectWithPoints>> getAllProjectsWithPoints() async {
    _logger.fine('Getting all projects with points');
    try {
      final allProjects = await getAllProjects();
      final result = <ProjectWithPoints>[];

      for (final project in allProjects) {
        final projectPoints = await getPointsForProject(project.id);
        final pointsWithImages = <PointWithImages>[];

        for (final point in projectPoints) {
          final pointImages = await getImagesForPoint(point.id);
          pointsWithImages.add(
            PointWithImages(point: point, images: pointImages),
          );
        }

        result.add(
          ProjectWithPoints(project: project, points: pointsWithImages),
        );
      }

      _logger.fine('Retrieved ${result.length} projects with points');
      return result;
    } catch (e) {
      _logger.severe('Error getting all projects with points: $e');
      rethrow;
    }
  }

  Future<ProjectWithPoints?> getProjectWithPoints(String projectId) async {
    _logger.fine('Getting project with points: $projectId');
    try {
      final project = await getProjectById(projectId);
      if (project == null) return null;

      final projectPoints = await getPointsForProject(projectId);
      final pointsWithImages = <PointWithImages>[];

      for (final point in projectPoints) {
        final pointImages = await getImagesForPoint(point.id);
        pointsWithImages.add(
          PointWithImages(point: point, images: pointImages),
        );
      }

      final result = ProjectWithPoints(
        project: project,
        points: pointsWithImages,
      );
      _logger.fine('Retrieved project with ${pointsWithImages.length} points');
      return result;
    } catch (e) {
      _logger.severe('Error getting project with points $projectId: $e');
      rethrow;
    }
  }

  Future<PointWithImages?> getPointWithImages(String pointId) async {
    _logger.fine('Getting point with images: $pointId');
    try {
      final point = await getPointById(pointId);
      if (point == null) return null;

      final pointImages = await getImagesForPoint(pointId);
      final result = PointWithImages(point: point, images: pointImages);
      _logger.fine('Retrieved point with ${pointImages.length} images');
      return result;
    } catch (e) {
      _logger.severe('Error getting point with images $pointId: $e');
      rethrow;
    }
  }

  // Update project timestamp
  Future<void> updateProjectTimestamp(String projectId) async {
    _logger.fine('Updating project timestamp: $projectId');
    try {
      final now = DateTime.now().toIso8601String();
      await (update(projects)..where((p) => p.id.equals(projectId))).write(
        ProjectCompanion(lastUpdate: Value(now)),
      );
      _logger.fine('Project timestamp updated successfully');
    } catch (e) {
      _logger.severe('Error updating project timestamp $projectId: $e');
      rethrow;
    }
  }
}

LazyDatabase _openConnection() {
  final logger = Logger('DatabaseConnection');
  logger.info('Opening database connection');

  return LazyDatabase(() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'Teleferika.db'));
      logger.info('Database file path: ${file.path}');

      final database = NativeDatabase.createInBackground(file);
      logger.info('Database connection created successfully');
      return database;
    } catch (e) {
      logger.severe('Error creating database connection: $e');
      rethrow;
    }
  });
}
