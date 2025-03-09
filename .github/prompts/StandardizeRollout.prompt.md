### **Standardize Rollout and Traffic Routing Configuration**

**Objective:** Ensure consistent and controlled rollout strategies across environments.

**Tasks:**

- Consolidate rollout parameters (`analysis templates`, `traffic routing settings`, `promotion configs`) into reusable
  patches.
- Parameterize dynamic values such as image tags, service names, and weight percentages for controlled updates.
- Ensure environment-specific customizations are handled via patches without affecting the base configurations.

**Expected Fixes:**

- Prevents inconsistencies where ArgoCD updates fail due to incorrect rollout configurations.
- Resolves `Error from server (Invalid): Deployment.apps "cilium-operator" is invalid` by ensuring immutable fields are
  correctly referenced.

📌 **Reference:** See `/root/homelab/docs/external-docs/argocd/argo-documentation.md` for rollout and traffic management
configurations in ArgoCD.
