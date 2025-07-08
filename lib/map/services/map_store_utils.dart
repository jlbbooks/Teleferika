import 'package:teleferika/map/map_type.dart';

/// Utility functions for map store management
class MapStoreUtils {
  /// Get the store name for a given map type
  ///
  /// Uses the cacheStoreName property from the MapType class
  /// e.g., MapType.openStreetMap -> 'mapStore_openStreetMap'
  static String getStoreNameForMapType(MapType mapType) {
    return MapType.of(mapType.id).cacheStoreName ?? 'mapStore_${mapType.id}';
  }
}
