---
tags:
  - overview
  - monorepo
---

# Project Structure

Root monorepo with one main app and two Git submodules.

```
Teleferika/
├── teleferika.app/                 # Main Flutter app
├── licensed_features_package/      # Submodule — premium features
├── licence_server/                 # Submodule — license server
├── docs/                           # Cross-cutting design notes
├── scripts/fvm-use.sh              # Sync Flutter version across packages
├── .fvmrc                          # Single Flutter version source of truth
├── .gitmodules
└── obsidian-vault/                 # This knowledge base
```

## Submodules (`.gitmodules`)

| Path | Remote |
|------|--------|
| `licensed_features_package` | `teleferika_licenced_packages` |
| `licence_server` | `teleferika-license-server` |

Clone with: `git clone --recurse-submodules …`

## Path dependencies

- `teleferika.app/pubspec.yaml` → `../licensed_features_package` (full flavor; placeholder-managed by setup scripts)
- `licensed_features_package/pubspec.yaml` → `../teleferika.app` (uses app models)

## App `lib/` layout

| Folder | Role |
|--------|------|
| `core/` | Config, logging, project state, settings |
| `db/` | Drift schema, helpers, models |
| `map/` | Map UI, markers, cache, location |
| `geometry/` | Bearings, distances, angle colors |
| `ble/` | RTK via BLE/USB, NMEA, NTRIP |
| `licensing/` | Licence client, feature registry |
| `ui/` | Screens and shared widgets |
| `projects/` | Cable equipment presets |
| `points/` | Reserved for point-domain logic |
| `l10n/` | EN / IT ARB + generated localizations |

## Related

- [[teleferika.app]] · [[licensed_features_package]] · [[licence_server]]
- [[Flavors]] · [[Setup]] · [[FVM]]
