### **Centralize Shared Metadata in Kustomize**

**Objective:** Reduce metadata duplication and enforce consistency across Kustomize overlays.

**Tasks:**

- Create a dedicated `common` directory for storing shared metadata, including labels and annotations.
- Refactor all overlays (`dev`, `prod`, etc.) to reference this `common` directory.
- Ensure overlays inherit metadata without redundant duplication.
- Verify that `kubectl apply --dry-run=server` correctly processes the changes without missing metadata.

**Expected Fixes:**

- Resolves issues where Kustomize fails to apply consistent labels.
- Ensures all resources include required metadata without manual duplication.

📌 **Reference:** See `/root/homelab/docs/external-docs/kustomize/kustomize.md` for details on Kustomize syntax and best
practices.
