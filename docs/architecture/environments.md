# Environment Architecture

## Overview

This document describes the environment configuration patterns used across our GitOps-based infrastructure.

## Environment Structure

The infrastructure follows a three-environment pattern with progressive configuration and requirements:

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
  - Relaxed resource constraints
  - Single replica deployments
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
  - High availability (3 replicas)
  - Pod anti-affinity rules
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
  - High availability (3 replicas)
  - Pod anti-affinity rules
  - No empty applications
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
- Resource limit patches
- High availability configurations
- Environment-specific labels

### ApplicationSet Integration

Managed through ArgoCD ApplicationSets with:

- Progressive sync waves (0 → 1 → 2)
- Environment-specific sync policies
- Automated pruning and self-healing
- Retry policies with exponential backoff

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
