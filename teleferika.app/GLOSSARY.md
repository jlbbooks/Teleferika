# Teleferika (field survey)

Cable-crane / ropeway line planning and survey in forestry: one operator plans and measures a line in the field.

## Language

**Teleferica**:
A forestry cable crane / ropeway used to move timber; the physical system a Project plans and surveys.
_Avoid_: Generic “cableway” when this forestry system is meant; treating the app brand as the only sense of the word

**Project**:
One planned or surveyed cable-crane line: its points, intended direction, and related line attributes.
_Avoid_: Photogrammetry project, workspace, job folder, multi-line container

**Point**:
A WGS84 survey vertex on a Project’s path, ordered along the line, with optional altitude, precision, note, and photos. Points are untyped today; roles such as anchor, tower, or landing are expected later but are not part of the model yet.
_Avoid_: Feature, waypoint (as the canonical name), typed support/anchor entities (until roles exist)

**Azimuth**:
The Project’s intended line direction in degrees, relative to true north.
_Avoid_: Bearing, heading, course (for this stored intent)

**Bearing**:
The computed direction in degrees from one Point to another.
_Avoid_: Azimuth, heading (for point-to-point geometry)

**Heading**:
The device or GNSS direction of travel or compass orientation; magnetic until corrected to true.
_Avoid_: Azimuth, bearing (for live device direction)

**Cable Type**:
A rope or equipment specification (for example diameter, weight per metre, breaking load) that can be assigned to a Project.
_Avoid_: Cable equipment type, cable equipment preset (as domain names)

**Photo**:
A picture attached to a Point.
_Avoid_: Image (as domain language)

**Ordinal**:
The Point’s sequence index on its Project; it defines path order. The first and last Points by Ordinal are the line’s start and end — not separate named entities.
_Avoid_: Starting point id, ending point id (as persisted concepts)

**Presumed Total Length**:
Operator-entered design length of the Project (metres), used when the full surveyed length is not yet known.
_Avoid_: Line length (when this design value is meant)

**Rope Length**:
Measured length of the Project along consecutive Points in 3D (horizontal distance plus altitude).
_Avoid_: Presumed total length, span length (as synonyms for this measured path)

**Project Heading Line**:
Theoretical alignment drawn from the first Point along the Project Azimuth for the Presumed Total Length.
_Avoid_: Surveyed polyline, connecting line, azimuth (alone)

**Segment**:
The edge between two consecutive Points on a Project.
_Avoid_: Span (until span is a distinct concept)

**Angle at Point**:
The planimetric turn at a Point between its incoming and outgoing Segments.
_Avoid_: Slope, grade, steepness (for this turn)

**RTK**:
A high-precision GNSS receiver used in the field, typically linked over BLE or USB.
_Avoid_: GPS (when RTK-grade positioning is meant)

**NTRIP**:
A correction-stream connection (caster, mount point, credentials) that improves GNSS solutions.
_Avoid_: “Corrections” alone when the NTRIP link is meant

**MagVar**:
Magnetic variation (declination) used to relate magnetic Heading to true north.
_Avoid_: Azimuth offset, compass error (as the canonical name)

**Fix Quality**:
The class of the current GNSS solution (for example autonomous GPS, DGPS, RTK fix/float).
_Avoid_: GPS precision (when solution class is meant)

**Elevation Profile**:
Altitude versus distance along the Project’s ordered Points.
_Avoid_: Line profile (when only the elevation view is meant), slope chart

**Plan Profile**:
Top-down view of the Project path along its ordered Points.
_Avoid_: Map (when this path chart is meant), line profile (when only the plan view is meant)

**GPS Accuracy**:
Horizontal accuracy of a Point capture, in metres.
_Avoid_: GPS precision (as the canonical domain name)
