import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/ui/tabs/map/state/map_state_manager.dart';

class DebugPanel extends StatelessWidget {
  final VoidCallback? onClose;
  final VoidCallback? onTestCalibrationPanel;

  const DebugPanel({super.key, this.onClose, this.onTestCalibrationPanel});

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
                          AppConfig.latitudeIcon,
                          size: 14,
                          color: AppConfig.latitudeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
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
                        Text(
                          stateManager.currentPosition!.longitude
                              .toStringAsFixed(6),
                        ),
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
}
