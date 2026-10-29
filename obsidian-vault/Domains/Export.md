---
tags:
  - domain
  - export
  - licensed
---

# Export

Premium data export (and related offline map download) from [[licensed_features_package]].

## Formats

| Format | Typical consumer |
|--------|------------------|
| KML | Google Earth / Maps |
| KMZ | KML + embedded images |
| CSV | Spreadsheets / analysis |
| GeoJSON | QGIS, web GIS |
| Shapefile | ArcGIS / professional GIS |

Architecture: **strategy** per format + factory/service (`LicensedExportService`).

## Gating

Requires valid licence features (e.g. `export_basic` / `export_advanced`) → [[Licensing]].

## Related

- [[Projects]] · [[Points]] · [[licensed_features_package]]
