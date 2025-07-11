# Migration from sqflite to Drift

This document explains the migration from the existing sqflite-based database to Drift, a type-safe SQLite library for Dart.

## Why Migrate to Drift?

### Benefits of Drift:
1. **Type Safety**: Compile-time checking of database operations
2. **Code Generation**: Automatic generation of data classes and queries
3. **Better Performance**: Optimized SQL generation and execution
4. **Reactive Programming**: Built-in support for reactive queries with streams
5. **Migration Support**: Better handling of schema changes
6. **IDE Support**: Better autocomplete and error detection
7. **Testing**: Easier to mock and test database operations

### Current Issues with sqflite:
1. Manual SQL string construction (error-prone)
2. No compile-time type checking
3. Complex migration handling
4. Manual data class mapping
5. No reactive query support

## Migration Strategy

### Phase 1: Setup and Dependencies
- [x] Add Drift dependencies to `pubspec.yaml`
- [x] Create Drift database schema (`database.dart`)
- [x] Create Drift database helper (`drift_database_helper.dart`)
- [x] Create migration helper (`migration_helper.dart`)

### Phase 2: Code Generation
```bash
# Run the Drift code generator
dart run build_runner build
```

### Phase 3: Migration Implementation
- [ ] Complete the migration logic in `MigrationHelper`
- [ ] Add data insertion methods to `DriftDatabaseHelper`
- [ ] Test migration with existing data

### Phase 4: Application Integration
- [ ] Update application code to use `DriftDatabaseHelper` instead of `DatabaseHelper`
- [ ] Test all database operations
- [ ] Remove old `DatabaseHelper` and sqflite dependency

## File Structure

```
lib/db/
├── database.dart                    # Drift database schema and operations
├── database.g.dart                  # Generated Drift code (after build_runner)
├── drift_database_helper.dart       # Drift-based database helper
├── migration_helper.dart            # Migration from sqflite to Drift
├── database_helper.dart             # Old sqflite-based helper (to be removed)
├── models/                          # Existing model classes (unchanged)
│   ├── project_model.dart
│   ├── point_model.dart
│   └── image_model.dart
└── DRIFT_MIGRATION_README.md        # This file
```

## Database Schema

The Drift schema maintains the same structure as the existing database:

### Projects Table
- `id` (TEXT, PRIMARY KEY)
- `name` (TEXT, NOT NULL)
- `note` (TEXT, NULLABLE)
- `azimuth` (REAL, NULLABLE)
- `lastUpdate` (TEXT, NULLABLE) - ISO8601 DateTime string
- `date` (TEXT, NULLABLE) - ISO8601 DateTime string
- `presumedTotalLength` (REAL, NULLABLE)

### Points Table
- `id` (TEXT, PRIMARY KEY)
- `projectId` (TEXT, FOREIGN KEY to Projects.id, CASCADE DELETE)
- `latitude` (REAL, NOT NULL)
- `longitude` (REAL, NOT NULL)
- `altitude` (REAL, NULLABLE)
- `gpsPrecision` (REAL, NULLABLE)
- `ordinalNumber` (INTEGER, NOT NULL)
- `note` (TEXT, NULLABLE)
- `timestamp` (TEXT, NULLABLE) - ISO8601 DateTime string

### Images Table
- `id` (TEXT, PRIMARY KEY)
- `pointId` (TEXT, FOREIGN KEY to Points.id, CASCADE DELETE)
- `ordinalNumber` (INTEGER, NOT NULL)
- `imagePath` (TEXT, NOT NULL)
- `note` (TEXT, NULLABLE)

## Usage Examples

### Basic Operations

```dart
// Get the Drift database helper instance
final dbHelper = DriftDatabaseHelper.instance;

// Get all projects
final projects = await dbHelper.getAllProjects();

// Get a specific project with its points
final project = await dbHelper.getProjectById('project-id');

// Insert a new project
final newProject = ProjectModel(
  name: 'New Project',
  note: 'Project description',
);
await dbHelper.insertProject(newProject);

// Insert a point with images
final newPoint = PointModel(
  projectId: 'project-id',
  latitude: 45.12345,
  longitude: 11.12345,
  ordinalNumber: 1,
  images: [image1, image2],
);
await dbHelper.insertPoint(newPoint);
```

### Reactive Queries (Future Enhancement)

```dart
// Watch all projects (reactive)
final projectsStream = dbHelper.watchAllProjects();

// Watch a specific project
final projectStream = dbHelper.watchProject('project-id');
```

## Migration Process

### 1. Backup Existing Data
```dart
final migrationHelper = MigrationHelper();
await migrationHelper.backupOldDatabase();
```

### 2. Check if Migration is Needed
```dart
if (await migrationHelper.isMigrationNeeded()) {
  // Perform migration
  await migrationHelper.migrateToDrift();
}
```

### 3. Switch to Drift Database Helper
```dart
// Replace DatabaseHelper.instance with DriftDatabaseHelper.instance
// in your application code
```

## Testing

### Unit Tests
```dart
// Test database operations
test('should insert and retrieve project', () async {
  final dbHelper = DriftDatabaseHelper.instance;
  final project = ProjectModel(name: 'Test Project', note: 'Test');
  
  await dbHelper.insertProject(project);
  final retrieved = await dbHelper.getProjectById(project.id);
  
  expect(retrieved?.name, equals('Test Project'));
});
```

### Integration Tests
```dart
// Test migration process
test('should migrate data from sqflite to Drift', () async {
  final migrationHelper = MigrationHelper();
  final success = await migrationHelper.migrateToDrift();
  
  expect(success, isTrue);
});
```

## Performance Considerations

### Optimizations
1. **Batch Operations**: Use transactions for multiple operations
2. **Lazy Loading**: Load related data only when needed
3. **Indexing**: Drift automatically creates indexes for foreign keys
4. **Streaming**: Use reactive queries for real-time updates

### Memory Management
1. **Close Database**: Always close the database when done
2. **Limit Query Results**: Use pagination for large datasets
3. **Garbage Collection**: Drift handles memory management automatically

## Troubleshooting

### Common Issues

1. **Code Generation Errors**
   ```bash
   # Clean and regenerate
   dart run build_runner clean
   dart run build_runner build
   ```

2. **Migration Failures**
   - Check backup file exists
   - Verify old database structure
   - Review migration logs

3. **Performance Issues**
   - Use transactions for bulk operations
   - Add appropriate indexes
   - Monitor query performance

### Debugging

```dart
// Enable Drift logging
final db = TeleferikaDatabase();
db.logStatements = true; // Log all SQL statements
```

## Future Enhancements

1. **Reactive Queries**: Implement stream-based data watching
2. **Advanced Migrations**: Add support for complex schema changes
3. **Query Optimization**: Add custom indexes and query hints
4. **Caching**: Implement query result caching
5. **Offline Support**: Add conflict resolution for offline operations

## Rollback Plan

If issues arise during migration:

1. **Restore from Backup**
   ```dart
   await migrationHelper.restoreOldDatabase();
   ```

2. **Switch Back to sqflite**
   - Revert to `DatabaseHelper.instance`
   - Remove Drift dependencies

3. **Data Recovery**
   - Use backup file to restore data
   - Verify data integrity

## Conclusion

The migration to Drift provides significant benefits in terms of type safety, performance, and maintainability. The migration process is designed to be safe and reversible, with proper backup and testing procedures in place.

The new Drift-based database helper maintains the same interface as the old sqflite helper, making the transition smooth for the application code while providing the benefits of Drift's type-safe database operations. 