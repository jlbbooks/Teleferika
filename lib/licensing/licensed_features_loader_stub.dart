// WARNING! This file is copied from licensed_features_loader_stub.dart
// when using the Opensource version, upon setting up the project.
// Do not commit licensed_features_loader.dart

import 'package:flutter/material.dart';
import 'package:teleferika/core/logger.dart';

/// Stub implementation for licensed features loader
/// This is used in the opensource version when licensed features are not available
class LicensedFeaturesLoader {
  /// Register licensed features with the feature registry
  /// In the opensource version, this does nothing
  static Future<void> registerLicensedFeatures() async {
    logger.info('Licensed features not available in this build');

    // In the full version, this would:
    // 1. Check if a valid licence exists
    // 2. Register premium features based on licence
    // 3. Set up feature availability flags
    // 4. Initialize premium plugins

    // For now, we just log that licensed features are not available
    logger.info(
      'This is the opensource version - premium features are disabled',
    );
  }

  /// Check if licensed features are available
  /// Always returns false in the opensource version
  static bool get hasLicensedFeatures => false;

  /// Get list of licensed features that would be available
  /// Returns empty list in the opensource version
  static List<String> get licensedFeatures => [];

  /// Check if a specific licensed feature would be available
  /// Always returns false in the opensource version
  static bool hasLicensedFeature(String featureName) => false;

  /// Get licence status for feature availability
  /// Returns null in the opensource version
  static Map<String, dynamic>? getLicenceStatus() => null;

  /// Build a licensed widget
  /// Always returns null in the opensource version
  static Widget? buildLicensedWidget(String widgetType) => null;

  /// Export project data using licensed export service
  /// Shows upgrade message in the opensource version
  static Future<bool> exportProject(
    String format,
    dynamic project,
    List<dynamic> points,
  ) async {
    logger.info('Export functionality not available in opensource version');
    // In a real app, you might want to show a dialog here
    // For now, we just return false to indicate failure
    return false;
  }

  /// Get available export formats
  /// Returns empty list in the opensource version
  static List<String> getExportFormats() {
    logger.info('Export formats not available in opensource version');
    return [];
  }

  /// Check if export functionality is available
  /// Always returns false in the opensource version
  static bool get hasExportFeature => false;

  /// Show upgrade dialog for export functionality
  static void showExportUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Text('Premium Feature'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Export functionality is a premium feature.'),
              SizedBox(height: 8),
              Text('Available in the full version:'),
              Text('• KML export (Google Earth)'),
              Text('• CSV export (Spreadsheets)'),
              Text('• Multiple format support'),
              Text('• Custom file naming'),
              Text('• Batch export operations'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
