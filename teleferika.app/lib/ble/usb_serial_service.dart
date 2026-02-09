import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/ble/ble_service.dart';
import 'package:teleferika/ble/nmea_parser.dart';
import 'package:teleferika/ble/ntrip_client.dart';
import 'package:usb_serial/usb_serial.dart';

/// Info about a USB serial device for display and selection.
class UsbDeviceInfo {
  const UsbDeviceInfo({
    required this.deviceId,
    required this.displayName,
    required this.device,
  });

  final int deviceId;
  final String displayName;
  final UsbDevice device;

  @override
  String toString() => displayName;
}

/// USB serial service for connecting to RTK devices via USB (Android only).
///
/// Mirrors the BLE service API so NTRIP and UI can use the same patterns:
/// [connectionState], [gpsData], [nmeaData], [sendData], [sendCommand],
/// [forwardRtcmData], [connectToNtrip], [disconnectFromNtrip].
/// [isSupported] is false on non-Android platforms.
class UsbSerialService {
  UsbSerialService._();
  static final UsbSerialService _instance = UsbSerialService._();
  static UsbSerialService get instance => _instance;

  static final Logger _logger = Logger('UsbSerialService');

  /// USB is only supported on Android (USB host API).
  static bool get isSupported => Platform.isAndroid;

  static const int _defaultBaudRate = 115200;

  UsbPort? _port;
  StreamSubscription<List<int>>? _readSubscription;
  String _nmeaBuffer = '';

  final StreamController<BLEConnectionState> _connectionStateController =
      StreamController<BLEConnectionState>.broadcast();
  Stream<BLEConnectionState> get connectionState =>
      _connectionStateController.stream;

  final StreamController<Position> _gpsDataController =
      StreamController<Position>.broadcast();
  Stream<Position> get gpsData => _gpsDataController.stream;

  final StreamController<NMEAData> _nmeaDataController =
      StreamController<NMEAData>.broadcast();
  Stream<NMEAData> get nmeaData => _nmeaDataController.stream;

  NTRIPClient? _ntripClient;
  StreamSubscription<List<int>>? _rtcmSubscription;
  bool _isForwardingRtcm = false;
  Position? _currentGpsPosition;
  NMEAData? _lastNmeaData;
  StreamSubscription<Position>? _ntripGgaPositionSubscription;

  /// Currently connected USB device description (for UI).
  String? _connectedDeviceName;
  String? get connectedDeviceName => _connectedDeviceName;

  /// Last USB connection error message (e.g. permission denied). Cleared on success.
  String? _lastConnectionError;
  String? get lastConnectionError => _lastConnectionError;

  /// Whether a device is connected (analogous to [BLEService.connectedDevice] != null).
  bool get isConnected => _port != null;

  NTRIPClient? get ntripClient => _ntripClient;
  bool get isForwardingRtcm => _isForwardingRtcm;

  /// Lists available USB serial devices. Returns empty on non-Android.
  Future<List<UsbDeviceInfo>> listDevices() async {
    if (!isSupported) {
      _logger.warning('listDevices() not supported (not Android), returning []');
      return [];
    }
    try {
      final devices = await UsbSerial.listDevices();
      final result = <UsbDeviceInfo>[];
      for (var i = 0; i < devices.length; i++) {
        final d = devices[i];
        result.add(UsbDeviceInfo(
          deviceId: i,
          displayName: 'USB Serial ${d.productName ?? 'Device'} (${d.manufacturerName ?? 'Unknown'})',
          device: d,
        ));
      }
      return result;
    } catch (e, stackTrace) {
      _logger.severe('listDevices() failed', e, stackTrace);
      return [];
    }
  }

  /// Connects to the given USB device. Disconnects any existing connection first.
  Future<void> connectToDevice(UsbDeviceInfo info) async {
    _lastConnectionError = null;
    if (!isSupported) {
      _lastConnectionError = 'USB not supported on this device';
      _connectionStateController.add(BLEConnectionState.error);
      return;
    }
    _connectionStateController.add(BLEConnectionState.connecting);
    await disconnectDevice();

    try {
      UsbPort? port;
      try {
        port = await info.device.create();
      } catch (e) {
        _lastConnectionError = e.toString();
        _logger.warning('USB create() failed: $e');
        _connectionStateController.add(BLEConnectionState.error);
        return;
      }
      if (port == null) {
        _lastConnectionError = 'Failed to create USB port';
        _logger.warning('Failed to create USB port');
        _connectionStateController.add(BLEConnectionState.error);
        return;
      }
      final opened = await port.open();
      if (!opened) {
        _lastConnectionError = 'Failed to open USB port';
        _logger.warning('Failed to open USB port');
        _connectionStateController.add(BLEConnectionState.error);
        return;
      }
      await port.setPortParameters(
        _defaultBaudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
      _port = port;
      _connectedDeviceName = info.displayName;
      _lastConnectionError = null;

      final stream = port.inputStream;
      if (stream == null) {
        _lastConnectionError = 'USB port has no input stream';
        _logger.warning('USB port has no input stream');
        _connectionStateController.add(BLEConnectionState.error);
        return;
      }
      _readSubscription = stream.listen(
        _handleReceivedData,
        onError: (e) {
          _logger.warning('USB read error: $e');
          _connectionStateController.add(BLEConnectionState.error);
        },
        onDone: () {
          if (_port != null) _connectionStateController.add(BLEConnectionState.disconnected);
        },
        cancelOnError: false,
      );

      _connectionStateController.add(BLEConnectionState.connected);
    } catch (e) {
      _lastConnectionError = e.toString();
      _logger.warning('USB connect error: $e');
      _connectionStateController.add(BLEConnectionState.error);
    }
  }

  /// Disconnects from the current USB device.
  Future<void> disconnectDevice() async {
    await _readSubscription?.cancel();
    _readSubscription = null;
    if (_port != null) {
      try {
        await _port!.close();
      } catch (e) {
        _logger.fine('Error closing USB port: $e');
      }
      _port = null;
    }
    _connectedDeviceName = null;
    _lastConnectionError = null;
    _nmeaBuffer = '';
    if (_connectionStateController.hasListener) {
      _connectionStateController.add(BLEConnectionState.disconnected);
    }
    await disconnectFromNtrip();
  }

  void _handleReceivedData(List<int> data) {
    try {
      if (data.isNotEmpty && data[0] == 0xD3) {
        return;
      }
      // Decode with allowMalformed so binary (RTCM or other) mixed in the stream
      // does not throw; we only process lines starting with '$' (NMEA).
      final text = utf8.decode(data, allowMalformed: true);
      _nmeaBuffer += text;
      final lines = _nmeaBuffer.split('\n');
      if (lines.length > 1) {
        _nmeaBuffer = lines.last;
        for (var i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isNotEmpty && line.startsWith('\$')) {
            _processNMEASentence(line);
          }
        }
      }
    } catch (e) {
      _logger.warning('USB _handleReceivedData: $e');
    }
  }

  void _processNMEASentence(String sentence) {
    try {
      final nmeaData = NMEAParser.parseSentence(sentence);
      if (nmeaData == null || !nmeaData.isValid) {
        return;
      }
      _lastNmeaData = nmeaData;
      _nmeaDataController.add(nmeaData);
      final position = Position(
        latitude: nmeaData.latitude,
        longitude: nmeaData.longitude,
        timestamp: nmeaData.time ?? DateTime.now(),
        accuracy: nmeaData.accuracy ?? 0.0,
        altitude: nmeaData.altitude ?? 0.0,
        heading: nmeaData.course ?? 0.0,
        speed: (nmeaData.speed ?? 0.0) / 3.6,
        speedAccuracy: 0.0,
        headingAccuracy: 0.0,
        altitudeAccuracy: 0.0,
      );
      _gpsDataController.add(position);
    } catch (e) {
      _logger.warning('USB _processNMEASentence: $e');
    }
  }

  Future<void> sendData(List<int> data) async {
    final port = _port;
    if (port == null) return;
    try {
      await port.write(Uint8List.fromList(data));
    } catch (e) {
      _logger.warning('USB write error: $e');
    }
  }

  Future<void> sendCommand(String command) async {
    await sendData(utf8.encode(command));
  }

  Future<void> forwardRtcmData(List<int> rtcmData) async {
    if (_port == null) return;
    if (rtcmData.isEmpty) return;
    try {
      await _port!.write(Uint8List.fromList(rtcmData));
    } catch (e) {
      _logger.warning('USB RTCM forward error: $e');
    }
  }

  Future<bool> connectToNtrip({
    required String host,
    required int port,
    required String mountPoint,
    required String username,
    required String password,
    bool useSsl = false,
  }) async {
    if (_port == null) return false;
    try {
      _ntripClient ??= NTRIPClient();
      await _ntripClient!.connect(
        host: host,
        port: port,
        mountPoint: mountPoint,
        username: username,
        password: password,
        useSsl: useSsl,
      );
      if (_ntripClient!.connectionState != NTRIPConnectionState.connected) {
        return false;
      }
      _setupNtripGgaSending();
      _rtcmSubscription?.cancel();
      _rtcmSubscription = _ntripClient!.rtcmData.listen(
        (rtcmData) {
          _isForwardingRtcm = true;
          forwardRtcmData(rtcmData);
        },
        onError: (_, __) => _isForwardingRtcm = false,
        onDone: () => _isForwardingRtcm = false,
        cancelOnError: false,
      );
      return true;
    } catch (e) {
      _logger.warning('NTRIP connect error: $e');
      return false;
    }
  }

  void _setupNtripGgaSending() {
    _ntripGgaPositionSubscription?.cancel();
    if (_currentGpsPosition != null) {
      _ntripClient?.sendGgaSentence(_currentGpsPosition!, _lastNmeaData);
    }
    _ntripGgaPositionSubscription = gpsData.listen((position) {
      _currentGpsPosition = position;
      _ntripClient?.sendGgaSentence(position, _lastNmeaData);
    });
  }

  Future<void> disconnectFromNtrip() async {
    _isForwardingRtcm = false;
    await _rtcmSubscription?.cancel();
    _rtcmSubscription = null;
    await _ntripGgaPositionSubscription?.cancel();
    _ntripGgaPositionSubscription = null;
    if (_ntripClient != null) {
      await _ntripClient!.disconnect();
    }
  }
}
