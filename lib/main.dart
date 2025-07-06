// main.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/licensing/feature_registry.dart';
import 'package:teleferika/licensing/licence_service.dart';
import 'package:teleferika/licensing/licensed_features_loader.dart';
import 'package:teleferika/ui/pages/loading_page.dart';

import 'core/logger.dart';
import 'db/database_helper.dart';
import 'ui/pages/projects_list_page.dart';
import 'ui/tabs/map/map_controller.dart';
import 'ui/tabs/map/services/map_cache_logger.dart';

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
    await DatabaseHelper.instance.database;
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

class MyAppRoot extends StatefulWidget {
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

      // Create stores for each MapType enum value
      for (final mapType in MapType.values) {
        final storeName = 'mapStore_${mapType.name}';
        await FMTCStore(storeName).manage.create();
        logger.info('Created store: $storeName');
        // Log store creation
        MapCacheLogger.logStoreCreated(storeName);
      }

      logger.info(
        'FMTCObjectBoxBackend initialised with stores for all map types',
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
      logger.finest("Building LoadingPage.");
      return const LoadingPage();
    }

    logger.finest("Building MyApp (which now loads ProjectsListPage).");
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectStateManager()),
        Provider<LicenceService>.value(value: LicenceService.instance),
      ],
      child: MaterialApp(
        title: 'Teleferika',
        // --- Dynamic Theme Settings ---
        theme: AppConfig.lightTheme,
        // Your defined light theme
        darkTheme: AppConfig.darkTheme,
        // Your defined dark theme
        themeMode: ThemeMode.system,
        // This is the key!
        // --- End Dynamic Theme Settings ---
        debugShowCheckedModeBanner: kDebugMode,
        localizationsDelegates: AppConfig.localizationsDelegates,
        supportedLocales: AppConfig.supportedLocales,
        home: const ProjectsListPage(),
      ),
    );
  }
}
