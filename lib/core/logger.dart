import 'package:logging/logging.dart'; // Import the logging package

// Create a logger instance. It's common to use the library or class name.
final Logger logger = Logger('teleferiKa');

void setupLogging() {
  Logger.root.level = Level.ALL; // Log all levels by default
  Logger.root.onRecord.listen((record) {
    // In a debug build, print to console.
    // In a release build, you might want to send logs to a
    // file, a remote logging service, or disable some levels.
    // The `flutter run` command usually runs in debug mode.
    // `flutter run --release` runs in release mode.
    // For simplicity here, we always print.
    // ignore: avoid_print
    print(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) {
      // ignore: avoid_print
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      // ignore: avoid_print
      print('StackTrace: ${record.stackTrace}');
    }
  });
}

/*
Replacing print() with Logger Methods:
•logger.info("Message"): For informational messages.
•logger.fine("Detailed message"): For more detailed debugging information.
•logger.config("Configuration message"): For static configuration messages.
•logger.warning("Potential issue"): For warnings.
•logger.severe("Error message", errorObject, stackTraceObject): For critical errors. You can pass the actual error object and stack trace.
•Other levels like shout, finer, finest are also available.
 */
