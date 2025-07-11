/// Teleferika - Cable Crane Line Planning Application
///
/// This is the main entry point for the Teleferika Flutter application.
/// Teleferika is a mobile application designed to support cable crane line
/// planning for forest operations, helping technicians optimize cable crane
/// positioning to minimize environmental impact and improve operational efficiency.
///
/// ## Features
/// - GPS-based point collection for cable crane positioning
/// - Compass integration for directional measurements
/// - Map visualization with OpenStreetMap integration
/// - Project management for organizing multiple operations
/// - Data export capabilities (full version)
/// - Offline operation support
///
/// ## Build Flavors
/// The application supports two build flavors:
/// - **opensource**: Open source version without licensed features
/// - **full**: Full version with licensed features and export functionality
///
/// ## Architecture
/// The application follows a layered architecture:
/// - **Core**: Configuration, logging, and state management
/// - **Database**: SQLite-based data persistence
/// - **UI**: Flutter widgets and screens
/// - **Map**: Map-related functionality and services
/// - **Licensing**: Feature control and license management
///
/// For more information, see the [README.md](../README.md) file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/drift_database_helper.dart';
import 'package:teleferika/licensing/feature_registry.dart';
import 'package:teleferika/licensing/licence_service.dart';
import 'package:teleferika/licensing/licensed_features_loader.dart';
import 'package:teleferika/ui/screens/loading/loading_screen.dart';

import 'core/logger.dart';
import 'ui/screens/projects/projects_list_screen.dart';
import 'map/services/map_cache_manager.dart';

/// Main entry point for the Teleferika application.
///
/// This function initializes all core services and components before
/// launching the Flutter application. It performs the following steps:
///
/// 1. **Flutter Binding**: Ensures Flutter is properly initialized
/// 2. **Logging Setup**: Configures the logging system for the application
/// 3. **License Service**: Initializes the license management system
/// 4. **Database**: Sets up the SQLite database connection
/// 5. **Licensed Features**: Loads and registers licensed features (if available)
/// 6. **Feature Registry**: Initializes the feature control system
/// 7. **App Launch**: Starts the main application
///
/// ## Error Handling
/// If any critical initialization step fails, the error is logged and
/// the application will not start. This ensures that the app only runs
/// when all required services are properly initialized.
///
/// ## Build Flavor Support
/// The initialization process automatically detects the build flavor
/// and loads appropriate features:
/// - **opensource**: Basic features only
/// - **full**: All features including licensed components
///
/// ## Dependencies
/// - [setupLogging]: Configures the logging system
/// - [LicenceService]: Manages application licensing
/// - [DatabaseHelper]: Handles database operations
/// - [LicensedFeaturesLoader]: Loads licensed features
/// - [FeatureRegistry]: Manages feature availability
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Call the setupLogging function from logger.dart
  setupLogging();

  final Logger logger = Logger('MainApp');

  try {
    logger.info('Starting app initialization...');

    // Initialize licence service
    await LicenceService.instance.initialize();
    logger.info('LicenceService initialized');

    // Initialize database
    await DriftDatabaseHelper.instance.database;
    logger.info('Database initialized');

    logger.info('App initialization complete');
  } catch (e, stackTrace) {
    logger.severe('Failed to initialize app', e, stackTrace);
    rethrow;
  }

  // Load licensed features
  try {
    await LicensedFeaturesLoader.registerLicensedFeatures();
    logger.info('Licensed features registered successfully');
  } catch (e) {
    logger.info('Could not load licensed features: $e');
  }

  // Initialize feature registry
  FeatureRegistry.initialize();
  logger.info('Feature registry initialized');

  runApp(const MyAppRoot());
}

/// Root widget for the Teleferika application.
///
/// This widget serves as the main entry point for the Flutter widget tree.
/// It manages the application's initialization state and provides the
/// overall app structure including:
///
/// - **Theme Configuration**: Light and dark theme support
/// - **Localization**: Multi-language support (English, Italian)
/// - **State Management**: Provider setup for global state
/// - **Navigation**: Routes to the main project list screen
///
/// ## State Management
/// The widget uses [Provider] to manage global application state:
/// - [ProjectStateManager]: Manages current project and points
/// - [LicenceService]: Provides license status and validation
///
/// ## Theme Support
/// The application supports both light and dark themes with automatic
/// switching based on system preferences. Themes are defined in [AppConfig].
///
/// ## Localization
/// The app supports multiple languages through Flutter's localization
/// system. Localization delegates are configured in [AppConfig].
///
/// ## Build Configuration
/// - Debug mode shows a banner when `kDebugMode` is true
/// - Release mode hides debug information
/// - Both modes support the same core functionality
class MyAppRoot extends StatefulWidget {
  /// Creates a new [MyAppRoot] widget.
  ///
  /// The [key] parameter is passed to the superclass constructor.
  const MyAppRoot({super.key});

  @override
  State<MyAppRoot> createState() => _MyAppRootState();
}

class _MyAppRootState extends State<MyAppRoot> {
  final Logger logger = Logger('MyAppRoot');
  bool _isInitialized = false;
  String? _versionInfo;
  String? _buildNumber;

  @override
  void initState() {
    super.initState();
    // Use the logger instance from logger.dart
    logger.info("MyAppRoot initState: Starting app initialization.");
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();
    logger.fine("Initialization started at $startTime");

    try {
      // Load version info
      final packageInfo = await PackageInfo.fromPlatform();
      _versionInfo = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      logger.info("Version info loaded successfully.");

      logger.info('Initialising FMTCObjectBoxBackend');
      await FMTCObjectBoxBackend()
          .initialise(); // Initialise the map cache store

      // Create and validate stores for each MapType enum value
      await MapCacheManager.validateAllStores();
      logger.info(
        'FMTCObjectBoxBackend initialised with validated stores for all map types',
      );

      // Simulate other essential checks
      await Future.delayed(
        const Duration(milliseconds: kDebugMode ? 100 : 3000),
      );
      logger.config("Other essential checks simulated successfully.");
    } catch (e, stackTrace) {
      logger.severe("Error during app initialization", e, stackTrace);
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    logger.fine("Initialization completed in ${duration.inMilliseconds}ms");
    logger.fine("Version: $_versionInfo, Build: $_buildNumber");

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      logger.info("Initialization complete. Navigating to main app.");
    } else {
      logger.warning(
        "Widget was disposed during initialization, cannot navigate to main app.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      logger.finest("Building LoadingScreen.");
      return const LoadingScreen();
    }

    logger.finest("Building MyApp (which now loads ProjectsListScreen).");
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectStateManager()),
        Provider<LicenceService>.value(value: LicenceService.instance),
      ],
      child: MaterialApp(
        title: 'Teleferika',
        // --- Dynamic Theme Settings ---
        theme: AppConfig.lightTheme,
        darkTheme: AppConfig.darkTheme,
        themeMode: ThemeMode.system,
        // --- End Dynamic Theme Settings ---
        debugShowCheckedModeBanner: kDebugMode,
        localizationsDelegates: AppConfig.localizationsDelegates,
        supportedLocales: AppConfig.supportedLocales,
        home: const ProjectsListScreen(),
      ),
    );
  }
}
