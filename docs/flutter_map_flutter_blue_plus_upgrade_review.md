# flutter_map & flutter_blue_plus upgrade review

**Module:** `teleferika.app`  
**Date:** 2026-05-15  
**Scope:** Current dependency versions, pub.dev changelogs, how Teleferika uses each package, and whether newer APIs are worth adopting.

---

## Executive summary

| Package | `pubspec.yaml` | Resolved (`pubspec.lock`) | Latest on pub.dev |
|---------|----------------|---------------------------|-------------------|
| `flutter_map` | `^8.2.1` | **8.2.2** | **8.3.0** |
| `flutter_blue_plus` | `^2.1.1` | **2.1.1** | **2.3.2** |

Teleferika is already on the **flutter_map 8.2** line and has adopted the main 8.2.0 tile-caching / request-abort changes (including removal of `flutter_map_cancellable_tile_provider`). The app is on **flutter_blue_plus 2.x** with the commercial-license `License` parameter on connect.

**Recommended next steps (by impact):**

1. **Patch `flutter_blue_plus` to 2.3.2** — Darwin RSSI crash fix (2.1.1, already satisfied), same-UUID services (2.3.0), and other stability fixes with low integration risk.
2. **Plan `flutter_map` 8.3.0** — Mostly bug fixes and performance; optional UX tweaks (`flingAnimationDampingRatio`, `onPointerMove`). Verify companion packages (`flutter_map_tile_caching`, `flutter_map_location_marker`, `flutter_map_compass`) before bumping.
3. **Consider selective 8.2.x APIs** without a major bump — e.g. `ContainCameraLatitude`, `CircleLayer.optimizeRadiusInMeters` (see below).

---

## Upgrade history in this repo

### flutter_blue_plus

| Version | When / commit | Notes |
|---------|---------------|-------|
| `^1.35.3` | Initial BLE (`774d184`) | Pre–2.x API and license model |
| `^2.1.0` | `4d64c5a` — feat(BLE): Upgrade flutter_blue_plus | Major bump; `License` on `connect()`, platform interface |
| `^2.1.1` | `b3b56dd` — chore: update dependencies | Darwin nil-guard on RSSI (#1318) |

### flutter_map

| Version | When / notes |
|---------|--------------|
| `^8.2.1` | Present since ~v1.1.3; lock resolves to **8.2.2** |
| 8.2.0 migration | App `CHANGELOG` **0.10.0+76** (2025-07-11): removed `flutter_map_cancellable_tile_provider`, native `NetworkTileProvider` fallback |

Related map stack (lock file):

- `flutter_map_location_marker` **10.2.0** (`^10.1.0` in pubspec)
- `flutter_map_tile_caching` **10.1.1**
- `flutter_map_compass` **1.1.1**

---

## Current usage in Teleferika

### flutter_map

**Primary file:** `lib/map/widgets/flutter_map_widget.dart`

| Area | Implementation |
|------|----------------|
| Map widget | `FlutterMap` + `MapController` |
| Tiles | `TileLayer` + `FMTCTileProvider` via `MapCacheManager`; fallback `NetworkTileProvider` + `BuiltInMapCachingProvider` (1 GB cache) |
| Attribution | `RichAttributionWidget` + `TextSourceAttribution` |
| Overlays | `PolylineLayer`, `MarkerLayer`, `MapCompass`, `CurrentLocationLayer` |
| Geometry | `Polyline` in `geometry_service.dart`, `map_controller.dart` |
| Events | `MapOptions.onMapEvent`, `mapController.mapEventStream` for zoom/rotation |
| Retina | `RetinaMode.isHighDensity(context)` when map type supports it |

**Not used today:** `PolygonLayer`, `CircleLayer`, `InteractionOptions`, `CameraConstraint` / `ContainCameraLatitude`, `MapOptions.onPointerMove`.

**Accuracy visualization:** Custom `AccuracyCirclePainter` in `lib/map/markers/location_markers.dart` (manual meters→pixels, clamped 5–50 px), not `CircleLayer`.

### flutter_blue_plus

**Primary files:** `lib/ble/ble_service.dart`, `lib/ble/ble_rtk_transport.dart`, `lib/ui/screens/ble/rtk_devices_screen.dart`, `lib/main.dart`

| Area | Implementation |
|------|----------------|
| Scanning | `FlutterBluePlus.startScan` / `stopScan`, `scanResults`, `isScanning` |
| Connect | `device.connect(license: License.free, timeout: …, autoConnect: false)` |
| GATT | `discoverServices`, Nordic UART UUIDs (short + full), `setNotifyValue`, `onValueReceived` |
| Writes | NMEA commands + RTCM (`write` / chunked `withoutResponse: true`) |
| MTU | `device.requestMtu(256)` after service discovery |
| Logging | `FlutterBluePlus.setLogLevel(LogLevel.warning)` in `main.dart` |
| Architecture | Singleton `BLEService` + `RtkDeviceService` transport abstraction (BLE / USB) |

**Not used today:** `FlutterBluePlus.setOperationQueueMode`, `androidCheckLocationServices` on scan, bonding/PIN APIs, `FlutterBluePlus.logs`.

---

## flutter_map — pub.dev changes & opportunities

### Already adopted (8.2.0+)

These match what the app changelog and code describe:

- **Built-in `NetworkTileProvider` caching** and **aborting obsolete HTTP tile requests** — fallback path in `_getTileProvider()`.
- **Removal of `flutter_map_cancellable_tile_provider`** — no longer in `pubspec.yaml`.
- **`RichAttributionWidget`** for map attribution.

### 8.2.0 features not yet used (still on 8.2.2)

| Feature | Relevance to Teleferika |
|---------|-------------------------|
| **`ContainCameraLatitude`** | **Medium** — Forest work in northern Italy stays away from poles, but constraining latitude can reduce accidental vertical panning on phones. Worth trying on `MapOptions.cameraConstraint`. |
| **`CircleLayer.optimizeRadiusInMeters`** | **Medium** — Could replace or complement `AccuracyCirclePainter` for georeferenced accuracy rings that scale correctly with zoom (today’s painter uses equator approximation and hard clamps). |
| **`PolylineLayer.oneWorld`** | **Low** — Only if polylines cross the anti-meridian. |
| **Polygon inverted fill / label placement** | **Low** — No polygon layers in the app today. |
| **Custom double-tap zoom (`InteractionOptions`)** | **Low–medium** — Fine-tune field use on gloves / rugged devices; defaults may be enough. |
| **OSM public tile server warning** | **Info** — Confirm production tile URLs comply with provider policy (Thunderforest, Esri, etc. are already used via `MapType`). |

### 8.2.2 (current lock)

- Fixes negative `TileLayer.zoomOffset` crash.
- Asserts finite `MapCamera.zoom` — helps catch bad camera state early.

### 8.3.0 (latest — not in project yet)

| Change | Opportunity |
|--------|-------------|
| **`MapOptions.onPointerMove`** | Hover-style previews on desktop/web; limited value on mobile. |
| **`InteractionOptions.flingAnimationDampingRatio`** | Tune map “feel” after fling; no `InteractionOptions` in codebase yet — add when upgrading. |
| **`TileLayer.tileBuilder` for errored tiles** | Custom placeholder / retry UI for offline or bad tiles (pairs well with FMTC). |
| **Polyline visibility / `LatLngBounds` fixes** | Free stability for dense polylines and project bounds. |
| **Tile rebuild performance (`TileKey`)** | Less jank when panning/zooming — upgrade-only win. |
| **Removed `package:logger` dependency** | Slightly leaner tree; Teleferika uses its own `logging` package anyway. |

**Companion package note:** `flutter_map_tile_caching` **10.1.1** is the latest stable; **11.0.0-dev.2** exists but is old. Before moving to `flutter_map` 8.3.0, run `flutter pub upgrade` in CI and smoke-test map tab, tile cache fallback, and offline regions. `flutter_map_location_marker` 10.2.0 already allows `flutter_map` 8.x per lock constraints.

---

## flutter_blue_plus — pub.dev changes & opportunities

### Already adopted (2.x)

| Feature | Where |
|---------|--------|
| **`License` on `connect()`** | `ble_service.dart` — `license: License.free` |
| **`onValueReceived` stream** | NMEA notify path (replaces older value APIs) |
| **`setLogLevel`** | `main.dart` |
| **Platform federation** | Transitive `flutter_blue_plus_android` 8.1.0, `darwin` 8.1.1, etc. |

### 2.1.1 → 2.3.2 (available upgrades)

| Version | Change | Teleferika impact |
|---------|--------|-------------------|
| **2.1.1** | Darwin: nil-guard RSSI (#1318) | **Already on 2.1.1** — important for RTK scan lists on iOS. |
| **2.2.x** | License tier clarifications | Review if org has **≥15 employees** — commercial license may apply (see [package license](https://pub.dev/packages/flutter_blue_plus/license)). |
| **2.3.0** | **`FlutterBluePlus.setOperationQueueMode`** — parallel writes across devices | **Low** today (single RTK connection). Useful if you add multi-peripheral workflows later. |
| **2.3.0** | **Services with duplicate UUIDs** | **Medium** — More robust `discoverServices` / characteristic lookup for non-standard RTK GATT layouts. |
| **2.3.0** | Darwin: discovery timeout when no services | **Medium** — Fewer hung connects on odd peripherals. |
| **2.3.1+** | Windows: explicit `flutter_blue_plus_winrt` dependency | **N/A** — mobile-focused app. |

### Older 1.35.x APIs still valuable (not wired up)

| API | Suggestion |
|-----|------------|
| **`androidCheckLocationServices`** on `startScan` | On Android, fail fast with a clear message if location is off (BLE scan requirement). Add in `BLEService.startScan()` before `FlutterBluePlus.startScan`. |
| **`FlutterBluePlus.logs`** | Optional debug screen or export for field support. |
| **`createBond` / pairing PIN** | Only if specific RTK hardware requires bonding (not in current flow). |

### License reminder (2.0+)

`flutter_blue_plus` 2.x uses the **FlutterBluePlus license**, not MIT. The app correctly passes `License.free` for development/small org use. Confirm compliance with your organization size before distributing production builds.

---

## Suggested adoption roadmap

### Quick wins (low risk)

1. **Bump `flutter_blue_plus` to `^2.3.2`** and run BLE regression on a physical RTK device (scan, connect, NMEA, NTRIP/RTCM write). See in-code `TODO(device-test)` in `ble_service.dart`.
2. **Add `androidCheckLocationServices: true`** (or handle the scan error in UI) on Android scans.
3. **Stay on `flutter_map` 8.2.2** until companion packages are verified; cherry-pick docs-only awareness of 8.2.2 zoom assertions.

### Medium effort (map UX / correctness)

1. **Evaluate `ContainCameraLatitude`** on project map screens (trial on `MapOptions` in `flutter_map_widget.dart`).
2. **Prototype `CircleLayer`** with `optimizeRadiusInMeters: true` for GPS accuracy instead of fixed pixel clamps — compare visually with `AccuracyCirclePainter` at high latitude (Alps).
3. **Upgrade to `flutter_map` 8.3.0** in a dedicated PR: add `InteractionOptions(flingAnimationDampingRatio: …)` if field testers want snappier/slower fling; consider `tileBuilder` for failed tiles when FMTC store is missing.

### Defer / low priority

- `setOperationQueueMode` — until multiple simultaneous BLE devices are required.
- `PolylineLayer.oneWorld`, polygon label APIs — no current use case.
- Windows WinRT split — not a target platform.

---

## Verification checklist (after any bump)

### Map (`flutter_map`)

- [ ] Map tab loads all `MapType` variants (OSM, satellite, topo, Thunderforest).
- [ ] Offline / FMTC cache and **fallback** `NetworkTileProvider` when store fails.
- [ ] Zoom controls, rotation, compass, location marker, polyline + markers.
- [ ] Move-point and long-press slide interactions (`projectAtZoom` / `unprojectAtZoom`).
- [ ] Retina tiles on high-DPI devices where enabled.

### BLE (`flutter_blue_plus`)

- [ ] Permissions flow on Android and iOS (`RtkDevicesScreen`).
- [ ] Scan timeout (20 s) and stop on connect.
- [ ] Connect → NMEA on notify → `gpsData` / map BLE source switch.
- [ ] RTCM forward to receiver during NTRIP session.
- [ ] Unexpected disconnect handling and UI state on `RtkDevicesScreen`.
- [ ] USB path still works (unchanged by FBP, but same screen).

---

## References

- [flutter_map changelog](https://pub.dev/packages/flutter_map/changelog) — 8.2.0–8.3.0
- [flutter_map — What's new in v8.2](https://docs.fleaflet.dev/getting-started/new-in-v8)
- [flutter_blue_plus changelog](https://pub.dev/packages/flutter_blue_plus/changelog) — 2.0.0–2.3.2
- In-repo: `teleferika.app/CHANGELOG.md` (0.10.0+76 FlutterMap 8.2.0 migration)
- In-repo: `teleferika.app/lib/map/widgets/flutter_map_widget.dart`, `teleferika.app/lib/ble/ble_service.dart`
