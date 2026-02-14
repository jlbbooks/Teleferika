# 16 KB page size support (Android)

Google Play requires apps targeting **Android 15 (API 35)** or later to support **16 KB memory page sizes** (policy in effect from **November 2025**). This project is configured for 16 KB compatibility.

## What we have in place

| Requirement              | Status |
|--------------------------|--------|
| **Flutter** 3.32+        | ✓ Using 3.41.1 — engine `libflutter.so` has 16 KB support since 3.24.1 |
| **AGP** 8.5.1+           | ✓ Using 8.13.2 — aligns native libs for 16 KB |
| **Gradle** 8.5+          | ✓ Using 8.14.4 |
| **NDK** r28+ (for builds) | ✓ Using `flutter.ndkVersion` (Flutter 3.41 ships NDK that supports 16 KB) |
| **JNI packaging**        | ✓ `packaging.jniLibs.useLegacyPackaging = false` in `app/build.gradle.kts` so `.so` files are not legacy-packed and stay page-aligned |

No custom native code (no `externalNativeBuild` / CMake) is used in this app; Flutter and plugins supply the native libs. The packaging option above ensures the APK/AAB is built in a 16 KB–friendly way.

## How to verify

1. **Build**  
   From `teleferika.app`:
   ```bash
   flutter clean && flutter pub get
   flutter build appbundle
   ```
   Or build an APK and install on a device/emulator.

2. **Test on a 16 KB device/emulator**  
   - In Android Studio: create an AVD with a **“Google APIs Experimental 16k Page Size ARM 64”** (or similar) system image if available.  
   - Install and run the app; exercise main flows (BLE, USB, maps, etc.). Crashes or load failures can indicate a plugin shipping a non–16 KB–aligned `.so` (see below).

3. **Play Console**  
   After uploading an AAB that targets Android 15+, use any “Pre-launch report” or device compatibility checks. Play may also show warnings for apps that don’t meet the 16 KB policy.

## If something fails

- **Flutter engine** — Already 16 KB–capable; no change needed.
- **Plugins with native code** — Some packages (e.g. `flutter_blue_plus`, `usb_serial`, `sqflite`) ship `.so` files. They must be built with NDK r28+ or with flexible page size support. If you see load/crash issues only on 16 KB devices/emulators, check for updates or open issues on those packages.
- **Custom native code** — If you add `externalNativeBuild` (CMake/NDK) later, use NDK r28+ and pass `-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON` in CMake arguments.

## References

- [Flutter issue #150168 – 16KB Page Sizes support](https://github.com/flutter/flutter/issues/150168)
- [Android: 16 KB page sizes](https://developer.android.com/guide/practices/page-sizes) (and linked docs)
- Play policy: support for 16 KB page sizes when targeting Android 15+ (Nov 2025+)
