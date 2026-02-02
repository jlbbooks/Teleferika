import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/ble/ble_service.dart';
import 'package:teleferika/ble/nmea_parser.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/widgets/permission_handler_widget.dart';

/// Screen for scanning and connecting to Bluetooth Low Energy devices.
///
/// This screen provides a user interface for:
/// - Requesting Bluetooth and location permissions
/// - Scanning for nearby BLE devices
/// - Viewing scan results with device information
/// - Connecting to and disconnecting from devices
/// - Viewing connection status
/// - Displaying GPS data from RTK receivers
class BLEScreen extends StatefulWidget {
  const BLEScreen({super.key});

  @override
  State<BLEScreen> createState() => _BLEScreenState();
}

class _BLEScreenState extends State<BLEScreen>
    with SingleTickerProviderStateMixin {
  final Logger logger = Logger('BLEScreen');
  final BLEService _bleService = BLEService();

  List<ScanResult> _scanResults = [];
  BLEConnectionState _connectionState = BLEConnectionState.disconnected;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<BLEConnectionState>? _connectionStateSubscription;
  StreamSubscription<Position>? _gpsDataSubscription;
  StreamSubscription<NMEAData>? _nmeaDataSubscription;
  bool _hasPermissions = false;

  // GPS data from RTK receiver
  Position? _currentPosition;
  NMEAData? _currentNmeaData;
  bool _hasReceivedFirstPosition = false;
  DateTime? _lastDataReceivedTime;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupSubscriptions();
    _setupPulseAnimation();
  }

  void _setupPulseAnimation() {
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _pulseAnimationController.repeat(reverse: true);
  }

  void _setupSubscriptions() {
    _scanResultsSubscription = _bleService.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    });

    _connectionStateSubscription = _bleService.connectionState.listen((state) {
      if (mounted) {
        setState(() {
          final wasConnected = _connectionState == BLEConnectionState.connected;
          _connectionState = state;
          // Reset position tracking when disconnecting
          if (state == BLEConnectionState.disconnected) {
            _hasReceivedFirstPosition = false;
            _lastDataReceivedTime = null;
            _currentPosition = null;
            _currentNmeaData = null;
          } else if (state == BLEConnectionState.connected && !wasConnected) {
            // Set initial timestamp when first connected to show indicator immediately
            _lastDataReceivedTime = DateTime.now();
            _hasReceivedFirstPosition = false; // Ensure this is false
            if (const bool.fromEnvironment('dart.vm.product') == false) {
              logger.info('BLEScreen: Connected - showing receiving indicator');
            }
          }
        });
      }
    });

    // Subscribe to GPS data from RTK receiver
    _gpsDataSubscription = _bleService.gpsData.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _hasReceivedFirstPosition =
              true; // Mark that we've received first position
        });
        // Only log in debug mode to reduce production logging
        if (const bool.fromEnvironment('dart.vm.product') == false) {
          logger.info(
            'GPS Position: ${position.latitude}, ${position.longitude}, '
            'accuracy: ${position.accuracy}m',
          );
        }
      }
    });

    // Subscribe to NMEA data for detailed information
    _nmeaDataSubscription = _bleService.nmeaData.listen((nmeaData) {
      if (mounted) {
        setState(() {
          _currentNmeaData = nmeaData;
          // Update timestamp when we receive data (for pulsing indicator)
          _lastDataReceivedTime = DateTime.now();
        });
        // Only log in debug mode to reduce production logging
        if (const bool.fromEnvironment('dart.vm.product') == false) {
          logger.info('NMEA Data: $nmeaData');
        }
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _gpsDataSubscription?.cancel();
    _nmeaDataSubscription?.cancel();
    _pulseAnimationController.dispose();
    _bleService.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    try {
      await _bleService.startScan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)?.bleScanStarted ?? 'Scan started...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      logger.severe('Error starting scan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.bleScanError ?? 'Error starting scan: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopScan() async {
    try {
      await _bleService.stopScan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)?.bleScanStopped ?? 'Scan stopped.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      logger.severe('Error stopping scan: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await _bleService.connectToDevice(device, context);
      if (mounted) {
        final s = S.of(context);
        final connectingText =
            s?.bleConnecting(device.platformName) ??
            'Connecting to ${device.platformName}...';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(connectingText)));
      }
    } catch (e) {
      logger.severe('Error connecting to device: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.bleConnectionError ?? 'Connection error: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectDevice() async {
    try {
      await _bleService.disconnectDevice();
      if (mounted) {
        setState(() {
          // Reset position tracking state on disconnect
          _hasReceivedFirstPosition = false;
          _lastDataReceivedTime = null;
          _currentPosition = null;
          _currentNmeaData = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.bleDisconnected ?? 'Device disconnected.',
            ),
          ),
        );
      }
    } catch (e) {
      logger.severe('Error disconnecting device: $e');
    }
  }

  Future<void> _requestMtu(BluetoothDevice device) async {
    try {
      await _bleService.requestMtu(device);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)?.bleMtuRequested ?? 'MTU requested.'),
          ),
        );
      }
    } catch (e) {
      logger.severe('Error requesting MTU: $e');
    }
  }

  void _handlePermissionsResult(Map<PermissionType, bool> permissions) {
    setState(() {
      _hasPermissions = permissions[PermissionType.bluetooth] ?? false;
    });

    if (!_hasPermissions) {
      logger.warning('Bluetooth permission not granted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s?.bleScreenTitle ?? 'Bluetooth Devices')),
      body: SafeArea(
        child: Stack(
          children: [
            PermissionHandlerWidget(
              requiredPermissions: [PermissionType.bluetooth],
              onPermissionsResult: _handlePermissionsResult,
              showOverlay: true,
              child: _buildContent(s),
            ),
            // Show pulsing indicator when connected but no position received yet
            if (_connectionState == BLEConnectionState.connected &&
                !_hasReceivedFirstPosition)
              _buildDataReceivingIndicator(s),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(S? s) {
    return Column(
      children: [
        // Connection Status Card
        _buildConnectionStatusCard(s),

        // GPS Data Card (shown when connected and receiving data)
        if (_connectionState == BLEConnectionState.connected &&
            (_currentPosition != null || _currentNmeaData != null))
          _buildGpsDataCard(s),

        // Scan Controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _bleService.isScanning ? null : _startScan,
                icon: const Icon(Icons.search),
                label: Text(s?.bleButtonStartScan ?? 'Start Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _bleService.isScanning ? _stopScan : null,
                icon: const Icon(Icons.stop),
                label: Text(s?.bleButtonStopScan ?? 'Stop Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Scan Results
        Expanded(child: _buildScanResultsList(s)),
      ],
    );
  }

  Widget _buildConnectionStatusCard(S? s) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_connectionState) {
      case BLEConnectionState.connected:
        statusColor = Colors.green;
        statusIcon = Icons.bluetooth_connected;
        statusText = s?.bleStatusConnected ?? 'Connected';
        break;
      case BLEConnectionState.connecting:
        statusColor = Colors.orange;
        statusIcon = Icons.bluetooth_searching;
        statusText = s?.bleStatusConnecting ?? 'Connecting...';
        break;
      case BLEConnectionState.error:
        statusColor = Colors.red;
        statusIcon = Icons.bluetooth_disabled;
        statusText = s?.bleStatusError ?? 'Connection Error';
        break;
      case BLEConnectionState.waiting:
        statusColor = Colors.blue;
        statusIcon = Icons.bluetooth_searching;
        statusText = s?.bleStatusWaiting ?? 'Waiting...';
        break;
      case BLEConnectionState.disconnected:
        statusColor = Colors.grey;
        statusIcon = Icons.bluetooth_disabled;
        statusText = s?.bleStatusDisconnected ?? 'Disconnected';
        break;
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s?.bleConnectionStatus ?? 'Connection Status',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_bleService.connectedDevice != null)
                    Text(
                      s?.bleConnectedDevice(
                            _bleService.connectedDevice!.platformName,
                          ) ??
                          'Device: ${_bleService.connectedDevice!.platformName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (_connectionState == BLEConnectionState.connected)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _disconnectDevice,
                tooltip: s?.bleButtonDisconnect ?? 'Disconnect',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanResultsList(S? s) {
    if (_scanResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              s?.bleNoDevicesFound ??
                  'No devices found.\nStart scanning to discover devices.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        final result = _scanResults[index];
        final device = result.device;
        final isConnected =
            _bleService.connectedDevice?.remoteId == device.remoteId;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            leading: Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: isConnected ? Colors.green : Colors.blue,
            ),
            title: Text(
              device.platformName.isEmpty
                  ? (s?.bleUnknownDevice ?? 'Unknown Device')
                  : device.platformName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${device.remoteId}'),
                Text('RSSI: ${result.rssi} dBm'),
                if (result.advertisementData.advName.isNotEmpty)
                  Text('Name: ${result.advertisementData.advName}'),
                if (result.advertisementData.serviceUuids.isNotEmpty)
                  Text(
                    'Services: ${result.advertisementData.serviceUuids.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: isConnected
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _disconnectDevice,
                    tooltip: s?.bleButtonDisconnect ?? 'Disconnect',
                  )
                : IconButton(
                    icon: const Icon(Icons.link),
                    onPressed: () => _connectToDevice(device),
                    tooltip: s?.bleButtonConnect ?? 'Connect',
                  ),
            onTap: isConnected ? null : () => _showDeviceDetails(result, s),
          ),
        );
      },
    );
  }

  void _showDeviceDetails(ScanResult result, S? s) {
    final device = result.device;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s?.bleDeviceDetails ?? 'Device Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                s?.bleDeviceName ?? 'Name',
                device.platformName.isEmpty
                    ? (s?.bleUnknownDevice ?? 'Unknown')
                    : device.platformName,
              ),
              _buildDetailRow(
                s?.bleDeviceId ?? 'Device ID',
                device.remoteId.toString(),
              ),
              _buildDetailRow(s?.bleRssi ?? 'RSSI', '${result.rssi} dBm'),
              _buildDetailRow(
                s?.bleAdvertisedName ?? 'Advertised Name',
                result.advertisementData.advName.isEmpty
                    ? (s?.bleNotAvailable ?? 'N/A')
                    : result.advertisementData.advName,
              ),
              _buildDetailRow(
                s?.bleConnectable ?? 'Connectable',
                result.advertisementData.connectable
                    ? (s?.bleYes ?? 'Yes')
                    : (s?.bleNo ?? 'No'),
              ),
              if (result.advertisementData.serviceUuids.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  s?.bleServiceUuids ?? 'Service UUIDs:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                ...result.advertisementData.serviceUuids.map(
                  (uuid) => Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                    child: Text(
                      uuid.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(s?.buttonCancel ?? 'Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _connectToDevice(device);
                    },
                    child: Text(s?.bleButtonConnect ?? 'Connect'),
                  ),
                  if (_connectionState == BLEConnectionState.connected &&
                      _bleService.connectedDevice?.remoteId == device.remoteId)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _requestMtu(device);
                      },
                      child: Text(s?.bleButtonRequestMtu ?? 'Request MTU'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildGpsDataCard(S? s) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode
        ? Colors.green.shade900.withOpacity(0.3)
        : Colors.green.shade50;
    final iconColor = isDarkMode
        ? Colors.green.shade300
        : Colors.green.shade700;
    final titleColor = isDarkMode
        ? Colors.green.shade300
        : Colors.green.shade700;

    return Card(
      margin: const EdgeInsets.all(16.0),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gps_fixed, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  s?.bleGpsDataTitle ?? 'GPS Data from RTK Receiver',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentPosition != null) ...[
              _buildGpsDataRow(
                s?.bleGpsLatitude ?? 'Latitude',
                '${_currentPosition!.latitude.toStringAsFixed(8)}°',
              ),
              _buildGpsDataRow(
                s?.bleGpsLongitude ?? 'Longitude',
                '${_currentPosition!.longitude.toStringAsFixed(8)}°',
              ),
              if (_currentPosition!.altitude != 0)
                _buildGpsDataRow(
                  s?.bleGpsAltitude ?? 'Altitude',
                  '${_currentPosition!.altitude.toStringAsFixed(2)} m',
                ),
              _buildGpsDataRow(
                s?.bleGpsAccuracy ?? 'Accuracy',
                '${_currentPosition!.accuracy.toStringAsFixed(2)} m',
                color: _getAccuracyColor(
                  _currentPosition!.accuracy,
                  isDarkMode,
                ),
              ),
            ],
            if (_currentNmeaData != null) ...[
              const Divider(height: 16),
              if (_currentNmeaData!.satellites != null)
                _buildGpsDataRow(
                  s?.bleGpsSatellites ?? 'Satellites',
                  '${_currentNmeaData!.satellites}',
                ),
              if (_currentNmeaData!.hdop != null)
                _buildGpsDataRow(
                  s?.bleGpsHdop ?? 'HDOP',
                  _currentNmeaData!.hdop!.toStringAsFixed(2),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              s?.bleGpsFixQuality ?? 'Fix Quality',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _showFixQualityExplanation(s),
                              child: Icon(
                                Icons.help_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _getFixQualityText(_currentNmeaData!.fixQuality, s),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getFixQualityColor(
                                  _currentNmeaData!.fixQuality,
                                  isDarkMode,
                                ),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildFixQualityBars(
                      _currentNmeaData!.fixQuality,
                      isDarkMode,
                    ),
                  ],
                ),
              ),
              if (_currentNmeaData!.speed != null)
                _buildGpsDataRow(
                  s?.bleGpsSpeed ?? 'Speed',
                  '${_currentNmeaData!.speed!.toStringAsFixed(2)} km/h',
                ),
            ],
            if (_currentPosition?.timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${s?.bleGpsUpdated ?? 'Updated:'} ${_formatTimestamp(_currentPosition!.timestamp)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsDataRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getFixQualityText(int quality, S? s) {
    switch (quality) {
      case 0:
        return s?.bleGpsFixQualityInvalid ?? 'Invalid';
      case 1:
        return s?.bleGpsFixQualityGps ?? 'GPS Fix';
      case 2:
        return s?.bleGpsFixQualityDgps ?? 'DGPS Fix';
      case 3:
        return s?.bleGpsFixQualityPps ?? 'PPS Fix';
      case 4:
        return s?.bleGpsFixQualityRtk ?? 'RTK Fix';
      case 5:
        return s?.bleGpsFixQualityRtkFloat ?? 'RTK Float';
      case 6:
        return s?.bleGpsFixQualityEstimated ?? 'Estimated';
      case 7:
        return s?.bleGpsFixQualityManual ?? 'Manual';
      case 8:
        return s?.bleGpsFixQualitySimulation ?? 'Simulation';
      default:
        return s?.bleGpsFixQualityUnknown(quality) ?? 'Unknown ($quality)';
    }
  }

  Color _getAccuracyColor(double accuracy, bool isDarkMode) {
    if (accuracy < 1.0) {
      return isDarkMode ? Colors.green.shade300 : Colors.green;
    } else if (accuracy < 5.0) {
      return isDarkMode ? Colors.orange.shade300 : Colors.orange;
    } else {
      return isDarkMode ? Colors.red.shade300 : Colors.red;
    }
  }

  Color _getFixQualityColor(int quality, bool isDarkMode) {
    // Only RTK Fix (quality 4) gets green, others get appropriate colors
    if (quality == 4) {
      return isDarkMode ? Colors.green.shade300 : Colors.green;
    } else if (quality == 5) {
      // RTK Float - light green/yellow-green
      return isDarkMode
          ? Colors.lightGreen.shade300
          : Colors.lightGreen.shade700;
    } else if (quality > 0) {
      // Other valid fixes - orange/yellow
      return isDarkMode ? Colors.orange.shade300 : Colors.orange;
    } else {
      // Invalid - red
      return isDarkMode ? Colors.red.shade300 : Colors.red;
    }
  }

  /// Builds a visual bar indicator for fix quality (0-5).
  /// Colors progress from red (0) to green (5).
  /// Note: RTK Fix (quality 4) is mapped to bar 5 (best), RTK Float (quality 5) to bar 4.
  Widget _buildFixQualityBars(int quality, bool isDarkMode) {
    // Clamp quality to 0-5 range for display
    final displayQuality = quality.clamp(0, 5);
    // Map quality to bar index (swap 4 and 5 so RTK Fix is highest)
    final barIndex = _qualityToBarIndex(displayQuality);

    return Row(
      children: List.generate(6, (index) {
        // Index 0-5 represents bars, with 5 being the best (RTK Fix)
        final isActive = index <= barIndex;
        final barColor = _getBarColor(index, isActive, isDarkMode);

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 5 ? 4.0 : 0),
            height: 8,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  /// Maps fix quality value to bar index.
  /// Swaps quality 4 (RTK Fix) and 5 (RTK Float) so RTK Fix appears as highest bar.
  int _qualityToBarIndex(int quality) {
    switch (quality) {
      case 0: // Invalid
        return 0;
      case 1: // GPS Fix
        return 1;
      case 2: // DGPS Fix
        return 2;
      case 3: // PPS Fix
        return 3;
      case 4: // RTK Fix - map to bar 5 (best)
        return 5;
      case 5: // RTK Float - map to bar 4
        return 4;
      default:
        return quality.clamp(0, 5);
    }
  }

  /// Gets the color for a specific bar based on its index and active state.
  Color _getBarColor(int index, bool isActive, bool isDarkMode) {
    if (!isActive) {
      // Inactive bars - gray
      return isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    }

    // Active bars - progressive colors from red to green
    // Bar 5 is RTK Fix (best), Bar 4 is RTK Float
    switch (index) {
      case 0: // Invalid
        return isDarkMode ? Colors.red.shade700 : Colors.red;
      case 1: // GPS Fix
        return isDarkMode ? Colors.orange.shade700 : Colors.orange;
      case 2: // DGPS Fix
        return isDarkMode ? Colors.orange.shade400 : Colors.deepOrange;
      case 3: // PPS Fix
        return isDarkMode ? Colors.yellow.shade700 : Colors.amber;
      case 4: // RTK Float - light green (quality 5)
        return isDarkMode
            ? Colors.lightGreen.shade300
            : Colors.lightGreen.shade700;
      case 5: // RTK Fix - green (quality 4, best)
        return isDarkMode ? Colors.green.shade300 : Colors.green;
      default:
        return isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    // Format absolute time
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';

    // Format relative time
    String relativeStr;
    if (difference.inSeconds < 60) {
      relativeStr = '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      relativeStr = '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      relativeStr = '${difference.inHours}h ago';
    } else {
      relativeStr = '${difference.inDays}d ago';
    }

    // Return both absolute and relative time
    return '$timeStr ($relativeStr)';
  }

  /// Shows an explanation dialog about fix quality values.
  void _showFixQualityExplanation(S? s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          s?.bleGpsFixQualityExplanationTitle ?? 'Fix Quality Explanation',
        ),
        content: SingleChildScrollView(
          child: Text(
            s?.bleGpsFixQualityExplanation ??
                'Fix Quality indicates the type and reliability of GPS positioning...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s?.buttonCancel ?? 'Cancel'),
          ),
        ],
      ),
    );
  }

  /// Builds a pulsing indicator overlay that shows when data is being received
  /// but no position has been received yet.
  Widget _buildDataReceivingIndicator(S? s) {
    // Always show when connected and no position received yet
    // The timestamp check is just to keep it "fresh" - if no data for 15+ seconds,
    // connection might be stale, but we'll still show it initially
    final timeSinceLastData = _lastDataReceivedTime != null
        ? DateTime.now().difference(_lastDataReceivedTime!)
        : const Duration(seconds: 0);

    // Only hide if we've been connected for a while with no data at all
    // (more than 15 seconds since connection and no NMEA data ever received)
    if (_lastDataReceivedTime != null &&
        timeSinceLastData.inSeconds > 15 &&
        _currentNmeaData == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return IgnorePointer(
            child: Opacity(
              opacity: _pulseAnimation.value,
              child: Material(
                elevation: 4,
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary
                            .withOpacity(0.4 * _pulseAnimation.value),
                        blurRadius: 12 * _pulseAnimation.value,
                        spreadRadius: 3 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        s?.bleReceivingData ?? 'Receiving data...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
