# **Kustomize Validation & Integrity Check Prompt**

Please analyze all **Kustomize** files within the `k8s/` directory and verify their correctness. The goal is to ensure
that **all configurations are properly structured, linked, and functional**.

## **Validation Requirements**

1. **Kustomize Structure Validation**

   - Ensure `kustomization.yaml` exists in each deployment directory.
   - Validate that all `resources`, `bases`, and `overlays` are correctly referenced.
   - Verify `labels`, `commonAnnotations`, and `namespace` are consistently applied.

2. **Component Linking & Dependencies**

   - Confirm that all `bases` and `overlays` reference valid manifests.
   - Ensure patches (`patchesStrategicMerge`, `patchesJson6902`) correctly apply.
   - Validate `configMapGenerator` and `secretGenerator` correctness (no missing keys).

3. **GitOps & ArgoCD Compatibility**

   - Check if `ApplicationSet` references are valid and properly structured.
   - Ensure proper syncing and reconciliation within ArgoCD.
   - Validate Kustomize manifests for `kustomize build` compatibility.

4. **CI/CD & Deployment Integrity**

   - Ensure manifests pass `kustomize build --enable-alpha-plugins` validation.
   - Detect configuration drift between overlays (staging vs production).
   - Identify misconfigurations that could lead to failed deployments.

5. **Optimization & Best Practices**
   - Suggest improvements for modularity and reuse of manifests.
   - Ensure that `namespace` definitions do not cause conflicts.
   - Optimize resource definitions for maintainability and performance.

## **Expected Output**

Provide a **detailed report** highlighting:

- Any **broken references, missing files, or misconfigured resources**.
- Best practice recommendations for **improving modularity, maintainability, and correctness**.
- Any **security or compliance issues** found in Kustomize configurations.
