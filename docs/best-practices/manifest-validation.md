# Manifest Validation Requirements

## Overview

This document outlines the validation requirements and procedures for Kubernetes manifests in our GitOps workflow.

## Validation Tools

### Kubeconform

- All manifests must pass validation against Kubernetes v1.32.0 schemas
- Strict validation is enabled
- CustomResourceDefinitions are exempted from schema validation
- Missing schemas are ignored to allow for custom resources

### Kustomize

- All kustomization directories must successfully build
- Kustomize overlays must follow the repository structure guidelines
- Helm support must be enabled with --enable-helm flag
- Components and ApplicationSets must be properly referenced

### Resource Validation

#### Development Environment

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
```

#### Staging Environment

```yaml
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
replicas: 3
```

#### Production Environment

```yaml
resources:
  requests:
    cpu: 1000m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 2Gi
replicas: 3
```

## Validation Process

1. **Local Validation**

   ```bash
   # Run from repository root
   ./scripts/validate_manifests.sh -d k8s/infra
   ```

2. **CI/CD Validation**

   - Runs automatically on pull requests
   - Validates all environments
   - Checks resource specifications
   - Verifies high availability configs

3. **Security Scanning**
   - Trivy scans for vulnerabilities
   - Critical and High severity issues must be addressed
   - Results uploaded to GitHub Security tab

## Common Validation Rules

1. **Resource Requirements**

   - All containers must have resource requests/limits
   - Values must match environment specifications
   - No over-provisioning allowed

2. **High Availability**

   - Staging/Production require 3 replicas
   - Pod anti-affinity rules enforced
   - Topology spread constraints validated

3. **Network Policies**

   - Must be present for all components
   - Follow zero-trust model
   - Proper ingress/egress rules

4. **Health Checks**
   - Liveness probes required
   - Readiness probes configured
   - Appropriate timeouts set

## Validation Scripts

### validate_manifests.sh

- Validates Kubernetes manifests
- Checks kustomize builds
- Verifies resource specifications
- Run from repository root

### fix_kustomize.sh

- Fixes common kustomization issues
- Updates deprecated fields
- Standardizes formatting

## Error Resolution

1. **Resource Validation Failures**

   - Check environment-specific requirements
   - Verify resource limits
   - Validate replica counts

2. **Kustomize Build Errors**

   - Verify path references
   - Check component existence
   - Validate patches

3. **Security Scan Failures**
   - Address Critical/High issues
   - Document exceptions
   - Update affected components
