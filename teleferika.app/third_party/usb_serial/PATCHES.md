# Patches applied to usb_serial 0.5.2

Vendored from [pub.dev usb_serial 0.5.2](https://pub.dev/packages/usb_serial) / [altera2015/usbserial](https://github.com/altera2015/usbserial).

## Gradle 9: replace `jcenter()` with `mavenCentral()`

Stock `android/build.gradle` calls `jcenter()`, which was removed in Gradle 9. That breaks configuration of `:usb_serial` and surfaces as a Flutter “AGP 9 newDsl” false positive.

Changed both repository blocks in `android/build.gradle` from `jcenter()` to `mavenCentral()`. JitPack (for `com.github.felHR85:UsbSerial`) is unchanged.
