import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/core/settings_service.dart';
import 'package:teleferika/l10n/app_localizations.dart';

/// Settings screen for configuring application behavior.
///
/// This screen provides a user interface for modifying configurable
/// application settings that are stored in SharedPreferences.
/// Currently supports:
/// - showSaveIconAlways: Whether to always show the save icon
/// - angleToRedThreshold: Threshold for angle color changes
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Logger logger = Logger('SettingsScreen');
  final SettingsService _settingsService = SettingsService();

  // Settings state
  bool _showSaveIconAlways = AppConfig.showSaveIconAlways;
  double _angleToRedThreshold = AppConfig.angleToRedThreshold;

  // Controllers for text fields
  final TextEditingController _angleThresholdController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _angleThresholdController.dispose();
    super.dispose();
  }

  /// Load settings from SettingsService
  Future<void> _loadSettings() async {
    try {
      final showSaveIconAlways = await _settingsService.showSaveIconAlways;
      final angleToRedThreshold = await _settingsService.angleToRedThreshold;

      setState(() {
        _showSaveIconAlways = showSaveIconAlways;
        _angleToRedThreshold = angleToRedThreshold;
        _angleThresholdController.text = _angleToRedThreshold.toString();
      });

      logger.info(
        'Settings loaded: showSaveIconAlways=$_showSaveIconAlways, angleToRedThreshold=$_angleToRedThreshold',
      );
    } catch (e, stackTrace) {
      logger.severe('Error loading settings', e, stackTrace);
    }
  }

  /// Save settings using SettingsService
  Future<void> _saveSettings() async {
    try {
      await _settingsService.setShowSaveIconAlways(_showSaveIconAlways);
      await _settingsService.setAngleToRedThreshold(_angleToRedThreshold);

      logger.info(
        'Settings saved: showSaveIconAlways=$_showSaveIconAlways, angleToRedThreshold=$_angleToRedThreshold',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.settings_saved_successfully ??
                  'Settings saved successfully',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Return true to indicate settings were changed
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      logger.severe('Error saving settings', e, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.error_saving_settings(e.toString()) ??
                  'Error saving settings: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Reset settings to default values
  Future<void> _resetToDefaults() async {
    try {
      await _settingsService.resetToDefaults();

      setState(() {
        _showSaveIconAlways = AppConfig.showSaveIconAlways;
        _angleToRedThreshold = AppConfig.angleToRedThreshold;
        _angleThresholdController.text = _angleToRedThreshold.toString();
      });

      logger.info('Settings reset to defaults');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.settings_reset_to_defaults ??
                  'Settings reset to defaults',
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.severe('Error resetting settings', e, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.error_resetting_settings(e.toString()) ??
                  'Error resetting settings: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.settings, size: 24),
            const SizedBox(width: 12),
            Text(
              S.of(context)?.settings_title ?? 'Settings',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: S.of(context)?.reset_to_defaults ?? 'Reset to Defaults',
            onPressed: _resetToDefaults,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // UI Behavior Section
            _buildSectionHeader(
              S.of(context)?.ui_behavior_section ?? 'UI Behavior',
              Icons.tune,
            ),
            const SizedBox(height: 8),

            // Show Save Icon Always
            Card(
              child: SwitchListTile(
                title: Text(
                  S.of(context)?.show_save_icon_always_title ??
                      'Always Show Save Icon',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  S.of(context)?.show_save_icon_always_description ??
                      'When enabled, the save icon is always visible. When disabled, it only appears when there are unsaved changes.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                value: _showSaveIconAlways,
                onChanged: (bool value) {
                  setState(() {
                    _showSaveIconAlways = value;
                  });
                  _saveSettings();
                },
                secondary: const Icon(Icons.save),
              ),
            ),

            const SizedBox(height: 16),

            // Map and Compass Section
            _buildSectionHeader(
              S.of(context)?.map_compass_section ?? 'Map & Compass',
              Icons.map,
            ),
            const SizedBox(height: 8),

            // Angle to Red Threshold
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            S.of(context)?.angle_to_red_threshold_title ??
                                'Angle to Red Threshold',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.of(context)?.angle_to_red_threshold_description ??
                          'The angle threshold (in degrees) at which the compass angle indicator changes from green to red. Lower values make the indicator more sensitive.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _angleThresholdController,
                            decoration: InputDecoration(
                              labelText:
                                  S.of(context)?.threshold_degrees ??
                                  'Threshold (degrees)',
                              hintText: '2.0',
                              suffixText: '°',
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (value) {
                              final doubleValue = double.tryParse(value);
                              if (doubleValue != null && doubleValue > 0) {
                                setState(() {
                                  _angleToRedThreshold = doubleValue;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppConfig.angleColorGood,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppConfig.angleColorBad,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.of(context)?.angle_threshold_legend ??
                          'Green: Good angle | Red: Poor angle',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Information Section
            _buildSectionHeader(
              S.of(context)?.information_section ?? 'Information',
              Icons.info_outline,
            ),
            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context)?.settings_info_title ?? 'About Settings',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.of(context)?.settings_info_description ??
                          'These settings are stored locally on your device and will persist between app sessions. Changes take effect immediately.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
