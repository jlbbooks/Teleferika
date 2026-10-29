---
tags:
  - architecture
  - state
---

# State Management

Primary pattern: **Provider** + dedicated manager classes.

| Piece | Role |
|-------|------|
| `ProjectStateManager` | Current project + points; dirty tracking; CRUD coordination |
| `project_provider.dart` | Selection / current project helpers |
| `MapStateManager` | Location, compass, map UI state, heading (+ magVar) |
| `SettingsService` | Persisted app settings |
| `LicenceService` | Licence presence, validation, feature checks |

Map heading nuance: `effectiveDeviceHeading` applies [[Magnetic Variation]] from NMEA when RTK is active so the location arrow matches **true** [[Azimuth]].

## Related

- [[Projects]] · [[Map]] · [[App Initialization]]
