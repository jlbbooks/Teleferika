// app_config.dart (new file)

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class AppConfig {
  static const String appName = 'TeleferiKa';
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    ),
    // Add other light theme specific customizations here
    // e.g., appBarTheme, textTheme, buttonTheme, etc.
    // appBarTheme: const AppBarTheme(
    //   backgroundColor: Colors.teal,
    //   foregroundColor: Colors.white,
    // ),
  );
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    // Example
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
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

  // Private constructor to prevent instantiation if all members are static
  AppConfig._();
}
