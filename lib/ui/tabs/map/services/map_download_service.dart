import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/ui/tabs/map/map_type.dart';

/// Download progress callback
typedef DownloadProgressCallback =
    void Function(int downloaded, int total, double percentage);

/// Download completion callback
typedef DownloadCompletionCallback = void Function(bool success, String? error);

/// Service for downloading offline map tiles
class MapDownloadService {
  static final Logger _logger = Logger('MapDownloadService');

  /// Downloads map tiles for the specified area and map type
  static Future<void> downloadMapArea({
    required LatLngBounds bounds,
    required MapType mapType,
    required int minZoom,
    required int maxZoom,
    required DownloadProgressCallback onProgress,
    required DownloadCompletionCallback onComplete,
  }) async {
    try {
      _logger.info(
        'Starting download for area: $bounds, map type: ${mapType.name}, zoom: $minZoom-$maxZoom',
      );

      // Get the cache store for this map type
      final storeName = mapType.cacheStoreName;
      final store = FMTCStore(storeName);

      // Ensure the store exists
      try {
        await store.manage.create();
        _logger.info('Using cache store: $storeName');
      } catch (e) {
        if (e.toString().contains('already exists') ||
            e.toString().contains('StoreExists')) {
          _logger.info('Cache store already exists: $storeName');
        } else {
          _logger.warning('Failed to create cache store: $e');
          // Continue anyway, the store might already exist
        }
      }

      // Step 1: Define a region (RectangleRegion)
      final region = RectangleRegion(bounds);
      _logger.info('Created RectangleRegion for bounds: $bounds');

      // Step 2: Add information to make the region downloadable
      final downloadableRegion = region.toDownloadable(
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: TileLayer(
          urlTemplate: mapType.tileLayerUrl,
          userAgentPackageName: 'com.jlbbooks.teleferika',
          tileProvider: CancellableNetworkTileProvider(),
        ),
      );
      _logger.info(
        'Created DownloadableRegion with zoom levels: $minZoom-$maxZoom',
      );

      // Step 3: (Optional) Count the number of tiles in the region
      final totalTiles = await store.download.countTiles(downloadableRegion);
      _logger.info('Total tiles to download: $totalTiles');

      // Step 4: Configure and start the download
      final (:downloadProgress, :tileEvents) = store.download.startForeground(
        region: downloadableRegion,
        skipExistingTiles: true,
        skipSeaTiles: false,
        parallelThreads: 4,
        maxBufferLength: 100,
        rateLimit: 50, // 50ms delay between requests
      );

      // Step 5: Monitor the download outputs
      int downloadedTiles = 0;
      final completer = Completer<void>();

      // Listen to download progress
      downloadProgress.listen(
        (progress) {
          // Use a simple counter for progress tracking
          downloadedTiles++;
          final percentage = (downloadedTiles / totalTiles) * 100;
          onProgress(downloadedTiles, totalTiles, percentage);

          _logger.fine(
            'Download progress: $downloadedTiles/$totalTiles tiles (${percentage.toStringAsFixed(1)}%)',
          );
        },
        onDone: () {
          completer.complete();
        },
        onError: (error) {
          completer.completeError(error);
        },
      );

      // Listen to tile events for basic logging
      tileEvents.listen((event) {
        _logger.fine('Tile event: ${event.runtimeType}');
      });

      // Wait for download to complete
      await completer.future;

      _logger.info(
        'Download completed successfully. Downloaded: $downloadedTiles/$totalTiles tiles to cache store: $storeName',
      );

      // The downloaded tiles are now stored in the FMTC cache and will be available offline
      // when the map requests them through the FMTCTileProvider

      onComplete(true, null);
    } catch (e, stackTrace) {
      _logger.severe('Download failed: $e', e, stackTrace);
      onComplete(false, e.toString());
    }
  }
}
