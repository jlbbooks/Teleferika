---
tags:
  - architecture
  - runtime
---

# App Initialization

Entry: `teleferika.app/lib/main.dart`.

Typical order (conceptually):

1. Flutter binding
2. Logging (`core/logger.dart`)
3. [[Licensing|LicenceService]] init
4. Drift DB open (`DriftDatabaseHelper`) — DB file `Teleferika.db`
5. Load licensed features if present (`licensed_features_loader`)
6. [[Feature Registry]] initialize
7. Map tile caching / FMTC setup
8. BLE-related setup as needed
9. Launch UI → [[Loading Screen]] then projects list

Legacy sqflite DB (`photogrammetry.db`) can be migrated on load → [[Database]].

## Providers

App wraps state with Provider — notably [[State Management|ProjectStateManager]].

## Related

- [[Layered Architecture]] · [[Database]] · [[Licensing]]
