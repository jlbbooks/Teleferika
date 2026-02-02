import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/ble/ble_service.dart';
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
class BLEScreen extends StatefulWidget {
  const BLEScreen({super.key});

  @override
  State<BLEScreen> createState() => _BLEScreenState();
}

class _BLEScreenState extends State<BLEScreen> {
  final Logger logger = Logger('BLEScreen');
  final BLEService _bleService = BLEService();

  List<ScanResult> _scanResults = [];
  BLEConnectionState _connectionState = BLEConnectionState.disconnected;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<BLEConnectionState>? _connectionStateSubscription;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _setupSubscriptions();
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
          _connectionState = state;
        });
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    _connectionStateSubscription?.cancel();
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
        child: PermissionHandlerWidget(
          requiredPermissions: [PermissionType.bluetooth],
          onPermissionsResult: _handlePermissionsResult,
          showOverlay: true,
          child: _buildContent(s),
        ),
      ),
    );
  }

  Widget _buildContent(S? s) {
    return Column(
      children: [
        // Connection Status Card
        _buildConnectionStatusCard(s),

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
      builder: (context) => Container(
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
}
