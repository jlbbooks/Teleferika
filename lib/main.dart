import 'dart:async';

import 'package:flutter/material.dart';

import 'db/database_helper.dart';
import 'logger.dart';

void main() {
  // Ensure Flutter bindings are initialized before doing async work or using plugins.
  WidgetsFlutterBinding.ensureInitialized();
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
  final int _minimumSplashTimeSeconds = 3; // Minimum time for splash screen

  @override
  void initState() {
    super.initState();
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

      await Future.delayed(const Duration(milliseconds: 500));
      logger.config("License check simulated successfully.");
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
      logger.finest("Building MyApp.");
      return const MyApp();
    }
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  // Create a logger for this specific widget/class if needed for more granular logging
  // static final Logger _loadingPageLogger = Logger('LoadingPage');

  @override
  Widget build(BuildContext context) {
    // _loadingPageLogger.fine("Building LoadingPage UI.");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.blueAccent,
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

// Your existing MyApp and MyHomePage
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teleferika', // Updated title
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Teleferika Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  // static final Logger _homePageLogger = Logger('MyHomePage'); // Logger for this page

  void _incrementCounter() {
    // _homePageLogger.info("Counter incremented.");
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
