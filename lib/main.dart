// main.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/licensing/feature_registry.dart';
import 'package:teleferika/licensing/licence_service.dart';
import 'package:teleferika/licensing/licensed_features_loader.dart';
import 'package:teleferika/ui/pages/loading_page.dart';

import 'core/logger.dart';
import 'db/database_helper.dart';
import 'ui/pages/projects_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Call the setupLogging function from logger.dart
  setupLogging();

  // Initialize licensing and features
  await initializeApp();

  runApp(const MyAppRoot());
}

Future<void> initializeApp() async {
  try {
    logger.info('Starting app initialization...');

    // Initialize licence service first
    await LicenceService.instance.initialize();
    logger.info('LicenceService initialized');

    // Initialize database
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;
    logger.info('Database initialized');

    // Initialize features (including licensed features)
    await initializeFeatures();

    logger.info('App initialization complete');
  } catch (e, stackTrace) {
    logger.severe('Failed to initialize app', e, stackTrace);
    rethrow;
  }
}

Future<void> initializeFeatures() async {
  try {
    // Try to register licensed features
    await LicensedFeaturesLoader.registerLicensedFeatures();
    logger.info('Licensed features loader completed');
  } catch (e) {
    logger.info('Could not load licensed features: $e');
  }

  // Initialize the feature registry
  await FeatureRegistry.initialize();
  logger.info('Feature registry initialized');
}

class MyAppRoot extends StatefulWidget {
  const MyAppRoot({super.key});

  @override
  State<MyAppRoot> createState() => _MyAppRootState();
}

class _MyAppRootState extends State<MyAppRoot> {
  bool _isLoading = true;
  final int _minimumSplashTimeSeconds = 3;
  String _appVersion = ''; // State variable to hold the app version

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
      _loadVersionInfo();
      logger.info("Version info loaded successfully.");

      // Simulate other checks (e.g., remote config, analytics)
      await Future.delayed(const Duration(milliseconds: 500));
      logger.config("Other essential checks simulated successfully.");
    } catch (e, stackTrace) {
      logger.severe("Error during app initialization", e, stackTrace);
      // In a real app, you might want to display an error to the user
    }

    final elapsedTime = DateTime.now().difference(startTime);
    logger.fine(
      "Core initialization tasks took ${elapsedTime.inMilliseconds}ms.",
    );

    final remainingTime =
        Duration(seconds: _minimumSplashTimeSeconds) - elapsedTime;

    if (remainingTime > Duration.zero) {
      logger.fine(
        "Waiting for an additional ${remainingTime.inMilliseconds}ms to meet minimum splash time.",
      );
      await Future.delayed(remainingTime);
    }

    if (mounted) {
      // Check if the widget is still in the tree
      setState(() {
        _isLoading = false;
      });
      logger.info("Initialization complete. Navigating to main app.");
    } else {
      logger.warning(
        "Attempted to setState on an unmounted MyAppRoot widget after initialization.",
      );
    }
  }

  Future<void> _loadVersionInfo() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        // Check if the widget is still in the tree
        setState(() {
          // You can choose to display version, buildNumber, or both
          _appVersion = 'v${packageInfo.version} (${packageInfo.buildNumber})';
          // _appVersion = 'v${packageInfo.version}'; // Just version
        });
      }
    } catch (e, stackTrace) {
      logger.warning("Could not get package info: $e", e, stackTrace);
      if (mounted) {
        setState(() {
          _appVersion = 'v?.?.?'; // Fallback version display
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLicensedFeatures = FeatureRegistry.hasPlugin('licensed_features');

    if (_isLoading) {
      logger.finest("Building LoadingPage.");
      return LoadingPage(appVersion: _appVersion);
    } else {
      logger.finest("Building MyApp (which now loads ProjectsListPage).");
      return TeleferiKa(appVersion: _appVersion);
    }
  }
}

class TeleferiKa extends StatelessWidget {
  final String? appVersion;
  const TeleferiKa({super.key, this.appVersion});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,

      // --- Dynamic Theme Settings ---
      theme: AppConfig.lightTheme, // Your defined light theme
      darkTheme: AppConfig.darkTheme, // Your defined dark theme
      themeMode: ThemeMode.system, // This is the key!
      // --- End Dynamic Theme Settings ---
      debugShowCheckedModeBanner: kDebugMode,
      localizationsDelegates: AppConfig.localizationsDelegates,
      supportedLocales: AppConfig.supportedLocales,
      home: ProjectsListPage(
        appVersion: appVersion,
      ), // Set ProjectsListPage as the home screen
    );
  }
}
