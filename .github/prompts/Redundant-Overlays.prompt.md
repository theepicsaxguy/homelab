### **Eliminate Redundant Configurations in Overlays**

**Objective:** Reduce unnecessary duplication across Kustomize overlays by modularizing shared elements.

**Tasks:**

- Identify common configuration elements (e.g., namespace definitions, patches, secrets, resource limits).
- Extract these into reusable `patches` or `components` to be referenced by overlays.
- Modify overlay `kustomization.yaml` files to use the extracted components, ensuring consistent updates.

**Expected Fixes:**

- Fixes namespace-related errors (`Error from server (NotFound): namespaces "gateway" not found`).
- Prevents redundancy in resource definitions, making maintenance easier.

📌 **Reference:** See `/root/homelab/docs/external-docs/kustomize/kustomize.md` for information on modularizing
overlays.
