---
tags:
  - development
  - flutter
---

# FVM

Flutter Version Manager pins one SDK for the whole monorepo.

- **Source of truth:** root `.fvmrc`
- **Sync script:** `./scripts/fvm-use.sh [version]` — updates root + `teleferika.app`, `licence_server`, etc.
- IDE: open workspace at **repo root** so `.vscode/settings.json` points at root FVM SDK

When upgrading Flutter, run the sync script; do not hand-edit only one package’s `.fvmrc`.

## Related

- [[Setup]] · [[Project Structure]]
