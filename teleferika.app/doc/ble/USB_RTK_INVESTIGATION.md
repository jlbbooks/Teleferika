# USB Connection for RTK Device – Investigation

## Summary

**USB connection to the RTK device is feasible on Android** using the existing NMEA/NTRIP data flow. The same app logic (NMEA in, RTCM/commands out) can run over a USB serial link. **iOS does not support USB host for serial devices**, so USB would be Android-only; BLE remains the option for iOS.

---

## Current Architecture

- **BLE (Nordic UART)**  
  - **In:** NMEA sentences from device → `_handleReceivedData` → `_processNMEASentence` → `gpsData` / `nmeaData` streams.  
  - **Out:** `sendData` / `sendCommand` / `forwardRtcmData` → BLE RX characteristic.  
- **NTRIP:** App connects to caster on the phone and forwards RTCM to the device via the same BLE write path.
- **UI:** `BLEService.instance` used everywhere (connect, disconnect, `gpsData`, `nmeaData`, `connectToNtrip`, etc.).

For USB we need the **same logical channel**: one bidirectional serial stream (NMEA in, RTCM + commands out), with the same streams and methods so NTRIP and UI can stay unchanged.

---

## Platform Support

| Platform | USB serial support | Notes |
|----------|--------------------|--------|
| **Android** | Yes | USB Host API (OTG). App is host, RTK device is USB device. Requires USB serial chip (FTDI, CP210x, CH340, CDC-ACM, etc.) on the device. |
| **iOS** | No | No USB host for arbitrary serial devices. No standard API for “USB serial” like Android. BLE remains the only option on iPhone/iPad. |

So: **implement USB on Android only**; keep BLE as the only transport on iOS.

---

## Recommended Package: `usb_serial`

- **Package:** [usb_serial](https://pub.dev/packages/usb_serial) (e.g. `usb_serial: ^0.5.2`).
- **Supports:** FTDI, CDC-ACM, and other common USB‑serial chips (CP210x, CH340, etc.) used on RTK hardware.
- **API:** Async; list devices → create port → open → set baud (e.g. 115200) → read from `port.inputStream`, write with `port.write()`.
- **Android:** Optional device filter (e.g. `res/xml/device_filter.xml`) + intent filter in `AndroidManifest.xml` to detect attachment of relevant USB devices.

**Alternative:** `usb_serial_communication` or `flutter_serial_communication` if you need different driver coverage or API style; the design below is transport-agnostic.

---

## Data Flow (Same as BLE)

- **From device (USB serial in):**  
  Raw bytes → decode as UTF-8 → split NMEA lines → `NMEAParser.parseSentence` → `gpsData` / `nmeaData`.  
  (Reuse the same NMEA parsing and RTCM-skip logic as in `_handleReceivedData`.)
- **To device (USB serial out):**  
  `sendCommand` / `sendData` / `forwardRtcmData` → write bytes to the USB serial port.  
  For RTCM, chunking (e.g. 200-byte chunks) is less critical than on BLE but can be kept for consistency.

Baud rate: **115200** (or 38400 for older kits), matching your RTK doc.

---

## Architecture Options

### Option A – Transport abstraction (recommended long-term)

- Define an interface, e.g. `RtkDeviceTransport`, with:
  - Connection: `connect`, `disconnect`, `connectionState` stream, current device/port info.
  - Data in: `gpsData`, `nmeaData` (same types as now).
  - Data out: `sendData(List<int>)`, `sendCommand(String)`, `forwardRtcmData(List<int>)`.
- Implement:
  - `BleRtkTransport` – wraps current `BLEService` (same NMEA/RTCM behavior).
  - `UsbSerialRtkTransport` – uses `usb_serial` (or another package); implements same interface; Android-only.
- Single entry point (e.g. `RtkDeviceService` or `BLEService` refactored) that holds the active transport and exposes the same API. NTRIP and all UI keep using this entry point; they don’t care whether the backend is BLE or USB.

**Pros:** One place for NTRIP and UI logic; easy to add more transports later.  
**Cons:** Requires refactoring `BLEService` into a transport and a facade.

### Option B – Separate USB service (faster to ship)

- Add `UsbSerialService` (or `UsbRtkService`) that mirrors the **public** API used by the UI and NTRIP:
  - `connect(device/port)`, `disconnect`, `connectionState`, `gpsData`, `nmeaData`, `sendData`, `sendCommand`, `forwardRtcmData`, `connectToNtrip`, etc.
- Internally: use `usb_serial` to open port, read bytes → same NMEA parsing pipeline (reuse `NMEAParser` and the same stream types).
- UI: “Connect via Bluetooth” vs “Connect via USB”; only one active at a time. When USB is selected, use `UsbSerialService`; when BLE, use `BLEService` (or a thin wrapper so call sites stay identical).

**Pros:** Minimal change to existing BLE code; USB can be added behind a single “USB” entry point.  
**Cons:** Some duplication (two services, two connection flows in UI) until you later refactor to Option A.

### Option C – Single service, internal BLE vs USB

- Extend `BLEService` (or rename to `RtkDeviceService`) to support both:
  - Either connect to a BLE device **or** to a USB serial device (one at a time).
  - Internal state: “current transport” = BLE or USB; all `gpsData`/`nmeaData`/`sendData`/`forwardRtcmData` delegate to the active transport.

Same idea as Option A but without a formal interface; more conditionals inside one class. Possible but Option A is cleaner.

**Recommendation:** Implement **Option B** first (USB as a second service, Android-only) to get USB working quickly; then, if you want a single “RTK device” concept and less duplication, refactor to **Option A** (transport interface + `BleRtkTransport` + `UsbSerialRtkTransport`).

---

## Android Setup (when you add USB)

1. **Dependency:** e.g. `usb_serial: ^0.5.2` in `pubspec.yaml`.
2. **Manifest:**  
   - No extra permission for USB host (handled by the plugin).  
   - Optional: add an `<intent-filter>` for `android.hardware.usb.action.USB_DEVICE_ATTACHED` and a `meta-data` pointing to `res/xml/device_filter.xml` so the app can be launched or notified when the RTK USB device is plugged in.
3. **Device filter (optional):** In `res/xml/device_filter.xml`, list USB vendor/product IDs for the RTK’s serial chip (FTDI, Silicon Labs CP210x, CH340, etc.) if you want automatic detection. Otherwise you can list devices in-app without the intent filter.
4. **Runtime:** List devices with `UsbSerial.listDevices()`, let user select, then `device.create()` → `port.open()` with baud 115200 (or 38400), then wire `port.inputStream` into your NMEA pipeline and use `port.write()` for send/RTCM.

---

## Implementation Checklist (Option B)

- [ ] Add `usb_serial` (or chosen package) to `pubspec.yaml`.
- [ ] Implement `UsbSerialService` (Android-only, e.g. with `dart:io` Platform or conditional export):
  - [ ] List USB serial devices.
  - [ ] Open port at 115200 (or configurable) and keep reference.
  - [ ] Read from `port.inputStream` → push bytes through the same NMEA parsing and buffer logic as BLE (reuse `NMEAParser` and avoid duplicating `_handleReceivedData`; either share a helper or copy the logic once).
  - [ ] Expose `gpsData`, `nmeaData`, `connectionState` with the same types as `BLEService`.
  - [ ] Implement `sendData`, `sendCommand`, `forwardRtcmData` via `port.write()`, with optional RTCM chunking.
  - [ ] Implement `connectToNtrip` the same way as BLE: require “device connected” (here: USB port open), then use existing NTRIP client and forward RTCM to `forwardRtcmData`.
- [ ] Android: add USB device filter (optional) and intent filter if you want “plug and open app”.
- [ ] UI: add “USB” as a connection mode (e.g. on BLE screen or a small “Connection: Bluetooth | USB” selector). When USB is selected, show a list of USB serial devices and connect via `UsbSerialService`; when Bluetooth, keep current `BLEService` flow. Ensure only one of BLE or USB is connected at a time.
- [ ] Hide or disable USB option on iOS (no USB serial support).
- [ ] Test: connect RTK via USB, verify NMEA in (position/fix), then connect to NTRIP and verify RTCM forwarding and RTK fix.

---

## References

- Current BLE/NTRIP flow: `lib/ble/ble_service.dart`, `lib/ble/ntrip_client.dart`, `lib/ui/screens/ble/ble_screen.dart`.
- RTK connection methods (USB vs BLE): `lib/ble/RTK_BLE_IMPLEMENTATION.md` (section “Connection Methods Supported”).
- NMEA parsing: `lib/ble/nmea_parser.dart` (reuse for USB).
- [usb_serial on pub.dev](https://pub.dev/packages/usb_serial) – API and device filter examples.
