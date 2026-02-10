# ProjectStateManager – Improvement Recommendations

This document lists recommended improvements for `lib/core/project_state_manager.dart`. Use it step by step; you can decide which items to apply.

**Context:** Editing is in memory until the user saves. Undo discards in-memory changes by reloading from the DB.

---

## Already applied

- [x] **setProjectEditState: merge metadata only**  
  Implemented: form updates (name, note, etc.) are applied via `project.copyWith(points: _currentPoints)` so the current points list is never overwritten by a potentially stale form snapshot. Aligns with “all editing in memory until save” and undo.

---

## High priority

### 1. Single source of truth for points

**Issue:** Both `_currentPoints` and `_currentProject!.points` are kept in sync in many places. Forgetting to update one (e.g. in `setProjectEditState`) causes bugs.

**Recommendation:** Derive points from the project only.

- Remove the field `_currentPoints`.
- Add a getter that derives from the project:

  ```dart
  List<PointModel> get currentPoints =>
      _currentProject != null
          ? List.unmodifiable(_currentProject!.points)
          : <PointModel>[];
  ```

- Everywhere that currently does both `_currentProject = ...copyWith(points: resequenced)` and `_currentPoints = resequenced`, do only:

  ```dart
  _currentProject = _currentProject!.copyWith(points: resequenced);
  ```

- In `loadProject`, `clearProject`, and `refreshPoints`, set only `_currentProject` (and in clear, set `_currentProject = null`). Remove all assignments to `_currentPoints`.

**Files to touch:** `project_state_manager.dart` (and any tests). Search for `_currentPoints` and replace/remove as above.

**Decision:** [ ] Apply  [ ] Skip

---

## Medium priority

### 2. refreshPoints: avoid double fetch

**Issue:** `refreshPoints()` calls both `getPointsForProject(_currentProject!.id)` and `getProjectById(_currentProject!.id)`. `getProjectById` already loads points, so points are fetched twice.

**Recommendation:** Use only `getProjectById`, then set `_currentProject` (and, if you keep `_currentPoints` until recommendation 1 is done, set `_currentPoints = project.points`).

**Example (if you still have `_currentPoints`):**

```dart
Future<void> refreshPoints() async {
  if (_currentProject == null) return;
  try {
    final project = await _dbHelper.getProjectById(_currentProject!.id);
    if (project != null) {
      _currentProject = project;
      _currentPoints = project.points;
    }
    logger.info(
      "ProjectStateManager: Refreshed ${project?.points.length ?? 0} points and project data",
    );
    notifyListeners();
  } catch (e, stackTrace) {
    logger.severe(
      "ProjectStateManager: Error refreshing points",
      e,
      stackTrace,
    );
    rethrow;
  }
}
```

**Decision:** [ ] Apply  [ ] Skip

---

### 3. saveProject: batch point deletes

**Issue:** Points to delete are removed one-by-one with `deletePointById` in a loop.

**Recommendation:** Use `_dbHelper.deletePointsByIds(pointsToDelete.toList())` instead of the loop.

**Example:**

Replace:

```dart
final pointsToDelete = dbPointIds.difference(memPointIds);
for (final pointId in pointsToDelete) {
  await _dbHelper.deletePointById(pointId);
}
```

with:

```dart
final pointsToDelete = dbPointIds.difference(memPointIds);
if (pointsToDelete.isNotEmpty) {
  await _dbHelper.deletePointsByIds(pointsToDelete.toList());
}
```

**Decision:** [ ] Apply  [ ] Skip

---

### 4. clearProject: reset _isLoading

**Issue:** If `loadProject` is in progress and `clearProject()` is called (e.g. user switches project), `_isLoading` can stay `true`.

**Recommendation:** In `clearProject()`, set `_isLoading = false` before (or when) clearing state.

**Example:** Add at the start of `clearProject()`:

```dart
_isLoading = false;
```

**Decision:** [ ] Apply  [ ] Skip

---

## Low priority

### 5. undoChanges: remove redundant notifyListeners

**Issue:** `undoChanges()` calls `loadProject(_currentProject!.id)` and then `notifyListeners()`. `loadProject` already calls `notifyListeners()` on success.

**Recommendation:** Remove the extra `notifyListeners()` from `undoChanges()`.

**Decision:** [ ] Apply  [ ] Skip

---

### 6. Rename or remove setState(VoidCallback fn)

**Issue:** The name `setState` is used for Flutter’s `State.setState`. Here it only runs a callback and calls `notifyListeners()`.

**Recommendation:** Rename to something like `_runAndNotify` and use only internally, or inline the two call sites and remove the helper.

**Decision:** [ ] Apply  [ ] Skip

---

### 7. getPointById: clearer implementation

**Issue:** Uses `firstWhere` and catches the “not found” case to return `null`. Works but is indirect.

**Recommendation:** Use an explicit loop or a single lookup, e.g.:

```dart
PointModel? getPointById(String pointId) {
  for (final p in _currentPoints) {
    if (p.id == pointId) return p;
  }
  return null;
}
```

(If you implement recommendation 1, this will use `_currentProject!.points` or the new getter.)

**Decision:** [ ] Apply  [ ] Skip

---

### 8. createPoint / updatePoint / deletePoint / movePoint: sync vs async

**Issue:** These methods are `async` and return `Future<bool>` but only call synchronous helpers and log. No async I/O.

**Recommendation:** Either make them synchronous (return `bool`) and update call sites, or leave as-is and add a short comment that they are async for future use. No change required for correctness.

**Decision:** [ ] Apply  [ ] Skip

---

### 9. Import order

**Issue:** `dart:io` is mixed with package imports. Convention is dart imports first, then package, then local.

**Recommendation:** Put `dart:io` at the top with any other `dart:` imports, then `package:` imports.

**Decision:** [ ] Apply  [ ] Skip

---

### 10. createProject: document or set current project

**Issue:** After creating a project, `_currentProject` is not set to the new project. The new project is not “open” in the manager. This may be intentional (e.g. stay on list and let user open it).

**Recommendation:** If “create and open” is desired, set `_currentProject` (and `_currentPoints` if still used) after insert and call `notifyListeners()`. If “create and stay on list” is intended, add a one-line comment on `createProject()`.

**Decision:** [ ] Apply  [ ] Skip

---

## Suggested order

1. **High:** Single source of truth (1) – reduces risk of future bugs and simplifies the rest.
2. **Medium:** refreshPoints (2), saveProject batch delete (3), clearProject _isLoading (4).
3. **Low:** Apply any of 5–10 as you touch the file or during cleanup.

---

## Reference

- File: `lib/core/project_state_manager.dart`
- Related: `lib/core/project_provider.dart`, `lib/db/drift_database_helper.dart`, `lib/db/models/project_model.dart`
- Undo: `undoChanges()` → `loadProject(id)` (reload from DB discards in-memory edits).
