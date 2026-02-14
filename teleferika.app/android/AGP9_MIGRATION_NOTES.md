# AGP 9 migration notes

We tried upgrading to **Android Gradle Plugin 9.0.1** and **Gradle 9.1.0**. The project was reverted to **AGP 8.13.2** and **Gradle 8.14.4** due to plugin compatibility.

## What was tried

1. **settings.gradle.kts** – AGP `9.0.1`, Gradle wrapper `9.1.0`.
2. **gradle.properties** – `android.newDsl=false` (Flutter still uses old DSL), `android.builtInKotlin=false` (so plugins can apply `kotlin-android`).
3. **app/build.gradle.kts** – `buildFeatures.resValues = true` (required in AGP 9 for product flavor `resValue()`).
4. With **built-in Kotlin disabled**, the Kotlin plugin was re-applied so Flutter plugins that use `kotlin-android` could run.

## Blockers

1. **`device_info_plus` (and similar)**  
   With AGP 9 built-in Kotlin enabled, plugins that apply `org.jetbrains.kotlin.android` fail with:  
   `Cannot add extension with name 'kotlin', as there is an extension already registered with that name.`  
   Using `android.builtInKotlin=false` avoids this.

2. **`usb_serial`**  
   The plugin’s `android/build.gradle` calls `repositories { jcenter() }`.  
   **jcenter() was removed in Gradle 9**, so the build fails with:  
   `Could not find method jcenter() for arguments []`.  
   Use the fork/patch below to get a Gradle-9-compatible version.

---

## usb_serial: Gradle 9–compatible options

### Status of official package

- **pub.dev:** [usb_serial](https://pub.dev/packages/usb_serial) **0.5.2** (latest, 19 months old). No update that removes jcenter.
- **Repo:** [altera2015/usbserial](https://github.com/altera2015/usbserial). The Android dependency is `com.github.felHR85:UsbSerial:6.1.0` from **JitPack**, not jcenter. Replacing `jcenter()` with `mavenCentral()` in the plugin’s `android/build.gradle` is enough for Gradle 9.

### Option A: Fork and git dependency (recommended)

1. Fork [altera2015/usbserial](https://github.com/altera2015/usbserial) (e.g. to your GitHub).
2. In the fork, edit **android/build.gradle**:
   - In both `buildscript { repositories { ... } }` and `rootProject.allprojects { repositories { ... } }`, remove the `jcenter()` line and ensure you have `mavenCentral()` (and keep `google()` and the existing `maven { url "https://jitpack.io" }`).
3. In **teleferika.app/pubspec.yaml**, point to your fork:

   ```yaml
   dependencies:
     usb_serial:
       git:
         url: https://github.com/YOUR_USERNAME/usbserial.git
         ref: main   # or the branch you fixed
   ```

4. Run `flutter pub get`. Your app will use the forked plugin; no change to Dart code.

### Option B: Local path dependency (patched copy)

1. Clone the repo: `git clone https://github.com/altera2015/usbserial.git` into a folder next to your app (e.g. `../usbserial`).
2. Apply the same **android/build.gradle** change as in Option A (replace jcenter with mavenCentral).
3. In **pubspec.yaml**:

   ```yaml
   dependencies:
     usb_serial:
       path: ../usbserial
   ```

4. Run `flutter pub get`. Your Dart code stays the same.

### Option C: Alternative package (API differs)

- **[usb_serial_for_android](https://pub.dev/packages/usb_serial_for_android)** (0.0.9, 3 years old, 44 downloads) uses [mik3y/usb-serial-for-android](https://github.com/mik3y/usb-serial-for-android) and a different API (platform interface). It would require rewriting `UsbSerialService` and related code; not a drop-in replacement.
- **flusbserial** is for **desktop** (Windows/Linux/macOS) only, not Android.

### Exact build.gradle fix for usb_serial

In **android/build.gradle** of the plugin, use this (or equivalent) so Gradle 9 works:

**Buildscript block:** use `mavenCentral()` instead of `jcenter()`:

```groovy
buildscript {
  repositories {
    google()
    mavenCentral()
  }
  dependencies {
    classpath 'com.android.tools.build:gradle:4.1.0'
  }
}
```

**rootProject.allprojects block:** use `mavenCentral()` instead of `jcenter()`:

```groovy
rootProject.allprojects {
  repositories {
    google()
    mavenCentral()
    maven { url "https://jitpack.io" }
  }
  // ... rest unchanged
}
```

A ready-made patch file is in **android/patches/usb_serial_jcenter_to_mavencentral.patch** (if you use `patch -p1` from the plugin root).

---

## When retrying AGP 9

- Ensure **usb_serial** (and any other plugin using `jcenter()`) is updated or replaced.
- Use **Gradle 9.1.0** (URL: `gradle-9.1.0-bin.zip`).
- In **gradle.properties** set:
  - `android.newDsl=false`
  - `android.builtInKotlin=false` (until all plugins support AGP 9 built-in Kotlin).
- In **app/build.gradle.kts** set `buildFeatures.resValues = true` if you use product flavor `resValue()`.
- Official Flutter notes: https://docs.flutter.dev/release/breaking-changes/migrate-to-agp-9
