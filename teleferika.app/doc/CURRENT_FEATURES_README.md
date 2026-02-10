# Teleferika — Current Features for Ropeway / Log-Transport Professionals

This document summarizes the app’s **current** functionality that is relevant for professionals planning and operating ropeways (cable cranes, cable yarding) for log transport and forest operations.

---

## 1. GPS-Based Point Collection

- **Place and store points** (e.g. anchors, intermediate supports, endpoints) with latitude, longitude, and altitude.
- **GPS precision/accuracy** and timestamps are stored per point so you can assess reliability of each fix.
- Points are ordered within a project and can be edited (coordinates, notes, images).

**Use case:** Survey anchor and support locations in the field with one consistent workflow.

---

## 2. Compass and Azimuth

- **Compass integration** for directional reference in the field.
- **Project azimuth** — the intended direction of the cable line — is stored at project level.
- **Moving marker** shows the project azimuth as an arrow overlay from the current device location, helping align the planned line while walking or driving.

**Use case:** Orient the line and check alignment against terrain without extra tools.

---

## 3. Bearing, Distance, and Rope Length

- **Bearing and distance** between consecutive points are calculated (geometry layer) and used in the map and points UI.
- **Rope length calculations** on the project model estimate cable length along the surveyed line.
- **Presumed total length** can be set at project level for quick length estimates before or after detailed survey.

**Use case:** Span lengths, tower spacing, and rough cable length for planning and ordering.

---

## 4. Altitude and Slope Along the Line

- Each point stores **altitude**, so elevation is available along the full line.
- **Angle-at-point** and **angle-based coloring** on the polyline visualize slope/steepness between points (e.g. for safety or machine limits).

**Use case:** Assess slope and elevation change for sag, clearance, and equipment suitability.

---

## 5. Topographic and Aerial Map Backgrounds

- **Open Topo Map** — contours and terrain; well suited to European fieldwork.
- **Thunderforest Outdoors** — outdoor-focused with trails and contours.
- **Esri World Topo** — general topographic base.
- **Esri Satellite** — aerial imagery for obstacles, landings, and line-of-sight.
- **CartoDB Positron** — minimal base for overlaying your line data.
- **Thunderforest Landscape** — terrain-focused visual style.

**Use case:** Choose the right base (topo vs satellite) for planning and field checks.

---

## 6. Offline Operation

- **Offline operation** so the app remains usable without mobile data.
- **Map tile caching** with optional bulk download per map type for areas you work in.

**Use case:** Reliable use in remote forest with no or poor connectivity.

---

## 7. Cable / Equipment Type (Project Level)

- **Project-level cable type selection** — each project can be assigned a cable/equipment type (e.g. rope diameter, weight, breaking load).
- **Cable types table** — a separate DB table stores cable types with UUIDs; built-in types (Italy/EU forestry: fune portante, fune traente, skyline, mainline) are seeded on first run.
- **Seed data** — `cable_equipment_presets.dart` defines built-in cable types with fixed UUIDs; seeding runs only when the table is empty.
- **User-added types** — the DB supports adding custom cable types at runtime (UI to be implemented); project details always read from the DB, not from presets.

**Use case:** Consistent assumptions for future sag, clearance, or payload logic; aligns vocabulary with desktop tools (e.g. SEILAPLAN).

---

## 8. Project and Line Organization

- **Projects** group points into distinct lines or operations.
- **Points list and editor** support ordering, numbering, and editing of points (e.g. anchor sequence along the line).

**Use case:** One project per line; manage multiple lines via multiple projects.

---

## 9. Fine-Tuning Point Positions (Marker Slide)

- **Marker slide:** long-press and drag a marker on the map to move it; coordinates are updated when you release.
- Original position can be shown during drag; coordinate conversion uses the map projection for accurate placement.

**Use case:** Adjust points after better GPS or office review without re-surveying.

---

## 10. Photos at Points

- **Images linked to points** (per-point photo attachment) for documenting anchors, supports, obstacles, and landings.

**Use case:** Visual record at each critical location for reports and handover.

---

## 11. Line Visualization on the Map

- **Polylines** connect points in sequence along the line.
- **Polyline arrowhead** indicates direction of the line.
- **Angle-based coloring** on segments can show slope/angle along the line.

**Use case:** See the full line and slope at a glance on the map.

---

## 12. Data Export

- **Data export** (in the full/licensed version) to use project and point data in other tools, reports, or permits.

**Use case:** Move data to office workflows, GIS, or design software.

---

## 13. Location Accuracy Feedback

- **Location marker with accuracy circle** so you see current GPS quality when placing or checking points (e.g. for RTK or standard GNSS).

**Use case:** Decide when to capture a point or wait for better fix quality.

---

## Summary

Teleferika today supports **field survey of ropeway lines**: GPS point collection with altitude, compass/azimuth alignment, bearing/distance and rope length, project-level cable/equipment type selection, multiple map types (including topo and satellite), offline use, photo documentation per point, and line visualization with slope-related coloring. It is aimed at forest technicians, surveyors, project managers, and environmental planners who need to lay out and document cable crane lines for log transport.

For possible future features that could further help companies, see **[FUNCTIONS_FOR_COMPANIES_README.md](./FUNCTIONS_FOR_COMPANIES_README.md)**.
