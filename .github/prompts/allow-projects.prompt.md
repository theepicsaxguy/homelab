**Prompt:** I want to dynamically manage namespaces in ArgoCD using Kustomize components. We already have the following
folder structure:

```
infrastructure/
├── auth/
├── common/
│   ├── components/
│   │   ├── configmap-validation/
│   │   ├── container-images/
│   │   ├── env-vars/
│   │   ├── ha-settings/
│   │   ├── immutable-resources/
│   │   ├── metadata/
│   │   ├── namespace-manager/
│   │   ├── rollouts/
│   │   ├── high-availability.yaml
│   │   ├── kustomization.yaml
│   │   ├── pod-disruption-budget.yaml
│   │   ├── resource-limits.yaml
│   ├── kustomization.yaml
│   ├── varreference.yaml
```

### **Requirements:**

1.  **Dynamically manage namespaces** inside `infrastructure/common/components/namespace-manager/`
2.  **Use Kustomize components** to define namespaces without hardcoding them in ArgoCD AppProject.
3.  **Ensure new namespaces are automatically included** when added to `namespace-manager/` without manual updates.
4.  **ArgoCD AppProject should reference the dynamically managed namespaces** without modifying its YAML when new
    namespaces are added.
5.  **Ensure compatibility with ArgoCD v2.10+**, which supports Kustomize components natively.

### **Implementation Details:**

- **Each namespace is defined as a Kustomize resource** under `infrastructure/common/components/namespace-manager/`.
- **`kustomization.yaml` in `namespace-manager/` automatically aggregates all namespaces**.
- **AppProject uses `kustomize.components` to reference the namespace-manager dynamically**.
- **New namespaces should not require modifying AppProject YAML**.

### **Expected Output:**

- A **fully working example** of:
  - `namespace-manager/kustomization.yaml` that aggregates all namespaces dynamically.
  - `ArgoCD AppProject` definition that dynamically includes all namespaces from `namespace-manager/`.
  - Example ArgoCD Application YAML demonstrating how to deploy into dynamically managed namespaces.

Provide only **fully functional and tested YAML files** with no placeholders.
