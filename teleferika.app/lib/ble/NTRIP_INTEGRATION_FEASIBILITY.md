# NTRIP Integration Feasibility Report

## Executive Summary

**Yes, NTRIP integration is feasible**, but requires implementing an NTRIP client in Dart/Flutter since no ready-made package exists. The implementation would allow the app to receive RTK corrections from NTRIP casters (like RTK2go) and forward them to the RTK device via BLE.

## What is NTRIP?

**NTRIP** (Networked Transport of RTCM via Internet Protocol) is a protocol for streaming RTCM (Radio Technical Commission for Maritime Services) correction data from base stations to rover devices over the internet. This enables RTK positioning without requiring a local base station.

### RTK2go Service Details

Based on [rtk2go.com](http://rtk2go.com/):

- **Service**: Free community NTRIP caster
- **Connection**: `rtk2go.com:2101` (or IP `3.143.243.81:2101`)
- **SSL/TLS**: `3.143.243.81:2102`
- **Username**: Valid email address (required)
  - Can use `-at-` instead of `@` if device doesn't support it
  - Can use `-d-` instead of `.` if needed
- **Password**: `"none"`
- **Mount Points**: 800+ free base stations available
- **Status**: Operational, 150,000-250,000 connections per day

## Current Architecture

### What We Have Now

1. **BLE Connection**: App connects to RTK device via Bluetooth Low Energy
2. **NMEA Data Reception**: Receives GPS position data in NMEA format
3. **Data Parsing**: Parses NMEA sentences (GPGGA, GPRMC) to extract position
4. **UI Display**: Shows GPS data, fix quality, accuracy, etc.
5. **BLE Data Sending**: Already has `sendCommand()` and `sendData()` methods via RX characteristic

### What's Missing

1. **NTRIP Client**: No implementation to connect to NTRIP casters
2. **RTCM Handling**: No code to receive/parse RTCM correction messages
3. **Correction Forwarding**: Need to implement RTCM data forwarding via existing BLE send methods

## Integration Approaches

### Approach 1: App as NTRIP Client (Recommended)

**How it works:**
1. App connects to NTRIP caster (e.g., RTK2go) using phone's internet
2. App receives RTCM correction data from NTRIP caster
3. App forwards RTCM data to RTK device via BLE (RX characteristic)
4. RTK device applies corrections and achieves RTK fix

**Advantages:**
- Uses phone's internet connection (WiFi or cellular)
- RTK device doesn't need internet connectivity
- Full control over NTRIP connection
- Can switch between different NTRIP casters
- Can cache/store corrections

**Disadvantages:**
- Requires implementing NTRIP protocol in Dart
- Need to handle RTCM message forwarding
- More complex implementation

**Implementation Requirements:**
- NTRIP client protocol implementation
- TCP socket connection to NTRIP caster
- HTTP-style authentication (username/password)
- RTCM message parsing/validation
- BLE data forwarding to device

### Approach 2: RTK Device Handles NTRIP (If Supported)

**How it works:**
1. RTK device connects to NTRIP caster directly (if it has WiFi/cellular)
2. Device receives corrections internally
3. App only receives final position data via BLE

**Advantages:**
- Simpler app implementation
- Device handles all NTRIP complexity
- No app changes needed

**Disadvantages:**
- Requires RTK device to have internet connectivity
- Device must support NTRIP client functionality
- Less control over connection
- May require device configuration via UBX commands

**Current Status:**
- Unknown if RTK Handheld 2 Mapping Kit supports NTRIP client mode
- Would need to check device documentation or test UBX configuration commands

## NTRIP Protocol Overview

### Connection Flow

1. **TCP Connection**: Connect to NTRIP caster on port 2101 (or 2102 for SSL)
2. **HTTP-Style Request**: Send GET request with authentication
   ```
   GET /<mountpoint> HTTP/1.0\r\n
   User-Agent: NTRIP ClientName/Version\r\n
   Authorization: Basic <base64(username:password)>\r\n
   \r\n
   ```
3. **Response**: Receive HTTP response (200 OK for success)
4. **RTCM Stream**: Receive binary RTCM messages continuously
5. **Keep-Alive**: Maintain connection, handle reconnection

### Mount Point Selection

- **Source Table Request**: `GET / HTTP/1.0` returns list of available mount points
- **Mount Point Format**: Base station identifier (e.g., `AUTO`, `STR2`, etc.)
- **Selection**: Choose nearest base station or specific one

### RTCM Messages

- **Format**: Binary RTCM 3.x messages
- **Message Types**: Various correction message types (1001-1009, 1010-1012, etc.)
- **Forwarding**: Send raw RTCM bytes to RTK device via BLE

## Implementation Plan

### Phase 1: NTRIP Client Core

1. **Create `ntrip_client.dart`**:
   - TCP socket connection to NTRIP caster
   - HTTP-style authentication
   - Source table request/parsing
   - Mount point selection
   - RTCM data stream reception

2. **Dependencies**:
   - `dart:io` for TCP sockets
   - `dart:convert` for base64 encoding
   - Existing `http` package (optional, for source table parsing)

### Phase 2: RTCM Forwarding

1. **Create `rtcm_forwarder.dart`**:
   - Receive RTCM messages from NTRIP client
   - Validate RTCM message format
   - Forward to RTK device via BLE RX characteristic
   - Handle message fragmentation (BLE MTU limits)

2. **Integration with BLEService**:
   - Add method to send RTCM data
   - Handle large messages (split if needed)
   - Queue messages if device not ready

### Phase 3: UI Integration

1. **NTRIP Settings Screen**:
   - Caster URL/IP input
   - Port selection (2101 or 2102)
   - Username (email) input
   - Password input (default: "none")
   - Mount point selection (with source table)
   - Connection status indicator

2. **BLE Screen Updates**:
   - Show NTRIP connection status
   - Display selected mount point
   - Show correction data reception rate
   - Indicate when RTK fix is achieved

### Phase 4: Error Handling & Reliability

1. **Connection Management**:
   - Automatic reconnection on disconnect
   - Connection timeout handling
   - Network error recovery

2. **Data Validation**:
   - RTCM message checksum validation
   - Message type verification
   - Data integrity checks

## Technical Challenges

### 1. No Existing Dart NTRIP Package

**Challenge**: No ready-made NTRIP client package for Dart/Flutter

**Solution**: 
- Implement NTRIP protocol from scratch (relatively simple HTTP-style protocol)
- Reference NTRIP specification (RFC or implementation guides)
- Use existing TCP socket libraries (`dart:io`)

### 2. RTCM Message Handling

**Challenge**: RTCM messages are binary format, need proper parsing

**Solution**:
- Use existing RTCM parsing libraries if available
- Or implement basic RTCM message structure (header, data, checksum)
- Forward messages as-is to device (device handles parsing)

### 3. BLE Message Size Limits

**Challenge**: RTCM messages can be large, BLE has MTU limits (typically 20-517 bytes)

**Solution**:
- Split large RTCM messages into smaller chunks
- Send chunks sequentially via BLE
- Device reassembles messages (if supported)
- Or use write-without-response for better throughput

### 4. Network Connectivity

**Challenge**: App needs reliable internet connection

**Solution**:
- Check network connectivity before connecting
- Handle network changes gracefully
- Provide user feedback on connection status
- Support both WiFi and cellular

### 5. Battery Impact

**Challenge**: Continuous NTRIP connection and BLE forwarding consumes battery

**Solution**:
- Allow user to enable/disable NTRIP corrections
- Optimize data forwarding (batch if possible)
- Monitor battery level and warn user

## Estimated Implementation Effort

### Minimum Viable Product (MVP)

- **NTRIP Client Core**: 2-3 days
- **RTCM Forwarding**: 1-2 days
- **Basic UI**: 1-2 days
- **Testing & Debugging**: 2-3 days

**Total**: ~1-2 weeks for basic functionality

### Full Featured Implementation

- **Advanced error handling**: +1-2 days
- **Source table UI**: +1 day
- **Connection management**: +1 day
- **Settings persistence**: +1 day
- **Comprehensive testing**: +2-3 days

**Total**: ~2-3 weeks for production-ready feature

## Recommended Next Steps

1. **Research RTK Device Capabilities**:
   - Check if device supports receiving RTCM corrections via BLE
   - Verify UBX protocol support for NTRIP configuration
   - Test if device can process forwarded RTCM messages

2. **Prototype NTRIP Client**:
   - Implement basic NTRIP connection to RTK2go
   - Test connection and data reception
   - Verify RTCM message format

3. **Test RTCM Forwarding**:
   - Send test RTCM messages to device via BLE
   - Verify device accepts and processes corrections
   - Check if RTK fix quality improves

4. **Full Implementation**:
   - Build complete NTRIP client
   - Integrate with existing BLE service
   - Create UI for configuration and status

## Alternative: Use Existing Libraries

### Flutter RTKLIB

There's a Flutter RTKLIB implementation available:
- **GitHub**: [IgorKilipenko/flutter_rtklib](https://github.com/IgorKilipenko/flutter_rtklib)
- **Status**: May include NTRIP client functionality
- **Consideration**: Evaluate if it meets our needs or can be adapted

### Platform Channels

- Wrap existing C/C++ NTRIP libraries via platform channels
- More complex but leverages proven implementations
- Requires native code maintenance

## Research Findings: RTK Handheld 2 Mapping Kit

Based on research of the [ArduSimple RTK Handheld 2 Mapping Kit](https://www.ardusimple.com/product/rtk-handheld-surveyor-kit/):

### Device Capabilities ✅

1. **ZED-F9P Chip**: Uses u-blox ZED-F9P RTK receiver
   - Supports RTCM corrections via UART/serial ports
   - Can receive corrections while simultaneously sending NMEA data
   - Multiple communication ports (USB, UART1, UART2, I2C, SPI)

2. **BT+BLE Bridge Module**: 
   - Provides bidirectional BLE communication
   - Uses Nordic UART Service (NUS) - same as our current implementation
   - Pre-configured to send NMEA data via BLE

3. **RTCM Reception via BLE**: ✅ **CONFIRMED**
   - SW Maps app (recommended by ArduSimple) acts as NTRIP client
   - SW Maps receives RTCM corrections from NTRIP caster
   - SW Maps forwards RTCM corrections to device via **the same BLE connection**
   - Device processes RTCM corrections and achieves RTK fix
   - This proves the device CAN receive RTCM corrections via BLE!

### How It Works (SW Maps Example)

1. App connects to RTK device via BLE (Nordic UART Service)
2. App connects to NTRIP caster (e.g., RTK2go) using phone's internet
3. App receives RTCM correction stream from NTRIP caster
4. App forwards RTCM binary data to device via BLE RX characteristic
5. Device applies corrections and achieves centimeter-level RTK fix
6. Device sends updated NMEA data back via BLE TX characteristic

### Current Implementation Status

Our existing `BLEService` already has:
- ✅ BLE connection established
- ✅ RX characteristic identified (`_rxCharacteristic`)
- ✅ `sendCommand()` and `sendData()` methods implemented
- ✅ Bidirectional communication via Nordic UART Service

**What we need to add:**
- NTRIP client to connect to casters
- RTCM data reception and forwarding
- UI for NTRIP configuration

## Conclusion

**NTRIP integration is definitely feasible and confirmed to work!** 

The RTK Handheld 2 Mapping Kit **CAN receive RTCM corrections via BLE**, as proven by SW Maps app which uses the exact same approach we're planning. The implementation requires:

1. Building an NTRIP client in Dart (moderate complexity)
2. Forwarding RTCM data to RTK device via existing BLE `sendData()` method (straightforward)
3. UI for configuration and status (standard Flutter development)

The device architecture supports this workflow, and our existing BLE implementation already has the necessary infrastructure for bidirectional communication.

## References

- [RTK2go Website](http://rtk2go.com/)
- [NTRIP Protocol Specification](https://www.use-snip.com/kb/knowledge-base/)
- [RTK Corrections Explained](https://blog.emlid.com/rtk-corrections-explained-from-base-station-to-ntrip-service/)
- [Flutter RTKLIB](https://github.com/IgorKilipenko/flutter_rtklib)
