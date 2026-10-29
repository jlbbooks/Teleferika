---
tags:
  - data-model
  - licensing
aliases:
  - License
---

# License Model

Unified licence object shared conceptually by client and server (`UNIFIED_LICENSE_README.md`).

## Fields (conceptual)

- Identity: `email`, `customerId`, `deviceFingerprint`
- Validity: `issuedAt`, `validUntil`, `status` (active / expired / revoked)
- Entitlements: `features[]`, `maxDevices`, `version`
- Crypto: `signature`, `algorithm` (RSA-SHA256)
- Ops: `usageCount`, `lastUsed`, revocation metadata

JSON: nested `data`+`signature` on client; flat on server.

## Related

- [[Licensing]] · [[licence_server]] · [[Device Fingerprint]] · [[RSA Licence Signing]]
