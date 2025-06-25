import 'package:flutter/material.dart';

abstract class FeaturePlugin {
  String get name;
  void initialize();
  Widget? buildWidget(String widgetType);
}

class FeatureRegistry {
  static final List<FeaturePlugin> _plugins = [];
  static bool _initialized = false;

  static void registerPlugin(FeaturePlugin plugin) {
    if (!_plugins.any((p) => p.name == plugin.name)) {
      _plugins.add(plugin);
      print('Registered plugin: ${plugin.name}');
    }
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    print('Initializing feature registry...');

    // Auto-discover and register available plugins
    await _discoverPlugins();

    // Initialize all registered plugins
    for (final plugin in _plugins) {
      try {
        plugin.initialize();
        print('Initialized plugin: ${plugin.name}');
      } catch (e) {
        print('Failed to initialize plugin ${plugin.name}: $e');
      }
    }

    _initialized = true;
    print(
      'Feature registry initialization complete. ${_plugins.length} plugins registered.',
    );
  }

  static Future<void> _discoverPlugins() async {
    // Try to register licensed features if available
    try {
      await _tryRegisterLicensedFeatures();
    } catch (e) {
      print('Licensed features not available: $e');
    }

    // Register other plugins here as needed
    _registerCoreFeatures();
  }

  static Future<void> _tryRegisterLicensedFeatures() async {
    // This method will be conditionally compiled based on available dependencies
    // Implementation will be in a separate file
  }

  static void _registerCoreFeatures() {
    // Register any core/free features here
    registerPlugin(CoreFeaturesPlugin());
  }

  static Widget? buildWidget(String pluginName, String widgetType) {
    final plugin = _plugins.where((p) => p.name == pluginName).firstOrNull;
    return plugin?.buildWidget(widgetType);
  }

  static bool hasPlugin(String name) {
    return _plugins.any((p) => p.name == name);
  }

  static List<String> get availablePlugins {
    return _plugins.map((p) => p.name).toList();
  }
}

// Core features that are always available
class CoreFeaturesPlugin extends FeaturePlugin {
  @override
  String get name => 'core_features';

  @override
  void initialize() {
    print('Core features initialized');
  }

  @override
  Widget? buildWidget(String widgetType) {
    switch (widgetType) {
      case 'opensource_banner':
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '💡 Opensource Version',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      default:
        return null;
    }
  }
}
