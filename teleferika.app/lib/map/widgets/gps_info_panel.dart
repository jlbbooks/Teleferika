import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teleferika/ble/rtk_device_service.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ble/nmea_parser.dart';
import 'package:teleferika/core/fix_quality_colors.dart';
import 'package:teleferika/core/platform_gps_info.dart';
import 'package:teleferika/ui/screens/ble/rtk_devices_screen.dart';

class GPSInfoPanel extends StatefulWidget {
  final RtkDeviceService rtkService;
  final Position? currentPosition;
  final bool isUsingBleGps;

  const GPSInfoPanel({
    super.key,
    required this.rtkService,
    required this.currentPosition,
    required this.isUsingBleGps,
  });

  @override
  State<GPSInfoPanel> createState() => _GPSInfoPanelState();
}

class _GPSInfoPanelState extends State<GPSInfoPanel> {
  NMEAData? _latestNmeaData;
  Position? _currentPosition;
  StreamSubscription<NMEAData>? _nmeaSubscription;
  StreamSubscription<Position>? _positionSubscription;
  int? _platformSatelliteCount;
  int? _platformFixQuality;
  Timer? _platformInfoTimer;

  @override
  void initState() {
    super.initState();
    // Initialize with the provided position
    _currentPosition = widget.currentPosition;

    if (widget.isUsingBleGps) {
      // Subscribe to RTK GPS data streams (BLE or USB)
      _nmeaSubscription = widget.rtkService.nmeaData.listen((data) {
        if (mounted) {
          setState(() {
            _latestNmeaData = data;
          });
        }
      });

      _positionSubscription = widget.rtkService.gpsData.listen((position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      });
    } else {
      // For internal GPS, subscribe to Geolocator position stream
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );

      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((position) {
            if (mounted) {
              setState(() {
                _currentPosition = position;
              });
              // Also refresh platform info when position updates
              _loadPlatformGpsInfo();
            }
          });

      // For internal GPS, try to get platform-specific info
      _loadPlatformGpsInfo();
      // Refresh platform info periodically
      _platformInfoTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _loadPlatformGpsInfo(),
      );
    }
  }

  Future<void> _loadPlatformGpsInfo() async {
    if (widget.isUsingBleGps) return; // Only for internal GPS

    try {
      final satelliteCount = await PlatformGpsInfo.getSatelliteCount();
      final fixQuality = await PlatformGpsInfo.getFixQuality();
      if (mounted) {
        setState(() {
          _platformSatelliteCount = satelliteCount;
          _platformFixQuality = fixQuality;
        });
      }
    } catch (e) {
      // Ignore errors - platform channel may not be implemented
    }
  }

  @override
  void dispose() {
    _nmeaSubscription?.cancel();
    _positionSubscription?.cancel();
    _platformInfoTimer?.cancel();
    super.dispose();
  }

  String _getFixQualityText(BuildContext context, int fixQuality) {
    final s = S.of(context);
    switch (fixQuality) {
      case 0:
        return s?.bleGpsFixQualityInvalid ?? 'No Fix';
      case 1:
        return s?.bleGpsFixQualityGps ?? 'GPS Fix';
      case 2:
        return s?.bleGpsFixQualityDgps ?? 'DGPS Fix';
      case 4:
        return s?.bleGpsFixQualityRtk ?? 'RTK Fixed';
      case 5:
        return s?.bleGpsFixQualityRtkFloat ?? 'RTK Float';
      default:
        return s?.bleGpsFixQualityUnknown(fixQuality) ?? 'Unknown ($fixQuality)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceName = widget.rtkService.connectedDeviceName;
    final isBleConnected = widget.rtkService.isConnected;
    final position = _currentPosition ?? widget.currentPosition;
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
                    S.of(context)?.gpsInfoTitle ?? 'GPS Information',
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
                    S.of(context)?.gpsInfoTitle ?? 'GPS Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fix Quality (from NMEA or platform API)
                  if (nmeaData != null) ...[
                    _buildInfoRow(
                      S.of(context)?.bleGpsFixQuality ?? 'Fix Quality',
                      _getFixQualityText(context, nmeaData.fixQuality),
                      FixQualityColors.getColor(nmeaData.fixQuality),
                    ),
                    const SizedBox(height: 8),
                  ] else if (_platformFixQuality != null) ...[
                    _buildInfoRow(
                      S.of(context)?.bleGpsFixQuality ?? 'Fix Quality',
                      _getFixQualityText(context, _platformFixQuality!),
                      FixQualityColors.getColor(_platformFixQuality!),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Satellites (from NMEA or platform API)
                  if (nmeaData?.satellites != null) ...[
                    _buildInfoRow(S.of(context)?.bleGpsSatellites ?? 'Satellites', '${nmeaData!.satellites}'),
                    const SizedBox(height: 8),
                  ] else if (_platformSatelliteCount != null) ...[
                    _buildInfoRow(S.of(context)?.bleGpsSatellites ?? 'Satellites', '$_platformSatelliteCount'),
                    const SizedBox(height: 8),
                  ],

                  // Accuracy
                  _buildInfoRow(
                    S.of(context)?.bleGpsAccuracy ?? 'Accuracy',
                    '${position.accuracy.toStringAsFixed(2)} m',
                  ),
                  const SizedBox(height: 8),

                  // HDOP (only from NMEA)
                  if (nmeaData?.hdop != null) ...[
                    _buildInfoRow(S.of(context)?.bleGpsHdop ?? 'HDOP', nmeaData!.hdop!.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                  ],
                  // DGPS/RTK correction age and station (only from NMEA)
                  if (nmeaData?.dgpsAgeSec != null) ...[
                    _buildInfoRow(
                      S.of(context)?.bleGpsDgpsAge ?? 'DGPS age',
                      '${nmeaData!.dgpsAgeSec!.toStringAsFixed(1)} s',
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (nmeaData?.dgpsStationId != null && nmeaData!.dgpsStationId!.isNotEmpty) ...[
                    _buildInfoRow(
                      S.of(context)?.bleGpsDgpsStation ?? 'DGPS station',
                      nmeaData.dgpsStationId!,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (nmeaData?.magneticVariation != null) ...[
                    _buildInfoRow(
                      S.of(context)?.bleGpsMagneticVariation ?? 'Mag. var.',
                      '${nmeaData!.magneticVariation!.toStringAsFixed(1)}°',
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Coordinates
                  _buildInfoRow(
                    S.of(context)?.bleGpsLatitude ?? 'Latitude',
                    position.latitude.toStringAsFixed(8),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    S.of(context)?.bleGpsLongitude ?? 'Longitude',
                    position.longitude.toStringAsFixed(8),
                  ),
                  const SizedBox(height: 8),

                  // Altitude
                  if (position.altitude != 0.0) ...[
                    _buildInfoRow(
                      S.of(context)?.bleGpsAltitude ?? 'Altitude',
                      '${position.altitude.toStringAsFixed(2)} m',
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Speed
                  if (position.speed > 0) ...[
                    _buildInfoRow(
                      S.of(context)?.bleGpsSpeed ?? 'Speed',
                      '${(position.speed * 3.6).toStringAsFixed(2)} km/h',
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Course
                  if (position.heading > 0) ...[
                    _buildInfoRow(
                      S.of(context)?.gpsCourseLabel ?? 'Course',
                      '${position.heading.toStringAsFixed(1)}°',
                    ),
                    const SizedBox(height: 8),
                  ],
                ] else ...[
                  Text(
                    S.of(context)?.gpsWaitingForData ?? 'Waiting for GPS data...',
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
                    S.of(context)?.gpsDeviceInfoSection ?? 'Device Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (isBleConnected) ...[
                  // RTK Device Info
                  _buildInfoRow(S.of(context)?.gpsSourceLabel ?? 'Source', S.of(context)?.gpsRtkDevice ?? 'RTK Device', Colors.green),
                  const SizedBox(height: 8),
                  _buildInfoRow(S.of(context)?.gpsStatusLabel ?? 'Status', S.of(context)?.bleStatusConnected ?? 'Connected', Colors.green),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    S.of(context)?.gpsDeviceLabel ?? 'Device',
                    deviceName?.isNotEmpty == true
                        ? deviceName!
                        : (S.of(context)?.gpsRtkReceiver ?? 'RTK Receiver'),
                  ),
                  const SizedBox(height: 16),
                  // Button to disconnect from RTK device
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await widget.rtkService.disconnect();
                          if (mounted) {
                            Navigator.of(
                              context,
                            ).pop(); // Close the GPS info panel
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(S.of(context)?.errorDisconnecting(e.toString()) ?? 'Error disconnecting: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.bluetooth_disabled),
                      label: Text(S.of(context)?.bleButtonDisconnect ?? 'Disconnect'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ] else ...[
                  // Internal GPS Info
                  _buildInfoRow(S.of(context)?.gpsSourceLabel ?? 'Source', S.of(context)?.gpsInternalGps ?? 'Internal GPS', Colors.blue),
                  const SizedBox(height: 8),
                  _buildInfoRow(S.of(context)?.gpsStatusLabel ?? 'Status', S.of(context)?.gpsStatusActive ?? 'Active', Colors.blue),
                  const SizedBox(height: 16),
                  // Button to connect to RTK device
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the GPS info panel
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const RtkDevicesScreen(autoStartScan: true),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bluetooth),
                      label: Text(S.of(context)?.gpsConnectRtkDevice ?? 'Connect RTK Device'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
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
