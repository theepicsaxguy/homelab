# Manifest Validation Requirements

## Overview

All Kubernetes manifests in this repository must pass automated validation checks before being merged. This document
outlines the validation requirements and tools used.

## Validation Tools

### Kubeconform

- All manifests must pass validation against Kubernetes v1.32.0 schemas
- Strict validation is enabled
- CustomResourceDefinitions are exempted from schema validation
- Missing schemas are ignored to allow for custom resources

### Kustomize

- All kustomization directories must successfully build
- Kustomize overlays must follow the repository structure guidelines
- Components and ApplicationSets must be properly referenced
- Helm chart references must be properly configured with appropriate version pinning

### Helm Chart Validation

- All Helm charts referenced in kustomizations must pass `helm lint`
- Charts must be compatible with Kubernetes v1.32.0
- Charts are validated in their downloaded location under the component's `charts/` directory
- Chart dependencies must be properly declared and versioned
- Icons in Chart.yaml are recommended but not required

### Trivy Security Scanner

- All manifests are scanned for security issues
- Critical and High severity issues must be addressed
- Results are uploaded to GitHub Security tab for tracking

## Structure Requirements

- All manifests must be in YAML format
- Raw manifests should be avoided in favor of kustomizations
- Infrastructure-level resources must be in `k8s/infra/`
- Application resources must be in `k8s/apps/`

## Environment-Specific Configurations

### Patch Structure

Each environment (dev/staging/prod) should follow these guidelines for patches:

1. Each configuration type should have its own patch file (e.g., `monitoring-patch.yaml`, `network-patch.yaml`)
2. Patches must be explicitly targeted in kustomization.yaml:

```yaml
patches:
  - path: monitoring-patch.yaml
    target:
      kind: ConfigMap
      name: monitoring-config
```

3. Never combine multiple resource patches in a single file
4. Use consistent naming patterns across environments
5. Each patch file should modify only one resource

### Environment Organization

- Base configurations in `k8s/infra/base/`
- Environment-specific patches in respective directories:
  - `k8s/infra/dev/`
  - `k8s/infra/staging/`
  - `k8s/infra/prod/`
- Each environment should maintain its own set of patch files

## Best Practices

1. Use kustomization overlays for environment-specific changes
2. Keep base configurations minimal
3. Version all images explicitly
4. Document any security-related exceptions
5. Test builds locally before pushing changes

## Local Validation

To run validation checks locally:

```bash
# Validate manifests structure
./scripts/validate_manifests.sh -d k8s

# Validate with kubeconform
kubeconform -strict -ignore-missing-schemas -summary -kubernetes-version=1.32.0 -skip CustomResourceDefinition k8s/**/*.yaml

# Validate kustomize builds
find k8s -name kustomization.yaml -exec dirname {} \; | while read dir; do
    kustomize build --enable-helm "$dir"
done
```
