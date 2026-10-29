---
tags:
  - concept
  - gnss
  - rtk
---

# NTRIP

Networked Transport of RTCM via Internet Protocol — streams correction data to the RTK receiver for fixed/float solutions.

- Client: `lib/ble/ntrip_client.dart`
- UI: `ntrip_configuration_widget.dart`
- Saved profiles: `NtripSettings` table → [[Database]]

Corrections are forwarded over the active RTK transport (BLE or USB).

## Related

- [[BLE RTK]] · [[NMEA]] · [[Open Reminders]] (background NTRIP TODOs)
