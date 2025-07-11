# Database Layer Documentation

This document describes the database architecture, migration from sqflite to drift, and how to handle schema changes.

## Overview

The Teleferika application uses **Drift** (formerly Moor) as its database solution, providing type-safe database operations with automatic code generation. This replaces the previous direct sqflite implementation.

## Architecture

### Database Components

1. **`database.dart`** - Main database definition with table schemas and Drift configuration
2. **`drift_database_helper.dart`** - Helper class providing a familiar interface for database operations
3. **`models/`** - Data models that abstract the database layer
   - `project_model.dart` - Project data model
   - `point_model.dart` - Geographic point data model  
   - `image_model.dart` - Image data model

### Key Features

- **Type Safety**: Drift provides compile-time type checking for all database operations
- **Code Generation**: Automatic generation of database classes and queries
- **Migration Support**: Built-in schema migration system
- **Transaction Support**: ACID-compliant database transactions
- **Relationship Handling**: Foreign key relationships with cascade operations

## Database Versioning and Migrations

### How Drift Handles Versions

Drift uses the `schemaVersion` property in the `TeleferikaDatabase` class as the single source of truth for database versioning:

```dart
@override
int get schemaVersion => 1;
```

### Migration Strategy

Schema changes are handled through the `MigrationStrategy` in the database class:

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      // Called when creating a new database
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Called when upgrading from version 'from' to version 'to'
      // Handle schema changes here
    },
  );
}
```

### Making Schema Changes

When you need to modify the database schema, follow these steps:

#### Step 1: Update Table Definitions

Modify the table classes in `database.dart`:

```dart
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get note => text().nullable()();
  RealColumn get azimuth => real().nullable()();
  TextColumn get lastUpdate => text().nullable()();
  TextColumn get date => text().nullable()();
  RealColumn get presumedTotalLength => real().nullable()();
  
  // NEW COLUMN - Add your changes here
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### Step 2: Increment Schema Version

Update the schema version in `TeleferikaDatabase`:

```dart
@override
int get schemaVersion => 2; // Increment from current version
```

#### Step 3: Add Migration Logic

Add the migration logic in the `onUpgrade` method:

```dart
onUpgrade: (Migrator m, int from, int to) async {
  _logger.info('Upgrading database from version $from to $to');
  
  if (from < 2) {
    // Add the new description column to existing projects table
    await m.addColumn(projects, projects.description);
    _logger.info('Added description column to projects table');
  }
  
  _logger.info('Database upgrade completed');
},
```

#### Step 4: Update Model Classes

Update the corresponding model classes to include the new fields:

```dart
class ProjectModel {
  // ... existing fields ...
  final String? description; // Add new field
  
  ProjectModel({
    // ... existing parameters ...
    this.description,
  });
  
  // Update toMap, fromMap, copyWith methods
}
```

#### Step 5: Regenerate Code

Run the code generation to update the generated files:

```bash
flutter packages pub run build_runner build
```

### Available Migration Operations

Drift provides several migration operations for schema changes:

```dart
// Add a column
await m.addColumn(table, table.newColumn);

// Drop a column
await m.dropColumn(table, table.oldColumn);

// Rename a column
await m.renameColumn(table, table.oldColumn, table.newColumn);

// Create a new table
await m.createTable(newTable);

// Drop a table
await m.dropTable(oldTable);

// Execute custom SQL
await m.customStatement('ALTER TABLE projects ADD COLUMN description TEXT');
```

### Complex Migration Example

Here's an example of a migration that handles multiple changes:

```dart
onUpgrade: (Migrator m, int from, int to) async {
  _logger.info('Upgrading database from version $from to $to');
  
  // Handle upgrades to version 2
  if (from < 2) {
    await m.addColumn(projects, projects.description);
    _logger.info('Added description column');
  }
  
  // Handle upgrades to version 3
  if (from < 3) {
    await m.addColumn(points, points.gpsAccuracy);
    await m.renameColumn(points, points.gpsPrecision, points.gpsPrecisionOld);
    _logger.info('Added gpsAccuracy and renamed gpsPrecision');
  }
  
  // Handle upgrades to version 4
  if (from < 4) {
    await m.dropColumn(points, points.gpsPrecisionOld);
    _logger.info('Dropped old gpsPrecision column');
  }
  
  _logger.info('Database upgrade completed');
},
```

## Model Layer

### Data Models

The application uses three main data models that abstract the database layer:

#### ProjectModel
- Represents a photogrammetry project
- Contains project metadata (name, notes, azimuth, etc.)
- Has an in-memory list of associated points
- Provides methods for rope length calculations and validation

#### PointModel
- Represents a geographic point within a project
- Contains coordinates (latitude, longitude, altitude)
- Has an in-memory list of associated images
- Provides distance calculation methods
- Includes GPS precision and timestamp data

#### ImageModel
- Represents an image associated with a point
- Contains file path, ordinal number, and notes
- Linked to points via foreign key relationship

### Model Features

- **Immutability**: All models are immutable for thread safety
- **Validation**: Built-in validation methods for data integrity
- **Serialization**: `toMap()` and `fromMap()` methods for data persistence
- **Copy Operations**: `copyWith()` methods for creating modified instances
- **Relationship Management**: Automatic handling of related data

## Database Helper

### DriftDatabaseHelper

The `DriftDatabaseHelper` class provides a familiar interface for database operations, abstracting away the Drift-specific details:

#### Key Features
- **Singleton Pattern**: Single instance ensures consistent state
- **Conversion Methods**: Automatic conversion between Drift entities and model classes
- **Transaction Support**: Wrapped operations in transactions where appropriate
- **Error Handling**: Comprehensive error handling and logging
- **Timestamp Management**: Automatic updating of project timestamps

#### Usage Example

```dart
final dbHelper = DriftDatabaseHelper.instance;

// Get all projects with their points
final projects = await dbHelper.getAllProjects();

// Insert a new project
final project = ProjectModel(name: 'New Project', note: 'Project description');
final projectId = await dbHelper.insertProject(project);

// Get points for a project
final points = await dbHelper.getPointsForProject(projectId);
```

## Migration from sqflite

### What Changed

1. **Database Engine**: Replaced direct sqflite with Drift
2. **Type Safety**: Added compile-time type checking
3. **Code Generation**: Automatic generation of database classes
4. **Migration System**: Built-in schema migration support
5. **Query Builder**: Type-safe query building

### What Stayed the Same

1. **Model Interfaces**: All model classes maintain the same public interface
2. **Helper Methods**: Database helper provides the same methods
3. **Data Structure**: Database schema remains compatible
4. **External Dependencies**: Licensed features package continues to work unchanged

### Compatibility

The migration maintains full backward compatibility:
- All existing data is preserved
- Model classes have the same interface
- Database helper provides the same methods
- External packages (like licensed_features_package) work without changes

### Data Migration from Old sqflite Database

When users upgrade from the old sqflite version to the new drift version, their existing data needs to be migrated. This is handled automatically by the migration system.

#### Migration Components

1. **`SqliteMigrationHelper`**: Handles the actual data migration from old to new database
2. **`MigrationService`**: Manages the migration process and user feedback
3. **Automatic Detection**: The system automatically detects if migration is needed

#### Migration Process

1. **Detection**: App checks for old sqflite database on startup
2. **Statistics**: Calculates how much data needs to be migrated
3. **Migration**: Transfers all projects, points, and images to new database
4. **Backup**: Creates a backup of the old database
5. **Cleanup**: Removes the old database after successful migration
6. **User Feedback**: Shows migration progress and results to user

#### Migration Features

- **Automatic**: No user intervention required
- **Safe**: Creates backup before migration
- **Comprehensive**: Migrates all data types (projects, points, images)
- **Error Handling**: Graceful handling of migration failures
- **Progress Feedback**: User sees migration progress and results
- **Rollback**: Old database is preserved until migration succeeds

#### Usage in App

```dart
// In your app startup (e.g., main.dart or initial screen)
final migrationResult = await MigrationService.performMigrationIfNeeded();

if (migrationResult.status != MigrationStatus.notNeeded) {
  MigrationService.showMigrationDialog(context, migrationResult);
}
```

#### Migration Statistics

The migration system provides detailed statistics:
- Number of projects migrated
- Number of points migrated  
- Number of images migrated
- Migration success/failure status

#### Error Handling

If migration fails:
- Old database remains untouched
- User is informed of the error
- App continues to work normally
- Migration can be retried later

## Best Practices

### Database Operations

1. **Use Transactions**: Wrap related operations in transactions
2. **Handle Errors**: Always catch and log database errors
3. **Update Timestamps**: Keep project timestamps current
4. **Validate Data**: Use model validation before database operations

### Schema Changes

1. **Test Migrations**: Always test on a copy of production data
2. **Incremental Versions**: Use sequential version numbers (1, 2, 3, etc.)
3. **Handle All Paths**: Consider users who might skip versions
4. **Log Changes**: Add logging for debugging migration issues
5. **Make Reversible**: Design migrations to be reversible when possible

### Code Organization

1. **Separation of Concerns**: Keep database logic separate from business logic
2. **Model Abstraction**: Use models to abstract database details
3. **Helper Methods**: Use the database helper for all database operations
4. **Type Safety**: Leverage Drift's type safety features

## Troubleshooting

### Common Issues

1. **Code Generation Errors**: Run `flutter packages pub run build_runner build`
2. **Migration Failures**: Check logs for specific error messages
3. **Type Errors**: Ensure all model fields match table definitions
4. **Performance Issues**: Use transactions for bulk operations

### Debugging

1. **Enable Logging**: Database operations are logged for debugging
2. **Check Schema Version**: Verify the current schema version
3. **Test Migrations**: Use test data to verify migration logic
4. **Review Generated Code**: Check generated files for issues

## Dependencies

### Required Packages

```yaml
dependencies:
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.5
  path: ^1.8.0

dev_dependencies:
  drift_dev: ^2.14.0
  build_runner: ^2.4.0
```

### Code Generation

Run code generation after schema changes:

```bash
# Generate code
flutter packages pub run build_runner build

# Watch for changes (development)
flutter packages pub run build_runner watch

# Clean and regenerate
flutter packages pub run build_runner clean
flutter packages pub run build_runner build
```

## Future Considerations

### Potential Improvements

1. **Database Encryption**: Add encryption for sensitive data
2. **Backup/Restore**: Implement database backup and restore functionality
3. **Performance Optimization**: Add database indexes for common queries
4. **Data Validation**: Enhanced validation rules and constraints

### Migration Planning

1. **Version Strategy**: Plan for future schema changes
2. **Data Integrity**: Ensure data consistency across migrations
3. **Performance Impact**: Consider performance implications of schema changes
4. **Rollback Strategy**: Plan for migration rollbacks if needed

## Database Files

The application uses the following database files:

- **Drift Database**: `Teleferika.db` - New drift-based database (created fresh)
- **Old Database**: `photogrammetry.db` - Legacy sqflite database (preserved for migration)

### Database Naming Strategy

To ensure safe migration from sqflite to drift:

1. **Drift Database**: Uses `Teleferika.db` to avoid conflicts with existing data
2. **Old Database**: Preserves `photogrammetry.db` for data migration
3. **Initialization**: Drift database is initialized in `main()` before any UI loads
4. **Migration**: Old data is migrated in `LoadingScreen` after drift is ready

---

For more information about Drift, see the [official documentation](https://drift.simonbinder.eu/). 