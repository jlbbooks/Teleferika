import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/map/map_type.dart';
import 'package:teleferika/map/state/map_state_manager.dart';
import 'package:teleferika/map/services/map_store_utils.dart';
import 'package:teleferika/map/services/map_cache_logger.dart';
import 'package:teleferika/map/services/map_cache_manager.dart';

class DebugPanel extends StatelessWidget {
  static final Logger _logger = Logger('DebugPanel');
  final VoidCallback? onClose;
  final VoidCallback? onTestCalibrationPanel;
  final MapType currentMapType;

  const DebugPanel({
    super.key,
    this.onClose,
    this.onTestCalibrationPanel,
    required this.currentMapType,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MapStateManager>(
      builder: (context, stateManager, child) {
        return Material(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row with title and close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DEBUG PANEL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.amber,
                        ),
                      ),
                      if (onClose != null)
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onClose,
                          tooltip: 'Close debug panel',
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Test buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (onTestCalibrationPanel != null) ...[
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: onTestCalibrationPanel,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text(
                              'Test Calibration',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () {
                            try {
                              if (kIsWeb) {
                                _logger.info(
                                  'Haptic feedback not available on web',
                                );
                                return;
                              }
                              HapticFeedback.mediumImpact();
                              _logger.fine('Haptic feedback test triggered');
                            } catch (e) {
                              _logger.warning(
                                'Haptic feedback test failed: $e',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Test Haptic',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Heading: ${stateManager.currentDeviceHeading?.toStringAsFixed(2) ?? "-"}°',
                  ),
                  Text(
                    'Compass accuracy: ${stateManager.currentCompassAccuracy?.toStringAsFixed(2) ?? "-"}',
                  ),
                  Text(
                    'Should calibrate: ${stateManager.shouldCalibrateCompass == true ? "YES" : "NO"}',
                  ),
                  if (stateManager.currentPosition != null) ...[
                    Row(
                      children: [
                        Icon(
                          stateManager.isUsingBleGps
                              ? Icons.bluetooth
                              : Icons.phone_android,
                          size: 14,
                          color: stateManager.isUsingBleGps
                              ? Colors.blue
                              : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'GPS Source: ',
                          style: TextStyle(
                            color: stateManager.isUsingBleGps
                                ? Colors.blue
                                : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          stateManager.isUsingBleGps
                              ? 'RTK Device (BLE)'
                              : 'Device GPS',
                          style: TextStyle(
                            color: stateManager.isUsingBleGps
                                ? Colors.blue
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          AppConfig.latitudeIcon,
                          size: 14,
                          color: AppConfig.latitudeColor,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Lat: ',
                          style: TextStyle(color: AppConfig.latitudeColor),
                        ),
                        Text(
                          stateManager.currentPosition!.latitude
                              .toStringAsFixed(6),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          AppConfig.longitudeIcon,
                          size: 14,
                          color: AppConfig.longitudeColor,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Lon: ',
                          style: TextStyle(color: AppConfig.longitudeColor),
                        ),
                        Text(
                          stateManager.currentPosition!.longitude
                              .toStringAsFixed(6),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          AppConfig.altitudeIcon,
                          size: 14,
                          color: AppConfig.altitudeColor,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Alt: ',
                          style: TextStyle(color: AppConfig.altitudeColor),
                        ),
                        Text(
                          stateManager.currentPosition!.altitude
                              .toStringAsFixed(2),
                        ),
                        const Text(' m'),
                      ],
                    ),
                    Text(
                      'Location accuracy: ${stateManager.currentPosition!.accuracy.toStringAsFixed(2)} m',
                    ),
                    Text(
                      'Speed: ${stateManager.currentPosition!.speed.toStringAsFixed(2)} m/s',
                    ),
                    Text(
                      'Speed accuracy: ${stateManager.currentPosition!.speedAccuracy.toStringAsFixed(2)} m/s',
                    ),
                    Text('Map type: ${stateManager.currentMapType.id}'),
                    Row(
                      children: [
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () async {
                              await MapCacheLogger.logAllCacheStats();
                              if (context.mounted) {
                                _showCacheStatsDialog(context);
                              }
                            },
                            child: const Text('Cache Stats'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              _showStoreStatusDialog(context);
                            },
                            child: const Text('Store Status'),
                          ),
                        ),
                      ],
                    ),
                    FutureBuilder<double>(
                      future: FMTCStore(
                        MapStoreUtils.getStoreNameForMapType(currentMapType),
                      ).stats.size,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            'FMTCStore size: Error - ${snapshot.error}',
                          );
                        } else if (snapshot.hasData) {
                          return Text(
                            'FMTCStore size: ${snapshot.data?.toStringAsFixed(0) ?? '0'}',
                          );
                        } else if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text('FMTCStore size: Loading...');
                        } else {
                          return const Text('FMTCStore size: -');
                        }
                      },
                    ),
                    FutureBuilder<double>(
                      future: FMTCRoot.stats.realSize,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            'Map cache size: Error - ${snapshot.error}',
                          );
                        } else if (snapshot.hasData) {
                          return Text(
                            'Map cache size: ${snapshot.data?.toStringAsFixed(0) ?? '0'} bytes',
                          );
                        } else if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text('Map cache size: Loading...');
                        } else {
                          return const Text('Map cache size: -');
                        }
                      },
                    ),
                    Text(
                      'Timestamp: ${stateManager.currentPosition!.timestamp}',
                    ),
                  ] else ...[
                    const Text('Location: -'),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Show store status in a dialog
  void _showStoreStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cache Store Status'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show current map type id for context
                Text(
                  'Current map type: ${currentMapType.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Store validation status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...MapCacheManager.getStoreStatus().entries.map((entry) {
                  final status = entry.value;
                  Color statusColor;
                  IconData statusIcon;
                  switch (status) {
                    case 'validated':
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                      break;
                    case 'failed':
                      statusColor = Colors.red;
                      statusIcon = Icons.cancel;
                      break;
                    default:
                      statusColor = Colors.orange;
                      statusIcon = Icons.check_circle;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key}:',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 16),
                            const SizedBox(width: 4),
                            Text(status, style: TextStyle(color: statusColor)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Text(
                  'Actions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        await MapCacheManager.validateAllStores();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          _showStoreStatusDialog(context);
                        }
                      },
                      child: const Text('Revalidate All'),
                    ),
                    TextButton(
                      onPressed: () {
                        MapCacheManager.resetAllStoreValidation();
                        Navigator.of(context).pop();
                        _showStoreStatusDialog(context);
                      },
                      child: const Text('Reset Validation'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Show cache statistics in a dialog
  void _showCacheStatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Map Cache Statistics'),
          content: FutureBuilder<Map<String, dynamic>>(
            future: MapCacheLogger.getCacheSummary(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error loading cache stats: ${snapshot.error}');
              } else if (snapshot.hasData) {
                final data = snapshot.data!;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Cache Size: ${data['totalSizeFormatted'] ?? 'Unknown'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      if (data['stores'] != null) ...[
                        Text(
                          'Store Details:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        ...data['stores'].entries.map<Widget>((entry) {
                          final storeData = entry.value as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.key.toUpperCase()}:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (storeData['error'] != null)
                                  Text(
                                    'Error: ${storeData['error']}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  )
                                else ...[
                                  Text(
                                    'Size: ${storeData['size'] ?? 'Unknown'}',
                                  ),
                                  Text(
                                    'Len: ${storeData['length'] ?? 'Unknown'}'
                                    ' | '
                                    'Hits: ${storeData['hits'] ?? 'Unknown'}'
                                    ' | '
                                    'Misses: ${storeData['misses'] ?? 'Unknown'}',
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      if (data['error'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Error: ${data['error']}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              } else {
                return const Text('No data available');
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
