// This is the database.dart file for Drift
import 'dart:async';
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

class NtripSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // Display name for the host
  TextColumn get country => text()(); // Country name
  TextColumn get state =>
      text().nullable()(); // State/Region (optional, "Regione" in Italian)
  TextColumn get host => text()();
  IntColumn get port => integer()();
  TextColumn get mountPoint => text()();
  TextColumn get username => text()();
  TextColumn get password => text()();
  BoolColumn get useSsl => boolean().withDefault(const Constant(false))();
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

// Query interceptor for monitoring database operations
class DatabaseQueryInterceptor extends QueryInterceptor {
  final Logger _logger = Logger('DatabaseQueryInterceptor');

  Future<T> _run<T>(
    String description,
    FutureOr<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    _logger.finest('Running: $description');
    try {
      final result = await operation();
      _logger.finest(' => succeeded after ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      _logger.warning(
        ' => failed after ${stopwatch.elapsedMilliseconds}ms: $e',
      );
      rethrow;
    }
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _run(
      'SELECT: $statement (args: $args)',
      () => executor.runSelect(statement, args),
    );
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _run(
      'UPDATE: $statement (args: $args)',
      () => executor.runUpdate(statement, args),
    );
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _run(
      'INSERT: $statement (args: $args)',
      () => executor.runInsert(statement, args),
    );
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _run(
      'DELETE: $statement (args: $args)',
      () => executor.runDelete(statement, args),
    );
  }

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _run(
      'CUSTOM: $statement (args: $args)',
      () => executor.runCustom(statement, args),
    );
  }
}

// Database class
@DriftDatabase(tables: [Projects, Points, Images, NtripSettings])
class TeleferikaDatabase extends _$TeleferikaDatabase {
  static final Logger _logger = Logger('TeleferikaDatabase');

  TeleferikaDatabase() : super(_openConnection()) {
    _logger.info('TeleferikaDatabase initialized');
  }

  @override
  int get schemaVersion => 3;

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

        if (from < 2) {
          // Add NtripSettings table for version 2
          _logger.info('Adding ntrip_settings table');
          await m.createTable(ntripSettings);
          _logger.info('ntrip_settings table created');
        }

        if (from < 3) {
          // Add new fields to NtripSettings table for version 3
          _logger.info(
            'Adding name, country, and state fields to ntrip_settings table',
          );

          // SQLite requires default values when adding NOT NULL columns to existing tables
          // We'll add the columns with temporary defaults, then update the data
          await customStatement(
            'ALTER TABLE ntrip_settings ADD COLUMN name TEXT NOT NULL DEFAULT \'Default\'',
          );
          await customStatement(
            'ALTER TABLE ntrip_settings ADD COLUMN country TEXT NOT NULL DEFAULT \'Unknown\'',
          );
          await customStatement(
            'ALTER TABLE ntrip_settings ADD COLUMN state TEXT',
          );

          // Migrate existing data: update with better default values if needed
          final existingSettings = await (select(
            ntripSettings,
          )..where((t) => t.id.equals(1))).getSingleOrNull();

          if (existingSettings != null) {
            // Update existing row with default values based on host if possible
            final hostName = existingSettings.host;
            final defaultName = hostName.isNotEmpty ? hostName : 'Default';

            await (update(ntripSettings)..where((t) => t.id.equals(1))).write(
              NtripSettingCompanion(
                name: Value(defaultName),
                country: const Value('Unknown'),
                state: const Value(null),
              ),
            );
            _logger.info(
              'Migrated existing NTRIP settings with default values',
            );
          }

          _logger.info('ntrip_settings table updated with new fields');
        }

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
      // For text primary keys, insert returns the number of rows affected (1 if successful)
      final rowsAffected = await into(projects).insert(project);
      _logger.fine(
        'Project inserted successfully. Rows affected: $rowsAffected',
      );
      // Return 1 to indicate success (the actual ID is in project.id.value)
      return rowsAffected > 0 ? 1 : 0;
    } catch (e, stackTrace) {
      _logger.severe('Error inserting project: $e', e, stackTrace);
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

  /// Batch insert multiple images atomically (more efficient than individual inserts)
  Future<void> insertImages(List<ImageCompanion> imageList) async {
    if (imageList.isEmpty) {
      _logger.fine('No images to insert');
      return;
    }
    _logger.fine('Batch inserting ${imageList.length} images');
    try {
      await batch((batch) {
        batch.insertAll(images, imageList);
      });
      _logger.fine('Successfully batch inserted ${imageList.length} images');
    } catch (e) {
      _logger.severe('Error batch inserting images: $e');
      rethrow;
    }
  }

  /// Batch delete multiple images by their IDs
  Future<int> deleteImagesByIds(List<String> ids) async {
    if (ids.isEmpty) {
      _logger.fine('No images to delete');
      return 0;
    }
    _logger.fine('Batch deleting ${ids.length} images');
    try {
      final deleted = await (delete(images)..where((i) => i.id.isIn(ids))).go();
      _logger.fine('Successfully deleted $deleted image(s)');
      return deleted;
    } catch (e) {
      _logger.severe('Error batch deleting images: $e');
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

  // NTRIP Settings operations
  Future<List<NtripSetting>> getAllNtripSettings() async {
    _logger.fine('Getting all NTRIP settings');
    try {
      final settingsList = await select(ntripSettings).get();
      _logger.fine('Retrieved ${settingsList.length} NTRIP settings');
      return settingsList;
    } catch (e) {
      _logger.severe('Error getting all NTRIP settings: $e');
      rethrow;
    }
  }

  Future<List<NtripSetting>> getNtripSettingsByCountry(String country) async {
    _logger.fine('Getting NTRIP settings for country: $country');
    try {
      final settingsList = await (select(
        ntripSettings,
      )..where((t) => t.country.equals(country))).get();
      _logger.fine(
        'Retrieved ${settingsList.length} NTRIP settings for $country',
      );
      return settingsList;
    } catch (e) {
      _logger.severe('Error getting NTRIP settings by country: $e');
      rethrow;
    }
  }

  Future<List<NtripSetting>> getNtripSettingsByCountryAndState(
    String country,
    String? state,
  ) async {
    _logger.fine('Getting NTRIP settings for country: $country, state: $state');
    try {
      final query = select(ntripSettings)
        ..where((t) => t.country.equals(country));

      if (state == null || state == 'N/A') {
        query.where((t) => t.state.isNull());
      } else {
        query.where((t) => t.state.equals(state));
      }

      final settingsList = await query.get();
      _logger.fine(
        'Retrieved ${settingsList.length} NTRIP settings for $country, $state',
      );
      return settingsList;
    } catch (e) {
      _logger.severe('Error getting NTRIP settings by country and state: $e');
      rethrow;
    }
  }

  Future<NtripSetting?> getNtripSettingById(int id) async {
    _logger.fine('Getting NTRIP setting by ID: $id');
    try {
      final settings = await (select(
        ntripSettings,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      return settings;
    } catch (e) {
      _logger.severe('Error getting NTRIP setting by ID: $e');
      rethrow;
    }
  }

  // Legacy method for backward compatibility - gets first setting or null
  Future<NtripSetting?> getNtripSettings() async {
    _logger.fine('Getting first NTRIP settings (legacy method)');
    try {
      final settingsList = await select(ntripSettings).get();
      return settingsList.isNotEmpty ? settingsList.first : null;
    } catch (e) {
      _logger.severe('Error getting NTRIP settings: $e');
      rethrow;
    }
  }

  Future<int> insertNtripSetting(NtripSettingCompanion settings) async {
    _logger.fine('Inserting NTRIP setting: ${settings.name.value}');
    try {
      final id = await into(ntripSettings).insert(settings);
      _logger.fine('NTRIP setting inserted with ID: $id');
      return id;
    } catch (e) {
      _logger.severe('Error inserting NTRIP setting: $e');
      rethrow;
    }
  }

  Future<bool> updateNtripSetting(NtripSettingCompanion settings) async {
    _logger.fine('Updating NTRIP setting');
    try {
      final id = settings.id.value;
      if (id == null) {
        throw ArgumentError('ID is required for update');
      }
      final rowsAffected = await (update(
        ntripSettings,
      )..where((t) => t.id.equals(id))).write(settings);
      final success = rowsAffected > 0;
      _logger.fine('NTRIP setting update ${success ? 'succeeded' : 'failed'}');
      return success;
    } catch (e) {
      _logger.severe('Error updating NTRIP setting: $e');
      rethrow;
    }
  }

  Future<int> deleteNtripSetting(int id) async {
    _logger.fine('Deleting NTRIP setting: $id');
    try {
      final deleted = await (delete(
        ntripSettings,
      )..where((t) => t.id.equals(id))).go();
      _logger.fine('Deleted $deleted NTRIP setting(s)');
      return deleted;
    } catch (e) {
      _logger.severe('Error deleting NTRIP setting: $e');
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Future<void> saveNtripSettings(NtripSettingCompanion settings) async {
    _logger.fine('Saving NTRIP settings (legacy method)');
    try {
      // If ID is provided, update; otherwise insert
      final id = settings.id.value;
      if (id != null) {
        await updateNtripSetting(settings);
      } else {
        await insertNtripSetting(settings);
      }
      _logger.fine('NTRIP settings saved successfully');
    } catch (e) {
      _logger.severe('Error saving NTRIP settings: $e');
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

      // Use NativeDatabase directly instead of createInBackground to ensure
      // synchronous initialization and avoid potential race conditions
      final database = NativeDatabase(file);

      // Apply query interceptor for monitoring
      final interceptedDatabase = database.interceptWith(
        DatabaseQueryInterceptor(),
      );
      logger.info('Database connection created successfully with interceptor');
      return interceptedDatabase;
    } catch (e, stackTrace) {
      logger.severe('Error creating database connection: $e', e, stackTrace);
      rethrow;
    }
  });
}
