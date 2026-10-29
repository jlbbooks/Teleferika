---
tags:
  - domain
  - points
---

# Points

Geographic survey points along a [[Projects|project]] line (anchors, supports, endpoints).

## Persistence

- Table `Points` FK → Projects (cascade delete)
- Model [[PointModel]]
- Child [[ImageModel|Images]]

## Fields

- Lat / lon / altitude
- GPS precision/accuracy
- Ordinal number (ordering along the line)
- Note, timestamp

## Capture & edit

- Map: place from GPS / RTK; **marker slide** (long-press drag)
- Points list + point editor screens
- Photos via photo manager widgets

## Derived

Bearings, distances, angles computed via [[Geometry]] (not stored as primary source of truth).

## Folder note

`lib/points/` is reserved for future point-domain logic; models live under `db/models/`.

## Related

- [[Map]] · [[BLE RTK]] · [[Projects]]
