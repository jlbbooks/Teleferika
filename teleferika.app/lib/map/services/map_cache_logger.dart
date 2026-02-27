import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/map/map_type.dart';
import 'package:teleferika/map/services/map_store_utils.dart';

/// Service for logging map cache usage and statistics
class MapCacheLogger {
  static final Logger _logger = Logger('MapCacheLogger');

  /// Log comprehensive cache statistics for all map types
  static Future<void> logAllCacheStats() async {
    try {
      // Log overall cache statistics
      await _logOverallCacheStats();

      // Log individual store statistics
      await _logIndividualStoreStats();
    } catch (e, stackTrace) {
      _logger.severe('Error logging cache statistics', e, stackTrace);
    }
  }

  /// Log overall cache statistics from FMTCRoot
  static Future<void> _logOverallCacheStats() async {
    try {
      await FMTCRoot.stats.realSize;
      // Try to get additional stats if available
      try {
        await FMTCRoot.stats.size;
      } catch (e) {
        // Size stats not available
      }
    } catch (e) {
      _logger.warning('Could not retrieve overall cache stats: $e');
    }
  }

  /// Log individual store statistics for each map type
  static Future<void> _logIndividualStoreStats() async {
    for (final mapType in MapType.all) {
      await _logStoreStats(mapType);
    }
  }

  /// Log statistics for a specific map type store
  static Future<void> _logStoreStats(MapType mapType) async {
    try {
      final storeName = MapStoreUtils.getStoreNameForMapType(mapType);
      final store = FMTCStore(storeName);

      // Get store size
      try {
        await store.stats.size;
      } catch (e) {
        // Store size not available
      }
    } catch (e) {
      _logger.warning('Error logging stats for ${mapType.name}: $e');
    }
  }

  /// Log cache performance metrics
  static Future<void> logCachePerformance(MapType mapType) async {
    try {
      final storeName = MapStoreUtils.getStoreNameForMapType(mapType);
      final store = FMTCStore(storeName);

      // Log store size
      try {
        await store.stats.size;
      } catch (e) {
        // Could not get store size
      }

      // Log cache hit/miss information if available
      await _logCacheHitMissInfo(store, mapType);
    } catch (e, stackTrace) {
      _logger.severe(
        'Error logging cache performance for $mapType',
        e,
        stackTrace,
      );
    }
  }

  /// Log cache hit/miss information
  static Future<void> _logCacheHitMissInfo(
    FMTCStore store,
    MapType mapType,
  ) async {
    try {
      // This is speculative - the actual API might be different
      // You may need to implement your own hit/miss tracking
    } catch (e) {
      // Hit/miss info not available
    }
  }

  /// Log cache cleanup operations
  static Future<void> logCacheCleanup() async {
    try {
      // Log before cleanup stats
      await logAllCacheStats();

      // Perform cleanup (if needed)

      // Log after cleanup stats
      await logAllCacheStats();
    } catch (e, stackTrace) {
      _logger.severe('Error during cache cleanup logging', e, stackTrace);
    }
  }

  /// Log when a new tile is cached
  static void logTileCached(MapType mapType, String tileKey) {
    // Verbose logging removed
  }

  /// Log when a tile is retrieved from cache
  static void logTileRetrievedFromCache(MapType mapType, String tileKey) {
    // Verbose logging removed
  }

  /// Log when a tile is fetched from network
  static void logTileFetchedFromNetwork(MapType mapType, String tileKey) {
    // Verbose logging removed
  }

  /// Log cache store creation
  static void logStoreCreated(String storeName) {
    // Verbose logging removed
  }

  /// Log cache store deletion
  static void logStoreDeleted(String storeName) {
    // Verbose logging removed
  }

  /// Log cache store error
  static void logStoreError(String storeName, String operation, Object error) {
    _logger.warning(
      'Cache store error in $storeName during $operation: $error',
    );
  }

  /// Get a summary of cache usage for debugging
  static Future<Map<String, dynamic>> getCacheSummary() async {
    final summary = <String, dynamic>{};

    try {
      // Overall stats
      final totalSize = await FMTCRoot.stats.size;
      summary['totalSize'] = totalSize;
      summary['totalSizeFormatted'] = totalSize.toString();

      // Individual store stats
      final storeStats = <String, dynamic>{};
      for (final mapType in MapType.all) {
        try {
          final storeName = MapStoreUtils.getStoreNameForMapType(mapType);
          final store = FMTCStore(storeName);
          final stats = store.stats;
          final size = await stats.size;
          int? length;
          int? hits;
          int? misses;
          try {
            length = await stats.length;
          } catch (_) {}
          try {
            hits = await stats.hits;
          } catch (_) {}
          try {
            misses = await stats.misses;
          } catch (_) {}
          storeStats[mapType.name] = {
            'storeName': storeName,
            'size': size,
            'length': length,
            'hits': hits,
            'misses': misses,
          };
        } catch (e) {
          storeStats[mapType.name] = {'error': e.toString()};
        }
      }
      summary['stores'] = storeStats;
    } catch (e) {
      summary['error'] = e.toString();
    }

    return summary;
  }
}
