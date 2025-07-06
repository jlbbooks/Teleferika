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

/// Download status callback
typedef DownloadStatusCallback = void Function(bool isPaused);

/// Controller for managing an active download
class MapDownloadController {
  final StoreDownload _download;
  final StreamSubscription<DownloadProgress> _progressSubscription;
  final StreamSubscription<TileEvent> _tileEventsSubscription;
  final Completer<void> _completer;
  final Logger _logger = Logger('MapDownloadController');

  MapDownloadController({
    required StoreDownload download,
    required StreamSubscription<DownloadProgress> progressSubscription,
    required StreamSubscription<TileEvent> tileEventsSubscription,
    required Completer<void> completer,
  }) : _download = download,
       _progressSubscription = progressSubscription,
       _tileEventsSubscription = tileEventsSubscription,
       _completer = completer;

  /// Check if the download is currently paused
  bool get isPaused => _download.isPaused();

  /// Pause the download
  Future<void> pause() async {
    try {
      _logger.info('Pausing download...');
      await _download.pause();
      _logger.info('Download paused successfully');
    } catch (e) {
      _logger.warning('Failed to pause download: $e');
      rethrow;
    }
  }

  /// Resume the download
  Future<void> resume() async {
    try {
      _logger.info('Resuming download...');
      await _download.resume();
      _logger.info('Download resumed successfully');
    } catch (e) {
      _logger.warning('Failed to resume download: $e');
      rethrow;
    }
  }

  /// Cancel the download
  Future<void> cancel() async {
    try {
      _logger.info('Cancelling download...');

      // Cancel the download
      await _download.cancel();

      // Cancel subscriptions
      await _progressSubscription.cancel();
      await _tileEventsSubscription.cancel();

      // Complete with cancellation
      if (!_completer.isCompleted) {
        _completer.complete();
      }

      _logger.info('Download cancelled successfully');
    } catch (e) {
      _logger.warning('Failed to cancel download: $e');
      rethrow;
    }
  }

  /// Wait for the download to complete (either successfully or by cancellation)
  Future<void> waitForCompletion() async {
    return _completer.future;
  }

  /// Dispose of the controller
  void dispose() {
    _progressSubscription.cancel();
    _tileEventsSubscription.cancel();
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
}

/// Service for downloading offline map tiles
class MapDownloadService {
  static final Logger _logger = Logger('MapDownloadService');

  /// Downloads map tiles for the specified area and map type
  /// Returns a controller that can be used to pause, resume, or cancel the download
  static Future<MapDownloadController> downloadMapArea({
    required LatLngBounds bounds,
    required MapType mapType,
    required int minZoom,
    required int maxZoom,
    required DownloadProgressCallback onProgress,
    required DownloadCompletionCallback onComplete,
    DownloadStatusCallback? onStatusChanged,
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
      final progressSubscription = downloadProgress.listen(
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
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );

      // Listen to tile events for basic logging
      final tileEventsSubscription = tileEvents.listen(
        (event) {
          _logger.fine('Tile event: ${event.runtimeType}');
        },
        onError: (error) {
          _logger.warning('Tile events error: $error');
        },
      );

      // Create the download controller
      final controller = MapDownloadController(
        download: store.download,
        progressSubscription: progressSubscription,
        tileEventsSubscription: tileEventsSubscription,
        completer: completer,
      );

      // Wait for completion in the background
      completer.future
          .then((_) {
            _logger.info(
              'Download completed. Downloaded: $downloadedTiles/$totalTiles tiles to cache store: $storeName',
            );
            onComplete(true, null);
          })
          .catchError((error) {
            _logger.severe('Download failed: $error');
            onComplete(false, error.toString());
          });

      return controller;
    } catch (e, stackTrace) {
      _logger.severe('Failed to start download: $e', e, stackTrace);
      onComplete(false, e.toString());
      rethrow;
    }
  }
}
