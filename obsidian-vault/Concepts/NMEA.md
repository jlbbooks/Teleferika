---
tags:
  - concept
  - gnss
---

# NMEA

Text sentences from GNSS receivers, parsed in `nmea_parser.dart`.

| Sentence | Used for |
|----------|----------|
| GGA / GPGGA / GNGGA | Lat/lon, alt, fix quality, HDOP, sats |
| RMC / GPRMC / GNRMC | Position, speed, **course**, **magVar**, time |

Checksum validated; invalid sentences discarded.

`NMEAData` feeds map GPS panel and point capture via [[BLE RTK]].

## Related

- [[NTRIP]] · [[Magnetic Variation]] · [[Fix Quality Colors]]
