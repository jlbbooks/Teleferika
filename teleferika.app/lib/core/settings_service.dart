import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teleferika/core/app_config.dart';

/// Service for managing application settings that can be modified by the user.
///
/// This service provides a centralized way to access and modify user-configurable
/// settings that are stored in SharedPreferences. It provides default values
/// from AppConfig and allows runtime modification of these settings.
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final Logger _logger = Logger('SettingsService');

  // SharedPreferences keys
  static const String _showSaveIconAlwaysKey = 'show_save_icon_always';
  static const String _angleToRedThresholdKey = 'angle_to_red_threshold';
  static const String _showAllProjectsOnMapKey = 'show_all_projects_on_map';
  static const String _showBleSatelliteButtonKey = 'show_ble_satellite_button';

  /// Get the current value for showSaveIconAlways setting.
  /// Returns the stored value or the default (true).
  Future<bool> get showSaveIconAlways async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_showSaveIconAlwaysKey) ?? true;
    } catch (e, stackTrace) {
      _logger.warning(
        'Error getting showSaveIconAlways setting, using default',
        e,
        stackTrace,
      );
      return true;
    }
  }

  /// Set the showSaveIconAlways setting value.
  Future<void> setShowSaveIconAlways(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showSaveIconAlwaysKey, value);
      _logger.info('showSaveIconAlways setting saved: $value');
    } catch (e, stackTrace) {
      _logger.severe('Error saving showSaveIconAlways setting', e, stackTrace);
      rethrow;
    }
  }

  /// Get the current value for angleToRedThreshold setting.
  /// Returns the stored value or the default from AppConfig.
  Future<double> get angleToRedThreshold async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_angleToRedThresholdKey) ??
          AppConfig.angleToRedThreshold;
    } catch (e, stackTrace) {
      _logger.warning(
        'Error getting angleToRedThreshold setting, using default',
        e,
        stackTrace,
      );
      return AppConfig.angleToRedThreshold;
    }
  }

  /// Set the angleToRedThreshold setting value.
  Future<void> setAngleToRedThreshold(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_angleToRedThresholdKey, value);
      _logger.info('angleToRedThreshold setting saved: $value');
    } catch (e, stackTrace) {
      _logger.severe('Error saving angleToRedThreshold setting', e, stackTrace);
      rethrow;
    }
  }

  /// Reset all settings to their default values from AppConfig.
  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_showSaveIconAlwaysKey);
      await prefs.remove(_angleToRedThresholdKey);
      await prefs.remove(_showAllProjectsOnMapKey);
      await prefs.remove(_showBleSatelliteButtonKey);
      _logger.info('All settings reset to defaults');
    } catch (e, stackTrace) {
      _logger.severe('Error resetting settings to defaults', e, stackTrace);
      rethrow;
    }
  }

  /// Get the current value for showAllProjectsOnMap setting.
  /// Returns the stored value or the default (false).
  Future<bool> get showAllProjectsOnMap async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_showAllProjectsOnMapKey) ?? false;
    } catch (e, stackTrace) {
      _logger.warning(
        'Error getting showAllProjectsOnMap setting, using default',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Set the showAllProjectsOnMap setting value.
  Future<void> setShowAllProjectsOnMap(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showAllProjectsOnMapKey, value);
      _logger.info('showAllProjectsOnMap setting saved: $value');
    } catch (e, stackTrace) {
      _logger.severe(
        'Error saving showAllProjectsOnMap setting',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Get the current value for showBleSatelliteButton setting.
  /// Returns the stored value or the default (true).
  Future<bool> get showBleSatelliteButton async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_showBleSatelliteButtonKey) ?? true;
    } catch (e, stackTrace) {
      _logger.warning(
        'Error getting showBleSatelliteButton setting, using default',
        e,
        stackTrace,
      );
      return true;
    }
  }

  /// Set the showBleSatelliteButton setting value.
  Future<void> setShowBleSatelliteButton(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showBleSatelliteButtonKey, value);
      _logger.info('showBleSatelliteButton setting saved: $value');
    } catch (e, stackTrace) {
      _logger.severe(
        'Error saving showBleSatelliteButton setting',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Get all current settings as a map for debugging or export purposes.
  Future<Map<String, dynamic>> getAllSettings() async {
    try {
      return {
        'showSaveIconAlways': await showSaveIconAlways,
        'angleToRedThreshold': await angleToRedThreshold,
        'showAllProjectsOnMap': await showAllProjectsOnMap,
        'showBleSatelliteButton': await showBleSatelliteButton,
      };
    } catch (e, stackTrace) {
      _logger.severe('Error getting all settings', e, stackTrace);
      rethrow;
    }
  }
}
