import 'dart:io';
import 'package:flutter/services.dart';

/// Platform-specific GPS information that's not available through Geolocator
class PlatformGpsInfo {
  static const MethodChannel _channel = MethodChannel(
    'teleferika.app/gps_info',
  );

  /// Get satellite count (Android only, returns null on iOS)
  static Future<int?> getSatelliteCount() async {
    if (!Platform.isAndroid) {
      return null; // Not available on iOS
    }

    try {
      final result = await _channel.invokeMethod<int>('getSatelliteCount');
      return result;
    } catch (e) {
      // Method not implemented or error - return null
      return null;
    }
  }

  /// Get GPS fix quality/status (Android only, returns null on iOS)
  /// Returns: 0 = no fix, 1 = GPS fix, 2 = DGPS fix, etc.
  static Future<int?> getFixQuality() async {
    if (!Platform.isAndroid) {
      return null; // Not available on iOS
    }

    try {
      final result = await _channel.invokeMethod<int>('getFixQuality');
      return result;
    } catch (e) {
      // Method not implemented or error - return null
      return null;
    }
  }
}
