import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/core/settings_service.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/screens/ble/ble_screen.dart';
import 'package:teleferika/db/drift_database_helper.dart';

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
  bool _showAllProjectsOnMap = false;
  bool _showBleSatelliteButton = true;

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
      final showAllProjectsOnMap = await _settingsService.showAllProjectsOnMap;
      final showBleSatelliteButton =
          await _settingsService.showBleSatelliteButton;

      setState(() {
        _showSaveIconAlways = showSaveIconAlways;
        _angleToRedThreshold = angleToRedThreshold;
        _showAllProjectsOnMap = showAllProjectsOnMap;
        _showBleSatelliteButton = showBleSatelliteButton;
        _angleThresholdController.text = _angleToRedThreshold.toString();
      });

      logger.info(
        'Settings loaded: showSaveIconAlways=$_showSaveIconAlways, angleToRedThreshold=$_angleToRedThreshold, showAllProjectsOnMap=$_showAllProjectsOnMap',
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
      await _settingsService.setShowAllProjectsOnMap(_showAllProjectsOnMap);
      await _settingsService.setShowBleSatelliteButton(_showBleSatelliteButton);

      logger.info(
        'Settings saved: showSaveIconAlways=$_showSaveIconAlways, angleToRedThreshold=$_angleToRedThreshold, showAllProjectsOnMap=$_showAllProjectsOnMap',
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
        _showAllProjectsOnMap = false;
        _showBleSatelliteButton = true;
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
      body: SafeArea(
        child: SingleChildScrollView(
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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

              const SizedBox(height: 16),

              // Map Display Section
              _buildSectionHeader(
                S.of(context)?.map_display_section ?? 'Map Display',
                Icons.map_outlined,
              ),
              const SizedBox(height: 8),

              // Show All Projects on Map
              Card(
                child: SwitchListTile(
                  title: Text(
                    S.of(context)?.show_all_projects_on_map_title ??
                        'Show All Projects on Map',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    S.of(context)?.show_all_projects_on_map_description ??
                        'When enabled, all projects will be displayed on the map as grey markers and lines. When disabled, only the current project is shown.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  value: _showAllProjectsOnMap,
                  onChanged: (bool value) {
                    setState(() {
                      _showAllProjectsOnMap = value;
                    });
                    _saveSettings();
                  },
                  secondary: const Icon(Icons.layers),
                ),
              ),

              const SizedBox(height: 16),

              // Show BLE Satellite Button
              Card(
                child: SwitchListTile(
                  title: Text(
                    S.of(context)?.show_ble_satellite_button_title ??
                        'Show RTK Device Button',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    S.of(context)?.show_ble_satellite_button_description ??
                        'When enabled, a satellite button appears on the map when connected to an RTK device. Tap it to view device information.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  value: _showBleSatelliteButton,
                  onChanged: (bool value) {
                    setState(() {
                      _showBleSatelliteButton = value;
                    });
                    _saveSettings();
                  },
                  secondary: const Icon(Icons.satellite),
                ),
              ),

              const SizedBox(height: 16),

              // Bluetooth / Devices Section
              _buildSectionHeader(
                S.of(context)?.ble_devices_section ?? 'Bluetooth Devices',
                Icons.bluetooth,
              ),
              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.bluetooth_searching,
                    color: Colors.blue,
                  ),
                  title: Text(
                    S.of(context)?.ble_devices_title ?? 'Bluetooth Devices',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    S.of(context)?.ble_devices_description ??
                        'Scan and connect to Bluetooth Low Energy devices',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BLEScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // NTRIP Hosts Section (Debug only)
              if (kDebugMode) ...[
                _buildSectionHeader('NTRIP Hosts', Icons.satellite),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NTRIP Hosts Management',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Delete all saved NTRIP hosts from the database. This action cannot be undone.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _deleteAllNtripHosts(context),
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('DROP hosts'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ] else
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

  Future<void> _deleteAllNtripHosts(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All NTRIP Hosts'),
          content: const Text(
            'Are you sure you want to delete ALL NTRIP hosts? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('DELETE ALL'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        final deleted = await DriftDatabaseHelper.instance
            .deleteAllNtripSettings();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted $deleted NTRIP host(s)'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 1000),
          ),
        );
      } catch (e) {
        logger.severe('Error deleting all NTRIP hosts: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting hosts: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 1000),
          ),
        );
      }
    }
  }
}
