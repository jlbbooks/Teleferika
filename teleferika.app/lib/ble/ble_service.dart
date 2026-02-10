import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';
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

  final Logger _logger = Logger('BLEService');

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

  // Cached regex patterns for NMEA parsing (avoid allocating in hot path)
  static final RegExp _reNmeaLikeChars = RegExp(r'[\$A-Za-z0-9,]');
  static final RegExp _reNmeaTalker = RegExp(r'\$[A-Z]{2}[A-Z]{3}');
  static final RegExp _reNmeaCommaNumbers = RegExp(r'[0-9]+,[0-9]+');
  static final RegExp _reNmeaTalkerOnly = RegExp(r'[A-Z]{2}[A-Z]{3}');
  static const Latin1Decoder _latin1Decoder = Latin1Decoder();

  // TODO(device-test): Test BLE data path with physical RTK/BLE device when available.
  // _handleReceivedData (Uint8List, cached regex, Latin1) was optimized and not yet validated on device.

  BluetoothService? _uartService;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<BluetoothConnectionState>? _deviceConnectionSubscription;

  // Buffer for incomplete NMEA sentences
  String _nmeaBuffer = '';

  final StreamController<List<ScanResult>> _scanResultsController =
      StreamController<List<ScanResult>>.broadcast();
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;

  /// Stream of scanning state
  Stream<bool> get isScanningStream => FlutterBluePlus.isScanning;

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

  bool _disposed = false;

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
      _logger.warning('Scan error: $e');
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

      // Listen for unexpected disconnections
      _deviceConnectionSubscription?.cancel();
      _deviceConnectionSubscription = device.connectionState.listen(
        (state) {
          if (state == BluetoothConnectionState.disconnected &&
              connectedDevice != null) {
            // Unexpected disconnection detected
            _logger.warning(
              'Unexpected disconnection detected from device: '
              '${device.remoteId}',
            );
            _handleUnexpectedDisconnection();
          }
        },
        onError: (error) {
          _logger.warning('Connection state stream error: $error');
          // Treat stream errors as disconnection
          if (connectedDevice != null) {
            _handleUnexpectedDisconnection();
          }
        },
      );

      // Discover services after connection
      await _discoverServices(device);

      // Stop scanning when successfully connected
      if (isScanning) {
        await stopScan();
      }

      _connectionStateController.add(BLEConnectionState.connected);
    } catch (e) {
      _logger.warning('Connection error: $e');
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
        _logger.fine('Found ${services.length} services');
        for (final service in services) {
          _logger.finer('Service UUID: ${service.uuid}');
          for (final characteristic in service.characteristics) {
            final uuid = characteristic.uuid.toString().toLowerCase();
            _logger.finer('  Characteristic UUID: $uuid');
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
        _logger.warning(
          'Nordic UART Service not found. '
          'Device may use different service UUIDs.',
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
          _logger.fine('Could not send NMEA enable command: $e');
        }
      }
    } catch (e) {
      _logger.warning('Service discovery error: $e');
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
      _logger.fine('Error enabling NMEA output: $e');
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

      // Listen to value updates (convert to Uint8List for faster hot path)
      _dataSubscription = characteristic.onValueReceived.listen(
        (value) {
          _handleReceivedData(Uint8List.fromList(value));
        },
        onError: (error) {
          _logger.warning('Data subscription error: $error');
        },
        cancelOnError: false,
      );

      // Also try reading the current value (some devices send data on read)
      try {
        final currentValue = await characteristic.read();
        if (currentValue.isNotEmpty) {
          _handleReceivedData(Uint8List.fromList(currentValue));
        }
      } catch (e) {
        // Characteristic may not support read - this is fine
      }
    } catch (e) {
      _logger.warning('Error subscribing to data: $e');
      rethrow;
    }
  }

  /// Handles received data bytes and parses NMEA sentences.
  /// Uses [Uint8List] for better performance in the hot path.
  void _handleReceivedData(Uint8List data) {
    try {
      // Raw data reception logging removed

      // Check if data looks like binary RTCM (starts with 0xD3)
      // RTCM data shouldn't come from the BLE device, so skip it
      if (data.isNotEmpty && data[0] == 0xD3) {
        // This is RTCM binary data, not NMEA text - skip it
        // RTCM data should come from NTRIP, not from the BLE device
        return;
      }

      // Try to decode as UTF-8 text (NMEA sentences)
      String text;
      try {
        text = utf8.decode(data);
      } catch (e) {
        // If UTF-8 decode fails, investigate what this data might be
        if (data.isNotEmpty && data[0] == 0xD3) {
          // RTCM data - skip it
          return;
        }

        // Check if all bytes are printable ASCII (0x20-0x7E) or common control chars
        bool isPrintableAscii = true;
        for (final byte in data) {
          // Allow printable ASCII, newline, carriage return, tab
          if (!(byte >= 0x20 && byte <= 0x7E) &&
              byte != 0x0A &&
              byte != 0x0D &&
              byte != 0x09) {
            isPrintableAscii = false;
            break;
          }
        }

        if (isPrintableAscii) {
          // It's ASCII but UTF-8 decode failed - might be a continuation byte issue
          // Try decoding as Latin-1 (which maps bytes 0x00-0xFF directly to characters)
          try {
            text = _latin1Decoder.convert(data);
            // If it looks like it could be part of NMEA (contains $, letters, numbers, commas)
            if (text.contains(_reNmeaLikeChars) || _nmeaBuffer.isNotEmpty) {
              // Likely part of an NMEA sentence - add to buffer
              _nmeaBuffer += text;
              // Try to process if we have complete sentences
              final lines = _nmeaBuffer.split('\n');
              if (lines.length > 1) {
                _nmeaBuffer = lines.last;
                for (int i = 0; i < lines.length - 1; i++) {
                  final line = lines[i].trim();
                  if (line.isNotEmpty && line.startsWith('\$')) {
                    _processNMEASentence(line);
                  }
                }
              }
              return;
            }
          } catch (e2) {
            // Even Latin-1 decode failed - log details
          }
        }

        // Try to extract ASCII/printable parts even if UTF-8 decode failed
        // This handles cases where binary data is mixed with NMEA sentences
        String? extractedText;
        try {
          // Extract printable ASCII characters (0x20-0x7E) and common control chars
          final printableBytes = <int>[];
          for (final byte in data) {
            // Include printable ASCII, newline, carriage return, tab, and $ (for NMEA)
            if ((byte >= 0x20 && byte <= 0x7E) ||
                byte == 0x0A ||
                byte == 0x0D ||
                byte == 0x09 ||
                byte == 0x24) {
              printableBytes.add(byte);
            }
          }

          if (printableBytes.isNotEmpty) {
            extractedText = String.fromCharCodes(printableBytes);
            // Check if it contains NMEA-like patterns (starts with $, or contains comma-separated numbers/letters)
            final hasNmeaMarker = extractedText.contains(_reNmeaTalker);
            final hasNmeaPattern = extractedText.contains(_reNmeaCommaNumbers) ||
                extractedText.contains(_reNmeaTalkerOnly);

            if (hasNmeaMarker || (hasNmeaPattern && _nmeaBuffer.isNotEmpty)) {
              // Contains NMEA sentence markers or patterns - process it
              _nmeaBuffer += extractedText;
              // Process complete sentences
              final lines = _nmeaBuffer.split('\n');
              if (lines.length > 1) {
                _nmeaBuffer = lines.last;
                for (int i = 0; i < lines.length - 1; i++) {
                  final line = lines[i].trim();
                  if (line.isNotEmpty && line.startsWith('\$')) {
                    _processNMEASentence(line);
                  }
                }
              }
              // Log successful extraction for investigation
              if (const bool.fromEnvironment('dart.vm.product') == false) {
                _logger.finer(
                  'Extracted NMEA from binary data: ${extractedText.length} chars, '
                  'preview: ${extractedText.substring(0, extractedText.length > 50 ? 50 : extractedText.length)}',
                );
              }
              return; // Successfully processed
            }
          }
        } catch (e) {
          // Extraction failed - log and continue to detailed logging
        }

        // Not ASCII and not RTCM - log detailed info for investigation
        if (const bool.fromEnvironment('dart.vm.product') == false) {
          final hexDump = data
              .sublist(0, data.length > 30 ? 30 : data.length)
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join(' ');

          // Try to extract all ASCII parts for better investigation
          String? asciiPreview;
          String? asciiFull;
          try {
            final asciiBytes = data
                .where(
                  (b) =>
                      (b >= 0x20 && b <= 0x7E) ||
                      b == 0x0A ||
                      b == 0x0D ||
                      b == 0x09 ||
                      b == 0x24,
                )
                .toList();
            if (asciiBytes.isNotEmpty) {
              asciiFull = String.fromCharCodes(asciiBytes);
              asciiPreview = asciiFull.length > 100
                  ? '${asciiFull.substring(0, 100)}...'
                  : asciiFull;
            }
          } catch (e) {
            // Ignore
          }

          // Count printable vs non-printable bytes
          int printableCount = 0;
          int nonPrintableCount = 0;
          for (final byte in data) {
            if ((byte >= 0x20 && byte <= 0x7E) ||
                byte == 0x0A ||
                byte == 0x0D ||
                byte == 0x09) {
              printableCount++;
            } else {
              nonPrintableCount++;
            }
          }

          _logger.finer(
            "Received data that couldn't be decoded as UTF-8. "
            'Length: ${data.length} bytes ($printableCount printable, $nonPrintableCount non-printable), '
            "Hex (first 30): $hexDump${data.length > 30 ? '...' : ''}, "
            "First byte: 0x${data[0].toRadixString(16)} (${data[0] >= 0x20 && data[0] <= 0x7E ? String.fromCharCode(data[0]) : 'non-printable'}), "
            "${asciiPreview != null ? 'ASCII extracted: $asciiPreview, ' : ''}"
            "Buffer length: ${_nmeaBuffer.length}${_nmeaBuffer.isNotEmpty ? ', buffer ends with: ${_nmeaBuffer.substring(_nmeaBuffer.length > 20 ? _nmeaBuffer.length - 20 : 0)}' : ''}",
          );

          // If we have significant ASCII content, try to process it anyway
          if (asciiFull != null &&
              asciiFull.length > 5 &&
              (asciiFull.contains('\$') ||
                  asciiFull.contains(_reNmeaCommaNumbers))) {
            _logger.finer(
              'Attempting to process extracted ASCII as potential NMEA fragment',
            );
            _nmeaBuffer += asciiFull;
            // Try to process complete sentences
            final lines = _nmeaBuffer.split('\n');
            if (lines.length > 1) {
              _nmeaBuffer = lines.last;
              for (int i = 0; i < lines.length - 1; i++) {
                final line = lines[i].trim();
                if (line.isNotEmpty && line.startsWith('\$')) {
                  _processNMEASentence(line);
                }
              }
            }
          }
        }
        return;
      }

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
      // Only log unexpected errors (not FormatException from UTF-8 decode)
      if (e is! FormatException) {
        _logger.warning('Error handling received data: $e');
      }
    }
  }

  /// Processes a complete NMEA sentence and emits GPS data.
  void _processNMEASentence(String sentence) {
    try {
      final nmeaData = NMEAParser.parseSentence(sentence);

      if (nmeaData != null && nmeaData.isValid) {
        // NMEA processing logging removed

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

        // GPS position emission logging removed

        _gpsDataController.add(position);
      }
      // Note: We don't log "invalid" for non-position sentences (GSV, GSA, etc.)
      // as they are valid NMEA but don't contain position data
    } catch (e) {
      _logger.warning('Error processing NMEA sentence: $e');
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
      _logger.warning('Error sending data: $e');
    }
  }

  /// Sends a string command to the device.
  Future<void> sendCommand(String command) async {
    final data = utf8.encode(command);
    await sendData(data);
  }

  int _totalRtcmBytesForwarded = 0;
  int _rtcmMessageCount = 0;
  DateTime? _lastRtcmForwardTime;

  /// Forwards RTCM correction data to the RTK device via BLE.
  /// This method handles splitting large RTCM messages to fit BLE MTU limits.
  Future<void> forwardRtcmData(List<int> rtcmData) async {
    if (_rxCharacteristic == null) {
      _logger.warning('Cannot forward RTCM - RX characteristic not available');
      return;
    }

    if (rtcmData.isEmpty) {
      _logger.fine('Received empty RTCM data, skipping');
      return;
    }

    try {
      _totalRtcmBytesForwarded += rtcmData.length;
      _rtcmMessageCount++;
      _lastRtcmForwardTime = DateTime.now();

      // BLE typically has MTU limits (20-517 bytes depending on device)
      // Split large RTCM messages into chunks
      const maxChunkSize = 200; // Conservative chunk size for BLE

      // Logging removed - RTCM forwarding is working correctly

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
    } catch (e, stackTrace) {
      _logger.warning('Error forwarding RTCM data: $e', e, stackTrace);
    }
  }

  /// Gets RTCM forwarding statistics
  Map<String, dynamic> getRtcmStats() {
    return {
      'totalBytes': _totalRtcmBytesForwarded,
      'messageCount': _rtcmMessageCount,
      'lastForwardTime': _lastRtcmForwardTime?.toIso8601String(),
      'isForwarding': _isForwardingRtcm,
    };
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
      // Error logging removed - error is returned to caller
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

      // Check if connection was successful
      // Note: connect() now waits for HTTP response, so state should be set
      if (_ntripClient!.connectionState == NTRIPConnectionState.connected) {
        // Set up GGA sentence sending to NTRIP server
        _setupNtripGgaSending();

        // Subscribe to RTCM data stream
        _rtcmSubscription?.cancel();
        _rtcmSubscription = _ntripClient!.rtcmData.listen(
          (rtcmData) {
            _isForwardingRtcm = true;
            // RTCM reception logging removed - data is validated before reaching here
            forwardRtcmData(rtcmData);
          },
          onError: (error, stackTrace) {
            // RTCM stream errors are logged by NTRIP client - only log here if critical
            _isForwardingRtcm = false;
          },
          onDone: () {
            // Stream ended - logging removed
            _isForwardingRtcm = false;
          },
          cancelOnError: false,
        );

        // Connection successful - logging removed
        return true;
      } else {
        // Connection failed - error message is set in NTRIP client
        return false;
      }
    } catch (e) {
      // Error logging removed - error is handled by NTRIP client
      return false;
    }
  }

  StreamSubscription<Position>? _ntripGgaPositionSubscription;
  Position? _currentGpsPosition;
  NMEAData? _lastNmeaData;
  DateTime? _lastGgaSendTime;

  /// Sets up GPS position subscription to send GGA sentences to NTRIP server
  /// For i-Max services (like IMAX2), an initial GGA sentence must be sent immediately
  /// after connection to trigger RTCM data transmission.
  void _setupNtripGgaSending() {
    // Cancel existing subscription
    _ntripGgaPositionSubscription?.cancel();

    // Subscribe to NMEA data to get detailed GPS info (satellites, fix quality)
    _nmeaDataController.stream.listen((nmeaData) {
      _lastNmeaData = nmeaData;
    });

    // For i-Max services, send an initial GGA sentence immediately if we have position
    if (_currentGpsPosition != null) {
      _ntripClient?.sendGgaSentence(_currentGpsPosition!, _lastNmeaData);
      _lastGgaSendTime = DateTime.now();
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        _logger.fine(
          'Sent initial GGA sentence to NTRIP server (i-Max requirement)',
        );
      }
    }

    // Subscribe to GPS position updates and send GGA every 5 seconds
    Timer? ggaTimer;
    Position? lastSentPosition;

    _ntripGgaPositionSubscription = gpsData.listen(
      (position) {
        _currentGpsPosition = position; // Store for future initial GGA sends

        // Send GGA sentence immediately when position updates (or if first time)
        final shouldSend =
            lastSentPosition == null ||
            (position.latitude - lastSentPosition!.latitude).abs() > 0.0001 ||
            (position.longitude - lastSentPosition!.longitude).abs() > 0.0001 ||
            (_lastGgaSendTime == null) ||
            (DateTime.now().difference(_lastGgaSendTime!).inSeconds >= 5);

        if (shouldSend) {
          _ntripClient?.sendGgaSentence(position, _lastNmeaData);
          _lastGgaSendTime = DateTime.now();
          lastSentPosition = position;
        }

        // Set up periodic sending (every 5 seconds) if not already set
        ggaTimer ??= Timer.periodic(const Duration(seconds: 5), (timer) {
          if (_ntripClient?.connectionState == NTRIPConnectionState.connected) {
            final currentPos =
                _currentGpsPosition ?? lastSentPosition ?? position;
            _ntripClient?.sendGgaSentence(currentPos, _lastNmeaData);
            _lastGgaSendTime = DateTime.now();
          } else {
            timer.cancel();
            ggaTimer = null;
          }
        });
      },
      onError: (error) {
        // GGA subscription error logging removed - non-critical
        ggaTimer?.cancel();
      },
      onDone: () {
        ggaTimer?.cancel();
      },
    );

    if (const bool.fromEnvironment('dart.vm.product') == false) {
      _logger.fine(
        'Set up NTRIP GGA sentence sending (every 5 seconds, initial GGA: ${_currentGpsPosition != null})',
      );
    }
  }

  /// Disconnects from NTRIP caster and stops forwarding RTCM corrections.
  Future<void> disconnectFromNtrip() async {
    _isForwardingRtcm = false;

    // Cancel RTCM subscription
    try {
      await _rtcmSubscription?.cancel();
      _rtcmSubscription = null;
    } catch (e) {
      _logger.warning('Error canceling RTCM subscription: $e');
    }

    // Cancel GGA position subscription
    try {
      await _ntripGgaPositionSubscription?.cancel();
      _ntripGgaPositionSubscription = null;
    } catch (e) {
      _logger.warning('Error canceling GGA position subscription: $e');
    }

    // Disconnect from NTRIP client if connected
    final ntripClient = _ntripClient;
    if (ntripClient != null) {
      final wasConnected =
          ntripClient.connectionState == NTRIPConnectionState.connected ||
          ntripClient.connectionState == NTRIPConnectionState.connecting;

      if (wasConnected) {
        _logger.info('Disconnecting from NTRIP server (was connected)');
      }

      try {
        await ntripClient.disconnect();
        if (wasConnected) {
          _logger.info('Successfully disconnected from NTRIP server');
        }
      } catch (e) {
        _logger.warning('Error disconnecting from NTRIP server: $e');
        // Continue - we've done our best to disconnect
      }
    }
  }

  /// Handles unexpected disconnection (device went out of range, battery died, etc.)
  Future<void> _handleUnexpectedDisconnection() async {
    _logger.warning('Handling unexpected disconnection');

    // Cancel device connection subscription
    await _deviceConnectionSubscription?.cancel();
    _deviceConnectionSubscription = null;

    // Disconnect from NTRIP if connected
    await disconnectFromNtrip();

    // Unsubscribe from data
    await _dataSubscription?.cancel();
    _dataSubscription = null;

    // Disable notifications (may fail if device is already disconnected)
    if (_txCharacteristic != null) {
      try {
        await _txCharacteristic!.setNotifyValue(false);
      } catch (e) {
        // Ignore errors - device may already be disconnected
        // This is expected behavior during unexpected disconnections
        if (const bool.fromEnvironment('dart.vm.product') == false) {
          final errorMsg = e.toString();
          // Only log if it's not the expected "device is not connected" error
          if (!errorMsg.contains('not connected') &&
              !errorMsg.contains('disconnected')) {
            _logger.fine(
              'Error unsubscribing during unexpected disconnect: $e',
            );
          }
        }
      }
    }

    // Clear service references
    _uartService = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _nmeaBuffer = '';

    // Clear connected device reference
    final device = connectedDevice;
    connectedDevice = null;

    // Try to disconnect gracefully (may fail if already disconnected)
    if (device != null) {
      try {
        await device.disconnect();
      } catch (e) {
        _logger.fine('Error during disconnect cleanup: $e');
        // Ignore errors - device may already be disconnected
      }
    }

    // Notify listeners of disconnection
    _connectionStateController.add(BLEConnectionState.disconnected);
  }

  Future<void> disconnectDevice() async {
    _connectionStateController.add(BLEConnectionState.waiting);

    // Cancel device connection subscription
    await _deviceConnectionSubscription?.cancel();
    _deviceConnectionSubscription = null;

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
        // Ignore errors - device may already be disconnected
        final errorMsg = e.toString();
        if (const bool.fromEnvironment('dart.vm.product') == false) {
          // Only log if it's not the expected "device is not connected" error
          if (!errorMsg.contains('not connected') &&
              !errorMsg.contains('disconnected')) {
            _logger.fine('Error unsubscribing: $e');
          }
        }
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
    if (_disposed) return;
    _disposed = true;
    _dataSubscription?.cancel();
    _deviceConnectionSubscription?.cancel();
    _rtcmSubscription?.cancel();
    _ntripGgaPositionSubscription?.cancel();
    disconnectFromNtrip();
    _ntripClient?.disconnect();
    _ntripClient?.dispose();
    _scanResultsController.close();
    _connectionStateController.close();
    _gpsDataController.close();
    _nmeaDataController.close();
    _logger.info('BLEService disposed');
  }

  /// Checks if the service is currently connected to a device
  bool get isConnected => connectedDevice != null;

  /// Request a larger MTU for the connection (e.g. for faster data transfer).
  Future<void> requestMtu(BluetoothDevice device, {int size = 256}) async {
    try {
      await device.requestMtu(size);
    } catch (e) {
      _logger.fine('MTU error: $e');
    }
  }

  void _printScanResult(ScanResult r) {
    _logger.finer('-------------------- BLE Scan Result --------------------');
    _logger.finer('Device Name: ${r.device.platformName}');
    _logger.finer('Device ID: ${r.device.remoteId}');
    _logger.finer('RSSI: ${r.rssi}');
    _logger.finer('Advertisement Data:');
    _logger.finer('  Local Name: ${r.advertisementData.advName}');
    _logger.finer('  Tx Power Level: ${r.advertisementData.txPowerLevel}');
    _logger.finer('  Connectable: ${r.advertisementData.connectable}');
    _logger.finer(
      '  Manufacturer Data: ${r.advertisementData.manufacturerData}',
    );
    _logger.finer('  Service UUIDs: ${r.advertisementData.serviceUuids}');
    _logger.finer('  Service Data: ${r.advertisementData.serviceData}');
    _logger.finer('----------------------------------------------------------');
  }
}
