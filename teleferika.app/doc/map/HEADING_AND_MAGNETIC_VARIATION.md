# Heading and Magnetic Variation on the Map

## Current behaviour

- **Location marker (arrow)** on the map uses **device compass** only: `currentDeviceHeading` from the magnetometer. That is **magnetic** heading (0° = magnetic north).
- **GPS info panel** shows **course** from `position.heading`, which comes from NMEA GPRMC “course over ground” when using the RTK device. That is **true** heading (0° = true north).
- **Project azimuth** (heading line, azimuth arrow) is in **true** north (survey convention).

So we mix two references: the map arrow is magnetic, while project heading and (when on RTK) GPS course are true.

## NMEA magnetic variation

- GPRMC field 10 is **magnetic variation** (declination) in degrees: **E positive, W negative**.
- Conversion: **true heading = magnetic heading + variation** (e.g. 5° E ⇒ true = magnetic + 5).

## Using magVar when receiving NMEA from RTK

When we have NMEA from the RTK device we get `magneticVariation` (and already use `course` as true). We can:

1. **Correct the compass for the map arrow**  
   Use: `displayHeading = (currentDeviceHeading + magneticVariation)` normalized to 0–360.  
   Then the location arrow is in **true** north and consistent with project azimuth and GPS course.

2. **Leave GPS course as-is**  
   `position.heading` is already true (GPRMC course); no magVar needed there.

## Implementation (done)

- **MapStateManager** stores optional `magneticVariation` (set from NMEA when using RTK).
- **MapScreen** sets `_stateManager.magneticVariation` from `nmeaData.magneticVariation` in the existing NMEA subscription; clears it when BLE disconnects.
- **Effective heading** passed to the map: if both `currentDeviceHeading` and `magneticVariation` are non-null, use `(currentDeviceHeading! + magneticVariation!)` normalized to 0–360; otherwise use raw `currentDeviceHeading`.
- The location marker and any UI that use “device heading” now see **true** heading when magVar is available from the RTK device.

## When magVar is not available

- When using **device GPS only** (no RTK), we do not have NMEA magnetic variation. The map arrow stays **magnetic**.
- When **RTK is connected** but the receiver does not send GPRMC or magVar, we also keep using magnetic heading. Correction is applied only when `nmeaData.magneticVariation != null`.
