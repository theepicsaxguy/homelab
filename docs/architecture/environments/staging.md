# Staging Environment

This document describes the staging environment infrastructure configuration.

## Overview

The staging environment (`staging-infra`) mirrors production configuration, enabling pre-production validation with
production-like resource constraints and high availability settings.

## Configuration Details

### Resource Allocation

```yaml
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

### High Availability Configuration

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

### Deployment Characteristics

- Three-replica deployments
- Sync Wave: 1 (Deploys after dev)
- Pod anti-affinity for HA
- Production-like configuration

### Use Cases

- Pre-production validation
- Performance testing
- HA configuration testing
- Integration verification

## Validation

```bash
# Run from repository root
./scripts/validate_manifests.sh -d k8s/infra/overlays/staging
```

## Security Notes

- Production-equivalent network policies
- Strict RBAC enforcement
- Full security scanning
- Comprehensive monitoring
