---
tags:
  - overview
  - build
aliases:
  - opensource
  - full flavor
---

# Flavors

Two Android/iOS product flavors, switched by setup scripts (not only `--flavor`).

| Flavor | Licensed package | Licence server needed | Typical audience |
|--------|------------------|----------------------|------------------|
| **opensource** | Removed / stub | No | OSS contributors |
| **full** | Path dependency present | For validation / requests | Team + paying users |

## How setup works

Scripts under `teleferika.app/scripts/`:

- `setup-flavor.sh opensource|full`
- Shortcuts: `setup-opensource.sh`, `setup-full.sh`

They rewrite `pubspec.yaml` around `LICENSED_PACKAGE_PLACEHOLDER` and sync submodules for full.

Run then:

```bash
fvm flutter run --flavor opensource   # or full
```

## Platform notes

- Separate Android `applicationId` / icon sets per flavor (`flavors.md`)
- iOS: distinct App Icon asset catalogs per configuration
- Folder name `teleferika.app` is treated as a macOS app bundle — open Xcode via `./scripts/open-xcode.sh`

## Related

- [[Setup]] · [[licensed_features_package]] · [[Licensing]] · [[Scripts]]
