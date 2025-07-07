import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teleferika/ui/tabs/map/map_type.dart';
import 'package:latlong2/latlong.dart';
import 'package:teleferika/core/app_config.dart';

class MapPreferencesService {
  static const String _mapTypeKey = 'map_type';
  static const String _defaultMapType = 'openStreetMap';
  static const String _lastLocationLatKey = 'last_location_lat';
  static const String _lastLocationLngKey = 'last_location_lng';
  static const String _lastLocationTimestampKey = 'last_location_timestamp';
  static final Logger _logger = Logger('MapPreferencesService');

  /// Save the current map type to SharedPreferences
  static Future<void> saveMapType(MapType mapType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mapTypeKey, mapType.id);
    } catch (e) {
      // Log error but don't throw - preferences are not critical
      _logger.warning('Error saving map type preference: $e');
    }
  }

  /// Load the saved map type from SharedPreferences
  /// Returns the default map type if no preference is saved or on error
  static Future<MapType> loadMapType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapTypeString = prefs.getString(_mapTypeKey) ?? _defaultMapType;
      return MapType.of(mapTypeString);
    } catch (e) {
      // Log error but return default - preferences are not critical
      _logger.warning('Error loading map type preference: $e');
      return MapType.of(_defaultMapType);
    }
  }

  /// Save the last known location to SharedPreferences
  static Future<void> saveLastLocation(LatLng location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_lastLocationLatKey, location.latitude);
      await prefs.setDouble(_lastLocationLngKey, location.longitude);
      await prefs.setInt(
        _lastLocationTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Log error but don't throw - preferences are not critical
      _logger.warning('Error saving last location preference: $e');
    }
  }

  /// Load the last known location from SharedPreferences
  /// Returns null if no location is saved or on error
  static Future<LatLng?> loadLastLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_lastLocationLatKey);
      final lng = prefs.getDouble(_lastLocationLngKey);
      final timestamp = prefs.getInt(_lastLocationTimestampKey);

      // Check if we have valid coordinates
      if (lat == null || lng == null) {
        return null;
      }

      // Check if the location is not too old (e.g., less than 30 days)
      if (timestamp != null) {
        final locationAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        const maxAgeMs = 30 * 24 * 60 * 60 * 1000; // 30 days
        if (locationAge > maxAgeMs) {
          _logger.info(
            'Last location is too old (${locationAge ~/ (24 * 60 * 60 * 1000)} days), ignoring',
          );
          return null;
        }
      }

      return LatLng(lat, lng);
    } catch (e) {
      // Log error but return null - preferences are not critical
      _logger.warning('Error loading last location preference: $e');
      return null;
    }
  }

  /// Get a default location if no saved location is available
  static LatLng getDefaultLocation() {
    return AppConfig.defaultMapCenter; // Use config instead of hardcoded Milan
  }
}
