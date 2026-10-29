---
tags:
  - component
  - server
  - licensed
---

# licence_server

Standalone Dart server for generating, storing, and validating Teleferika licences.

## Runtime

| Surface | Default |
|---------|---------|
| REST API | `:8444` |
| Web admin UI | `:8443` |

Storage: CSV file-based (`csv_storage.dart`). Signing: **RSA-SHA256** → [[RSA Licence Signing]].

## Features

- Device-bound licences ([[Device Fingerprint]])
- License request + approve/deny workflow
- Admin challenge-response auth + web sessions
- Stats / health endpoints
- Debian package + systemd (`build-package.sh deb`)

## Layout

```
licence_server/
├── bin/                  # server + admin client entrypoints
├── lib/api/              # REST
├── lib/models/           # LicenseRecord
├── lib/services/         # generator, CSV storage
├── web/                  # static admin assets
└── docs/                 # API, security, packaging
```

## Client contract

Unified [[License Model]] shared conceptually with the app (`UNIFIED_LICENSE_README.md`).

Endpoints (high level): `POST /licenses/validate`, `GET /licenses/{email}`, admin CRUD, `/health`, web auth — see `docs/API_DOCUMENTATION.md`.

## Related

- [[Licensing]] · [[License Request Workflow]] · [[teleferika.app]]
