import 'package:geolocator/geolocator.dart';
import 'package:teleferika/ble/ble_service.dart';
import 'package:teleferika/ble/nmea_parser.dart';
import 'package:teleferika/ble/ntrip_client.dart';

/// Abstract transport for RTK device communication (BLE or USB serial).
///
/// Implementations provide the same logical channel: NMEA in, RTCM/commands out.
/// Used by [RtkDeviceService] as the active transport.
abstract class RtkDeviceTransport {
  /// Connection state stream.
  Stream<BLEConnectionState> get connectionState;

  /// GPS position data stream (parsed from NMEA).
  Stream<Position> get gpsData;

  /// Raw NMEA data stream.
  Stream<NMEAData> get nmeaData;

  /// Whether a device is currently connected.
  bool get isConnected;

  /// Display name of the connected device (for UI).
  String? get connectedDeviceName;

  /// NTRIP client instance (if connected to NTRIP).
  NTRIPClient? get ntripClient;

  /// Whether RTCM corrections are being forwarded.
  bool get isForwardingRtcm;

  /// Sends raw bytes to the device.
  Future<void> sendData(List<int> data);

  /// Sends a string command to the device.
  Future<void> sendCommand(String command);

  /// Forwards RTCM correction data to the RTK device.
  Future<void> forwardRtcmData(List<int> rtcmData);

  /// Connects to NTRIP caster and forwards RTCM to this transport.
  Future<bool> connectToNtrip({
    required String host,
    required int port,
    required String mountPoint,
    required String username,
    required String password,
    bool useSsl = false,
  });

  /// Disconnects from NTRIP and stops forwarding RTCM.
  Future<void> disconnectFromNtrip();

  /// Disconnects from the RTK device.
  Future<void> disconnect();
}
