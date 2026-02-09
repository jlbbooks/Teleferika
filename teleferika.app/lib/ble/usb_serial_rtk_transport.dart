import 'package:geolocator/geolocator.dart';
import 'package:teleferika/ble/ble_service.dart';
import 'package:teleferika/ble/nmea_parser.dart';
import 'package:teleferika/ble/ntrip_client.dart';
import 'package:teleferika/ble/rtk_device_transport.dart';
import 'package:teleferika/ble/usb_serial_service.dart';

/// USB serial transport implementation for RTK devices (Android only).
///
/// Wraps [UsbSerialService] to implement [RtkDeviceTransport].
class UsbSerialRtkTransport implements RtkDeviceTransport {
  UsbSerialRtkTransport(this._usbService);

  final UsbSerialService _usbService;

  @override
  Stream<BLEConnectionState> get connectionState =>
      _usbService.connectionState;

  @override
  Stream<Position> get gpsData => _usbService.gpsData;

  @override
  Stream<NMEAData> get nmeaData => _usbService.nmeaData;

  @override
  bool get isConnected => _usbService.isConnected;

  @override
  String? get connectedDeviceName => _usbService.connectedDeviceName;

  @override
  NTRIPClient? get ntripClient => _usbService.ntripClient;

  @override
  bool get isForwardingRtcm => _usbService.isForwardingRtcm;

  @override
  Future<void> sendData(List<int> data) => _usbService.sendData(data);

  @override
  Future<void> sendCommand(String command) =>
      _usbService.sendCommand(command);

  @override
  Future<void> forwardRtcmData(List<int> rtcmData) =>
      _usbService.forwardRtcmData(rtcmData);

  @override
  Future<bool> connectToNtrip({
    required String host,
    required int port,
    required String mountPoint,
    required String username,
    required String password,
    bool useSsl = false,
  }) =>
      _usbService.connectToNtrip(
        host: host,
        port: port,
        mountPoint: mountPoint,
        username: username,
        password: password,
        useSsl: useSsl,
      );

  @override
  Future<void> disconnectFromNtrip() => _usbService.disconnectFromNtrip();

  @override
  Future<void> disconnect() => _usbService.disconnectDevice();

  /// USB-specific: connect to a device. Call this before using the transport.
  Future<void> connectToDevice(UsbDeviceInfo info) =>
      _usbService.connectToDevice(info);

  /// USB-specific: list available USB serial devices.
  Future<List<UsbDeviceInfo>> listDevices() => _usbService.listDevices();

  /// USB-specific: last connection error (e.g. permission denied).
  String? get lastConnectionError => _usbService.lastConnectionError;

  /// Whether USB serial is supported on this platform (Android only).
  static bool get isSupported => UsbSerialService.isSupported;
}
