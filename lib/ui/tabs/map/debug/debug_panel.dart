import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teleferika/core/app_config.dart';

class DebugPanel extends StatelessWidget {
  final double? heading;
  final double? compassAccuracy;
  final bool? shouldCalibrate;
  final Position? position;
  final VoidCallback? onClose;
  final VoidCallback? onTestCalibrationPanel;

  const DebugPanel({
    super.key,
    this.heading,
    this.compassAccuracy,
    this.shouldCalibrate,
    this.position,
    this.onClose,
    this.onTestCalibrationPanel,
  });

  @override
  Widget build(BuildContext context) {
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
                  if (onTestCalibrationPanel != null)
                    TextButton(
                      onPressed: onTestCalibrationPanel,
                      child: const Text(
                        'Test Calibration Panel',
                        style: TextStyle(color: Colors.amber, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Heading: ${heading?.toStringAsFixed(2) ?? "-"}°'),
              Text(
                'Compass accuracy: ${compassAccuracy?.toStringAsFixed(2) ?? "-"}',
              ),
              Text(
                'Should calibrate: ${shouldCalibrate == true ? "YES" : "NO"}',
              ),
              if (position != null) ...[
                Row(
                  children: [
                    Icon(
                      AppConfig.latitudeIcon,
                      size: 14,
                      color: AppConfig.latitudeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lat: ',
                      style: TextStyle(color: AppConfig.latitudeColor),
                    ),
                    Text(position!.latitude.toStringAsFixed(6)),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      AppConfig.longitudeIcon,
                      size: 14,
                      color: AppConfig.longitudeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lon: ',
                      style: TextStyle(color: AppConfig.longitudeColor),
                    ),
                    Text(position!.longitude.toStringAsFixed(6)),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      AppConfig.altitudeIcon,
                      size: 14,
                      color: AppConfig.altitudeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Alt: ',
                      style: TextStyle(color: AppConfig.altitudeColor),
                    ),
                    Text(position!.altitude.toStringAsFixed(2)),
                    const Text(' m'),
                  ],
                ),
                Text(
                  'Location accuracy: ${position!.accuracy.toStringAsFixed(2)} m',
                ),
                Text('Speed: ${position!.speed.toStringAsFixed(2)} m/s'),
                Text(
                  'Speed accuracy: ${position!.speedAccuracy.toStringAsFixed(2)} m/s',
                ),
                Text('Timestamp: ${position!.timestamp}'),
              ] else ...[
                const Text('Location: -'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
