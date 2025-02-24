# Environment Architecture

## Overview

This document describes our environment architecture and configuration patterns across development, staging, and
production environments.

## Environment Structure

### Development (dev-infra)

- **Purpose**: Testing and development environment
- **Resource Configuration**:

  ```yaml
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
  ```

- **Characteristics**:
  - Allows empty applications
  - Single replica deployments
  - 30s health check timeout
  - Sync Wave: 0 (First to deploy)

### Staging (staging-infra)

- **Purpose**: Pre-production validation environment
- **Resource Configuration**:

  ```yaml
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
  ```

- **Characteristics**:
  - Mirrors production topology
  - Two replicas minimum
  - 60s health check timeout
  - Pod anti-affinity (preferred)
  - Sync Wave: 1 (Deploys after dev)

### Production (prod-infra)

- **Purpose**: Production environment
- **Resource Configuration**:

  ```yaml
  requests:
    cpu: 1000m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 2Gi
  ```

- **Characteristics**:
  - Strict resource limits
  - Three replicas minimum
  - 300s health check timeout
  - Required pod anti-affinity
  - Sync Wave: 2 (Deploys last)

## Implementation Details

### Base Configuration (`k8s/infra/base`)

- Common configurations shared across environments
- Core infrastructure components:
  - Network (Cilium, DNS, Gateway)
  - Storage (CSI drivers)
  - Authentication
  - Controllers
  - Monitoring
  - VPN

### Environment-Specific Overlays

Located in `k8s/infra/overlays/<environment>`:

- Namespace definitions
- Centralized patches directory containing:
  - Resource limit patches
  - High availability configurations
  - Component-specific overrides
- Environment-specific labels

Directory structure:

```
k8s/infra/overlays/<environment>/
├── kustomization.yaml    # Environment overlay configuration
└── patches/             # Centralized location for all patches
    ├── resource-limits.yaml    # Global resource limits
    ├── high-availability.yaml  # HA configurations
    └── <component>.yaml        # Component-specific patches
```

### ApplicationSet Integration

Managed through ArgoCD ApplicationSets with:

- Progressive sync waves (0 → 1 → 2)
- Environment-specific sync policies
- Automated pruning and self-healing
- Retry policies with exponential backoff

## ApplicationSet Configuration

### Key Configuration Requirements

1. **Orphaned Resources**:

   ```yaml
   orphanedResources:
     warn: true
     ignore:
       - group: ''
         kind: ConfigMap
         name: kube-root-ca.crt
       - group: ''
         kind: ServiceAccount
         name: default
   ```

2. **Sync Policy**:

   ```yaml
   syncPolicy:
     automated:
       prune: true
       selfHeal: true
     syncOptions:
       - CreateNamespace=true
       - ServerSideApply=true
     retry:
       limit: 5
       backoff:
         duration: '30s'
         factor: 2
         maxDuration: '10m'
   ```

3. **Environment Variables**:
   - Must use `values.environment` in template references
   - Must use `values.namespace` for namespace definitions

### Implementation Notes

- ApplicationSets must be defined at the infrastructure level
- All boolean values should be direct (`true`/`false`), not strings
- Retry configuration belongs under syncPolicy
- Orphaned resources configuration belongs under spec.template.spec

## High Availability Configuration

### Production & Staging

```yaml
spec:
  replicas: 3
  template:
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfied: DoNotSchedule
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              topologyKey: kubernetes.io/hostname
```

## GitOps Workflow

1. Changes start in development environment
2. Validated changes promote to staging
3. Final validation before production deployment
4. ArgoCD ensures state reconciliation across all environments

## Validation Requirements

- All changes must pass manifest validation
- Kustomize builds must succeed with Helm support
- Resource limits must be appropriate for environment
- High availability configurations must be validated
- Security policies must be environment-appropriate

## Best Practices

- Use targeted patches for environment-specific changes
- Maintain consistent structure across all environments
- Follow progressive deployment patterns
- Implement proper health checks for each environment
- Configure appropriate resource limits
