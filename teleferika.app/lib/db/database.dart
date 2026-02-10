// This is the database.dart file for Drift
import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';
import 'package:teleferika/projects/cable_equipment_presets.dart';

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
  TextColumn get cableEquipmentTypeId => text().nullable()();

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

class CableTypes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get diameterMm => real()();
  RealColumn get weightPerMeterKg => real()();
  RealColumn get breakingLoadKn => real()();
  RealColumn get elasticModulusGPa => real().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

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
  BoolColumn get lastConnectionSuccessful => boolean()
      .nullable()(); // Whether the last connection attempt was successful
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

/// Result of projects left-join points (single query, no N+1).
/// Used by [TeleferikaDatabase.getAllProjectsWithPointsJoined].
class ProjectWithPointsRaw {
  final Project project;
  final List<Point> points;

  ProjectWithPointsRaw({required this.project, required this.points});
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
@DriftDatabase(tables: [Projects, Points, Images, CableTypes, NtripSettings])
class TeleferikaDatabase extends _$TeleferikaDatabase {
  static final Logger _logger = Logger('TeleferikaDatabase');

  TeleferikaDatabase() : super(_openConnection()) {
    _logger.info('TeleferikaDatabase initialized');
  }

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        _logger.info('Creating database schema (version $schemaVersion)');
        await m.createAll();
        await _seedCableTypes();
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
          // Add new fields to NtripSettings table for version 3 (idempotent: skip if already present)
          _logger.info(
            'Adding name, country, and state fields to ntrip_settings table',
          );

          final columns = await _getTableColumnNames('ntrip_settings');

          // SQLite requires default values when adding NOT NULL columns to existing tables
          if (!columns.contains('name')) {
            await customStatement(
              'ALTER TABLE ntrip_settings ADD COLUMN name TEXT NOT NULL DEFAULT \'Default\'',
            );
          }
          if (!columns.contains('country')) {
            await customStatement(
              'ALTER TABLE ntrip_settings ADD COLUMN country TEXT NOT NULL DEFAULT \'Unknown\'',
            );
          }
          if (!columns.contains('state')) {
            await customStatement(
              'ALTER TABLE ntrip_settings ADD COLUMN state TEXT',
            );
          }

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

        if (from < 4) {
          // Add lastConnectionSuccessful field to NtripSettings table for version 4 (idempotent)
          _logger.info(
            'Adding lastConnectionSuccessful field to ntrip_settings table',
          );

          final columns = await _getTableColumnNames('ntrip_settings');
          if (!columns.contains('last_connection_successful')) {
            await customStatement(
              'ALTER TABLE ntrip_settings ADD COLUMN last_connection_successful INTEGER',
            );
          }

          _logger.info(
            'ntrip_settings table updated with lastConnectionSuccessful field',
          );
        }

        if (from < 5) {
          // Add cable/equipment type to projects + cable_types table (idempotent)
          _logger.info(
            'Adding cable_equipment_type_id column and cable_types table',
          );

          final projectColumns = await _getTableColumnNames('projects');
          if (!projectColumns.contains('cable_equipment_type_id')) {
            await customStatement(
              'ALTER TABLE projects ADD COLUMN cable_equipment_type_id TEXT',
            );
          }

          await m.createTable(cableTypes);
          await _seedCableTypes();

          _logger.info(
            'projects and cable_types updated for version 5',
          );
        }

        _logger.info('Database upgrade completed');
      },
    );
  }

  /// Seeds built-in cable types (Italy/EU forestry). Idempotent: only inserts
  /// when the table is empty so migration can be re-run safely.
  /// Uses [cableEquipmentTypeSeedData] with fixed UUIDs.
  Future<void> _seedCableTypes() async {
    final existing = await select(cableTypes).get();
    if (existing.isNotEmpty) {
      _logger.fine('cable_types already seeded (${existing.length} rows), skipping');
      return;
    }
    for (final row in cableEquipmentTypeSeedData) {
      await into(cableTypes).insert(CableTypeCompanion(
        id: Value(row.id),
        name: Value(row.name),
        diameterMm: Value(row.diameterMm),
        weightPerMeterKg: Value(row.weightPerMeterKg),
        breakingLoadKn: Value(row.breakingLoadKn),
        elasticModulusGPa: row.elasticModulusGPa != null
            ? Value(row.elasticModulusGPa)
            : const Value.absent(),
        sortOrder: Value(row.sortOrder),
      ));
    }
    _logger.info('Seeded ${cableEquipmentTypeSeedData.length} cable types');
  }

  /// Returns the set of column names for [tableName]. Used to make migrations
  /// idempotent (skip ADD COLUMN if column already exists).
  Future<Set<String>> _getTableColumnNames(String tableName) async {
    final rows = await customSelect('PRAGMA table_info($tableName)').get();
    return rows.map((r) => r.read<String>('name')).toSet();
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

  // Cable type operations
  Future<List<CableType>> getAllCableTypes() async {
    _logger.fine('Getting all cable types');
    try {
      final list = await (select(cableTypes)
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();
      _logger.fine('Retrieved ${list.length} cable types');
      return list;
    } catch (e) {
      _logger.severe('Error getting cable types: $e');
      rethrow;
    }
  }

  Future<CableType?> getCableTypeById(String id) async {
    _logger.fine('Getting cable type by ID: $id');
    try {
      return await (select(cableTypes)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
    } catch (e) {
      _logger.severe('Error getting cable type $id: $e');
      rethrow;
    }
  }

  Future<int> insertCableType(CableTypeCompanion cableType) async {
    _logger.fine('Inserting cable type: ${cableType.name.value}');
    try {
      final rowsAffected = await into(cableTypes).insert(cableType);
      return rowsAffected > 0 ? 1 : 0;
    } catch (e, stackTrace) {
      _logger.severe('Error inserting cable type: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> updateCableType(CableTypeCompanion cableType) async {
    _logger.fine('Updating cable type: ${cableType.id.value}');
    try {
      return await update(cableTypes).replace(cableType);
    } catch (e) {
      _logger.severe('Error updating cable type: $e');
      rethrow;
    }
  }

  Future<int> deleteCableType(String id) async {
    _logger.fine('Deleting cable type: $id');
    try {
      return await (delete(cableTypes)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      _logger.severe('Error deleting cable type $id: $e');
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

  /// Loads all images for the given point IDs in one query.
  /// Returns a map from pointId to list of images (ordered by ordinalNumber).
  Future<Map<String, List<Image>>> getImagesForPointIds(
    List<String> pointIds,
  ) async {
    if (pointIds.isEmpty) {
      return {};
    }
    _logger.fine('Getting images for ${pointIds.length} points (batch)');
    try {
      final imageList = await (select(images)
            ..where((i) => i.pointId.isIn(pointIds))
            ..orderBy([(i) => OrderingTerm(expression: i.ordinalNumber)]))
          .get();
      final map = <String, List<Image>>{};
      for (final img in imageList) {
        map.putIfAbsent(img.pointId, () => []).add(img);
      }
      _logger.fine('Retrieved ${imageList.length} images for ${map.length} points');
      return map;
    } catch (e) {
      _logger.severe('Error getting images for point IDs: $e');
      rethrow;
    }
  }

  /// Returns all projects with their points in a single join query (avoids N+1).
  /// Points are ordered by [Points.ordinalNumber].
  Future<List<ProjectWithPointsRaw>> getAllProjectsWithPointsJoined() async {
    _logger.fine('Getting all projects with points (join)');
    try {
      final query = select(projects).join([
        leftOuterJoin(points, points.projectId.equalsExp(projects.id)),
      ])
        ..orderBy([
          OrderingTerm(expression: projects.id),
          OrderingTerm(expression: points.ordinalNumber),
        ]);
      final rows = await query.get();
      final map = <String, ProjectWithPointsRaw>{};
      for (final row in rows) {
        final project = row.readTable(projects);
        final point = row.readTableOrNull(points);
        map.putIfAbsent(
          project.id,
          () => ProjectWithPointsRaw(project: project, points: []),
        );
        if (point != null) {
          map[project.id]!.points.add(point);
        }
      }
      final result = map.values.toList();
      _logger.fine('Retrieved ${result.length} projects with points (join)');
      return result;
    } catch (e) {
      _logger.severe('Error getting all projects with points (join): $e');
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
      if (!settings.id.present) {
        throw ArgumentError('ID is required for update');
      }
      final id = settings.id.value;
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

  Future<int> deleteAllNtripSettings() async {
    _logger.fine('Deleting all NTRIP settings');
    try {
      final deleted = await delete(ntripSettings).go();
      _logger.fine('Deleted $deleted NTRIP setting(s)');
      return deleted;
    } catch (e) {
      _logger.severe('Error deleting all NTRIP settings: $e');
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Future<void> saveNtripSettings(NtripSettingCompanion settings) async {
    _logger.fine('Saving NTRIP settings (legacy method)');
    try {
      // If ID is provided, update; otherwise insert (use .present to distinguish set vs absent)
      if (settings.id.present) {
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

  /// Returns projects that use the given cable type (id and name only).
  Future<List<Project>> getProjectsUsingCableType(String cableTypeId) async {
    _logger.fine('Getting projects using cable type: $cableTypeId');
    try {
      final list = await (select(projects)
            ..where((p) => p.cableEquipmentTypeId.equals(cableTypeId)))
          .get();
      _logger.fine('Found ${list.length} project(s) using cable type');
      return list;
    } catch (e) {
      _logger.severe('Error getting projects by cable type: $e');
      rethrow;
    }
  }

  /// Clears [cableTypeId] from all projects that reference it (before deleting).
  Future<int> clearCableTypeFromProjects(String cableTypeId) async {
    _logger.fine('Clearing cable type $cableTypeId from projects');
    try {
      final now = DateTime.now().toIso8601String();
      final count = await (update(projects)
            ..where((p) => p.cableEquipmentTypeId.equals(cableTypeId)))
          .write(
        ProjectCompanion(
          cableEquipmentTypeId: const Value(null),
          lastUpdate: Value(now),
        ),
      );
      _logger.fine('Cleared cable type from $count project(s)');
      return count;
    } catch (e) {
      _logger.severe('Error clearing cable type from projects: $e');
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
