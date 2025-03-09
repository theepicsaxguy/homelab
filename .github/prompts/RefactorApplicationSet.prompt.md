### **Refactor ArgoCD ApplicationSet & Project Configurations**

**Objective:** Ensure centralized, secure, and structured management of ArgoCD `ApplicationSet` and `Project`
definitions.

**Tasks:**

- Standardize sync policies, prune/self-heal settings, and security constraints in a central `ApplicationSet` template.
- Remove wildcard configurations like `sourceRepos: ['*']` and enforce explicit security policies.
- Ensure ArgoCD `Project` configurations define clear boundaries and permissions.
- Validate that ArgoCD applications reference the standardized configurations without unintended drift.

**Expected Fixes:**

- Avoids security misconfigurations by enforcing explicit repo and destination constraints.
- Fixes missing `appproject.argoproj.io` errors due to inconsistent definitions.

📌 **Reference:** See `/root/homelab/docs/external-docs/argocd/argo-documentation.md` for ArgoCD ApplicationSet and
Project syntax.
