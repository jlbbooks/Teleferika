import 'package:teleferika/ui/tabs/map/map_controller.dart';

/// Utility functions for map store management
class MapStoreUtils {
  /// Get the store name for a given map type
  ///
  /// Converts enum name to store name format
  /// e.g., MapType.openStreetMap -> 'mapStore_openStreetMap'
  static String getStoreNameForMapType(MapType mapType) {
    final enumName = mapType.name;
    return 'mapStore_$enumName';
  }
}
