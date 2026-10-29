---
tags:
  - workflow
  - licensing
---

# License Request Workflow

1. Full-flavor app collects email + [[Device Fingerprint]]
2. `LicenceRequestService` submits request to [[licence_server]]
3. Admin reviews in web UI (`:8443`) — approve/deny / enable toggle
4. Server issues RSA-signed [[License Model]]
5. App stores licence; [[Feature Registry]] unlocks [[Export]] / map download

Validation path: `POST /licenses/validate` on each check / startup as configured.

## Related

- [[Licensing]] · [[RSA Licence Signing]] · [[licence_server]]
