# Plan: Fix `use_build_context_synchronously` Issues

This document lists all current **BuildContext-across-async-gap** diagnostics and how to fix them.

---

## Summary

| Location | Count | Strategy |
|----------|-------|----------|
| **Analyzer-reported (active)** | 9 | Fix with mounted/refactor |
| **Existing `// ignore`** | 3 | Replace with proper fix where possible |

**Total distinct sites:** 6 files (9 analyzer issues + 2 files with existing ignores that can be fixed).

---

## 1. `lib/ble/rtk_device_service.dart` (line 109)

**Issue:** `context` is passed into `connectViaBle(device, context)` and then passed to `_bleTransport.connectToDevice(device, context)` **after** `await _disconnectCurrent()`, so the BuildContext is used across an async gap.

**Root cause:** The optional `BuildContext?` is threaded through the async call chain. `BleService.connectToDevice` and `BleRtkTransport.connectToDevice` accept it but **do not use it** in the current code (it’s reserved for “future extensions”).

**Fix (recommended):**

- **Option A (clean):** Remove the `context` parameter from the async chain so BuildContext is never passed across an async gap.
  - In `RtkDeviceService.connectViaBle`: remove the `BuildContext? context` parameter; call `_bleTransport.connectToDevice(device)` (no context).
  - In `BleRtkTransport.connectToDevice`: remove the `BuildContext? context` parameter; delegate to `_bleService.connectToDevice(device)` without context.
  - In `BleService.connectToDevice`: remove the `BuildContext? context` parameter.
  - **Call site** (`rtk_devices_screen.dart`): change to `await _rtkService.connectViaBle(device)`. Any UI (snackbars, dialogs) after connect should be done **after** the `await`, guarded by `if (!mounted) return;` (call site already has access to `context` and can do that).
- **Option B:** If you must keep a way to show UI from inside the service later, use a callback (e.g. `void Function()? onConnected`) or a value-notifier instead of passing `BuildContext` through async code.

**Recommended:** Option A.

---

## 2. `lib/map/widgets/gps_info_panel.dart` (lines 348, 353, 355)

**Issue:** “Guarded by an unrelated 'mounted' check.” After `await widget.rtkService.disconnect()`, the code uses `if (mounted) { ... Navigator.of(context).pop(); ... ScaffoldMessenger.of(context).showSnackBar(...) }`. The linter does not treat this as a proper guard for `context` in this async callback.

**Fix:**

- Use an explicit “guard then use” pattern so the guard is clearly for the following `context` use:
  - After the `await`, start with `if (!mounted) return;` on its own line.
  - Then use `context` (e.g. `Navigator.of(context).pop()`, `ScaffoldMessenger.of(context).showSnackBar(...)`, `S.of(context)`).
- Apply this in both the `try` block (Navigator + SnackBar) and the `catch` block (SnackBar + `S.of(context)`), so every use of `context` after the async gap is preceded by `if (!mounted) return;`.

---

## 3. `lib/ui/screens/ble/rtk_devices_screen.dart` (lines 1819, 1851, 1853)

**Issue:** After multiple `await`s and inner `if (mounted) setState(...)` blocks, `ScaffoldMessenger.of(context).showSnackBar(...)` and `S.of(context)` are called **outside** any `mounted` check, so context is used across an async gap.

**Fix:**

- **Line 1819:** Wrap the “connection failed” SnackBar in `if (mounted) { ScaffoldMessenger.of(context).showSnackBar(...); }`.
- **Lines 1851 & 1853:** In the `catch` block, wrap the SnackBar (and the `S.of(context)` used inside it) in `if (mounted) { ... }`.

Ensure every use of `context` after any `await` in this method is inside a block that is guarded by `if (!mounted) return;` or `if (mounted) { ... }`.

---

## 4. `lib/ui/screens/settings/settings_screen.dart` (lines 597, 607)

**Issue:** “Guarded by an unrelated 'mounted' check.” In `_deleteAllNtripHosts(BuildContext context)`, `context` is a **parameter** (could be any caller’s context), while `mounted` refers to the **State**. The linter considers the mounted check unrelated to this `context`.

**Fix:**

- Prefer using the **State’s** `context` for any UI after async work, and guard it with the State’s `mounted`:
  - Change the method to **not** take `BuildContext context`; use the State’s `context` inside the method when showing the dialog and SnackBars.
  - After `await showDialog(...)` use `if (!mounted) return;` then use `context` for the next operations.
  - After `await DriftDatabaseHelper.instance.deleteAllNtripSettings()` use `if (!mounted) return;` then `ScaffoldMessenger.of(context).showSnackBar(...)` (and same in the catch block).
- Update the **call site** of `_deleteAllNtripHosts` to call it with no arguments, e.g. `_deleteAllNtripHosts()`.

---

## 5. Existing ignores that can be fixed properly

### 5.1 `lib/ui/screens/projects/project_tabbed_screen.dart` (lines 192–195)

**Current:** After `await context.projectState.createProject(...)`, the code uses `context.projectState.loadProject(...)` and `context.projectState.currentProject` with `// ignore: use_build_context_synchronously`.

**Fix:** Capture the provider/state reference **before** any await so you never use `context` after an async gap:

- At the start of `_insertNewProjectToDb()`:  
  `final projectState = context.projectState;`
- After the first await, use `projectState` instead of `context.projectState`:  
  `await projectState.loadProject(widget.project.id);`  
  `final dbProject = projectState.currentProject;`
- Remove the two `// ignore` comments.

### 5.2 `lib/ui/screens/projects/projects_list_screen.dart` (line 1037)

**Current:** Inside a loop, `await context.projectState.deleteProject(id)` is used with `// ignore: use_build_context_synchronously`.

**Fix:** Capture the state reference before the loop (and before any await in that flow):

- Before the `for (String id in idsToDelete)` loop:  
  `final projectState = context.projectState;`
- Inside the loop:  
  `final success = await projectState.deleteProject(id);`
- Remove the `// ignore` comment.

---

## Implementation order

1. **rtk_device_service + ble_rtk_transport + ble_service**  
   Remove `BuildContext?` from the connect APIs and update `rtk_devices_screen` call site (and add mounted guard for any UI after `connectViaBle` if needed).

2. **gps_info_panel**  
   Use `if (!mounted) return;` then use `context` after each async gap in the disconnect button callback.

3. **rtk_devices_screen**  
   Wrap both SnackBar usages (connection failed + catch block) in `if (mounted) { ... }`.

4. **settings_screen**  
   Refactor `_deleteAllNtripHosts` to use the State’s `context` and no parameter, with `if (!mounted) return;` before each use of `context` after an await.

5. **project_tabbed_screen**  
   Capture `context.projectState` before await and use that reference after; remove ignores.

6. **projects_list_screen**  
   Capture `context.projectState` before the delete loop and use it inside the loop; remove ignore.

---

## Verification

After changes:

- Run:  
  `dart analyze teleferika.app`  
  and confirm there are no `use_build_context_synchronously` infos.
- Search the repo for:  
  `use_build_context_synchronously`  
  and ensure no remaining `// ignore` comments (unless explicitly justified and documented).

---

## References

- [Dart lint: use_build_context_synchronously](https://dart.dev/tools/linter-rules/use-build-context-synchronously)
- Flutter: use `mounted` on `State` before using `context` after `await`; avoid passing `BuildContext` into async methods or storing it across async gaps.
