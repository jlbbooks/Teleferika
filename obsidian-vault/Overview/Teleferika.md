---
tags:
  - overview
  - product
aliases:
  - TeleferiKa
---

# Teleferika

Flutter mobile app for **cable crane (ropeway) line planning** in forest / log-transport operations.

Technicians survey anchors and supports in the field (GPS + compass), organize them into projects (one line per project), visualize the line on topo/satellite maps, estimate rope length and slope, and — in the full flavor — export to GIS formats under licence control.

## Problem it solves

Lay out and document cable crane routes with minimal environmental impact and better operational efficiency — especially offline in remote forest.

## Target users

- Forest technicians managing cable crane operations
- Surveyors collecting geographic field data
- Project managers coordinating multiple lines
- Environmental planners assessing impact

→ Details: [[Target Users]]

## Product surface

| Area | Capability |
|------|------------|
| Survey | GPS points with accuracy, altitude, photos |
| Orientation | Compass + project [[Azimuth]]; true heading via RTK magVar |
| Line math | Bearing, distance, rope length, slope/angle coloring → [[Geometry]] |
| Map | Multiple tile providers, offline cache → [[Map]] |
| Equipment | Project-level [[Cable Types]] |
| Precision GPS | BLE/USB [[BLE RTK]] + [[NTRIP]] |
| Premium | [[Export]], bulk map download → [[licensed_features_package]] |

## Versions / flavors

| Flavor | Contents |
|--------|----------|
| `opensource` | Core survey + map; no licensed package |
| `full` | + export, offline map download, licence gating |

→ [[Flavors]] · [[Project Structure]]

## Repo snapshot

- App version (pubspec): **1.3.2+105**
- Flutter (FVM root `.fvmrc`): see [[FVM]]
- DB schema version: **8** (Drift) → [[Database]]

## Related

- [[Current Features]]
- [[Layered Architecture]]
- [[Components MOC]]
