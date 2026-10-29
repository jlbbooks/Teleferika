---
tags:
  - development
  - ios
  - flutter
  - known-issue
aliases:
  - SPM warnings
  - compassx SPM
  - objectbox SPM
---

# iOS SPM Plugin Warnings

Authoritative note: `docs/knowledge/ios_spm_plugin_warnings.md`.

## Summary

Build warns that **compassx** and **objectbox_flutter_libs** lack Swift Package Manager support. **Not easily fixable** in-app: compassx is unmaintained for SPM; objectbox SPM needs v6 preview, blocked by **flutter_map_tile_caching**’s `objectbox: ^4.1.0` pin. CocoaPods fallback still works — don’t disable SPM just to silence the warning; don’t block releases on it.

Also: after a `pubspec` version bump, refresh `ios/Flutter/Generated.xcconfig` before Xcode Archive (`flutter build ios --flavor full --config-only --release`).

## Related

- [[Debugging]] · [[FVM]] · [[Flavors]] · [[Documentation Index]] · [[Open Reminders]]
