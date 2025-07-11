// migration_integration_example.dart
// This file shows how to integrate the migration service into your app startup

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'migration_service.dart';
import 'sqlite_migration_helper.dart';

/// Example of how to integrate database migration into your app startup
class MigrationIntegrationExample {
  static final Logger _logger = Logger('MigrationIntegrationExample');

  /// Call this method during app startup (e.g., in main.dart or initial screen)
  static Future<void> handleDatabaseMigration(BuildContext context) async {
    try {
      _logger.info('Starting database migration check');

      // Show migration progress dialog if needed
      final migrationResult = await MigrationService.performMigrationIfNeeded();

      // Show result dialog if migration was performed
      if (migrationResult.status != MigrationStatus.notNeeded) {
        if (context.mounted) {
          await MigrationService.showMigrationDialog(context, migrationResult);
        }
      }

      _logger.info('Database migration check completed');
    } catch (e) {
      _logger.severe('Error during database migration: $e');

      // Show error dialog to user
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Migration Error'),
                ],
              ),
              content: const Text(
                'An error occurred while checking for database migration. '
                'The app will continue to work normally.',
              ),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  /// Alternative: Show progress dialog during migration
  static Future<void> handleDatabaseMigrationWithProgress(
    BuildContext context,
  ) async {
    try {
      _logger.info('Starting database migration check with progress');

      // Check if migration is needed
      if (await SqliteMigrationHelper.hasOldDatabase()) {
        // Show progress dialog
        if (context.mounted) {
          MigrationService.showMigrationProgressDialog(context);
        }

        // Perform migration
        final migrationResult =
            await MigrationService.performMigrationIfNeeded();

        // Close progress dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Show result dialog
        if (context.mounted) {
          await MigrationService.showMigrationDialog(context, migrationResult);
        }
      }

      _logger.info('Database migration check completed');
    } catch (e) {
      _logger.severe('Error during database migration: $e');

      // Close progress dialog if open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Migration Error'),
                ],
              ),
              content: const Text(
                'An error occurred during database migration. '
                'Your old data is still available.',
              ),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }
}

/// Example usage in main.dart or initial screen
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    
    // Handle database migration on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MigrationIntegrationExample.handleDatabaseMigration(context);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My App')),
      body: Center(
        child: Text('App is ready!'),
      ),
    );
  }
}
*/
