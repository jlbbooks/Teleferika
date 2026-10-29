---
tags:
  - domain
  - l10n
aliases:
  - i18n
---

# Localization

- App: `lib/l10n/` — ARB `app_en.arb`, `app_it.arb` + generated `AppLocalizations`
- Licensed package: its own `lib/l10n/`
- Country/region helper: `country_region_localizations.dart` (NTRIP hosts UI)

Flutter `generate: true` in pubspec; `l10n.yaml` configures codegen.

## Related

- [[teleferika.app]] · [[licensed_features_package]]
