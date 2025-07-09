/// Application configuration and constants for Teleferika.
///
/// This class contains all application-wide configuration settings,
/// theme definitions, and constants used throughout the app. It provides
/// a centralized location for managing app appearance, behavior, and
/// configuration values.
///
/// ## Features
/// - **Theme Configuration**: Light and dark theme definitions
/// - **Localization**: Supported locales and delegates
/// - **Map Configuration**: Default map center and zoom levels
/// - **UI Constants**: Colors, icons, and styling constants
/// - **Behavior Settings**: Configurable app behavior flags
///
/// ## Usage
/// All configuration values are accessed as static constants:
/// ```dart
/// // Get app name
/// String name = AppConfig.appName;
///
/// // Get theme
/// ThemeData theme = AppConfig.lightTheme;
///
/// // Get default map center
/// LatLng center = AppConfig.defaultMapCenter;
/// ```
///
/// ## Customization
/// To modify app behavior, update the appropriate constants in this class.
/// For theme customization, modify the [lightTheme] and [darkTheme] properties.
///
/// ## Constants Categories
/// - **App Identity**: App name and branding
/// - **Coordinate UI**: Icons and colors for coordinate display
/// - **Themes**: Material Design theme configurations
/// - **Localization**: Language and locale settings
/// - **Map Settings**: Default map configuration
/// - **Behavior Flags**: Configurable app behavior

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/l10n/app_localizations.dart';

/// Application configuration and constants for Teleferika.
///
/// This class provides centralized configuration for all app settings,
/// themes, and constants. It cannot be instantiated as all members are static.
class AppConfig {
  /// The official name of the application.
  ///
  /// This is used throughout the app for branding and display purposes.
  /// It should not be translated as it's a brand name.
  static const String appName = 'TeleferiKa';

  /// Coordinate display configuration for consistent UI across the app.
  ///
  /// These constants define the icons and colors used to display
  /// coordinate information (latitude, longitude, altitude, GPS precision)
  /// throughout the application.

  /// Icon for latitude display (vertical swap icon).
  static const IconData latitudeIcon = Icons.swap_vert;

  /// Color for latitude values and UI elements.
  static const Color latitudeColor = Colors.green;

  /// Icon for longitude display (horizontal swap icon).
  static const IconData longitudeIcon = Icons.swap_horiz;

  /// Color for longitude values and UI elements.
  static const Color longitudeColor = Colors.orange;

  /// Icon for altitude display (terrain icon).
  static const IconData altitudeIcon = Icons.terrain;

  /// Color for altitude values and UI elements.
  static const Color altitudeColor = Colors.brown;

  /// Icon for GPS precision display (location icon).
  static const IconData gpsPrecisionIcon = Icons.my_location;

  /// Color for GPS precision values and UI elements.
  static const Color gpsPrecisionColor = Colors.blueGrey;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue[100],
      foregroundColor: Colors.blue[900],
      elevation: 2,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.blue[900],
      ),
      iconTheme: IconThemeData(color: Colors.blue[900]),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ).copyWith(
          primary: Colors.teal[100],
          onPrimary: Colors.teal[900],
          surface: Colors.grey[900],
          onSurface: Colors.white,
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.teal[100],
      foregroundColor: Colors.teal[900],
      elevation: 2,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.teal[900],
      ),
      iconTheme: IconThemeData(color: Colors.teal[900]),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade600),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade600),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.teal, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade800,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
  );

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('it'),
    // ...
  ];
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// If true, the save icon is always shown even if there are no unsaved changes.
  /// If false, the save icon is only shown when there are unsaved changes.
  static const bool showSaveIconAlways = true;

  /// If true, orphaned image files and folders will be cleaned up from disk.
  static const bool cleanupOrphanedImageFiles = true;

  static const Duration polylineArrowheadAnimationDuration = Duration(
    seconds: 7,
  );

  static const double angleToRedThreshold = 30.0;

  static const Color angleColorGood = Colors.green;
  static const Color angleColorBad = Colors.red;

  // Default map center (Trento, Italy) - used as fallback when no last known location
  static const LatLng defaultMapCenter = LatLng(46.0669, 11.1211);
  static const double defaultMapZoom = 12.0;

  // Private constructor to prevent instantiation if all members are static
  AppConfig._();
}
