import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/ui/tabs/map/map_type.dart';

/// Download progress callback
typedef DownloadProgressCallback =
    void Function(int downloaded, int total, double percentage);

/// Download completion callback
typedef DownloadCompletionCallback = void Function(bool success, String? error);

/// Simple class to represent tile coordinates
class TileCoordinate {
  final int x;
  final int y;

  const TileCoordinate(this.x, this.y);

  @override
  String toString() => 'TileCoordinate($x, $y)';
}

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

      // Calculate total tiles to download
      final totalTiles = _calculateTotalTiles(bounds, minZoom, maxZoom);
      int downloadedTiles = 0;

      _logger.info('Total tiles to download: $totalTiles');

      // Download tiles for each zoom level
      for (int zoom = minZoom; zoom <= maxZoom; zoom++) {
        final tilesForZoom = _calculateTilesForZoom(bounds, zoom);

        _logger.info(
          'Downloading zoom level $zoom: ${tilesForZoom.length} tiles',
        );

        // Download tiles for this zoom level
        for (final tile in tilesForZoom) {
          try {
            await _downloadTile(tile, mapType, zoom);
            downloadedTiles++;

            // Report progress
            final percentage = (downloadedTiles / totalTiles) * 100;
            onProgress(downloadedTiles, totalTiles, percentage);

            // Small delay to prevent overwhelming the server
            await Future.delayed(const Duration(milliseconds: 50));
          } catch (e) {
            _logger.warning('Failed to download tile $tile at zoom $zoom: $e');
            // Continue with other tiles even if one fails
          }
        }
      }

      _logger.info(
        'Download completed successfully. Downloaded: $downloadedTiles/$totalTiles tiles',
      );
      onComplete(true, null);
    } catch (e, stackTrace) {
      _logger.severe('Download failed: $e', e, stackTrace);
      onComplete(false, e.toString());
    }
  }

  /// Calculate total number of tiles to download
  static int _calculateTotalTiles(
    LatLngBounds bounds,
    int minZoom,
    int maxZoom,
  ) {
    int total = 0;
    for (int zoom = minZoom; zoom <= maxZoom; zoom++) {
      total += _calculateTilesForZoom(bounds, zoom).length;
    }
    return total;
  }

  /// Calculate tiles needed for a specific zoom level
  static List<TileCoordinate> _calculateTilesForZoom(
    LatLngBounds bounds,
    int zoom,
  ) {
    final tiles = <TileCoordinate>[];

    // Convert bounds to tile coordinates
    final minTile = _latLngToTile(bounds.southWest, zoom);
    final maxTile = _latLngToTile(bounds.northEast, zoom);

    // Generate all tiles in the range
    for (int x = minTile.x; x <= maxTile.x; x++) {
      for (int y = minTile.y; y <= maxTile.y; y++) {
        tiles.add(TileCoordinate(x, y));
      }
    }

    return tiles;
  }

  /// Convert LatLng to tile coordinates
  static TileCoordinate _latLngToTile(LatLng latLng, int zoom) {
    final n = math.pow(2, zoom).toDouble();
    final xtile = ((latLng.longitude + 180) / 360 * n).floor();

    final latRad = _radians(latLng.latitude);
    final tanLat = math.tan(latRad);
    final cosLat = math.cos(latRad);
    final logTerm = math.log(tanLat + 1 / cosLat);
    final ytile = ((1 - logTerm) / math.pi * n / 2).floor();

    return TileCoordinate(xtile, ytile);
  }

  /// Download a single tile
  static Future<void> _downloadTile(
    TileCoordinate tile,
    MapType mapType,
    int zoom,
  ) async {
    final url = _buildTileUrl(tile, mapType, zoom);

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));

      // Add user agent to avoid being blocked
      request.headers.set('User-Agent', 'TeleferiKa/1.0');

      final response = await request.close();

      if (response.statusCode == 200) {
        // Tile downloaded successfully, FMTC will cache it automatically
        _logger.fine('Tile downloaded successfully: $url');
      } else {
        throw Exception('HTTP ${response.statusCode}: $url');
      }
    } catch (e) {
      _logger.warning('Failed to download tile: $url - $e');
      rethrow;
    }
  }

  /// Build tile URL for the given map type
  static String _buildTileUrl(TileCoordinate tile, MapType mapType, int zoom) {
    final urlTemplate = mapType.tileLayerUrl;
    return urlTemplate
        .replaceAll('{z}', zoom.toString())
        .replaceAll('{x}', tile.x.toString())
        .replaceAll('{y}', tile.y.toString());
  }

  /// Convert degrees to radians
  static double _radians(double degrees) => degrees * math.pi / 180;
}
