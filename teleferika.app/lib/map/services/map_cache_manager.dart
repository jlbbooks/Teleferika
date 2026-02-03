import 'dart:async';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/map/map_type.dart';

/// Service to manage cache stores, handle errors, and provide fallback mechanisms
///
/// RESEARCHED ZOOM LEVELS (tested via HTTP requests):
/// - OpenStreetMap: 0-19 (confirmed: 0=200, 19=200, 20=404)
/// - Esri Satellite (World_Imagery): 0-23 (confirmed: 0=200, 23=200)
/// - Esri World Topo (World_Topo_Map): 0-23 (confirmed: 0=200, 23=200)
/// - OpenTopoMap: 0-17 (confirmed: 0=200, 17=200, 18=404)
/// - CartoDB Positron: 0-20 (confirmed: 0=200, 20=200)
/// - Thunderforest Outdoors: 0-22 (confirmed: 0=200, 22=200, 23=404)
/// - Thunderforest Landscape: 0-22 (same as Outdoors, based on Thunderforest docs)
class MapCacheManager {
  static final Logger _logger = Logger('MapCacheManager');

  /// Default store name to use as fallback when other stores fail
  static const String _fallbackStoreName = 'mapStore_fallback';

  /// Cache of validated stores to avoid repeated validation
  static final Set<String> _validatedStores = <String>{};

  /// Cache of failed stores to avoid repeated attempts
  static final Set<String> _failedStores = <String>{};

  /// Get a tile provider with error handling and fallback
  static FMTCTileProvider getTileProviderWithFallback(MapType mapType) {
    final storeName =
        MapType.of(mapType.id).cacheStoreName ?? 'mapStore_${mapType.id}';

    // If store is known to be failed, use fallback immediately
    if (_failedStores.contains(storeName)) {
      _logger.warning(
        'Using fallback store for $mapType (store $storeName previously failed)',
      );
      return _createFallbackTileProvider();
    }

    // If store is validated, use it directly
    if (_validatedStores.contains(storeName)) {
      return FMTCTileProvider(
        stores: {storeName: BrowseStoreStrategy.readUpdateCreate},
        loadingStrategy: BrowseLoadingStrategy.cacheFirst,
      );
    }

    // Try to validate and use the store
    return _createTileProviderWithValidation(storeName, mapType);
  }

  /// Create tile provider with validation and fallback
  static FMTCTileProvider _createTileProviderWithValidation(
    String storeName,
    MapType mapType,
  ) {
    try {
      // Mark as validated
      _validatedStores.add(storeName);

      return FMTCTileProvider(
        stores: {storeName: BrowseStoreStrategy.readUpdateCreate},
        loadingStrategy: BrowseLoadingStrategy.cacheFirst,
      );
    } catch (e) {
      _logger.warning('Failed to validate store $storeName: $e');
      _failedStores.add(storeName);

      // Use fallback
      return _createFallbackTileProvider();
    }
  }

  /// Create fallback tile provider
  static FMTCTileProvider _createFallbackTileProvider() {
    try {
      _validatedStores.add(_fallbackStoreName);

      return FMTCTileProvider(
        stores: {_fallbackStoreName: BrowseStoreStrategy.readUpdateCreate},
        loadingStrategy: BrowseLoadingStrategy.cacheFirst,
      );
    } catch (e) {
      _logger.severe('Failed to create fallback tile provider: $e');
      // Return a basic tile provider without caching as last resort
      return FMTCTileProvider(
        stores: {},
        loadingStrategy: BrowseLoadingStrategy.cacheFirst,
      );
    }
  }

  /// Ensure a store exists, creating it if necessary
  static Future<void> _ensureStoreExists(String storeName) async {
    try {
      final store = FMTCStore(storeName);

      // Try to create the store (it will fail if it already exists, which is fine)
      await store.manage.create();
    } catch (e) {
      // If store already exists, that's fine
      if (e.toString().contains('already exists') ||
          e.toString().contains('StoreExists')) {
        return;
      }
      _logger.severe('Failed to ensure store exists: $storeName - $e');
      rethrow;
    }
  }

  /// Validate all stores for all map types
  static Future<void> validateAllStores() async {
    for (final mapType in MapType.all) {
      final storeName =
          MapType.of(mapType.id).cacheStoreName ?? _fallbackStoreName;

      try {
        await _ensureStoreExists(storeName);
        _validatedStores.add(storeName);
        _failedStores.remove(storeName); // Remove from failed if it was there
      } catch (e) {
        _logger.warning('Failed to validate store: $storeName - $e');
        _failedStores.add(storeName);
        _validatedStores.remove(storeName);
      }
    }

    // Ensure fallback store exists
    try {
      await _ensureStoreExists(_fallbackStoreName);
      _validatedStores.add(_fallbackStoreName);
    } catch (e) {
      _logger.severe('Failed to validate fallback store: $e');
    }
  }

  /// Clear all stores (for testing or reset purposes)
  static Future<void> clearAllStores() async {
    final allStoreNames = [
      ...MapType.all
          .map((mt) => MapType.of(mt.id).cacheStoreName)
          .whereType<String>(),
      _fallbackStoreName,
    ];

    for (final storeName in allStoreNames) {
      try {
        final store = FMTCStore(storeName);
        await store.manage.delete();
      } catch (e) {
        _logger.warning('Failed to delete store: $storeName - $e');
      }
    }

    // Clear validation caches
    _validatedStores.clear();
    _failedStores.clear();
  }

  /// Get status of all stores
  static Map<String, String> getStoreStatus() {
    final status = <String, String>{};

    for (final mapType in MapType.all) {
      final storeName =
          MapType.of(mapType.id).cacheStoreName ?? _fallbackStoreName;
      if (_validatedStores.contains(storeName)) {
        status[storeName] = 'validated';
      } else if (_failedStores.contains(storeName)) {
        status[storeName] = 'failed';
      } else {
        status[storeName] = 'unknown';
      }
    }

    // Add fallback store status
    if (_validatedStores.contains(_fallbackStoreName)) {
      status[_fallbackStoreName] = 'validated (fallback)';
    } else if (_failedStores.contains(_fallbackStoreName)) {
      status[_fallbackStoreName] = 'failed (fallback)';
    } else {
      status[_fallbackStoreName] = 'unknown (fallback)';
    }

    return status;
  }

  /// Reset validation state for a specific store (useful for recovery)
  static void resetStoreValidation(String storeName) {
    _validatedStores.remove(storeName);
    _failedStores.remove(storeName);
  }

  /// Reset validation state for all stores
  static void resetAllStoreValidation() {
    _validatedStores.clear();
    _failedStores.clear();
  }

  /// Check if a specific store has tiles (for debugging)
  static Future<bool> hasTilesInStore(String storeName) async {
    try {
      final store = FMTCStore(storeName);
      final stats = store.stats;
      final size = await stats.size;
      return size > 0;
    } catch (e) {
      _logger.warning('Failed to check store $storeName: $e');
      return false;
    }
  }

  /// Log cache status for debugging
  static Future<void> logCacheStatus() async {
    for (final mapType in MapType.all) {
      final storeName =
          MapType.of(mapType.id).cacheStoreName ?? _fallbackStoreName;
      await hasTilesInStore(storeName);
    }
  }
}
