// main.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_config.dart';
import 'db/database_helper.dart';
import 'logger.dart'; // Assuming logger.dart is in the same directory (lib)
import 'projects_list_page.dart'; // Import your ProjectsListPage

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Call the setupLogging function from logger.dart
  setupLogging();
  runApp(const MyAppRoot());
}

class MyAppRoot extends StatefulWidget {
  const MyAppRoot({super.key});

  @override
  State<MyAppRoot> createState() => _MyAppRootState();
}

class _MyAppRootState extends State<MyAppRoot> {
  bool _isLoading = true;
  final int _minimumSplashTimeSeconds = 3;

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
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.database;
      logger.info("Database initialized successfully.");

      // Simulate other checks (e.g., license, remote config)
      await Future.delayed(const Duration(milliseconds: 500));
      logger.config("Other essential checks simulated successfully.");
      // Add more initialization steps here if needed
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      logger.finest("Building LoadingPage.");
      return const LoadingPage();
    } else {
      logger.finest("Building MyApp (which now loads ProjectsListPage).");
      return const MyApp();
    }
  }
}

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  String _appVersion = ''; // State variable to hold the app version

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
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
    return MaterialApp(
      debugShowCheckedModeBanner: kDebugMode,
      localizationsDelegates: AppConfig.localizationsDelegates,
      supportedLocales: AppConfig.supportedLocales,
      // --- Dynamic Theme Settings ---
      theme: AppConfig.lightTheme, // Your defined light theme
      darkTheme: AppConfig.darkTheme, // Your defined dark theme
      themeMode: ThemeMode.system, // Auto-switch light/dark theme!
      // --- End Dynamic Theme Settings ---
      home: Scaffold(
        backgroundColor:
            Colors.blueAccent, // TODO: Or your app's splash background
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading ${AppConfig.appName}...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10), // Add some space
              if (_appVersion.isNotEmpty) // Only show if version is loaded
                Text(
                  _appVersion,
                  style: TextStyle(
                    color: Colors.white.withAlpha(
                      (0.7 * 255).round(),
                    ), // Slightly dimmer
                    fontSize: 12.0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const ProjectsListPage(), // Set ProjectsListPage as the home screen
    );
  }
}
