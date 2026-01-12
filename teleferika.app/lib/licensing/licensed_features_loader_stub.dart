// WARNING! This file is copied from licensed_features_loader_stub.dart
// when using the Opensource version, upon setting up the project.
// Do not commit licensed_features_loader.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/core/app_config.dart';

/// Stub implementation for licensed features loader
/// This is used in the opensource version when licensed features are not available
class LicensedFeaturesLoaderStub {
  final Logger logger = Logger('LicensedFeaturesLoaderStub');
  static final LicensedFeaturesLoaderStub _instance =
      LicensedFeaturesLoaderStub._internal();

  factory LicensedFeaturesLoaderStub() => _instance;

  LicensedFeaturesLoaderStub._internal();

  static LicensedFeaturesLoaderStub get instance => _instance;

  /// Register licensed features with the feature registry
  /// In the opensource version, this does nothing
  static Future<void> registerLicensedFeatures() async {
    final logger = Logger('LicensedFeaturesLoaderStub');
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

  /// Load features for the stub implementation
  Future<void> loadFeatures() async {
    logger.info('Licensed features not available in this build');
  }

  /// Check if licensed features are available
  /// Always returns false in the opensource version
  static bool get hasLicensedFeatures => false;

  /// Get list of licensed features that would be available
  /// Returns empty list in the opensource version
  static List<String> get licensedFeatures => [];

  /// Check if a specific licensed feature would be available
  /// Always returns false in the opensource version
  static bool hasLicensedFeature(String featureName) {
    // If licensing is disabled, all features are available
    if (AppConfig.disableLicensing) {
      final logger = Logger('LicensedFeaturesLoaderStub');
      logger.info(
        'Licensing disabled - allowing access to feature: $featureName',
      );
      return true;
    }

    return false;
  }

  /// Get licence status for feature availability
  /// Returns null in the opensource version
  static Map<String, dynamic>? getLicenceStatus() {
    // If licensing is disabled, return a valid status
    if (AppConfig.disableLicensing) {
      final logger = Logger('LicensedFeaturesLoaderStub');
      logger.info('Licensing disabled - returning valid status');
      return {
        'status': 'valid',
        'type': 'disabled',
        'expiry_date': null,
        'features': ['all'],
        'email': 'licensing_disabled@teleferika.com',
        'license_status': 'active',
      };
    }

    return null;
  }

  /// Build a licensed widget
  /// Always returns null in the opensource version
  static Widget? buildLicensedWidget(String widgetType) => null;
}
