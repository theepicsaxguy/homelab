# Progressive Deployment with Argo Rollouts

## Overview

This document describes the progressive deployment configuration using Argo Rollouts in our infrastructure.

## Configuration Structure

```bash
infra/
├── base/
│   └── controllers/
│       └── argo-rollouts/
│           └── kustomization.yaml    # Base configuration
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml
    │   └── patches/
    │       └── argo-rollouts.yaml    # Single replica, basic resources
    ├── staging/
    │   ├── kustomization.yaml
    │   └── patches/
    │       └── argo-rollouts.yaml    # 2 replicas, increased resources
    └── prod/
        ├── kustomization.yaml
        └── patches/
            └── argo-rollouts.yaml    # 3 replicas, HA with pod anti-affinity
```

## Environment-Specific Configuration Details

### Development Environment

- **Replicas**: 1 (Single replica deployment)
- **Resource Limits**:

  ```yaml
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
  ```

- **Canary Strategy**:
  - Initial weight: 10%
  - Pause duration: 30s
  - Analysis after each step
  - Final promotion to 100%

### Staging Environment

- **Replicas**: 2 (Multi-replica deployment)
- **Resource Limits**:

  ```yaml
  requests:
    cpu: 500m
    memory: 256Mi
  limits:
    cpu: 2000m
    memory: 512Mi
  ```

- **High Availability**:

  - Preferred pod anti-affinity
  - Topology key: kubernetes.io/hostname
  - Weight: 100

- **Canary Strategy**:
  - Initial weight: 20%
  - Pause duration: 60s
  - Analysis after initial deployment
  - Intermediate step at 50%
  - Final promotion to 100%

### Production Environment

- **Replicas**: 3 (High availability deployment)
- **Resource Limits**:

  ```yaml
  requests:
    cpu: 1000m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 2Gi
  ```

- **High Availability**:

  - Required pod anti-affinity
  - Topology key: kubernetes.io/hostname
  - Strict node distribution

- **Canary Strategy**:
  - Conservative initial weight: 10%
  - Extended pause duration: 300s
  - Multiple analysis steps
  - Intermediate step at 30%
  - Final promotion to 100%

## Common Configuration

### Template Structure

All rollout templates must include:

- Proper label selectors using app.kubernetes.io/part-of
- Consistent revision history limit (3)
- Image specification
- Resource limits
- Environment-appropriate affinity rules

### Health Checks

- Development: 30s timeout
- Staging: 60s timeout
- Production: 300s timeout

## Usage

The Rollouts controller is deployed automatically through our infrastructure ApplicationSet with appropriate sync waves.
Both infrastructure and application rollouts follow the same pattern with environment-specific configurations.

### Implementing New Rollouts

When implementing new rollouts:

1. Start with the development environment configuration
2. Ensure proper resource limits are set
3. Configure appropriate anti-affinity rules for staging/production
4. Set environment-specific analysis templates
5. Validate configurations using validate_manifests.sh

For application-specific rollout implementations, refer to the applications documentation.
