import 'dart:async';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/ble/ble_rtk_transport.dart';
import 'package:teleferika/ble/ble_service.dart';
import 'package:teleferika/ble/nmea_parser.dart';
import 'package:teleferika/ble/ntrip_client.dart';
import 'package:teleferika/ble/rtk_device_transport.dart';
import 'package:teleferika/ble/usb_serial_rtk_transport.dart';
import 'package:teleferika/ble/usb_serial_service.dart';

/// Connection mode: Bluetooth (BLE) or USB serial.
enum RtkConnectionMode { ble, usb }

/// Single entry point for RTK device communication (BLE or USB).
///
/// Implements Option A (transport abstraction): holds the active transport
/// and exposes a unified API. NTRIP and UI use this service; they don't care
/// whether the backend is BLE or USB.
class RtkDeviceService {
  RtkDeviceService._();
  static final RtkDeviceService _instance = RtkDeviceService._();
  static RtkDeviceService get instance => _instance;

  static final Logger _logger = Logger('RtkDeviceService');

  late final BleRtkTransport _bleTransport;
  late final UsbSerialRtkTransport _usbTransport;
  RtkDeviceTransport? _activeTransport;
  RtkConnectionMode? _activeMode;
  StreamSubscription<BLEConnectionState>? _connectionStateSub;
  StreamSubscription<Position>? _gpsDataSub;
  StreamSubscription<NMEAData>? _nmeaDataSub;

  final StreamController<BLEConnectionState> _connectionStateController =
      StreamController<BLEConnectionState>.broadcast();
  final StreamController<Position> _gpsDataController =
      StreamController<Position>.broadcast();
  final StreamController<NMEAData> _nmeaDataController =
      StreamController<NMEAData>.broadcast();

  bool _initialized = false;

  void _ensureInitialized() {
    if (_initialized) return;
    _bleTransport = BleRtkTransport(BLEService.instance);
    _usbTransport = UsbSerialRtkTransport(UsbSerialService.instance);
    _initialized = true;
    // Sync active transport if BLE or USB is already connected (e.g. from previous session)
    if (_bleTransport.isConnected) {
      unawaited(_setActiveTransport(_bleTransport, RtkConnectionMode.ble));
    } else if (_usbTransport.isConnected) {
      unawaited(_setActiveTransport(_usbTransport, RtkConnectionMode.usb));
    }
  }

  /// Connection state stream (unified across BLE and USB).
  Stream<BLEConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// GPS position data stream (unified).
  Stream<Position> get gpsData => _gpsDataController.stream;

  /// NMEA data stream (unified).
  Stream<NMEAData> get nmeaData => _nmeaDataController.stream;

  /// Whether any transport is connected.
  bool get isConnected => _activeTransport?.isConnected ?? false;

  /// Current connection mode, or null if disconnected.
  RtkConnectionMode? get activeMode => _activeMode;

  /// Display name of the connected device.
  String? get connectedDeviceName => _activeTransport?.connectedDeviceName;

  /// NTRIP client (from active transport).
  NTRIPClient? get ntripClient => _activeTransport?.ntripClient;

  /// Whether RTCM is being forwarded.
  bool get isForwardingRtcm => _activeTransport?.isForwardingRtcm ?? false;

  /// BLE transport (for BLE-specific operations like scanning).
  BleRtkTransport get bleTransport {
    _ensureInitialized();
    return _bleTransport;
  }

  /// USB transport (for USB-specific operations like listing devices).
  UsbSerialRtkTransport get usbTransport {
    _ensureInitialized();
    return _usbTransport;
  }

  /// Whether USB is supported on this platform.
  static bool get isUsbSupported => Platform.isAndroid;

  /// Connect via BLE. Disconnects USB if connected.
  /// [context] is optional; pass for UI (e.g. dialogs) in BLE flow.
  Future<void> connectViaBle(BluetoothDevice device, [BuildContext? context]) async {
    _ensureInitialized();
    await _disconnectCurrent();
    await _bleTransport.connectToDevice(device, context);
    await _setActiveTransport(_bleTransport, RtkConnectionMode.ble);
  }

  /// Connect via USB. Disconnects BLE if connected.
  Future<void> connectViaUsb(UsbDeviceInfo info) async {
    _ensureInitialized();
    if (!UsbSerialRtkTransport.isSupported) {
      _logger.warning('USB not supported on this platform');
      return;
    }
    await _disconnectCurrent();
    await _usbTransport.connectToDevice(info);
    await _setActiveTransport(_usbTransport, RtkConnectionMode.usb);
  }

  /// Disconnect the current transport.
  Future<void> disconnect() async {
    await _disconnectCurrent();
  }

  Future<void> _disconnectCurrent() async {
    await _clearActiveTransport();
    if (_bleTransport.isConnected) {
      await _bleTransport.disconnect();
    }
    if (_usbTransport.isConnected) {
      await _usbTransport.disconnect();
    }
  }

  Future<void> _setActiveTransport(
    RtkDeviceTransport transport,
    RtkConnectionMode mode,
  ) async {
    await _clearActiveTransport();
    _activeTransport = transport;
    _activeMode = mode;

    _connectionStateSub = transport.connectionState.listen(
      _connectionStateController.add,
      onError: _connectionStateController.addError,
      onDone: () {
        if (_activeTransport == transport) {
          _connectionStateController.add(BLEConnectionState.disconnected);
        }
      },
    );
    _gpsDataSub = transport.gpsData.listen(
      _gpsDataController.add,
      onError: _gpsDataController.addError,
    );
    _nmeaDataSub = transport.nmeaData.listen(
      _nmeaDataController.add,
      onError: _nmeaDataController.addError,
    );

    // Emit current state if connected
    if (transport.isConnected) {
      _connectionStateController.add(BLEConnectionState.connected);
    }
  }

  Future<void> _clearActiveTransport() async {
    await _connectionStateSub?.cancel();
    await _gpsDataSub?.cancel();
    await _nmeaDataSub?.cancel();
    _connectionStateSub = null;
    _gpsDataSub = null;
    _nmeaDataSub = null;
    _activeTransport = null;
    _activeMode = null;
    _connectionStateController.add(BLEConnectionState.disconnected);
  }

  /// Sends raw bytes to the device.
  Future<void> sendData(List<int> data) async {
    await _activeTransport?.sendData(data);
  }

  /// Sends a string command to the device.
  Future<void> sendCommand(String command) async {
    await _activeTransport?.sendCommand(command);
  }

  /// Forwards RTCM correction data to the RTK device.
  Future<void> forwardRtcmData(List<int> rtcmData) async {
    await _activeTransport?.forwardRtcmData(rtcmData);
  }

  /// Connects to NTRIP and forwards RTCM to the active transport.
  Future<bool> connectToNtrip({
    required String host,
    required int port,
    required String mountPoint,
    required String username,
    required String password,
    bool useSsl = false,
  }) async {
    final transport = _activeTransport;
    if (transport == null || !transport.isConnected) {
      return false;
    }
    return transport.connectToNtrip(
      host: host,
      port: port,
      mountPoint: mountPoint,
      username: username,
      password: password,
      useSsl: useSsl,
    );
  }

  /// Disconnects from NTRIP.
  Future<void> disconnectFromNtrip() async {
    await _activeTransport?.disconnectFromNtrip();
  }

  /// BLE: the connected device (when in BLE mode).
  BluetoothDevice? get connectedBleDevice => _bleTransport.connectedDevice;

  /// USB: last connection error (when using USB).
  String? get lastUsbConnectionError => _usbTransport.lastConnectionError;
}
