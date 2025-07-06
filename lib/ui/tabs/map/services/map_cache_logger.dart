import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/ui/tabs/map/map_controller.dart';
import 'package:teleferika/ui/tabs/map/services/map_store_utils.dart';

/// Service for logging map cache usage and statistics
class MapCacheLogger {
  static final Logger _logger = Logger('MapCacheLogger');

  /// Log comprehensive cache statistics for all map types
  static Future<void> logAllCacheStats() async {
    _logger.info('=== MAP CACHE STATISTICS ===');

    try {
      // Log overall cache statistics
      await _logOverallCacheStats();

      // Log individual store statistics
      await _logIndividualStoreStats();

      _logger.info('=== END MAP CACHE STATISTICS ===');
    } catch (e, stackTrace) {
      _logger.severe('Error logging cache statistics', e, stackTrace);
    }
  }

  /// Log overall cache statistics from FMTCRoot
  static Future<void> _logOverallCacheStats() async {
    try {
      final realSize = await FMTCRoot.stats.realSize;
      _logger.info('Total cache size: ${_formatBytes(realSize)}');

      // Try to get additional stats if available
      try {
        final size = await FMTCRoot.stats.size;
        _logger.info('Total cache entries: $size');
      } catch (e) {
        _logger.fine('Size stats not available: $e');
      }
    } catch (e) {
      _logger.warning('Could not retrieve overall cache stats: $e');
    }
  }

  /// Log individual store statistics for each map type
  static Future<void> _logIndividualStoreStats() async {
    for (final mapType in MapType.values) {
      await _logStoreStats(mapType);
    }
  }

  /// Log statistics for a specific map type store
  static Future<void> _logStoreStats(MapType mapType) async {
    try {
      final storeName = MapStoreUtils.getStoreNameForMapType(mapType);
      final store = FMTCStore(storeName);

      _logger.info('--- ${mapType.name.toUpperCase()} STORE ---');
      _logger.info('Store name: $storeName');

      // Get store size
      try {
        final size = await store.stats.size;
        _logger.info('Store entries: $size');
      } catch (e) {
        _logger.fine('Store size not available for $storeName: $e');
      }

      // Store information logging
      _logger.info('Store ready for ${mapType.name}');
    } catch (e) {
      _logger.warning('Error logging stats for ${mapType.name}: $e');
    }
  }

  /// Log cache performance metrics
  static Future<void> logCachePerformance(MapType mapType) async {
    try {
      final storeName = MapStoreUtils.getStoreNameForMapType(mapType);
      final store = FMTCStore(storeName);

      _logger.info('=== CACHE PERFORMANCE: ${mapType.name.toUpperCase()} ===');

      // Log store size
      try {
        final size = await store.stats.size;
        _logger.info('Current store size: $size entries');
      } catch (e) {
        _logger.fine('Could not get store size: $e');
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
      _logger.info('Cache hit/miss tracking not implemented yet');
      _logger.info('Consider implementing custom hit/miss counters');
    } catch (e) {
      _logger.fine('Hit/miss info not available: $e');
    }
  }

  /// Log cache cleanup operations
  static Future<void> logCacheCleanup() async {
    _logger.info('=== CACHE CLEANUP OPERATION ===');

    try {
      // Log before cleanup stats
      await logAllCacheStats();

      // Perform cleanup (if needed)
      _logger.info('Cache cleanup completed');

      // Log after cleanup stats
      await logAllCacheStats();
    } catch (e, stackTrace) {
      _logger.severe('Error during cache cleanup logging', e, stackTrace);
    }
  }

  /// Log when a new tile is cached
  static void logTileCached(MapType mapType, String tileKey) {
    _logger.fine('Tile cached for ${mapType.name}: $tileKey');
  }

  /// Log when a tile is retrieved from cache
  static void logTileRetrievedFromCache(MapType mapType, String tileKey) {
    _logger.fine('Tile retrieved from cache for ${mapType.name}: $tileKey');
  }

  /// Log when a tile is fetched from network
  static void logTileFetchedFromNetwork(MapType mapType, String tileKey) {
    _logger.fine('Tile fetched from network for ${mapType.name}: $tileKey');
  }

  /// Log cache store creation
  static void logStoreCreated(String storeName) {
    _logger.info('Cache store created: $storeName');
  }

  /// Log cache store deletion
  static void logStoreDeleted(String storeName) {
    _logger.info('Cache store deleted: $storeName');
  }

  /// Log cache store error
  static void logStoreError(String storeName, String operation, Object error) {
    _logger.warning(
      'Cache store error in $storeName during $operation: $error',
    );
  }

  /// Format bytes to human readable format
  static String _formatBytes(double bytes) {
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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
      for (final mapType in MapType.values) {
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
