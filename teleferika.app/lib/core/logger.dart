import 'package:logging/logging.dart'; // Import the logging package

// Create a logger instance. It's common to use the library or class name.
final Logger logger = Logger('teleferiKa');

/// ANSI color codes for terminal output
class LogColors {
  static const String reset = '\x1B[0m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  static const String gray = '\x1B[90m';
  static const String brightRed = '\x1B[91m';
  static const String brightYellow = '\x1B[93m';
}

/// Returns the ANSI color code for a given log level
String _getColorForLevel(Level level) {
  if (level == Level.SHOUT) {
    return LogColors.brightRed;
  } else if (level == Level.SEVERE) {
    return LogColors.red;
  } else if (level == Level.WARNING) {
    return LogColors.yellow;
  } else if (level == Level.INFO) {
    return LogColors.blue;
  } else if (level == Level.CONFIG) {
    return LogColors.cyan;
  } else if (level == Level.FINE) {
    return LogColors.green;
  } else if (level == Level.FINER || level == Level.FINEST) {
    return LogColors.gray;
  }
  return LogColors.white;
}

void setupLogging() {
  Logger.root.level = Level.ALL; // Log all levels by default
  Logger.root.onRecord.listen((record) {
    final color = _getColorForLevel(record.level);
    final reset = LogColors.reset;

    // In a debug build, print to console.
    // In a release build, you might want to send logs to a
    // file, a remote logging service, or disable some levels.
    // The `flutter run` command usually runs in debug mode.
    // `flutter run --release` runs in release mode.
    // ignore: avoid_print
    print(
      '$color${record.level.name}$reset: ${record.time}: ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) {
      // ignore: avoid_print
      print('${LogColors.red}Error: ${record.error}$reset');
    }
    if (record.stackTrace != null) {
      // ignore: avoid_print
      print('${LogColors.gray}StackTrace: ${record.stackTrace}$reset');
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
