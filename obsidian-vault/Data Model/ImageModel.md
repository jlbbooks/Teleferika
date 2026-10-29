---
tags:
  - data-model
---

# ImageModel

Photo attached to a [[PointModel]] (`db/models/image_model.dart`).

Fields: `id`, `pointId`, `ordinalNumber`, `imagePath`, `note`.

Cascade-deleted with parent point.

## Related

- [[Points]] · [[Export]] (KMZ embeds images)
