### **Automate Environment-Specific Overrides Using Kustomize**

**Objective:** Improve the flexibility and maintainability of environment-specific configurations.

**Tasks:**

- Use Kustomize variable substitution to externalize environment-specific values (e.g., namespace names, cluster IPs,
  environment tags).
- Create minimal override patch files for each environment to capture only necessary deviations from common settings.
- Ensure overrides remain lightweight while maintaining the existing folder structure.

**Expected Fixes:**

- Fixes deployment errors related to `spec.selector: Invalid value: v1.LabelSelector` by ensuring environment-specific
  values are correctly overridden.
- Prevents `Error from server (NotFound): namespaces "adguard" not found` by dynamically defining namespaces per
  environment.

📌 **Reference:** See `/root/homelab/docs/external-docs/kustomize/kustomize.md` for best practices on managing
environment-specific Kustomize configurations.
