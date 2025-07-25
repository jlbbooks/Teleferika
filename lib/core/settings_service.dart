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

  /// Get the current value for showSaveIconAlways setting.
  /// Returns the stored value or the default from AppConfig.
  Future<bool> get showSaveIconAlways async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_showSaveIconAlwaysKey) ??
          AppConfig.showSaveIconAlways;
    } catch (e, stackTrace) {
      _logger.warning(
        'Error getting showSaveIconAlways setting, using default',
        e,
        stackTrace,
      );
      return AppConfig.showSaveIconAlways;
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
      _logger.info('All settings reset to defaults');
    } catch (e, stackTrace) {
      _logger.severe('Error resetting settings to defaults', e, stackTrace);
      rethrow;
    }
  }

  /// Get all current settings as a map for debugging or export purposes.
  Future<Map<String, dynamic>> getAllSettings() async {
    try {
      return {
        'showSaveIconAlways': await showSaveIconAlways,
        'angleToRedThreshold': await angleToRedThreshold,
      };
    } catch (e, stackTrace) {
      _logger.severe('Error getting all settings', e, stackTrace);
      rethrow;
    }
  }
}
