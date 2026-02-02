import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum BLEConnectionState { disconnected, connecting, connected, error, waiting }

/// BLE service for scanning, connecting and disconnecting from Bluetooth Low Energy devices.
/// Ported from AcuME app.
class BLEService {
  BluetoothDevice? connectedDevice;
  bool isScanning = false;
  final Duration scanTimeout = const Duration(seconds: 20);

  final StreamController<List<ScanResult>> _scanResultsController =
      StreamController<List<ScanResult>>.broadcast();
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;

  final StreamController<BLEConnectionState> _connectionStateController =
      StreamController<BLEConnectionState>.broadcast();
  Stream<BLEConnectionState> get connectionState =>
      _connectionStateController.stream;

  Future<void> startScan() async {
    if (isScanning) return;
    debugPrint("BLE: Starting scan...");
    isScanning = true;
    _scanResultsController.add([]);

    try {
      await FlutterBluePlus.startScan(timeout: scanTimeout);

      await for (final results in FlutterBluePlus.scanResults) {
        _scanResultsController.add(results);
        results.forEach(_printScanResult);
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
    debugPrint("BLE: Scan stopped.");
  }

  /// Connects to the given BLE device.
  /// [context] is optional; pass it if you need it for UI (e.g. dialogs) in future extensions.
  Future<void> connectToDevice(
    BluetoothDevice device, [
    BuildContext? context,
  ]) async {
    _connectionStateController.add(BLEConnectionState.connecting);
    debugPrint("BLE: Connecting...");

    try {
      if (connectedDevice != null) {
        await connectedDevice!.disconnect();
        debugPrint("BLE: Previous device disconnected.");
      }

      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      connectedDevice = device;
      debugPrint("BLE: Connected to ${device.platformName}");
      _connectionStateController.add(BLEConnectionState.connected);
    } catch (e) {
      debugPrint("BLE: Connection error: $e");
      _connectionStateController.add(BLEConnectionState.error);
    }
  }

  Future<void> disconnectDevice() async {
    _connectionStateController.add(BLEConnectionState.waiting);
    await connectedDevice?.disconnect();
    connectedDevice = null;
    _connectionStateController.add(BLEConnectionState.disconnected);
    debugPrint("BLE: Device disconnected.");
  }

  void dispose() {
    _scanResultsController.close();
    _connectionStateController.close();
  }

  /// Request a larger MTU for the connection (e.g. for faster data transfer).
  Future<void> requestMtu(BluetoothDevice device, {int size = 256}) async {
    try {
      final mtu = await device.requestMtu(size);
      debugPrint("BLE: MTU negotiated to $mtu bytes.");
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
