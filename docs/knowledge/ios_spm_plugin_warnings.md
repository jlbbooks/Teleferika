# iOS Swift Package Manager plugin warnings

Status as of **2026-10-29** (Flutter **3.47.8** / SPM on by default since 3.44).

## What you see

```text
The following plugins do not support Swift Package Manager for ios:
  - compassx
  - objectbox_flutter_libs
This will become an error in a future version of Flutter.
```

Archive / `flutter build ios` still succeeds today: Flutter falls back to **CocoaPods** for plugins without SPM.

## Conclusions (do not “fix” in-app)

| Plugin | Source | Why it warns | Easy app-side fix? |
|--------|--------|--------------|--------------------|
| **compassx** | Direct dep (`pubspec.yaml`) | CocoaPods-only; last pub **1.0.1** (May 2024); no `Package.swift` | **No** — needs upstream SPM, a fork with SPM, or a package swap |
| **objectbox_flutter_libs** | Transitive via **flutter_map_tile_caching** (`objectbox: ^4.1.0` → locked **4.3.1**) | SPM only in **objectbox_flutter_libs 6.0.0-preview.5**; stable **5.3.2** still CocoaPods-only | **No** — FMTC still pins ObjectBox **^4.1.0**, so the SPM preview cannot be taken without forking/replacing FMTC |

## What not to do

- Do **not** turn off SPM project-wide (`flutter.config.enable-swift-package-manager: false`) just to silence this. CocoaPods registry goes read-only **2026-12-02**; disabling SPM is a temporary escape hatch, not a fix.
- Do **not** block releases on this warning while builds still succeed.

## Realistic unblock path

1. Wait for **ObjectBox 6** stable **and** a **flutter_map_tile_caching** release that allows it.
2. For compass: upstream SPM support, a small local/git fork with `Package.swift`, or migrate to an SPM-capable compass plugin (API change).

## Related build gotcha (Archive version)

Xcode Archive reads `ios/Flutter/Generated.xcconfig` (`FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER`), **not** `pubspec.yaml` directly. After bumping `version:` in `pubspec.yaml`, regenerate before Archive:

```bash
fvm flutter build ios --flavor full --config-only --release
```
