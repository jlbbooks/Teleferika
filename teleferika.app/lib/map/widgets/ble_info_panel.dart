import 'dart:async';
import 'package:flutter/material.dart';
import 'package:teleferika/ble/ble_service.dart';
import 'package:teleferika/ble/nmea_parser.dart';

class BLEInfoPanel extends StatefulWidget {
  final BLEService bleService;

  const BLEInfoPanel({super.key, required this.bleService});

  @override
  State<BLEInfoPanel> createState() => _BLEInfoPanelState();
}

class _BLEInfoPanelState extends State<BLEInfoPanel> {
  NMEAData? _latestNmeaData;
  StreamSubscription<NMEAData>? _nmeaSubscription;

  @override
  void initState() {
    super.initState();
    _nmeaSubscription = widget.bleService.nmeaData.listen((data) {
      if (mounted) {
        setState(() {
          _latestNmeaData = data;
        });
      }
    });
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
    final isConnected = widget.bleService.isConnected;

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
                    'RTK Device Info',
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
                // Connection Status
                _buildInfoRow(
                  'Status',
                  isConnected ? 'Connected' : 'Disconnected',
                  isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 8),

                // Device Name
                if (device != null) ...[
                  _buildInfoRow(
                    'Device',
                    device.platformName.isNotEmpty
                        ? device.platformName
                        : device.remoteId.toString(),
                  ),
                  const SizedBox(height: 8),
                ],

                // Latest NMEA Data
                if (_latestNmeaData != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'GPS Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fix Quality
                  _buildInfoRow(
                    'Fix Quality',
                    _getFixQualityText(_latestNmeaData!.fixQuality),
                    _getFixQualityColor(_latestNmeaData!.fixQuality),
                  ),
                  const SizedBox(height: 8),

                  // Satellites
                  if (_latestNmeaData!.satellites != null)
                    _buildInfoRow(
                      'Satellites',
                      '${_latestNmeaData!.satellites}',
                    ),
                  const SizedBox(height: 8),

                  // Accuracy
                  if (_latestNmeaData!.accuracy != null)
                    _buildInfoRow(
                      'Accuracy',
                      '${_latestNmeaData!.accuracy!.toStringAsFixed(2)} m',
                    ),
                  const SizedBox(height: 8),

                  // HDOP
                  if (_latestNmeaData!.hdop != null)
                    _buildInfoRow(
                      'HDOP',
                      _latestNmeaData!.hdop!.toStringAsFixed(2),
                    ),
                  const SizedBox(height: 8),

                  // Coordinates
                  _buildInfoRow(
                    'Latitude',
                    _latestNmeaData!.latitude.toStringAsFixed(8),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Longitude',
                    _latestNmeaData!.longitude.toStringAsFixed(8),
                  ),
                  const SizedBox(height: 8),

                  // Altitude
                  if (_latestNmeaData!.altitude != null)
                    _buildInfoRow(
                      'Altitude',
                      '${_latestNmeaData!.altitude!.toStringAsFixed(2)} m',
                    ),
                  const SizedBox(height: 8),

                  // Speed
                  if (_latestNmeaData!.speed != null)
                    _buildInfoRow(
                      'Speed',
                      '${_latestNmeaData!.speed!.toStringAsFixed(2)} km/h',
                    ),
                  const SizedBox(height: 8),

                  // Course
                  if (_latestNmeaData!.course != null)
                    _buildInfoRow(
                      'Course',
                      '${_latestNmeaData!.course!.toStringAsFixed(1)}°',
                    ),
                ] else if (isConnected) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Waiting for GPS data...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
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
}
