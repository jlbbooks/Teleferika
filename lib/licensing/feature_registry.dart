import 'package:flutter/material.dart';
import 'package:teleferika/core/logger.dart';

/// Represents a feature that can be enabled/disabled based on licensing
enum FeatureType {
  widget, // UI widgets
  function, // Functions/methods
  service, // Background services
  data, // Data access
}

/// Base class for all feature plugins
abstract class FeaturePlugin {
  String get name;

  String get description;

  List<FeatureType> get supportedTypes;

  bool get requiresLicence;

  void initialize();

  Widget? buildWidget(String widgetType);

  dynamic executeFunction(
    String functionName, [
    Map<String, dynamic>? parameters,
  ]);

  bool hasFeature(String featureName);

  List<String> get availableFeatures;
}

/// Registry for managing feature plugins and their availability
class FeatureRegistry {
  static final List<FeaturePlugin> _plugins = [];
  static bool _initialized = false;
  static final Map<String, bool> _featureAvailability = {};

  /// Register a new feature plugin
  static void registerPlugin(FeaturePlugin plugin) {
    if (plugin.name.isEmpty) {
      logger.warning('Attempted to register plugin with empty name');
      return;
    }

    if (_plugins.any((p) => p.name == plugin.name)) {
      logger.warning('Plugin ${plugin.name} is already registered');
      return;
    }

    _plugins.add(plugin);
    logger.info('Registered plugin: ${plugin.name}');

    // Initialize feature availability tracking
    for (final feature in plugin.availableFeatures) {
      _featureAvailability['${plugin.name}.$feature'] = true;
    }
  }

  /// Initialize the feature registry
  static Future<void> initialize() async {
    if (_initialized) {
      logger.info('Feature registry already initialized');
      return;
    }

    logger.info('Initializing feature registry...');

    try {
      // Auto-discover and register available plugins
      await _discoverPlugins();

      // Initialize all registered plugins
      for (final plugin in _plugins) {
        try {
          plugin.initialize();
          logger.info('Initialized plugin: ${plugin.name}');
        } catch (e, stackTrace) {
          logger.severe(
            'Failed to initialize plugin ${plugin.name}: $e',
            e,
            stackTrace,
          );
        }
      }

      _initialized = true;
      logger.info(
        'Feature registry initialization complete. ${_plugins.length} plugins registered.',
      );
    } catch (e, stackTrace) {
      logger.severe('Failed to initialize feature registry', e, stackTrace);
      rethrow;
    }
  }

  /// Discover and register available plugins
  static Future<void> _discoverPlugins() async {
    // Licensed features are now registered explicitly in main.dart
    // so we don't need to auto-discover them here

    // Register core features
    _registerCoreFeatures();
  }

  /// Register core features that are always available
  static void _registerCoreFeatures() {
    registerPlugin(CoreFeaturesPlugin());
  }

  /// Build a widget from a specific plugin
  static Widget? buildWidget(String pluginName, String widgetType) {
    if (!_initialized) {
      logger.warning('Feature registry not initialized');
      return null;
    }

    final plugin = _plugins.where((p) => p.name == pluginName).firstOrNull;
    if (plugin == null) {
      logger.warning('Plugin $pluginName not found');
      return null;
    }

    if (!plugin.supportedTypes.contains(FeatureType.widget)) {
      logger.warning('Plugin $pluginName does not support widgets');
      return null;
    }

    return plugin.buildWidget(widgetType);
  }

  /// Execute a function from a specific plugin
  static dynamic executeFunction(
    String pluginName,
    String functionName, [
    Map<String, dynamic>? parameters,
  ]) {
    if (!_initialized) {
      logger.warning('Feature registry not initialized');
      return null;
    }

    final plugin = _plugins.where((p) => p.name == pluginName).firstOrNull;
    if (plugin == null) {
      logger.warning('Plugin $pluginName not found');
      return null;
    }

    if (!plugin.supportedTypes.contains(FeatureType.function)) {
      logger.warning('Plugin $pluginName does not support functions');
      return null;
    }

    return plugin.executeFunction(functionName, parameters);
  }

  /// Check if a plugin is available
  static bool hasPlugin(String name) {
    return _plugins.any((p) => p.name == name);
  }

  /// Check if a specific feature is available
  static bool hasFeature(String pluginName, String featureName) {
    final fullFeatureName = '$pluginName.$featureName';
    return _featureAvailability[fullFeatureName] ?? false;
  }

  /// Get list of available plugins
  static List<String> get availablePlugins {
    return _plugins.map((p) => p.name).toList();
  }

  /// Get list of all available features
  static List<String> get availableFeatures {
    return _featureAvailability.keys
        .where((key) => _featureAvailability[key] == true)
        .toList();
  }

  /// Get plugin by name
  static FeaturePlugin? getPlugin(String name) {
    return _plugins.where((p) => p.name == name).firstOrNull;
  }

  /// Reset the registry (useful for testing)
  static void reset() {
    _plugins.clear();
    _featureAvailability.clear();
    _initialized = false;
    logger.info('Feature registry reset');
  }
}

/// Core features that are always available
class CoreFeaturesPlugin extends FeaturePlugin {
  @override
  String get name => 'core_features';

  @override
  String get description => 'Core features available in all versions';

  @override
  List<FeatureType> get supportedTypes => [
    FeatureType.widget,
    FeatureType.function,
  ];

  @override
  bool get requiresLicence => false;

  @override
  void initialize() {
    logger.info('Core features initialized');
  }

  @override
  Widget? buildWidget(String widgetType) {
    switch (widgetType) {
      case 'opensource_banner':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '💡 Opensource Version',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      case 'licence_status':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Licence: Not Required',
            style: TextStyle(fontSize: 12),
          ),
        );
      default:
        return null;
    }
  }

  @override
  dynamic executeFunction(
    String functionName, [
    Map<String, dynamic>? parameters,
  ]) {
    switch (functionName) {
      case 'get_version_info':
        return {
          'version': '1.0.0',
          'type': 'opensource',
          'features': availableFeatures,
        };
      default:
        return null;
    }
  }

  @override
  bool hasFeature(String featureName) {
    return availableFeatures.contains(featureName);
  }

  @override
  List<String> get availableFeatures => [
    'opensource_banner',
    'licence_status',
    'get_version_info',
  ];
}
