# Progressive Deployment with Argo Rollouts

## Overview

This document describes the progressive deployment configuration using Argo Rollouts in our infrastructure.

## Configuration Structure

```
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

## Configuration Details

### Base Configuration

The base configuration installs Argo Rollouts from the official release manifest without any modifications.

### Environment-Specific Configurations

Each environment customizes the deployment through patches in their respective `patches/` directory:

- **Development**: Single replica with minimal resource allocation
- **Staging**: Two replicas with moderate resources
- **Production**: Three replicas with HA configuration and pod anti-affinity

All patches follow our centralized patches structure within each environment's overlay directory.

## Usage

The Rollouts controller is deployed automatically through our infrastructure ApplicationSet with appropriate sync waves.
For using Rollouts in your applications, refer to the [external documentation](../external-docs/getting-started.md).
