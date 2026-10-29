---
tags:
  - concept
  - surveying
  - nmea
---

# Magnetic Variation

Declination / magnetic variation from NMEA **GPRMC**, applied so the map location arrow shows **true** heading when RTK is connected.

- Compass alone → magnetic heading
- RTK course (GPRMC) → true
- `MapStateManager.effectiveDeviceHeading` ≈ compass + magVar when available

Full write-up: `teleferika.app/doc/map/HEADING_AND_MAGNETIC_VARIATION.md`

## Why it matters

[[Azimuth]] and survey headings are true. Without correction, the arrow drifts vs the project heading line where declination is large.

## Related

- [[Map]] · [[NMEA]] · [[BLE RTK]]
