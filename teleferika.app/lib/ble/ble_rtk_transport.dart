import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teleferika/ble/ble_service.dart';
import 'package:teleferika/ble/nmea_parser.dart';
import 'package:teleferika/ble/ntrip_client.dart';
import 'package:teleferika/ble/rtk_device_transport.dart';

/// BLE transport implementation using Nordic UART Service (NUS).
///
/// Wraps [BLEService] to implement [RtkDeviceTransport].
class BleRtkTransport implements RtkDeviceTransport {
  BleRtkTransport(this._bleService);

  final BLEService _bleService;

  @override
  Stream<BLEConnectionState> get connectionState =>
      _bleService.connectionState;

  @override
  Stream<Position> get gpsData => _bleService.gpsData;

  @override
  Stream<NMEAData> get nmeaData => _bleService.nmeaData;

  @override
  bool get isConnected => _bleService.isConnected;

  @override
  String? get connectedDeviceName =>
      _bleService.connectedDevice?.platformName;

  @override
  NTRIPClient? get ntripClient => _bleService.ntripClient;

  @override
  bool get isForwardingRtcm => _bleService.isForwardingRtcm;

  @override
  Future<void> sendData(List<int> data) => _bleService.sendData(data);

  @override
  Future<void> sendCommand(String command) =>
      _bleService.sendCommand(command);

  @override
  Future<void> forwardRtcmData(List<int> rtcmData) =>
      _bleService.forwardRtcmData(rtcmData);

  @override
  Future<bool> connectToNtrip({
    required String host,
    required int port,
    required String mountPoint,
    required String username,
    required String password,
    bool useSsl = false,
  }) =>
      _bleService.connectToNtrip(
        host: host,
        port: port,
        mountPoint: mountPoint,
        username: username,
        password: password,
        useSsl: useSsl,
      );

  @override
  Future<void> disconnectFromNtrip() => _bleService.disconnectFromNtrip();

  @override
  Future<void> disconnect() => _bleService.disconnectDevice();

  /// BLE-specific: connect to a device. Call this before using the transport.
  /// [context] is optional; pass for UI (e.g. dialogs) in BLE flow.
  Future<void> connectToDevice(BluetoothDevice device, [BuildContext? context]) =>
      _bleService.connectToDevice(device, context);

  /// BLE-specific: the connected BLE device.
  BluetoothDevice? get connectedDevice => _bleService.connectedDevice;

  /// BLE-specific: start scanning for devices.
  Future<void> startScan() => _bleService.startScan();

  /// BLE-specific: stop scanning.
  Future<void> stopScan() => _bleService.stopScan();

  /// BLE-specific: scan results stream.
  Stream<List<ScanResult>> get scanResults => _bleService.scanResults;

  /// BLE-specific: whether currently scanning.
  bool get isScanning => _bleService.isScanning;

  /// BLE-specific: stream of scanning state.
  Stream<bool> get isScanningStream => _bleService.isScanningStream;
}
