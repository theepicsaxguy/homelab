# Production Environment

This document describes the production environment infrastructure configuration.

## Overview

The production environment (`prod-infra`) implements our strictest configurations with maximum resource allocation,
mandatory high availability, and zero-tolerance for empty applications.

## Configuration Details

### Resource Allocation

```yaml
resources:
  requests:
    cpu: 1000m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 2Gi
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

- Three-replica minimum
- Sync Wave: 2 (Deploys last)
- No empty applications allowed
- Strict resource requirements
- Mandatory pod anti-affinity

### Production Safeguards

- Progressive sync with validation
- Automated rollback on failure
- Mandatory health checks
- Resource quota enforcement
- Network policy validation

## Validation Requirements

- All components must pass resource validation
- High availability configuration required
- Network policies must be strict
- Health probes must be configured
- Security scanning must pass

## Validation Process

```bash
# Run from repository root
./scripts/validate_manifests.sh -d k8s/infra/overlays/prod
```

## Security Implementation

- Zero-trust network policies
- Strict RBAC enforcement
- Mandatory security scanning
- Comprehensive audit logging
- Regular secret rotation

## Monitoring and Alerts

- Resource utilization monitoring
- Performance metrics tracking
- Availability monitoring
- Security event monitoring
- Compliance auditing
