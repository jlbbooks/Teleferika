import 'package:flutter/material.dart';

/// Centralized utility for GPS fix quality colors.
///
/// Provides consistent color mapping for fix quality values across the app.
/// Color progression: Red → Deep Orange → Orange → Yellow → Light Green → Green
class FixQualityColors {
  /// Gets the color for a fix quality value (0-5).
  ///
  /// Color progression:
  /// - 0 (Invalid): Red
  /// - 1 (GPS Fix): Deep Orange
  /// - 2 (DGPS Fix): Orange
  /// - 3 (PPS Fix): Yellow
  /// - 4 (RTK Fix): Green
  /// - 5 (RTK Float): Light Green
  ///
  /// [isDarkMode] - Whether to use dark mode colors (optional, defaults to false)
  static Color getColor(int fixQuality, {bool isDarkMode = false}) {
    switch (fixQuality) {
      case 0: // Invalid
        return isDarkMode ? Colors.red.shade700 : Colors.red;
      case 1: // GPS Fix
        return isDarkMode ? Colors.deepOrange.shade700 : Colors.deepOrange;
      case 2: // DGPS Fix
        return isDarkMode ? Colors.orange.shade700 : Colors.orange;
      case 3: // PPS Fix
        return isDarkMode ? Colors.yellow.shade700 : Colors.yellow;
      case 4: // RTK Fix
        return isDarkMode ? Colors.green.shade300 : Colors.green;
      case 5: // RTK Float
        return isDarkMode
            ? Colors.lightGreen.shade300
            : Colors.lightGreen.shade700;
      default:
        return isDarkMode ? Colors.grey.shade700 : Colors.grey;
    }
  }

  /// Gets the color for a bar index (0-5) in the fix quality bar indicator.
  ///
  /// Used for the visual bar indicator where bars progress from red to green.
  /// Bar 5 is RTK Fix (best), Bar 4 is RTK Float.
  ///
  /// [isDarkMode] - Whether to use dark mode colors (optional, defaults to false)
  static Color getBarColor(int barIndex, {bool isDarkMode = false}) {
    switch (barIndex) {
      case 0: // Invalid
        return isDarkMode ? Colors.red.shade700 : Colors.red;
      case 1: // GPS Fix
        return isDarkMode ? Colors.deepOrange.shade700 : Colors.deepOrange;
      case 2: // DGPS Fix
        return isDarkMode ? Colors.orange.shade700 : Colors.orange;
      case 3: // PPS Fix
        return isDarkMode ? Colors.yellow.shade700 : Colors.yellow;
      case 4: // RTK Float - light green (quality 5)
        return isDarkMode
            ? Colors.lightGreen.shade300
            : Colors.lightGreen.shade700;
      case 5: // RTK Fix - green (quality 4, best)
        return isDarkMode ? Colors.green.shade300 : Colors.green;
      default:
        return isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    }
  }
}
