// app_config.dart (new file)

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class AppConfig {
  static const String appName = 'TeleferiKa';

  // Coordinate icons and colors for consistency across the app
  static const IconData latitudeIcon = Icons.swap_vert;
  static const Color latitudeColor = Colors.green;

  static const IconData longitudeIcon = Icons.swap_horiz;
  static const Color longitudeColor = Colors.orange;

  static const IconData altitudeIcon = Icons.terrain;
  static const Color altitudeColor = Colors.brown;

  static const IconData gpsPrecisionIcon = Icons.my_location;
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
