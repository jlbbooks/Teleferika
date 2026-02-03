import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'nmea_parser.dart';
import 'ntrip_client.dart';

enum BLEConnectionState { disconnected, connecting, connected, error, waiting }

/// BLE service for scanning, connecting and disconnecting from Bluetooth Low Energy devices.
/// Ported from AcuME app.
///
/// Supports reading GPS data from RTK receivers via Nordic UART Service (NUS).
/// 
/// This is a singleton service that persists across screens to maintain BLE connections
/// and continue receiving GPS data in the background.
class BLEService {
  // Singleton pattern
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  /// Get the singleton instance
  static BLEService get instance => _instance;

  BluetoothDevice? connectedDevice;
  bool isScanning = false;
  final Duration scanTimeout = const Duration(seconds: 20);

  // Nordic UART Service UUIDs (commonly used by RTK receivers)
  // Two variants: short UUID format and full UUID format
  static const String nordicUartServiceUuidShort =
      '0000ffe0-0000-1000-8000-00805f9b34fb';
  static const String nordicUartServiceUuidFull =
      '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

  // TX Characteristic (for reading data) - supports notify
  static const String nordicUartTxCharacteristicUuidShort =
      '0000ffe1-0000-1000-8000-00805f9b34fb';
  static const String nordicUartTxCharacteristicUuidFull =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  // RX Characteristic (for writing commands) - supports write
  static const String nordicUartRxCharacteristicUuidShort =
      '0000ffe1-0000-1000-8000-00805f9b34fb';
  static const String nordicUartRxCharacteristicUuidFull =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  BluetoothService? _uartService;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  StreamSubscription<List<int>>? _dataSubscription;

  // Buffer for incomplete NMEA sentences
  String _nmeaBuffer = '';

  final StreamController<List<ScanResult>> _scanResultsController =
      StreamController<List<ScanResult>>.broadcast();
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;

  final StreamController<BLEConnectionState> _connectionStateController =
      StreamController<BLEConnectionState>.broadcast();
  Stream<BLEConnectionState> get connectionState =>
      _connectionStateController.stream;

  // Stream for GPS position data from NMEA sentences
  final StreamController<Position> _gpsDataController =
      StreamController<Position>.broadcast();
  Stream<Position> get gpsData => _gpsDataController.stream;

  // Stream for raw NMEA data
  final StreamController<NMEAData> _nmeaDataController =
      StreamController<NMEAData>.broadcast();
  Stream<NMEAData> get nmeaData => _nmeaDataController.stream;

  // NTRIP client for RTCM corrections
  NTRIPClient? _ntripClient;
  StreamSubscription<List<int>>? _rtcmSubscription;
  bool _isForwardingRtcm = false;

  /// Gets the NTRIP client instance (creates if needed).
  NTRIPClient? get ntripClient => _ntripClient;

  /// Gets whether RTCM corrections are being forwarded.
  bool get isForwardingRtcm => _isForwardingRtcm;

  Future<void> startScan() async {
    if (isScanning) return;
    isScanning = true;
    _scanResultsController.add([]);

    try {
      await FlutterBluePlus.startScan(timeout: scanTimeout);

      await for (final results in FlutterBluePlus.scanResults) {
        _scanResultsController.add(results);
        // Only log scan results in debug mode
        if (const bool.fromEnvironment('dart.vm.product') == false) {
          results.forEach(_printScanResult);
        }
      }
    } catch (e) {
      debugPrint("BLE: Scan error: $e");
      _connectionStateController.add(BLEConnectionState.error);
    } finally {
      isScanning = false;
      stopScan();
    }
  }

  Future<void> stopScan() async {
    if (!isScanning) return;
    await FlutterBluePlus.stopScan();
    isScanning = false;
  }

  /// Connects to the given BLE device and discovers services.
  /// [context] is optional; pass it if you need it for UI (e.g. dialogs) in future extensions.
  Future<void> connectToDevice(
    BluetoothDevice device, [
    BuildContext? context,
  ]) async {
    _connectionStateController.add(BLEConnectionState.connecting);

    try {
      if (connectedDevice != null) {
        await disconnectDevice();
      }

      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      connectedDevice = device;

      // Discover services after connection
      await _discoverServices(device);

      _connectionStateController.add(BLEConnectionState.connected);
    } catch (e) {
      debugPrint("BLE: Connection error: $e");
      _connectionStateController.add(BLEConnectionState.error);
    }
  }

  /// Discovers BLE services and sets up data reading.
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      // Wait for services to be discovered
      final services = await device.discoverServices();

      // Only log service details in debug mode
      final isDebug = const bool.fromEnvironment('dart.vm.product') == false;
      if (isDebug) {
        debugPrint("BLE: Found ${services.length} services");
        for (final service in services) {
          debugPrint("BLE: Service UUID: ${service.uuid}");
          for (final characteristic in service.characteristics) {
            final uuid = characteristic.uuid.toString().toLowerCase();
            debugPrint("BLE:   Characteristic UUID: $uuid");
          }
        }
      }

      // Find Nordic UART Service (check both UUID formats)
      for (final service in services) {
        final serviceUuid = service.uuid.toString().toLowerCase();
        final isNordicUartShort =
            serviceUuid == nordicUartServiceUuidShort.toLowerCase();
        final isNordicUartFull =
            serviceUuid == nordicUartServiceUuidFull.toLowerCase();

        // Check if this is the Nordic UART Service (either format)
        if (isNordicUartShort || isNordicUartFull) {
          _uartService = service;

          // Find TX and RX characteristics
          for (final characteristic in service.characteristics) {
            final uuid = characteristic.uuid.toString().toLowerCase();

            // Check for TX characteristic (supports notify/indicate for reading)
            final isTxShort =
                uuid == nordicUartTxCharacteristicUuidShort.toLowerCase();
            final isTxFull =
                uuid == nordicUartTxCharacteristicUuidFull.toLowerCase();

            if (isTxShort || isTxFull) {
              _txCharacteristic = characteristic;
              // Subscribe to notifications for reading data
              await _subscribeToData(characteristic);
            }

            // Check for RX characteristic (supports write for sending commands)
            final isRxShort =
                uuid == nordicUartRxCharacteristicUuidShort.toLowerCase();
            final isRxFull =
                uuid == nordicUartRxCharacteristicUuidFull.toLowerCase();

            if (isRxShort || isRxFull) {
              _rxCharacteristic = characteristic;
            }
          }

          break;
        }
      }

      if (_uartService == null) {
        debugPrint(
          "BLE: Warning - Nordic UART Service not found. "
          "Device may use different service UUIDs.",
        );
        // Try to find any service with characteristics that support notifications
        await _tryFindGenericUartService(services);
      }

      // Request larger MTU for better data throughput
      await requestMtu(device, size: 256);

      // Some RTK devices need a command to start sending NMEA data
      // Try sending a query command to request NMEA output
      if (_rxCharacteristic != null) {
        // Send a command to request NMEA sentences (common for u-blox devices)
        // This is a query command that requests current position
        try {
          await _tryEnableNmeaOutput();
        } catch (e) {
          debugPrint("BLE: Could not send NMEA enable command: $e");
        }
      }
    } catch (e) {
      debugPrint("BLE: Service discovery error: $e");
    }
  }

  /// Attempts to enable NMEA output on the RTK device.
  /// Some devices need a command to start sending data.
  Future<void> _tryEnableNmeaOutput() async {
    if (_rxCharacteristic == null) {
      return;
    }

    try {
      // Common u-blox command to query position (triggers NMEA output)
      // $PUBX,00*33 - Query position
      final queryCommand = '\$PUBX,00*33\r\n';
      await sendCommand(queryCommand);

      // Also try enabling NMEA output on all ports (if device supports it)
      // This is a common configuration for u-blox ZED-F9P
      await Future.delayed(const Duration(milliseconds: 500));

      // Some devices might need a different command format
      // Try a simple newline to wake up the device
      await sendCommand('\r\n');
    } catch (e) {
      debugPrint("BLE: Error enabling NMEA output: $e");
    }
  }

  /// Attempts to find a generic UART service by looking for characteristics
  /// that support notifications.
  /// Prefers notify over indicate, and skips standard BLE characteristics.
  Future<void> _tryFindGenericUartService(
    List<BluetoothService> services,
  ) async {
    // Standard BLE service UUIDs to skip (not data services)
    final standardServices = [
      '1800', // Generic Access
      '1801', // Generic Attribute (Service Changed)
      '180a', // Device Information
      '180f', // Battery Service
    ];

    BluetoothCharacteristic? notifyCharacteristic;
    BluetoothCharacteristic? indicateCharacteristic;
    BluetoothService? notifyService;
    BluetoothService? indicateService;

    for (final service in services) {
      final serviceUuid = service.uuid.toString().toLowerCase();

      // Skip standard BLE services
      bool isStandardService = false;
      for (final stdUuid in standardServices) {
        if (serviceUuid.contains(stdUuid.toLowerCase())) {
          isStandardService = true;
          break;
        }
      }
      if (isStandardService) {
        continue;
      }

      for (final characteristic in service.characteristics) {
        final hasNotify = characteristic.properties.notify;
        final hasIndicate = characteristic.properties.indicate;

        // Also check for RX characteristic (write capability)
        if (characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse) {
          _rxCharacteristic ??= characteristic;
        }

        // Prefer notify over indicate
        if (hasNotify && notifyCharacteristic == null) {
          notifyCharacteristic = characteristic;
          notifyService = service;
        } else if (hasIndicate &&
            indicateCharacteristic == null &&
            notifyCharacteristic == null) {
          indicateCharacteristic = characteristic;
          indicateService = service;
        }
      }
    }

    // Use notify if available, otherwise use indicate
    if (notifyCharacteristic != null && notifyService != null) {
      _txCharacteristic = notifyCharacteristic;
      _uartService = notifyService;
      await _subscribeToData(notifyCharacteristic);
    } else if (indicateCharacteristic != null && indicateService != null) {
      _txCharacteristic = indicateCharacteristic;
      _uartService = indicateService;
      await _subscribeToData(indicateCharacteristic);
    }
  }

  /// Subscribes to characteristic notifications to receive data.
  Future<void> _subscribeToData(BluetoothCharacteristic characteristic) async {
    try {
      await characteristic.setNotifyValue(true);

      // Listen to value updates
      _dataSubscription = characteristic.onValueReceived.listen(
        (value) {
          _handleReceivedData(value);
        },
        onError: (error) {
          debugPrint("BLE: Data subscription error: $error");
        },
        cancelOnError: false,
      );

      // Also try reading the current value (some devices send data on read)
      try {
        final currentValue = await characteristic.read();
        if (currentValue.isNotEmpty) {
          _handleReceivedData(currentValue);
        }
      } catch (e) {
        // Characteristic may not support read - this is fine
      }
    } catch (e) {
      debugPrint("BLE: Error subscribing to data: $e");
      rethrow;
    }
  }

  /// Handles received data bytes and parses NMEA sentences.
  void _handleReceivedData(List<int> data) {
    try {
      // Log raw data reception (only in debug mode, but more verbose)
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        debugPrint("BLE: Received ${data.length} bytes of raw data");
      }
      
      // Convert bytes to string (assuming UTF-8 encoding)
      final text = utf8.decode(data);

      // Add to buffer
      _nmeaBuffer += text;

      // Process complete NMEA sentences (they end with \r\n)
      final lines = _nmeaBuffer.split('\n');

      // Keep the last incomplete line in buffer
      if (lines.length > 1) {
        _nmeaBuffer = lines.last;

        // Process complete sentences
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isNotEmpty && line.startsWith('\$')) {
            _processNMEASentence(line);
          }
        }
      }
    } catch (e) {
      debugPrint("BLE: Error handling received data: $e");
    }
  }

  /// Processes a complete NMEA sentence and emits GPS data.
  void _processNMEASentence(String sentence) {
    try {
      final nmeaData = NMEAParser.parseSentence(sentence);

      if (nmeaData != null && nmeaData.isValid) {
        // Log processed NMEA data (only in debug mode)
        if (const bool.fromEnvironment('dart.vm.product') == false) {
          debugPrint(
            "BLE: Processed NMEA -> Lat: ${nmeaData.latitude}, "
            "Lon: ${nmeaData.longitude}, Accuracy: ${nmeaData.accuracy}m, "
            "Fix: ${nmeaData.fixQuality}",
          );
        }
        
        // Emit NMEA data
        _nmeaDataController.add(nmeaData);

        // Convert to Position object and emit
        final position = Position(
          latitude: nmeaData.latitude,
          longitude: nmeaData.longitude,
          timestamp: nmeaData.time ?? DateTime.now(),
          accuracy: nmeaData.accuracy ?? 0.0,
          altitude: nmeaData.altitude ?? 0.0,
          heading: nmeaData.course ?? 0.0,
          speed: (nmeaData.speed ?? 0.0) / 3.6, // Convert km/h to m/s
          speedAccuracy: 0.0,
          headingAccuracy: 0.0,
          altitudeAccuracy: 0.0,
        );

        // Log GPS position emission (only in debug mode)
        if (const bool.fromEnvironment('dart.vm.product') == false) {
          debugPrint(
            "BLE: Emitting GPS position -> Lat: ${position.latitude}, "
            "Lon: ${position.longitude}, Accuracy: ${position.accuracy}m",
          );
        }
        
        _gpsDataController.add(position);
      }
      // Note: We don't log "invalid" for non-position sentences (GSV, GSA, etc.)
      // as they are valid NMEA but don't contain position data
    } catch (e) {
      debugPrint("BLE: Error processing NMEA sentence: $e");
    }
  }

  /// Sends data to the device (for configuration commands).
  Future<void> sendData(List<int> data) async {
    if (_rxCharacteristic == null) {
      return;
    }

    try {
      await _rxCharacteristic!.write(data, withoutResponse: false);
    } catch (e) {
      debugPrint("BLE: Error sending data: $e");
    }
  }

  /// Sends a string command to the device.
  Future<void> sendCommand(String command) async {
    final data = utf8.encode(command);
    await sendData(data);
  }

  /// Forwards RTCM correction data to the RTK device via BLE.
  /// This method handles splitting large RTCM messages to fit BLE MTU limits.
  Future<void> forwardRtcmData(List<int> rtcmData) async {
    if (_rxCharacteristic == null || rtcmData.isEmpty) {
      return;
    }

    try {
      // BLE typically has MTU limits (20-517 bytes depending on device)
      // Split large RTCM messages into chunks
      const maxChunkSize = 200; // Conservative chunk size for BLE

      if (rtcmData.length <= maxChunkSize) {
        // Small enough to send in one chunk
        await _rxCharacteristic!.write(rtcmData, withoutResponse: true);
      } else {
        // Split into chunks
        for (int i = 0; i < rtcmData.length; i += maxChunkSize) {
          final end = (i + maxChunkSize < rtcmData.length)
              ? i + maxChunkSize
              : rtcmData.length;
          final chunk = rtcmData.sublist(i, end);
          await _rxCharacteristic!.write(chunk, withoutResponse: true);

          // Small delay between chunks to avoid overwhelming the device
          if (end < rtcmData.length) {
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }
      }

      if (const bool.fromEnvironment('dart.vm.product') == false) {
        debugPrint('BLE: Forwarded ${rtcmData.length} bytes of RTCM data');
      }
    } catch (e) {
      debugPrint("BLE: Error forwarding RTCM data: $e");
    }
  }

  /// Connects to an NTRIP caster and starts forwarding RTCM corrections to the RTK device.
  ///
  /// Returns true if connection was successful, false otherwise.
  Future<bool> connectToNtrip({
    required String host,
    required int port,
    required String mountPoint,
    required String username,
    required String password,
    bool useSsl = false,
  }) async {
    // Ensure BLE device is connected
    if (connectedDevice == null || _rxCharacteristic == null) {
      debugPrint('BLE: Cannot connect to NTRIP - BLE device not connected');
      return false;
    }

    try {
      // Create or reuse NTRIP client
      _ntripClient ??= NTRIPClient();

      // Connect to NTRIP caster
      await _ntripClient!.connect(
        host: host,
        port: port,
        mountPoint: mountPoint,
        username: username,
        password: password,
        useSsl: useSsl,
      );

      // Wait a moment for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if connection was successful
      if (_ntripClient!.connectionState == NTRIPConnectionState.connected) {
        // Subscribe to RTCM data stream
        _rtcmSubscription?.cancel();
        _rtcmSubscription = _ntripClient!.rtcmData.listen(
          (rtcmData) {
            _isForwardingRtcm = true;
            forwardRtcmData(rtcmData);
          },
          onError: (error) {
            debugPrint('BLE: NTRIP RTCM stream error: $error');
            _isForwardingRtcm = false;
          },
        );

        debugPrint('BLE: NTRIP connected and forwarding RTCM corrections');
        return true;
      } else {
        debugPrint(
          'BLE: NTRIP connection failed: ${_ntripClient!.errorMessage}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('BLE: Error connecting to NTRIP: $e');
      return false;
    }
  }

  /// Disconnects from NTRIP caster and stops forwarding RTCM corrections.
  Future<void> disconnectFromNtrip() async {
    _isForwardingRtcm = false;
    await _rtcmSubscription?.cancel();
    _rtcmSubscription = null;
    await _ntripClient?.disconnect();
    debugPrint('BLE: Disconnected from NTRIP');
  }

  Future<void> disconnectDevice() async {
    _connectionStateController.add(BLEConnectionState.waiting);

    // Disconnect from NTRIP if connected
    await disconnectFromNtrip();

    // Unsubscribe from data
    await _dataSubscription?.cancel();
    _dataSubscription = null;

    // Disable notifications
    if (_txCharacteristic != null) {
      try {
        await _txCharacteristic!.setNotifyValue(false);
      } catch (e) {
        debugPrint("BLE: Error unsubscribing: $e");
      }
    }

    // Clear service references
    _uartService = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _nmeaBuffer = '';

    await connectedDevice?.disconnect();
    connectedDevice = null;
    _connectionStateController.add(BLEConnectionState.disconnected);
  }

  /// Disposes the service. Only call this when you want to completely shut down
  /// the BLE service (e.g., app termination). For normal screen navigation,
  /// the service should remain active to continue receiving GPS data.
  void dispose() {
    disconnectFromNtrip();
    _ntripClient?.dispose();
    _rtcmSubscription?.cancel();
    _dataSubscription?.cancel();
    _scanResultsController.close();
    _connectionStateController.close();
    _gpsDataController.close();
    _nmeaDataController.close();
  }

  /// Checks if the service is currently connected to a device
  bool get isConnected => connectedDevice != null;

  /// Request a larger MTU for the connection (e.g. for faster data transfer).
  Future<void> requestMtu(BluetoothDevice device, {int size = 256}) async {
    try {
      await device.requestMtu(size);
    } catch (e) {
      debugPrint("BLE: MTU error: $e");
    }
  }

  void _printScanResult(ScanResult r) {
    debugPrint("-------------------- BLE Scan Result --------------------");
    debugPrint("Device Name: ${r.device.platformName}");
    debugPrint("Device ID: ${r.device.remoteId}");
    debugPrint("RSSI: ${r.rssi}");
    debugPrint("Advertisement Data:");
    debugPrint("  Local Name: ${r.advertisementData.advName}");
    debugPrint("  Tx Power Level: ${r.advertisementData.txPowerLevel}");
    debugPrint("  Connectable: ${r.advertisementData.connectable}");
    debugPrint("  Manufacturer Data: ${r.advertisementData.manufacturerData}");
    debugPrint("  Service UUIDs: ${r.advertisementData.serviceUuids}");
    debugPrint("  Service Data: ${r.advertisementData.serviceData}");
    debugPrint("----------------------------------------------------------");
  }
}
