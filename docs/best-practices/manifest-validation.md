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

### Trivy Security Scanner

- All manifests are scanned for security issues
- Critical and High severity issues must be addressed
- Results are uploaded to GitHub Security tab for tracking

## Structure Requirements

- All manifests must be in YAML format
- Raw manifests should be avoided in favor of kustomizations
- Infrastructure-level resources must be in `k8s/infra/`
- Application resources must be in `k8s/apps/`

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
