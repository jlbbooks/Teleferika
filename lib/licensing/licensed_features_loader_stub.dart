// WARNING! This file is copied from licensed_features_loader_stub.dart
// when using the Opensource version, upon setting up the project.
// Do not commit licensed_features_loader.dart

import '../logger.dart';
import 'feature_registry.dart';
import 'package:flutter/widgets.dart';

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
    logger.info('This is the opensource version - premium features are disabled');
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
}
