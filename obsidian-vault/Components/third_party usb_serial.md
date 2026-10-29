---
tags:
  - component
  - android
aliases:
  - usb_serial
---

# third_party usb_serial

Local fork of `usb_serial` under `teleferika.app/third_party/usb_serial`.

**Why:** patched for Gradle 9 (e.g. remove `jcenter()`). Used by [[BLE RTK]] USB transport (`UsbSerialService` / `UsbSerialRtkTransport`).

See package `PATCHES.md` / `CHANGELOG.md` in that folder.
