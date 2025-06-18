// main.dart
import 'dart:async';

import 'package:flutter/material.dart';

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

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.blueAccent, // Or your app's splash background
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading Teleferika...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
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
      title: 'Teleferika',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        // Example theme color
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const ProjectsListPage(), // Set ProjectsListPage as the home screen
    );
  }
}
