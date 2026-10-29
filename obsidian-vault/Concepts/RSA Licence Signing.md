---
tags:
  - concept
  - licensing
  - security
---

# RSA Licence Signing

Licences are signed **RSA-SHA256** on [[licence_server]] and verified on-device by `cryptographic_validator.dart` (PointyCastle / ASN.1).

Server holds private key; clients embed/use public key for offline verification of the signed payload.

## Related

- [[Licensing]] · [[License Model]] · [[licence_server]]
