### **Centralize Shared Metadata**

**Task:** Refactor the `k8s/infrastructure` directory to centralize shared metadata.

**Requirements:**

- Create a dedicated directory (e.g., `common`) to store a Kustomization file defining standard labels and annotations.
- Ensure all overlays (e.g., dev, prod) reference this `common` directory to inherit the standardized metadata.
- Maintain the existing folder structure and ensure no metadata duplication.

---

### **Modularize and DRY Up Overlays**

**Task:** Refactor the `k8s/infrastructure` overlays to reduce redundancy and enforce modularity.

**Requirements:**

- Identify and extract repeated configurations (e.g., namespace definitions, common patches, secret references).
- Store these extracted blocks in reusable patch files or components.
- Modify overlay Kustomization files to reference the new common components, ensuring changes apply globally without
  duplication.

---

### **Centralize ArgoCD ApplicationSet & Project Configurations**

**Task:** Improve ArgoCD configuration by centralizing `ApplicationSet` and `Project` definitions within
`k8s/infrastructure`.

**Requirements:**

- Create a common `ApplicationSet` template and project definitions with standardized sync policies, prune/self-heal
  settings, and security constraints.
- Remove wildcard configurations (e.g., `sourceRepos: ['*']`, unrestricted destinations) and replace them with explicit,
  secure references.
- Organize these definitions into reusable modules that ensure all applications follow the same security and
  configuration standards.

---

### **Standardize Rollout and Traffic Routing Settings**

**Task:** Improve rollout and traffic routing configurations within `k8s/infrastructure` to ensure standardization and
flexibility.

**Requirements:**

- Consolidate rollout parameters (e.g., analysis templates, traffic routing settings, pause durations, promotion
  configs) into shared patch files.
- Parameterize dynamic values (e.g., image tags, service names, weight percentages) for easier updates in one central
  place.
- Maintain consistency while allowing environment-specific customizations via patches.

---

### **Automate Environment-Specific Overrides**

**Task:** Simplify environment-specific overrides in `k8s/infrastructure` by making configurations more dynamic.

**Requirements:**

- Utilize Kustomize variable substitution to externalize environment-specific values (e.g., namespace names, cluster
  IPs, environment tags).
- Create minimal override patch files per environment that capture only necessary deviations from common settings.
- Ensure overrides remain lightweight and maintainable while preserving existing folder structure.
