// migration_service.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'sqlite_migration_helper.dart';

/// Service that handles database migration from old sqflite to new drift database.
///
/// This service manages the migration process during app startup and provides
/// user feedback about the migration progress.
class MigrationService {
  static final Logger _logger = Logger('MigrationService');

  /// Checks if migration is needed and performs it if necessary
  static Future<MigrationResult> performMigrationIfNeeded() async {
    try {
      _logger.info('Checking if database migration is needed');

      // Check if old database exists
      if (!await SqliteMigrationHelper.hasOldDatabase()) {
        _logger.info('No old database found, migration not needed');
        return MigrationResult.notNeeded();
      }

      // Get migration statistics
      final stats = await SqliteMigrationHelper.getMigrationStats();
      _logger.info(
        'Found old database with: ${stats['projects']} projects, ${stats['points']} points, ${stats['images']} images',
      );

      // Perform migration
      final success = await SqliteMigrationHelper.migrateOldDatabase();

      if (success) {
        _logger.info('Migration completed successfully');

        // Remove old database after successful migration
        await SqliteMigrationHelper.removeOldDatabase();

        return MigrationResult.success(stats);
      } else {
        _logger.severe('Migration failed');
        return MigrationResult.failed('Migration failed');
      }
    } catch (e) {
      _logger.severe('Error during migration: $e');
      return MigrationResult.failed(e.toString());
    }
  }

  /// Shows migration dialog to user
  static Future<void> showMigrationDialog(
    BuildContext context,
    MigrationResult result,
  ) async {
    if (result.status == MigrationStatus.notNeeded) {
      return; // No dialog needed
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                result.status == MigrationStatus.success
                    ? Icons.check_circle
                    : Icons.error,
                color: result.status == MigrationStatus.success
                    ? Colors.green
                    : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                result.status == MigrationStatus.success
                    ? 'Migration Completed'
                    : 'Migration Failed',
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.status == MigrationStatus.success) ...[
                const Text(
                  'Your data has been successfully migrated to the new database format.',
                ),
                const SizedBox(height: 16),
                if (result.stats != null) ...[
                  const Text('Migrated:'),
                  Text('• ${result.stats!['projects']} projects'),
                  Text('• ${result.stats!['points']} points'),
                  Text('• ${result.stats!['images']} images'),
                  const SizedBox(height: 16),
                  const Text(
                    'Your old database has been backed up and removed.',
                  ),
                ],
              ] else ...[
                const Text('Failed to migrate your existing data.'),
                const SizedBox(height: 16),
                Text('Error: ${result.errorMessage}'),
                const SizedBox(height: 16),
                const Text(
                  'Your old data is still available. You can try again later or contact support.',
                ),
              ],
            ],
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

  /// Shows migration progress dialog
  static Future<void> showMigrationProgressDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const AlertDialog(
          title: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Migrating Data'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please wait while we migrate your existing data to the new database format.',
              ),
              SizedBox(height: 16),
              Text('This may take a few moments...'),
            ],
          ),
        );
      },
    );
  }
}

/// Result of a migration operation
class MigrationResult {
  final MigrationStatus status;
  final Map<String, int>? stats;
  final String? errorMessage;

  const MigrationResult._({
    required this.status,
    this.stats,
    this.errorMessage,
  });

  /// Migration was not needed (no old database found)
  factory MigrationResult.notNeeded() {
    return const MigrationResult._(status: MigrationStatus.notNeeded);
  }

  /// Migration completed successfully
  factory MigrationResult.success(Map<String, int> stats) {
    return MigrationResult._(status: MigrationStatus.success, stats: stats);
  }

  /// Migration failed
  factory MigrationResult.failed(String errorMessage) {
    return MigrationResult._(
      status: MigrationStatus.failed,
      errorMessage: errorMessage,
    );
  }
}

/// Status of a migration operation
enum MigrationStatus { notNeeded, success, failed }
