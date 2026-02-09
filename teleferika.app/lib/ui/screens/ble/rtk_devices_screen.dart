import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/ble/ble_service.dart';
import 'package:teleferika/ble/nmea_parser.dart';
import 'package:teleferika/ble/ntrip_client.dart';
import 'package:teleferika/ble/rtk_device_service.dart';
import 'package:teleferika/ble/usb_serial_service.dart';
import 'package:teleferika/core/fix_quality_colors.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/widgets/permission_handler_widget.dart';
import 'package:drift/drift.dart' as drift;
import 'package:teleferika/db/database.dart';
import 'package:teleferika/db/drift_database_helper.dart';
import 'package:teleferika/ui/widgets/ntrip_configuration_widget.dart';
import 'package:teleferika/ui/widgets/ble_scan_result_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen for connecting to RTK devices via Bluetooth or USB.
///
/// This screen provides a user interface for:
/// - Requesting Bluetooth and location permissions (for BLE)
/// - Scanning for nearby BLE devices
/// - Connecting to USB devices (Android)
/// - Viewing connection status
/// - Displaying GPS data from RTK receivers
/// - Configuring NTRIP correction streams
class RtkDevicesScreen extends StatefulWidget {
  final bool autoStartScan;

  const RtkDevicesScreen({super.key, this.autoStartScan = false});

  @override
  State<RtkDevicesScreen> createState() => _RtkDevicesScreenState();
}

class _RtkDevicesScreenState extends State<RtkDevicesScreen>
    with SingleTickerProviderStateMixin {
  final Logger logger = Logger('RtkDevicesScreen');
  final RtkDeviceService _rtkService = RtkDeviceService.instance;

  List<ScanResult> _scanResults = [];
  String? _lastConnectedDeviceId;
  BLEConnectionState _connectionState = BLEConnectionState.disconnected;
  bool _connectedViaUsb = false;
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BLEConnectionState>? _connectionStateSubscription;
  StreamSubscription<Position>? _gpsDataSubscription;
  StreamSubscription<NMEAData>? _nmeaDataSubscription;
  bool _hasPermissions = false;

  List<UsbDeviceInfo> _usbDevices = [];
  bool _usbDevicesLoading = false;
  int _connectionModeIndex = 0; // 0 = Bluetooth, 1 = USB

  // GPS data from RTK receiver
  Position? _currentPosition;
  NMEAData? _currentNmeaData;
  bool _hasReceivedFirstPosition = false;
  DateTime? _lastDataReceivedTime;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  // NTRIP configuration
  final TextEditingController _ntripHostController = TextEditingController(
    text: '194.105.50.232',
  );
  final TextEditingController _ntripPortController = TextEditingController(
    text: '2101',
  );
  final TextEditingController _ntripMountPointController =
      TextEditingController(text: 'IMAX3');
  final TextEditingController _ntripUsernameController = TextEditingController(
    text: 'TeleferiKa_2',
  );
  final TextEditingController _ntripPasswordController = TextEditingController(
    text: 'WqDS-n8r5p!r-Db',
  );
  NTRIPConnectionState _ntripConnectionState =
      NTRIPConnectionState.disconnected;
  StreamSubscription<NTRIPConnectionState>? _ntripConnectionStateSubscription;
  StreamSubscription<String>? _ntripErrorSubscription;
  StreamSubscription<List<int>>? _rtcmDataSubscription;
  bool _ntripUseSsl = false;
  int? _connectingHostId; // Track the host ID being connected
  bool _hasReceivedValidRtcm =
      false; // Track if we've received valid RTCM packets
  int _hostStatusRefreshTrigger = 0; // Trigger to force widget refresh

  @override
  void initState() {
    super.initState();
    // Initialize connection state from current service state before setting up subscriptions
    _refreshConnectionState();
    _setupSubscriptions();
    _setupPulseAnimation();
    _loadNtripSettings(); // Load persisted settings
    _loadLastConnectedDeviceId(); // Load last connected device ID
    // _startScanStateCheckTimer(); - Removed in favor of stream

    // Auto-start scan if requested
    if (widget.autoStartScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isScanning) {
          _startScan();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh connection state when screen becomes visible (e.g., navigating back)
    // This ensures the UI reflects the current state even if the widget wasn't recreated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshConnectionState();
    });
  }

  /// Refresh the connection state from the RTK device service
  void _refreshConnectionState() {
    if (!mounted) return;

    setState(() {
      _connectedViaUsb = _rtkService.activeMode == RtkConnectionMode.usb;
      if (_rtkService.isConnected) {
        _connectionState = BLEConnectionState.connected;
        _lastDataReceivedTime = DateTime.now();
        _connectionModeIndex = _connectedViaUsb ? 1 : 0;
      } else {
        _connectionState = BLEConnectionState.disconnected;
        _connectionModeIndex = 0;
      }
      _isScanning = _rtkService.bleTransport.isScanning;

      // Refresh NTRIP connection state from active service
      final ntripClient = _rtkService.ntripClient;
      if (ntripClient != null) {
        _ntripConnectionState = ntripClient.connectionState;
      } else {
        _ntripConnectionState = NTRIPConnectionState.disconnected;
      }
    });
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
    _scanResultsSubscription = _rtkService.bleTransport.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = _sortScanResults(results);
          // Update scanning state based on service state
          // _isScanning = _bleService.isScanning; // Managed by stream now
        });
      }
    });

    _isScanningSubscription = _rtkService.bleTransport.isScanningStream.listen((isScanning) {
      if (mounted) {
        setState(() {
          _isScanning = isScanning;
        });
      }
    });

    // NTRIP connection state subscription - subscribe to active service
    _setupNtripSubscriptions();

    _connectionStateSubscription = _rtkService.connectionState.listen((state) {
      if (mounted) {
        final wasError = _connectionState == BLEConnectionState.error;
        setState(() {
          _connectionState = state;
          _connectedViaUsb = _rtkService.activeMode == RtkConnectionMode.usb;
          _isScanning = _rtkService.bleTransport.isScanning;
          if (state == BLEConnectionState.disconnected) {
            _hasReceivedFirstPosition = false;
            _lastDataReceivedTime = null;
            _currentPosition = null;
            _currentNmeaData = null;
            _connectionModeIndex = 0;
            _setupNtripSubscriptions();
          } else if (state == BLEConnectionState.connected) {
            _connectionModeIndex = _connectedViaUsb ? 1 : 0;
            _lastDataReceivedTime = DateTime.now();
            if (_currentPosition != null || _currentNmeaData != null) {
              _hasReceivedFirstPosition = true;
            }
            _setupNtripSubscriptions();
          }
        });
        // When USB connection fails, show a hint about permission
        if (_connectedViaUsb &&
            state == BLEConnectionState.error &&
            !wasError &&
            mounted) {
          final msg = _rtkService.lastUsbConnectionError ?? '';
          final isPermission = msg.contains('Permission') ||
              msg.contains('SecurityException') ||
              msg.contains('permission');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isPermission
                    ? (S.of(context)?.usbPermissionRequired ?? 'USB permission required.')
                    : (S.of(context)?.usbConnectionFailedWithMessage(msg.isNotEmpty ? ' $msg' : '') ?? 'USB connection failed.'),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    });

    _gpsDataSubscription = _rtkService.gpsData.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _hasReceivedFirstPosition = true;
        });
      }
    });

    _nmeaDataSubscription = _rtkService.nmeaData.listen((nmeaData) {
      if (mounted) {
        setState(() {
          _currentNmeaData = nmeaData;
          _lastDataReceivedTime = DateTime.now();
        });
      }
    });
  }

  /// Sets up NTRIP subscriptions for the active service (BLE or USB)
  void _setupNtripSubscriptions() {
    // Cancel existing subscriptions
    _ntripConnectionStateSubscription?.cancel();
    _ntripErrorSubscription?.cancel();

    // Get the active service's NTRIP client
    final ntripClient = _rtkService.ntripClient;
    
    if (ntripClient != null) {
      // Initialize state from current client state
      if (mounted) {
        setState(() {
          _ntripConnectionState = ntripClient.connectionState;
        });
      }
      
      // Subscribe to connection state changes
      _ntripConnectionStateSubscription = ntripClient.connectionStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _ntripConnectionState = state;
          });
        }
      });

      // Subscribe to errors
      _ntripErrorSubscription = ntripClient.errors.listen((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context)?.ntripError(error) ?? 'NTRIP Error: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(milliseconds: 3000),
            ),
          );
        }
      });
    } else {
      // No active NTRIP client
      if (mounted) {
        setState(() {
          _ntripConnectionState = NTRIPConnectionState.disconnected;
        });
      }
    }
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _gpsDataSubscription?.cancel();
    _nmeaDataSubscription?.cancel();
    _ntripConnectionStateSubscription?.cancel();
    _ntripErrorSubscription?.cancel();
    _rtcmDataSubscription?.cancel();
    _ntripHostController.dispose();
    _ntripPortController.dispose();
    _ntripMountPointController.dispose();
    _ntripUsernameController.dispose();
    _ntripPasswordController.dispose();
    _pulseAnimationController.dispose();
    // Don't dispose the BLE service here - it's a singleton that should persist
    // across screens to continue receiving GPS data in the background
    super.dispose();
  }

  Future<void> _startScan() async {
    try {
      setState(() {
        _isScanning = true;
      });
      await _rtkService.bleTransport.startScan();
      // Update state after scan starts (it may complete immediately)
      if (mounted) {
        setState(() {
          _isScanning = _rtkService.bleTransport.isScanning;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)?.bleScanStarted ?? 'Scan started...'),
            duration: const Duration(milliseconds: 1000),
          ),
        );
      }
    } catch (e) {
      logger.severe('Error starting scan: $e');
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.bleScanError ?? 'Error starting scan: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 3000),
          ),
        );
      }
    }
  }

  Future<void> _stopScan() async {
    try {
      setState(() {
        _isScanning = false;
      });
      await _rtkService.bleTransport.stopScan();
      if (mounted) {
        setState(() {
          _isScanning = _rtkService.bleTransport.isScanning;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)?.bleScanStopped ?? 'Scan stopped.'),
            duration: const Duration(milliseconds: 1000),
          ),
        );
      }
    } catch (e) {
      logger.severe('Error stopping scan: $e');
      if (mounted) {
        setState(() {
          _isScanning = _rtkService.bleTransport.isScanning;
        });
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      final wasNtripConnected = _rtkService.ntripClient?.connectionState ==
          NTRIPConnectionState.connected;

      if (mounted) {
        final s = S.of(context);
        final connectingText =
            s?.bleConnecting(device.platformName) ??
            'Connecting to ${device.platformName}...';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(connectingText),
            duration: const Duration(milliseconds: 1000),
          ),
        );
      }

      await _rtkService.connectViaBle(device, context);

      if (!mounted) return;
      if (!_rtkService.isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.bleConnectionError ?? 'Connection error',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 3000),
          ),
        );
        return;
      }

      setState(() => _connectedViaUsb = false);
      _setupNtripSubscriptions();

      // Save the connected device ID for future scans
      await _saveLastConnectedDeviceId(device.remoteId.toString());

      if (wasNtripConnected) {
        await _reconnectNtripAfterSwitch();
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
            duration: const Duration(milliseconds: 3000),
          ),
        );
      }
    }
  }

  Future<void> _disconnectDevice() async {
    try {
      await _rtkService.disconnect();
      setState(() => _connectedViaUsb = false);
      if (mounted) {
        setState(() {
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
            duration: const Duration(milliseconds: 1000),
          ),
        );
      }
    } catch (e) {
      logger.severe('Error disconnecting device: $e');
    }
  }

  BLEConnectionState get _effectiveConnectionState => _connectionState;

  String? get _effectiveDeviceName => _rtkService.connectedDeviceName;

  bool get _isDeviceConnected => _rtkService.isConnected;

  Future<void> _refreshUsbDevices() async {
    final supported = RtkDeviceService.isUsbSupported;
    if (!supported) {
      logger.warning('[USB] Not supported, returning');
      return;
    }
    if (mounted) setState(() => _usbDevicesLoading = true);
    try {
      final devices = await _rtkService.usbTransport.listDevices();
      if (mounted) {
        setState(() {
          _usbDevices = devices;
          _usbDevicesLoading = false;
        });
      }
    } catch (e, stackTrace) {
      logger.severe('[USB] Failed to list USB devices', e, stackTrace);
      if (mounted) {
        setState(() => _usbDevicesLoading = false);
      }
    }
  }

  Future<void> _connectToUsbDevice(UsbDeviceInfo info) async {
    if (!RtkDeviceService.isUsbSupported) return;
    final wasNtripConnected = _rtkService.ntripClient?.connectionState ==
        NTRIPConnectionState.connected;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)?.usbConnectingTo(info.displayName) ?? 'Connecting to ${info.displayName}...'),
          duration: const Duration(milliseconds: 1000),
        ),
      );
    }

    await _rtkService.connectViaUsb(info);

    if (!mounted) return;
    if (!_rtkService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)?.usbConnectionFailed ?? 'USB connection failed'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 3000),
        ),
      );
      return;
    }

    setState(() => _connectedViaUsb = true);
    _setupNtripSubscriptions();

    if (wasNtripConnected) {
      await _reconnectNtripAfterSwitch();
    }
  }

  Future<void> _disconnectUsbDevice() async {
    await _rtkService.disconnect();
    if (mounted) {
      setState(() => _connectedViaUsb = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)?.usbDeviceDisconnected ?? 'USB device disconnected.'),
          duration: Duration(milliseconds: 1000),
        ),
      );
    }
  }

  /// Reconnects NTRIP on the currently active transport using current form params.
  /// Used after switching BLE↔USB so NTRIP stays active.
  Future<void> _reconnectNtripAfterSwitch() async {
    final host = _ntripHostController.text.trim();
    final portStr = _ntripPortController.text.trim();
    final mountPoint = _ntripMountPointController.text.trim();
    final username = _ntripUsernameController.text.trim();
    final password = _ntripPasswordController.text.trim();
    if (host.isEmpty || mountPoint.isEmpty || username.isEmpty) return;
    final port = int.tryParse(portStr) ?? (_ntripUseSsl ? 2102 : 2101);
    if (port < 1 || port > 65535) return;

    if (mounted) {
      setState(() => _ntripConnectionState = NTRIPConnectionState.connecting);
    }

    final success = await _rtkService.connectToNtrip(
      host: host,
      port: port,
      mountPoint: mountPoint,
      username: username,
      password: password.isEmpty ? 'none' : password,
      useSsl: _ntripUseSsl,
    );

    if (mounted) {
      _setupNtripSubscriptions();
      setState(() {
        _ntripConnectionState = _rtkService.ntripClient?.connectionState ??
            NTRIPConnectionState.disconnected;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)?.ntripReconnectedOnNewDevice ?? 'NTRIP reconnected on new device'),
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    }
  }

  Future<void> _requestMtu(BluetoothDevice device) async {
    try {
      await BLEService.instance.requestMtu(device);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)?.bleMtuRequested ?? 'MTU requested.'),
            duration: const Duration(milliseconds: 1000),
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
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.satellite),
            const SizedBox(width: 8),
            Text(s?.bleScreenTitle ?? 'RTK Devices'),
          ],
        ),
      ),
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
            if (_isDeviceConnected && !_hasReceivedFirstPosition)
              _buildDataReceivingIndicator(s),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(S? s) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                // Connection Status Card
                _buildConnectionStatusCard(s),

                // GPS Data Card (shown when connected and receiving data)
                if (_isDeviceConnected &&
                    (_currentPosition != null || _currentNmeaData != null))
                  _buildGpsDataCard(s),

                // NTRIP Configuration Card (shown when device is connected)
                if (_isDeviceConnected)
                  _buildNtripCard(s),

                // Connection mode: Bluetooth | USB (Android only)
                if (Platform.isAndroid && RtkDeviceService.isUsbSupported)
                  _buildConnectionModeSelector(s),

                // Scan Controls (Bluetooth) or USB device list
                if (!Platform.isAndroid || !RtkDeviceService.isUsbSupported || _connectionModeIndex == 0) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isScanning ? null : _startScan,
                            icon: const Icon(Icons.search),
                            label: Text(s?.bleButtonStartScan ?? 'Start Scan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isScanning ? _stopScan : null,
                            icon: const Icon(Icons.stop),
                            label: Text(s?.bleButtonStopScan ?? 'Stop Scan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight > 0
                          ? (constraints.maxHeight * 0.5).clamp(200.0, 400.0)
                          : 300,
                    ),
                    child: _buildScanResultsList(s),
                  ),
                ] else
                  _buildUsbDeviceList(s, constraints),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionStatusCard(S? s) {
    final state = _effectiveConnectionState;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (state) {
      case BLEConnectionState.connected:
        statusColor = Colors.green;
        statusIcon = _connectedViaUsb ? Icons.usb : Icons.bluetooth_connected;
        statusText = s?.bleStatusConnected ?? 'Connected';
        break;
      case BLEConnectionState.connecting:
        statusColor = Colors.orange;
        statusIcon = _connectedViaUsb ? Icons.usb : Icons.bluetooth_searching;
        statusText = s?.bleStatusConnecting ?? 'Connecting...';
        break;
      case BLEConnectionState.error:
        statusColor = Colors.red;
        statusIcon = _connectedViaUsb ? Icons.usb_off : Icons.bluetooth_disabled;
        statusText = s?.bleStatusError ?? 'Connection Error';
        break;
      case BLEConnectionState.waiting:
        statusColor = Colors.blue;
        statusIcon = _connectedViaUsb ? Icons.usb : Icons.bluetooth_searching;
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
                  if (_effectiveDeviceName != null && _effectiveDeviceName!.isNotEmpty)
                    Text(
                      s?.bleConnectedDevice(_effectiveDeviceName!) ??
                          'Device: $_effectiveDeviceName',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (state == BLEConnectionState.connected)
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

  Widget _buildConnectionModeSelector(S? s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bluetooth, size: 20),
                  const SizedBox(width: 8),
                  Text(s?.bleConnectionModeBluetooth ?? 'Bluetooth'),
                ],
              ),
              selected: _connectionModeIndex == 0,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _connectionModeIndex = 0);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.usb, size: 20),
                  const SizedBox(width: 8),
                  Text(s?.bleConnectionModeUsb ?? 'USB'),
                ],
              ),
              selected: _connectionModeIndex == 1,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _connectionModeIndex = 1;
                    if (_usbDevices.isEmpty && !_usbDevicesLoading) {
                      _refreshUsbDevices();
                    }
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsbDeviceList(S? s, BoxConstraints constraints) {
    final isConnectedViaUsb = _connectedViaUsb &&
        _connectionState == BLEConnectionState.connected;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isConnectedViaUsb)
            ElevatedButton.icon(
              onPressed: _disconnectUsbDevice,
              icon: const Icon(Icons.usb_off),
              label: Text(s?.usbDisconnectFromDevice ?? 'Disconnect from USB device'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _usbDevicesLoading
                  ? null
                  : () {
                      _refreshUsbDevices();
                    },
              icon: _usbDevicesLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_usbDevicesLoading ? (s?.usbLoading ?? 'Loading...') : (s?.usbRefreshDevices ?? 'Refresh USB devices')),
            ),
          const SizedBox(height: 12),
          if (!isConnectedViaUsb)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight > 0
                    ? (constraints.maxHeight * 0.5).clamp(200.0, 400.0)
                    : 300,
              ),
              child: _usbDevices.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.usb_off,
                              size: 48,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              s?.usbNoDevicesFound ?? 'No USB devices found',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.grey.shade700,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s?.usbNoDevicesHint ?? 'Connect your RTK receiver with a USB cable (USB OTG). The phone must support USB host (OTG). Then tap Refresh.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _usbDevices.length,
                      itemBuilder: (context, index) {
                        final info = _usbDevices[index];
                        return ListTile(
                          leading: const Icon(Icons.usb),
                          title: Text(
                            info.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _connectToUsbDevice(info),
                            child: Text(s?.usbConnectButton ?? 'Connect'),
                          ),
                        );
                      },
                    ),
            ),
        ],
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
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        final result = _scanResults[index];
        final device = result.device;
        final isConnected =
            _rtkService.connectedBleDevice?.remoteId == device.remoteId;

        final wasPreviouslyConnected = _lastConnectedDeviceId == device.remoteId.toString();

        return BleScanResultTile(
          result: result,
          isConnected: isConnected,
          wasPreviouslyConnected: wasPreviouslyConnected,
          onConnect: () => _connectToDevice(device),
          onDisconnect: _disconnectDevice,
          onTap: isConnected ? null : () => _showDeviceDetails(result, s),
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
                      _rtkService.connectedBleDevice?.remoteId == device.remoteId)
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
        ? Colors.green.shade900.withValues(alpha: 0.3)
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
                                color: FixQualityColors.getColor(
                                  _currentNmeaData!.fixQuality,
                                  isDarkMode: isDarkMode,
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

    // Active bars use centralized color utility
    return FixQualityColors.getBarColor(index, isDarkMode: isDarkMode);
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
                        color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: 0.4 * _pulseAnimation.value,
                        ),
                        blurRadius: 12 * _pulseAnimation.value,
                        spreadRadius: 3 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s?.bleReceivingData ?? 'Receiving data...',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                softWrap: true,
                              ),
                              if (s != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  s.bleReceivingDataHint,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  softWrap: true,
                                ),
                              ],
                            ],
                          ),
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

  Widget _buildNtripCard(S? s) {
    return NtripConfigurationWidget(
      connectionState: _ntripConnectionState,
      hostController: _ntripHostController,
      portController: _ntripPortController,
      mountPointController: _ntripMountPointController,
      usernameController: _ntripUsernameController,
      passwordController: _ntripPasswordController,
      useSsl: _ntripUseSsl,
      isForwardingRtcm: _rtkService.isForwardingRtcm,
      canConnectNtrip: _hasReceivedFirstPosition,
      hostStatusRefreshTrigger: _hostStatusRefreshTrigger,
      onConnect: _connectToNtrip,
      onDisconnect: _disconnectFromNtrip,
      onSslChanged: (value) {
        setState(() {
          _ntripUseSsl = value;
          // Auto-update port if SSL is toggled
          if (_ntripUseSsl && _ntripPortController.text == '2101') {
            _ntripPortController.text = '2102';
          } else if (!_ntripUseSsl && _ntripPortController.text == '2102') {
            _ntripPortController.text = '2101';
          }
        });
      },
    );
  }

  Future<void> _connectToNtrip(int? hostId) async {
    final s = S.of(context);
    if (!_hasReceivedFirstPosition) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s?.bleNtripWaitForPosition ??
                'Wait for GPS position from device before connecting to NTRIP.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(milliseconds: 3000),
        ),
      );
      return;
    }
    final host = _ntripHostController.text.trim();
    final portStr = _ntripPortController.text.trim();
    final mountPoint = _ntripMountPointController.text.trim();
    final username = _ntripUsernameController.text.trim();
    final password = _ntripPasswordController.text.trim();

    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s?.bleNtripErrorHostRequired ?? 'NTRIP host is required',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 1000),
        ),
      );
      return;
    }

    if (portStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s?.bleNtripErrorPortRequired ?? 'Port is required'),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 1000),
        ),
      );
      return;
    }

    final port = int.tryParse(portStr);
    if (port == null || port < 1 || port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s?.bleNtripErrorInvalidPort ?? 'Invalid port number'),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 1000),
        ),
      );
      return;
    }

    if (mountPoint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s?.bleNtripErrorMountPointRequired ?? 'Mount point is required',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 1000),
        ),
      );
      return;
    }

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s?.bleNtripErrorUsernameRequired ?? 'Username (email) is required',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 3000),
        ),
      );
      return;
    }

    try {
      setState(() {
        _ntripConnectionState = NTRIPConnectionState.connecting;
        _connectingHostId = hostId; // Track which host we're connecting to
      });

      // Clear the status immediately when connecting starts (remove checkmark/X)
      await _saveNtripSettings(
        hostId: hostId,
        lastConnectionSuccessful: null, // Clear status while connecting
      );

      // Save last used host ID
      if (hostId != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('lastUsedNtripHostId', hostId);
        } catch (e) {
          // Silently fail - not critical
        }
      }

      // Trigger UI refresh to remove the icon immediately
      if (mounted) {
        setState(() {
          _hostStatusRefreshTrigger++;
        });
      }

      final success = await _rtkService.connectToNtrip(
        host: host,
        port: port,
        mountPoint: mountPoint,
        username: username,
        password: password.isEmpty ? 'none' : password,
        useSsl: _ntripUseSsl,
      );

      if (mounted) {
        if (success) {
          // Reset RTCM validation flag
          _hasReceivedValidRtcm = false;

          // Update subscription to new client (from active service)
          final ntripClient = _rtkService.ntripClient;
          if (ntripClient != null) {
            _ntripConnectionStateSubscription?.cancel();
            _ntripErrorSubscription?.cancel();
            _rtcmDataSubscription?.cancel();

            // Explicitly set state to connected immediately
            setState(() {
              _ntripConnectionState = ntripClient.connectionState;
            });

            // Listen to RTCM data stream to detect successful packet processing
            _rtcmDataSubscription = ntripClient.rtcmData.listen((data) {
              if (mounted &&
                  !_hasReceivedValidRtcm &&
                  _connectingHostId != null) {
                // We've received valid RTCM data - mark connection as successful
                _hasReceivedValidRtcm = true;
                _saveNtripSettings(
                  hostId: _connectingHostId,
                  lastConnectionSuccessful: true,
                ).then((_) {
                  // Trigger a rebuild to refresh the widget UI
                  if (mounted) {
                    setState(() {
                      _hostStatusRefreshTrigger++; // Increment to trigger widget refresh
                    });
                  }
                });
              }
            });

            _ntripConnectionStateSubscription = ntripClient.connectionStateStream.listen((
              state,
            ) {
              if (mounted) {
                final previousState = _ntripConnectionState;
                setState(() {
                  _ntripConnectionState = state;
                });

                // If connection transitions from connecting or connected to error/disconnected, update status
                if ((previousState == NTRIPConnectionState.connecting ||
                        previousState == NTRIPConnectionState.connected) &&
                    (state == NTRIPConnectionState.error ||
                        state == NTRIPConnectionState.disconnected) &&
                    _connectingHostId != null) {
                  // Connection failed - update the host status
                  _saveNtripSettings(
                    hostId: _connectingHostId,
                    lastConnectionSuccessful: false,
                  ).then((_) {
                    // Trigger a rebuild to refresh the widget UI immediately
                    if (mounted) {
                      setState(() {
                        _hostStatusRefreshTrigger++; // Increment to trigger widget refresh
                      });
                    }
                  });
                  _connectingHostId = null; // Clear after updating
                  _hasReceivedValidRtcm = false; // Reset RTCM validation flag
                } else if (state == NTRIPConnectionState.connected) {
                  // Connection succeeded - keep tracking the host ID in case it fails later
                  // Don't clear _connectingHostId here, only clear it when disconnected/error
                }
              }
            });

            _ntripErrorSubscription = ntripClient.errors.listen((error) {
              if (mounted) {
                // If we get an error and haven't validated RTCM yet, mark as failed
                if (!_hasReceivedValidRtcm && _connectingHostId != null) {
                  _saveNtripSettings(
                    hostId: _connectingHostId,
                    lastConnectionSuccessful: false,
                  ).then((_) {
                    // Trigger a rebuild to refresh the widget UI immediately
                    if (mounted) {
                      setState(() {
                        _hostStatusRefreshTrigger++; // Increment to trigger widget refresh
                      });
                    }
                  });
                  _hasReceivedValidRtcm = false;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('NTRIP Error: $error'),
                    backgroundColor: Colors.red,
                    duration: const Duration(milliseconds: 1000),
                  ),
                );
              }
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s?.bleNtripConnectedSuccess ?? 'Connected to NTRIP caster',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(milliseconds: 1000),
            ),
          );
        } else {
          setState(() {
            _ntripConnectionState = NTRIPConnectionState.error;
          });
          // Connection failed immediately - mark as unsuccessful
          if (_connectingHostId != null) {
            await _saveNtripSettings(
              hostId: _connectingHostId,
              lastConnectionSuccessful: false,
            );
            if (mounted) {
              setState(() {
                _hostStatusRefreshTrigger++;
              });
            }
          }
          _connectingHostId = null; // Clear tracking
          final activeNtrip = _rtkService.ntripClient;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                activeNtrip?.errorMessage ??
                    (s?.bleNtripConnectionFailed ??
                        'Failed to connect to NTRIP caster'),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(milliseconds: 1000),
            ),
          );
        }
      }
    } catch (e) {
      logger.severe('Error connecting to NTRIP: $e');
      if (mounted) {
        setState(() {
          _ntripConnectionState = NTRIPConnectionState.error;
        });
        // Mark as unsuccessful if we were trying to connect
        if (_connectingHostId != null) {
          await _saveNtripSettings(
            hostId: _connectingHostId,
            lastConnectionSuccessful: false,
          );
          if (mounted) {
            setState(() {
              _hostStatusRefreshTrigger++;
            });
          }
          _connectingHostId = null;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)?.errorWithMessage(e.toString()) ?? 'Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 3000),
          ),
        );
      }
    }
  }

  Future<void> _disconnectFromNtrip() async {
    final s = S.of(context);
    try {
      setState(() {
        _ntripConnectionState = NTRIPConnectionState.disconnected;
      });

      await _rtkService.disconnectFromNtrip();

      if (mounted) {
        final ntripClient = _rtkService.ntripClient;
        if (ntripClient != null) {
          setState(() {
            _ntripConnectionState = ntripClient.connectionState;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s?.bleNtripDisconnectedSuccess ??
                  'Disconnected from NTRIP caster',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(milliseconds: 1000),
          ),
        );
      }
    } catch (e) {
      logger.severe('Error disconnecting from NTRIP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)?.errorDisconnecting(e.toString()) ?? 'Error disconnecting: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 3000),
          ),
        );
      }
    }
  }

  Future<void> _loadNtripSettings() async {
    try {
      final settings = await DriftDatabaseHelper.instance.getNtripSettings();
      // Only load settings if there's a saved host (non-empty)
      // Otherwise, keep the default values
      if (settings != null && settings.host.isNotEmpty && mounted) {
        setState(() {
          _ntripHostController.text = settings.host;
          _ntripPortController.text = settings.port.toString();
          _ntripMountPointController.text = settings.mountPoint;
          _ntripUsernameController.text = settings.username;
          _ntripPasswordController.text = settings.password;
          _ntripUseSsl = settings.useSsl;
        });
      }
    } catch (e) {
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        logger.warning('Error loading NTRIP settings: $e');
      }
    }
  }

  Future<void> _saveNtripSettings({
    int? hostId,
    bool? lastConnectionSuccessful,
  }) async {
    try {
      final host = _ntripHostController.text.trim();
      if (host.isEmpty) {
        return; // Don't save if host is empty
      }

      // If we have a host ID, update that specific host directly
      if (hostId != null) {
        final port =
            int.tryParse(_ntripPortController.text.trim()) ??
            (_ntripUseSsl ? 2102 : 2101);

        final settings = NtripSettingCompanion(
          id: drift.Value(hostId),
          host: drift.Value(host),
          port: drift.Value(port),
          mountPoint: drift.Value(_ntripMountPointController.text.trim()),
          username: drift.Value(_ntripUsernameController.text.trim()),
          password: drift.Value(_ntripPasswordController.text.trim()),
          useSsl: drift.Value(_ntripUseSsl),
          lastConnectionSuccessful: drift.Value(lastConnectionSuccessful),
        );

        await DriftDatabaseHelper.instance.updateNtripSetting(settings);
        return;
      }

      // Fallback: try to find existing host by connection parameters
      // This handles the case where hostId is not provided (legacy behavior)
      final fallbackPort =
          int.tryParse(_ntripPortController.text.trim()) ??
          (_ntripUseSsl ? 2102 : 2101);

      final allSettings = await DriftDatabaseHelper.instance
          .getAllNtripSettings();
      final mountPoint = _ntripMountPointController.text.trim();
      final username = _ntripUsernameController.text.trim();
      final password = _ntripPasswordController.text.trim();

      NtripSetting? existingHost;
      for (final setting in allSettings) {
        if (setting.host == host &&
            setting.port == fallbackPort &&
            setting.mountPoint == mountPoint &&
            setting.username == username &&
            setting.password == password) {
          existingHost = setting;
          break;
        }
      }

      final settings = NtripSettingCompanion(
        name: drift.Value(
          existingHost?.name ?? host,
        ), // Use existing name or host as name
        country: drift.Value(
          existingHost?.country ?? 'Italy',
        ), // Default to Italy
        state: drift.Value(
          existingHost?.state ?? 'Trentino',
        ), // Default to Trentino
        host: drift.Value(host),
        port: drift.Value(fallbackPort),
        mountPoint: drift.Value(_ntripMountPointController.text.trim()),
        username: drift.Value(_ntripUsernameController.text.trim()),
        password: drift.Value(_ntripPasswordController.text.trim()),
        useSsl: drift.Value(_ntripUseSsl),
        lastConnectionSuccessful: drift.Value(lastConnectionSuccessful),
      );

      // If we found an existing host, update it; otherwise insert new
      if (existingHost != null) {
        final updateSettings = settings.copyWith(
          id: drift.Value(existingHost.id),
        );
        await DriftDatabaseHelper.instance.updateNtripSetting(updateSettings);
      } else {
        await DriftDatabaseHelper.instance.insertNtripSetting(settings);
      }
    } catch (e) {
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        logger.warning('Error saving NTRIP settings: $e');
      }
    }
  }

  /// Saves the last connected device ID to SharedPreferences
  Future<void> _saveLastConnectedDeviceId(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastConnectedBleDeviceId', deviceId);
      if (mounted) {
        setState(() {
          _lastConnectedDeviceId = deviceId;
        });
      }
    } catch (e) {
      logger.warning('Error saving last connected device ID: $e');
    }
  }

  /// Loads the last connected device ID from SharedPreferences
  Future<void> _loadLastConnectedDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('lastConnectedBleDeviceId');
      if (mounted) {
        setState(() {
          _lastConnectedDeviceId = deviceId;
        });
      }
    } catch (e) {
      logger.warning('Error loading last connected device ID: $e');
    }
  }

  /// Sorts scan results to put previously connected devices first
  List<ScanResult> _sortScanResults(List<ScanResult> results) {
    if (_lastConnectedDeviceId == null) return results;
    
    final sorted = List<ScanResult>.from(results);
    sorted.sort((a, b) {
      final aWasConnected = a.device.remoteId.toString() == _lastConnectedDeviceId;
      final bWasConnected = b.device.remoteId.toString() == _lastConnectedDeviceId;
      
      if (aWasConnected && !bWasConnected) return -1;
      if (!aWasConnected && bWasConnected) return 1;
      return 0; // Keep original order for devices with same status
    });
    
    return sorted;
  }
}
