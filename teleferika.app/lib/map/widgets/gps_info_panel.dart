import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teleferika/ble/ble_service.dart';
import 'package:teleferika/ble/nmea_parser.dart';

class GPSInfoPanel extends StatefulWidget {
  final BLEService bleService;
  final Position? currentPosition;
  final bool isUsingBleGps;

  const GPSInfoPanel({
    super.key,
    required this.bleService,
    required this.currentPosition,
    required this.isUsingBleGps,
  });

  @override
  State<GPSInfoPanel> createState() => _GPSInfoPanelState();
}

class _GPSInfoPanelState extends State<GPSInfoPanel> {
  NMEAData? _latestNmeaData;
  StreamSubscription<NMEAData>? _nmeaSubscription;

  @override
  void initState() {
    super.initState();
    // Only subscribe to NMEA data if using BLE GPS
    if (widget.isUsingBleGps) {
      _nmeaSubscription = widget.bleService.nmeaData.listen((data) {
        if (mounted) {
          setState(() {
            _latestNmeaData = data;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nmeaSubscription?.cancel();
    super.dispose();
  }

  String _getFixQualityText(int fixQuality) {
    switch (fixQuality) {
      case 0:
        return 'No Fix';
      case 1:
        return 'GPS Fix';
      case 2:
        return 'DGPS Fix';
      case 4:
        return 'RTK Fixed';
      case 5:
        return 'RTK Float';
      default:
        return 'Unknown ($fixQuality)';
    }
  }

  Color _getFixQualityColor(int fixQuality) {
    switch (fixQuality) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.yellow;
      case 4:
        return Colors.green;
      case 5:
        return Colors.lightGreen;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.bleService.connectedDevice;
    final isBleConnected = widget.bleService.isConnected;
    final position = widget.currentPosition;
    final nmeaData = _latestNmeaData;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.satellite, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GPS Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GPS Information Section (always shown if position available)
                if (position != null) ...[
                  Text(
                    'GPS Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fix Quality (from NMEA if available, otherwise estimate from accuracy)
                  if (nmeaData != null) ...[
                    _buildInfoRow(
                      'Fix Quality',
                      _getFixQualityText(nmeaData.fixQuality),
                      _getFixQualityColor(nmeaData.fixQuality),
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
                    // Estimate fix quality from accuracy for internal GPS
                    _buildInfoRow(
                      'Fix Quality',
                      _estimateFixQualityFromAccuracy(position.accuracy),
                      _estimateFixQualityColorFromAccuracy(position.accuracy),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Satellites (only from NMEA)
                  if (nmeaData?.satellites != null) ...[
                    _buildInfoRow('Satellites', '${nmeaData!.satellites}'),
                    const SizedBox(height: 8),
                  ],

                  // Accuracy
                  _buildInfoRow(
                    'Accuracy',
                    '${position.accuracy.toStringAsFixed(2)} m',
                  ),
                  const SizedBox(height: 8),

                  // HDOP (only from NMEA)
                  if (nmeaData?.hdop != null) ...[
                    _buildInfoRow('HDOP', nmeaData!.hdop!.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                  ],

                  // Coordinates
                  _buildInfoRow(
                    'Latitude',
                    position.latitude.toStringAsFixed(8),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Longitude',
                    position.longitude.toStringAsFixed(8),
                  ),
                  const SizedBox(height: 8),

                  // Altitude
                  if (position.altitude != 0.0) ...[
                    _buildInfoRow(
                      'Altitude',
                      '${position.altitude.toStringAsFixed(2)} m',
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Speed
                  if (position.speed > 0) ...[
                    _buildInfoRow(
                      'Speed',
                      '${(position.speed * 3.6).toStringAsFixed(2)} km/h',
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Course
                  if (position.heading > 0) ...[
                    _buildInfoRow(
                      'Course',
                      '${position.heading.toStringAsFixed(1)}°',
                    ),
                    const SizedBox(height: 8),
                  ],
                ] else ...[
                  Text(
                    'Waiting for GPS data...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                // Device Information Section (at the bottom)
                if (position != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Device Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (isBleConnected && device != null) ...[
                  // RTK Device Info
                  _buildInfoRow('Source', 'RTK Device', Colors.green),
                  const SizedBox(height: 8),
                  _buildInfoRow('Status', 'Connected', Colors.green),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Device',
                    device.platformName.isNotEmpty
                        ? device.platformName
                        : device.remoteId.toString(),
                  ),
                ] else ...[
                  // Internal GPS Info
                  _buildInfoRow('Source', 'Internal GPS', Colors.blue),
                  const SizedBox(height: 8),
                  _buildInfoRow('Status', 'Active', Colors.blue),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: valueColor != null ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }

  String _estimateFixQualityFromAccuracy(double accuracy) {
    if (accuracy < 1.0) {
      return 'High Accuracy';
    } else if (accuracy < 5.0) {
      return 'Good';
    } else if (accuracy < 10.0) {
      return 'Moderate';
    } else {
      return 'Low Accuracy';
    }
  }

  Color _estimateFixQualityColorFromAccuracy(double accuracy) {
    if (accuracy < 1.0) {
      return Colors.green;
    } else if (accuracy < 5.0) {
      return Colors.lightGreen;
    } else if (accuracy < 10.0) {
      return Colors.yellow;
    } else {
      return Colors.orange;
    }
  }
}
