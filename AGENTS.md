## Agent skills

### Issue tracker

`gh` needs Shell `required_permissions: ["full_network"]` (sandbox GraphQL is Forbidden otherwise). Issues live in this repo's GitHub Issues via `gh`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Release

Tag from `main`, submodule then parent pointer, store AAB/IPA via `build-app.sh`: see `docs/agents/release.md`.

### Domain docs

Engineering glossary/ADRs vs product/ops vault: see `docs/agents/domain.md`.
