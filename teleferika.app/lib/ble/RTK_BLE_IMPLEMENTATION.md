# RTK GPS BLE Data Reading Implementation

This document explains the implementation of Bluetooth Low Energy (BLE) data reading functionality for RTK GPS receivers, specifically designed to work with the **RTK Handheld 2 Mapping Kit** from ArduSimple.

## Overview

The implementation enables the Teleferika app to:
- Connect to RTK GPS receivers via Bluetooth Low Energy
- Receive real-time GPS data in NMEA format
- Parse NMEA sentences to extract position, accuracy, and satellite information
- Display RTK GPS data in the user interface

## Architecture

The implementation consists of three main components:

1. **NMEA Parser** - Parses NMEA sentences and extracts GPS data
2. **BLE Service** - Handles BLE connection, service discovery, and data streaming
3. **BLE Screen UI** - Displays received GPS data to the user

---

## Component 1: NMEA Parser (`nmea_parser.dart`)

### Purpose

The NMEA parser converts raw NMEA sentences (text format) from RTK GPS receivers into structured data objects that the app can use.

### Key Features

- **Sentence Validation**: Validates NMEA sentence format and checksum
- **Multiple Sentence Types**: Supports GPGGA and GPRMC sentences
- **Data Extraction**: Extracts coordinates, altitude, accuracy, satellite count, and fix quality
- **Error Handling**: Gracefully handles malformed or incomplete sentences

### Supported NMEA Sentence Types

#### GPGGA (Global Positioning System Fix Data)
- **Format**: `$GPGGA,hhmmss.ss,llll.ll,a,yyyyy.yy,a,x,xx,x.x,x.x,M,x.x,M,x.x,xxxx*hh`
- **Data Extracted**:
  - Latitude and Longitude (decimal degrees)
  - Altitude (meters)
  - GPS Accuracy (calculated from HDOP)
  - Number of Satellites
  - Fix Quality (0=invalid, 1=GPS, 2=DGPS, 4=RTK, 5=RTK Float)
  - HDOP (Horizontal Dilution of Precision)
  - Geoid Height

#### GPRMC (Recommended Minimum)
- **Format**: `$GPRMC,hhmmss.ss,A,llll.ll,a,yyyyy.yy,a,x.x,x.x,ddmmyy,x.x,a*hh`
- **Data Extracted**:
  - Latitude and Longitude
  - Speed (km/h)
  - Course (degrees)
  - Date and Time
  - Fix Status

### NMEAData Class

The parser returns `NMEAData` objects containing:

```dart
class NMEAData {
  final double latitude;           // Decimal degrees
  final double longitude;          // Decimal degrees
  final double? altitude;          // Meters above sea level
  final double? accuracy;          // Meters (calculated from HDOP)
  final int? satellites;           // Number of satellites in view
  final int fixQuality;            // 0=invalid, 1=GPS, 2=DGPS, 4=RTK, 5=RTK Float
  final double? hdop;              // Horizontal Dilution of Precision
  final DateTime? time;            // Timestamp
  final double? speed;             // km/h
  final double? course;            // Degrees
  final String sentenceType;        // "GPGGA" or "GPRMC"
  
  bool get isValid => fixQuality > 0;  // True if fix is valid
}
```

### Checksum Validation

All NMEA sentences include a checksum for data integrity:
- Format: `$...*XX` where XX is a 2-digit hexadecimal checksum
- The parser validates checksums before processing sentences
- Invalid checksums result in the sentence being discarded

---

## Component 2: BLE Service (`ble_service.dart`)

### Purpose

The BLE Service manages the Bluetooth Low Energy connection lifecycle and handles data communication with RTK GPS receivers.

### Connection Flow

1. **Scanning**: Discovers nearby BLE devices
2. **Connection**: Establishes connection to selected device
3. **Service Discovery**: Automatically discovers available BLE services
4. **Characteristic Subscription**: Subscribes to data notifications
5. **Data Reception**: Receives and processes incoming data
6. **Disconnection**: Cleanly disconnects and unsubscribes

### Nordic UART Service (NUS)

The implementation targets the **Nordic UART Service**, which is commonly used by RTK receivers for serial data communication:

- **Service UUID**: `0000ffe0-0000-1000-8000-00805f9b34fb`
- **TX Characteristic UUID**: `0000ffe1-0000-1000-8000-00805f9b34fb` (for reading data)
- **RX Characteristic UUID**: `0000ffe1-0000-1000-8000-00805f9b34fb` (for writing commands)

### Key Methods

#### `connectToDevice(BluetoothDevice device)`
- Establishes BLE connection
- Automatically triggers service discovery
- Sets up data subscriptions

#### `_discoverServices(BluetoothDevice device)`
- Discovers all available BLE services
- Identifies the Nordic UART Service
- Finds TX and RX characteristics
- Falls back to generic UART service if Nordic UUID not found

#### `_subscribeToData(BluetoothCharacteristic characteristic)`
- Enables notifications on the TX characteristic
- Sets up stream listener for incoming data
- Handles data reception errors

#### `_handleReceivedData(List<int> data)`
- Converts raw bytes to UTF-8 text
- Buffers incomplete NMEA sentences
- Processes complete sentences (ending with `\n`)
- Calls NMEA parser for each complete sentence

#### `_processNMEASentence(String sentence)`
- Parses NMEA sentence using `NMEAParser`
- Converts `NMEAData` to `Position` objects (Geolocator compatible)
- Emits data to streams for UI consumption

### Data Streams

The service provides two data streams:

#### 1. `gpsData` Stream (`Stream<Position>`)
- Emits `Position` objects compatible with Geolocator package
- Contains: latitude, longitude, altitude, accuracy, timestamp
- Can be directly used with existing location services

#### 2. `nmeaData` Stream (`Stream<NMEAData>`)
- Emits detailed `NMEAData` objects
- Contains: satellite count, HDOP, fix quality, speed, course
- Provides RTK-specific information

### Buffer Management

The service uses a string buffer (`_nmeaBuffer`) to handle:
- **Incomplete Sentences**: Data received across multiple BLE packets
- **Multiple Sentences**: Multiple NMEA sentences in a single data packet
- **Line Endings**: Properly splits on `\n` to identify complete sentences

### MTU Negotiation

The service automatically requests a larger MTU (Maximum Transmission Unit) size:
- Default: 256 bytes
- Improves data throughput
- Reduces packet fragmentation

### Error Handling

- Connection timeouts (15 seconds)
- Service discovery failures (falls back to generic UART)
- Data parsing errors (logged, sentence discarded)
- Disconnection cleanup (unsubscribes, clears buffers)

---

## Component 3: BLE Screen UI (`ble_screen.dart`)

### Purpose

The BLE Screen provides a user interface for:
- Scanning for BLE devices
- Connecting/disconnecting to RTK receivers
- Viewing real-time GPS data

### UI Components

#### Connection Status Card
- Shows current connection state (Disconnected, Connecting, Connected, Error)
- Displays connected device name
- Color-coded status indicators

#### GPS Data Card
- **Visibility**: Only shown when connected and receiving GPS data
- **Display Fields**:
  - **Latitude/Longitude**: High-precision coordinates (8 decimal places)
  - **Altitude**: Height above sea level in meters
  - **Accuracy**: GPS accuracy in meters with color coding:
    - 🟢 Green: < 1 meter (RTK precision)
    - 🟠 Orange: 1-5 meters (good GPS)
    - 🔴 Red: > 5 meters (poor accuracy)
  - **Satellites**: Number of satellites in view
  - **HDOP**: Horizontal Dilution of Precision
  - **Fix Quality**: 
    - Invalid (0)
    - GPS Fix (1)
    - DGPS Fix (2)
    - PPS Fix (3)
    - RTK Fix (4) - Centimeter accuracy
    - RTK Float (5) - Sub-meter accuracy
    - Estimated (6)
    - Manual (7)
    - Simulation (8)
  - **Speed**: Current speed in km/h (if available)
  - **Last Update**: Timestamp showing when data was last received

### Data Flow

1. **User connects** to RTK device via BLE Screen
2. **BLE Service** establishes connection and discovers services
3. **Data subscription** is set up automatically
4. **NMEA sentences** are received and parsed
5. **GPS data** is emitted to streams
6. **BLE Screen** subscribes to streams and updates UI
7. **GPS Data Card** appears showing real-time information

### Stream Subscriptions

The screen subscribes to:
- `_bleService.gpsData` → Updates `_currentPosition`
- `_bleService.nmeaData` → Updates `_currentNmeaData`
- Both streams trigger UI updates via `setState()`

---

## RTK Handheld 2 Mapping Kit Compatibility

### Device Identification

When scanning for devices, look for:
- **Device Name**: `RTK_GNSS_***` or `BT+BLE_Bridge_XXXX`
- **May appear as**: MAC address only (e.g., `F0:0A:95:9D:68:16`)
- **Pairing Password**: `1234` (one-time pairing)

### Connection Methods Supported

1. **USB** (Recommended for Android)
   - Powers device and communicates simultaneously
   - Not handled by this BLE implementation

2. **Classic Bluetooth** (SPP)
   - Uses Serial Port Profile
   - Not handled by this BLE implementation

3. **Bluetooth Low Energy (BLE)** ✅
   - Uses Nordic UART Service
   - **This implementation handles BLE connections**

### Data Format

- **Protocol**: NMEA sentences (text format)
- **Default Output**: GPGGA and GPRMC sentences
- **Baud Rate**: 115200 bps (38400 for older kits)
- **Update Rate**: Typically 1Hz (configurable up to 20Hz)

### RTK Fix Quality

The implementation recognizes RTK-specific fix qualities:
- **RTK Fix (4)**: Centimeter-level accuracy (< 1cm)
- **RTK Float (5)**: Sub-meter accuracy (< 1m)
- **GPS Fix (1)**: Standard GPS accuracy (1-5m)

---

## Usage Example

### Basic Connection Flow

```dart
// 1. Create BLE service instance
final bleService = BLEService();

// 2. Start scanning for devices
await bleService.startScan();

// 3. Listen to scan results
bleService.scanResults.listen((results) {
  for (final result in results) {
    print('Found device: ${result.device.platformName}');
  }
});

// 4. Connect to a device
final device = scanResults.first.device;
await bleService.connectToDevice(device);

// 5. Listen to GPS data
bleService.gpsData.listen((position) {
  print('Lat: ${position.latitude}, Lon: ${position.longitude}');
  print('Accuracy: ${position.accuracy}m');
});

// 6. Listen to detailed NMEA data
bleService.nmeaData.listen((nmeaData) {
  print('Satellites: ${nmeaData.satellites}');
  print('Fix Quality: ${nmeaData.fixQuality}');
  print('HDOP: ${nmeaData.hdop}');
});

// 7. Disconnect when done
await bleService.disconnectDevice();
```

### Sending Commands to Device

```dart
// Send a configuration command (if needed)
await bleService.sendCommand('$PUBX,41,1,0007,0003,115200,0*10\r\n');
```

---

## Error Handling

### Common Issues and Solutions

1. **Service Not Found**
   - **Symptom**: Nordic UART Service not discovered
   - **Solution**: Implementation falls back to generic UART service detection
   - **Check**: Device may use different service UUIDs

2. **No Data Received**
   - **Symptom**: Connected but no GPS data appears
   - **Solutions**:
     - Ensure device has clear view of sky
     - Check device is powered on
     - Verify device is configured to output NMEA sentences
     - Check MTU size (may need larger MTU)

3. **Invalid NMEA Sentences**
   - **Symptom**: Data received but not parsed
   - **Solution**: Parser validates checksums and discards invalid sentences
   - **Check**: Device output format matches NMEA standard

4. **Connection Timeout**
   - **Symptom**: Connection fails after 15 seconds
   - **Solutions**:
     - Ensure device is in range
     - Check device is not already connected to another device
     - Verify Bluetooth permissions are granted

---

## Performance Considerations

### Data Throughput

- **Typical NMEA Sentence Size**: 50-100 bytes
- **Update Rate**: 1Hz (1 sentence per second) by default
- **BLE Packet Size**: 20 bytes (can be increased with MTU negotiation)
- **Buffer Management**: Handles multiple sentences per packet efficiently

### Battery Impact

- **BLE Scanning**: Moderate battery usage (limited to 20 seconds)
- **BLE Connection**: Low battery usage (efficient protocol)
- **Data Processing**: Minimal CPU usage (simple string parsing)

### Memory Usage

- **NMEA Buffer**: Small string buffer (< 1KB)
- **Stream Controllers**: Minimal overhead
- **Position Objects**: Small data structures

---

## Future Enhancements

Potential improvements for future versions:

1. **UBX Protocol Support**: Binary protocol for advanced configuration
2. **RTCM Correction Input**: Receive RTK corrections via BLE
3. **Configuration Commands**: Send UBX commands to configure receiver
4. **Data Logging**: Save NMEA sentences to file for analysis
5. **Multiple Device Support**: Connect to multiple RTK receivers simultaneously
6. **Mock Location Integration**: Use RTK data as Android mock location

---

## References

- [ArduSimple RTK Handheld 2 Product Page](https://www.ardusimple.com/product/rtk-handheld-surveyor-kit/)
- [ArduSimple User Guide](https://ardusimple.com/user-guide-rtk-portable-bluetooth-kit/)
- [NMEA Sentence Format](https://www.gpsinformation.org/dale/nmea.htm)
- [Nordic UART Service Specification](https://infocenter.nordicsemi.com/topic/sdk_nrf5_v17.1.0/ble_sdk_app_nus_eval.html)
- [u-blox ZED-F9P Documentation](https://content.u-blox.com/sites/default/files/ZED-F9P_IntegrationManual_UBX-18010802.pdf)

---

## File Structure

```
lib/ble/
├── ble_service.dart          # BLE connection and data handling
├── nmea_parser.dart          # NMEA sentence parsing
└── RTK_BLE_IMPLEMENTATION.md # This documentation file

lib/ui/screens/ble/
└── ble_screen.dart           # User interface for BLE connection and GPS display
```

---

## Summary

This implementation provides a complete solution for connecting to RTK GPS receivers via Bluetooth Low Energy and receiving real-time centimeter-accurate positioning data. The modular design separates concerns:

- **Parser**: Handles data format conversion
- **Service**: Manages BLE communication
- **UI**: Provides user interaction and data visualization

The implementation is production-ready and handles edge cases, errors, and various RTK receiver configurations.
