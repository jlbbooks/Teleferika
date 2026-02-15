# Profile tab — Line profiles

The **Profile** tab in the project editor shows two chart modes for the line defined by the project’s ordered points: **Elevation profile** and **Plan view**. Both use the same chart layout (axes, ticks, point labels, dotted guide lines, resizable height).

---

## When the tab is shown

- The tab is available as the fourth tab (Details, Points, Map, **Profile**) in the project screen.
- **Elevation profile** requires at least two points and at least one point with a non-null **altitude**.
- **Plan view** requires at least two points (altitude is ignored).
- If elevation cannot be shown (no altitude data) but plan can, the tab shows plan view. A segmented control lets you switch between the two when both are available.
- The last selected mode (Elevation vs Plan) is remembered **in memory only** (per project), so returning to the Profile tab restores that choice without saving it to the database.

---

## 1. Elevation profile

**Purpose:** Show how altitude varies along the line (longitudinal profile).

### What is displayed

- **X axis:** Distance along the line (m or km), from the first point (0) to the last point (total length).
- **Y axis:** Altitude (m above sea level), scaled between the **minimum and maximum altitude** among all points that have altitude.
- **Curve:** Polyline joining points that have altitude; segments are skipped when either endpoint has no altitude.
- **Points:** Each point with altitude is drawn as a dot on the curve, with dotted lines to the X and Y axes and a label (point name, e.g. P1, P2).
- **Axis labels:** At each such point, the X axis shows the cumulative distance up to that point; the Y axis shows that point’s altitude.

### Calculations

1. **Cumulative distance (X)**  
   For point index \(i\), the X value is the sum of **3D distances** from point 0 to point \(i\):
   - Between consecutive points we use `PointModel.distanceFromPoint(other)` (no altitude override), which is the 3D distance:  
     \(\sqrt{\text{horizontal}^2 + \text{vertical}^2}\), with horizontal from the Haversine formula (WGS84) and vertical = \(|\text{alt}_2 - \text{alt}_1|\).
   - So “distance” is the 3D rope-length style distance along the line, not horizontal-only.

2. **Altitude (Y)**  
   Taken directly from each point’s `altitude` (meters). Only points with non-null altitude are drawn; null altitudes are skipped for the polyline and dots.

3. **Vertical scale**  
   - \(Y_{\min}\) = minimum altitude among points that have altitude.  
   - \(Y_{\max}\) = maximum altitude among points that have altitude.  
   - If \(Y_{\max} \leq Y_{\min}\), \(Y_{\max}\) is set to \(Y_{\min} + 1\) so the chart has a non-zero range.

### Saved state (no project dirty)

- **Chart height:** Stored in the project as `profile_chart_height` in the database and updated in app state when the user drags the resize handle. Saving the height does not set the project’s “unsaved changes” flag.

---

## 2. Plan view (top view)

**Purpose:** Show how the line deviates laterally from a straight line between the first and last point (view from above; altitude is not used).

### What is displayed

- **Reference line:** The straight line from the **first point** to the **last point** (in latitude/longitude).
- **X axis:** Distance **along** that reference line (m or km), from 0 at the first point to the total horizontal length at the last point.
- **Y axis:** **Lateral offset** (m), i.e. perpendicular distance from the reference line (positive one side, negative the other).
- **Curve:** Polyline through all points, each positioned by its “along” and “lateral” coordinates.
- **Points:** Every point is drawn (altitude is ignored). First point at bottom-left (0, 0), last point at top-right (total along, 0); intermediate points show lateral deviation.
- **Axis labels:** At each point, X shows distance along the reference line to that point; Y shows lateral offset.

### Calculations (horizontal only)

All plan-view calculations use **latitude and longitude only**; altitude is ignored so that points with missing or zero altitude are not displaced.

1. **Reference bearing**  
   Bearing (azimuth) from first point to last point, in degrees (0–360), from the **forward azimuth** formula:
   - \(\Delta\lambda = \lambda_2 - \lambda_1\), \(\phi\) = latitude (radians).
   - \(y = \sin(\Delta\lambda) \cos(\phi_2)\), \(x = \cos(\phi_1)\sin(\phi_2) - \sin(\phi_1)\cos(\phi_2)\cos(\Delta\lambda)\).
   - Bearing = \(\mathrm{atan2}(y, x)\) converted to degrees and normalized to [0, 360).

2. **Horizontal distance**  
   All distances are **horizontal (Haversine)** only. We call  
   `first.distanceFromPoint(other, altitude: 0, otherAltitude: 0)` so the vertical component is zero and the result is the Haversine distance in meters.

3. **Along and lateral for each point**  
   For each point \(i\):
   - \(d_i\) = horizontal distance from first point to point \(i\).
   - \(\theta_i\) = bearing from first point to point \(i\) (same formula as above).
   - \(\Delta\theta = \theta_i - \theta_{\text{ref}}\) (difference from reference bearing), in radians.
   - **Along** = \(d_i \cos(\Delta\theta)\) (projection onto the reference line).
   - **Lateral** = \(d_i \sin(\Delta\theta)\) (signed perpendicular offset).

4. **Vertical scale (Y axis)**  
   - \(Y_{\min}\) = minimum lateral offset among all points.  
   - \(Y_{\max}\) = maximum lateral offset.  
   - If \(Y_{\max} \leq Y_{\min}\), \(Y_{\max}\) is set to \(Y_{\min} + 1\).

### Saved state (no project dirty)

- **Chart height:** Stored in the project as `plan_profile_chart_height` in the database and updated in app state when the user resizes the plan chart. Does not set the project’s “unsaved changes” flag.

---

## UI behaviour (both charts)

- **Resize handle:** A handle below the chart allows vertical resize; the chosen height is saved to the database (and to app state) for that chart type without marking the project dirty.
- **Initial height:** On first opening the Profile tab with no saved height for the current mode, the chart is given a square aspect ratio (height = chart width) in a post-frame callback; that value is then saved.
- **Axes:** X and Y axes are drawn as lines; at each point a short tick is drawn on both axes and dotted lines connect the point to the axes.
- **Labels:** Point names (e.g. P1, P2) and axis values (distance, altitude or lateral offset) are drawn; Y and X label positions are clamped so they stay inside the chart area.
- **Empty states:** If there are fewer than two points, or (for elevation only) no point has altitude, an empty state message is shown instead of the chart.

---

## References

- Elevation vs. distance profile aligns with the “Longitudinal profile” idea in [FUNCTIONS_FOR_COMPANIES_README.md](./FUNCTIONS_FOR_COMPANIES_README.md) (Section 2 — Terrain and Elevation).
- Implementation: `lib/ui/screens/projects/components/line_profile_section.dart`.
- Distance and bearing: `PointModel.distanceFromPoint` and bearing via forward azimuth (e.g. standard geographic formulas).
