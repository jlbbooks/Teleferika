import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teleferika/ui/tabs/map/map_controller.dart';

class MapPreferencesService {
  static const String _mapTypeKey = 'map_type';
  static const String _defaultMapType = 'openStreetMap';
  static final Logger _logger = Logger('MapPreferencesService');

  /// Save the current map type to SharedPreferences
  static Future<void> saveMapType(MapType mapType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapTypeString = _mapTypeToString(mapType);
      await prefs.setString(_mapTypeKey, mapTypeString);
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
      return _stringToMapType(mapTypeString);
    } catch (e) {
      // Log error but return default - preferences are not critical
      _logger.warning('Error loading map type preference: $e');
      return _stringToMapType(_defaultMapType);
    }
  }

  /// Convert MapType enum to string for storage
  static String _mapTypeToString(MapType mapType) {
    switch (mapType) {
      case MapType.openStreetMap:
        return 'openStreetMap';
      case MapType.satellite:
        return 'satellite';
      case MapType.terrain:
        return 'terrain';
    }
  }

  /// Convert string back to MapType enum
  static MapType _stringToMapType(String mapTypeString) {
    switch (mapTypeString) {
      case 'satellite':
        return MapType.satellite;
      case 'terrain':
        return MapType.terrain;
      case 'openStreetMap':
      default:
        return MapType.openStreetMap;
    }
  }
}
