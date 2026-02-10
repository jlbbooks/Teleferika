# TODO List

## Device testing (when device is available)

- [ ] **Test BLE data path** with physical RTK/BLE device: `lib/ble/ble_service.dart` — `_handleReceivedData` (Uint8List, cached regex, Latin1) not yet validated on device. See `TODO(device-test)` in that file.

## Background NTRIP Connection

### Keep NTRIP connection running when app is minimized

- [ ] **Android Background Service**
  - [ ] Implement foreground service for NTRIP connection to prevent Android from killing the connection
  - [ ] Add notification channel and persistent notification showing NTRIP connection status
  - [ ] Handle Android battery optimization restrictions
  - [ ] Test connection stability when app is in background for extended periods
  - [ ] Implement wake lock management to prevent device sleep from interrupting connection

- [ ] **iOS Background Modes**
  - [ ] Configure background modes in Info.plist for background processing
  - [ ] Implement background task handling for NTRIP connection
  - [ ] Handle iOS background execution time limits
  - [ ] Test connection stability when app enters background state
  - [ ] Implement background fetch or background processing as needed

- [ ] **Connection State Management**
  - [ ] Ensure NTRIP client maintains connection state when app is backgrounded
  - [ ] Implement connection state persistence to survive app lifecycle changes
  - [ ] Add reconnection logic for when connection drops in background
  - [ ] Handle network state changes (WiFi/cellular switching) in background
  - [ ] Monitor connection health and automatically reconnect if needed

- [ ] **RTCM Data Handling**
  - [ ] Ensure RTCM data continues to be received and processed in background
  - [ ] Buffer RTCM data if processing is delayed due to background constraints
  - [ ] Forward RTCM corrections to BLE device even when app is minimized
  - [ ] Handle data flow when app transitions between foreground/background

- [ ] **User Experience**
  - [ ] Add UI indicator showing background connection status
  - [ ] Provide user control to enable/disable background NTRIP connection
  - [ ] Show notification with connection status and data statistics
  - [ ] Handle user returning to app - ensure UI reflects current connection state
  - [ ] Add settings option for background connection behavior

- [ ] **Testing**
  - [ ] Test connection stability during app minimization
  - [ ] Test connection recovery after app is killed by system
  - [ ] Test battery impact of background connection
  - [ ] Test on various Android versions (especially Android 12+ with background restrictions)
  - [ ] Test on various iOS versions (especially iOS 13+ with background execution limits)
  - [ ] Test with different network conditions (WiFi, cellular, network switching)

- [ ] **Documentation**
  - [ ] Document background connection behavior and limitations
  - [ ] Add user guide for background NTRIP connection feature
  - [ ] Document battery usage implications
  - [ ] Document platform-specific requirements and permissions
