Great to hear it’s working well!  
A systematic testing order will help you catch any edge cases or regressions. Here’s a recommended sequence for thorough testing:

---

## **Recommended Order for Testing Project/Points Interactions**

### **1. Basic CRUD Operations**
- **Create** a new project.
- **Add** points (from both the Points tab and Map tab).
- **Edit** point details (coordinates, note, etc.) from:
  - Points tab (list and details page)
  - Map tab (inline panel and details page)
- **Delete** points from both tabs.
- **Reorder** points in the Points tab.

### **2. Cross-Tab Consistency**
- After editing a point in the Map tab, switch to the Points tab and verify the change is reflected (and vice versa).
- After deleting or reordering points in one tab, check the other tab for correct updates.
- Add a point in one tab, then edit or delete it in the other.

### **3. Save/Undo Workflow**
- Make multiple changes (add, edit, reorder, delete) without saving.
- Verify that the Save and Undo buttons appear as expected.
- Press Save and ensure all changes persist after navigating away and reloading the project.
- Press Undo and ensure all unsaved changes are discarded and the project reverts to the last saved state.

### **4. Edge Cases**
- Try editing/deleting the first and last points.
- Try reordering points to the start/end of the list.
- Add a point, edit it, then delete it before saving.
- Add a point, save, then delete and undo.

### **5. Project-Level Actions**
- Edit project details (name, date, etc.) and verify Save/Undo.
- Delete a project and ensure it is removed from the list.
- Export a project (if applicable) and verify the exported data matches the current state.

### **6. UI/UX**
- Switch tabs rapidly after making changes—ensure no crashes or stale data.
- Test on different device orientations and screen sizes.
- Check for any error messages, loading indicators, or unexpected UI states.

---

## **Tips**
- **Test with both new and existing projects.**
- **Test with projects with 0, 1, and many points.**
- **Check logs for any warnings or errors during each operation.**

---

If you want a printable checklist or want to automate any of these tests, let me know!