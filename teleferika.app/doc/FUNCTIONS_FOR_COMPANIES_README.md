# Teleferika — Functions That Could Help Companies

This document lists **potential features** that could make Teleferika more useful for companies using ropeway/cable crane systems for log transport. They are based on industry tools (e.g. SEILAPLAN, CHPS, Softree, SKYTOWER/SKYMOBILE) and common workflows. None of these are commitments; they are options for roadmap and prioritization.

---

## 1. Cable / Line Mechanics (Design-Oriented)

### Sag and clearance

- **Idea:** Use a simple catenary or parabolic model to estimate **sag** and **minimum clearance** between load path and ground along the line (or per segment).
- **Why it helps:** Tools like SEILAPLAN do this as a core check. Even an approximate “clearance OK?” in the app would support field checks and handover to desktop design.
- **Depends on:** Segment length, elevation difference, cable/load parameters (see “Cable/equipment type” below).

### Payload vs span

- **Idea:** Provide a **payload/span** helper: e.g. “longest span for given payload” or “max payload over this span” (or “max span for this rope type”).
- **Why it helps:** Programs such as SKYTOWER/SKYMOBILE answer these questions; a simplified version would help when siting intermediate supports and choosing line layout.
- **Depends on:** Cable type, slope, and possibly equipment presets.

### Intermediate support positions

- **Idea:** Treat **intermediate supports** explicitly (e.g. point type “tower” or “intermediate support”) and show **segment length and slope** between supports.
- **Why it helps:** Aligns with how professionals describe lines and with desktop tools that optimize support positions (e.g. SEILAPLAN).

---

## 2. Terrain and Elevation

### Longitudinal profile

- **Idea:** **Elevation profile** along the line: elevation vs. distance (view in-app and/or export as CSV/XY).
- **Why it helps:** Standard way to review a line; SEILAPLAN and others accept profile or DTM as input for layout design.
- **Depends on:** Current point altitudes; optional future: elevation from DTM under the line.

### DTM / DEM import (longer term)

- **Idea:** Support **import of a longitudinal profile** (e.g. CSV) or, later, **elevation under the line** from a raster (DTM/DEM).
- **Why it helps:** Bridges field app and office design tools that use LiDAR/DTM (Softree, CHPS, SEILAPLAN).

---

## 3. Equipment and Cable Types

### Cable crane / rope type

- **Implemented:** **Project-level cable/equipment type selection** is available. Cable types are stored in a dedicated DB table with UUIDs; built-in types (Italy/EU forestry) are seeded on first run from `cable_equipment_presets.dart`. Project details read from the DB; user-added types are supported (UI to be implemented).
- **Future:** Named crane types, extended manufacturer data, or integration with sag/payload calculations.

---

## 4. Export and Interoperability

### GIS-friendly export

- **Idea:** Export in formats commonly used in forestry/GIS:
  - **KML** — for Google Earth and field checks.
  - **Shapefile or GeoJSON** — for QGIS/ArcGIS and CHPS-style workflows.
  - **CSV** — coordinates, altitude, order, and key attributes for profiles and SEILAPLAN-style tools.
- **Why it helps:** Companies already use QGIS, ArcGIS, and CHPS; standard formats reduce manual conversion and errors.

### Line / project report

- **Idea:** **Simple report** (e.g. PDF or HTML): project name, point list (coordinates, altitude, order), segment lengths, total length, slope summary, optional photos/notes.
- **Why it helps:** Permits, documentation, and handover to design teams without opening GIS or design software.

---

## 5. Safety and Checks

### Minimum inclination / slope checks

- **Idea:** **Slope checks** along segments: e.g. “segment slope &lt; X%” or “&gt; Y%” with warnings or flags.
- **Why it helps:** SEILAPLAN checks minimum inclination for gravitational systems; similar checks in the app support safety and system-type validation.

### Anchor / tower point types

- **Idea:** **Point types or tags** such as “anchor”, “tower”, “landing”, “intermediate support” (and notes like “guy anchor”).
- **Why it helps:** Field data becomes structured for guyline/anchor analysis (e.g. GuylinePC) and for reporting.

---

## 6. Workflow and Planning

### Landing as first-class concept

- **Idea:** **Landing** as a dedicated point type or tag (e.g. “landing” at one or both ends of the line).
- **Why it helps:** Matches how CHPS/Softree and planning docs treat landings and corridors.

### Multi-line / harvest unit

- **Idea:** **Grouping projects** (e.g. “Harvest unit X” or “Block Y”) or **multi-select export** for several lines at once.
- **Why it helps:** Companies often plan and report by harvest area with multiple lines.

---

## Summary Table

| Area       | Example feature                      | Benefit for companies                                       |
| ---------- | ------------------------------------ | ----------------------------------------------------------- |
| Mechanics  | Sag/clearance (simplified)           | Quick “clearance OK?” check; fits SEILAPLAN/CHPS workflow   |
| Mechanics  | Payload/span or “max span” hint      | Supports span length and intermediate support decisions     |
| Terrain    | Elevation profile (view or export)   | Standard review; input for desktop design                   |
| Data model | Cable/equipment type per project     | ✅ Implemented — DB table, seed data, project selection      |
| Export     | KML, Shapefile/GeoJSON, profile CSV  | Fits GIS and SEILAPLAN/CHPS; better handover                |
| Reporting  | Line report (PDF/HTML)               | Permits, documentation, handover to design                  |
| Safety     | Slope / inclination checks           | Aligns with gravity-system and safety checks in other tools |
| Structure  | Point types (anchor, tower, landing) | Clearer field data; ready for guyline/design analysis       |

---

## References (research basis)

- **SEILAPLAN** — QGIS plugin for cable road layout; catenary, clearance, support optimization ([seilaplan.wsl.ch](https://seilaplan.wsl.ch/en/documentation/)).
- **CHPS** — Cable Harvest Planning Solution (ArcGIS); payload and terrain analysis ([cableharvesting.com](https://cableharvesting.com/)).
- **Softree** — Cable harvest planning with DTM, payload, multi-deflection ([softree.com](https://www.softree.com/products/cable-harvesting-planning)).
- **SKYTOWER / SKYMOBILE** — USDA Forest Service; payload vs span for tower and mobile yarder layouts.
- **GuylinePC** — Guyline tension analysis for guyed logging towers.

For the app’s **current** features, see **[CURRENT_FEATURES_README.md](./CURRENT_FEATURES_README.md)**.
