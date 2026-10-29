---
tags:
  - component
  - flutter
  - licensed
---

# licensed_features_package

Git submodule with **premium** features for the full flavor.

## Capabilities

1. **Export** — KML, CSV, GeoJSON, KMZ, Shapefile (strategy pattern) → [[Export]]
2. **Map download** — Area selection, zoom range, progress, FMTC cache
3. **Widgets / plugin** — Registered through [[Feature Registry]]
4. **l10n** — EN / IT for premium UI

## Integration

- Path dep from [[teleferika.app]] when flavor = full
- Package depends back on `teleferika` for models
- Stub loader in opensource so calls fail closed

Entry exports: `licensed_features.dart`, `licensed_plugin.dart`, `licensed_features_loader_full.dart`.

## Related

- [[Flavors]] · [[Licensing]] · [[Export]] · [[Map]]
