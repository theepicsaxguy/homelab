# Development Environment

This document describes the development environment infrastructure configuration.

## Overview

The development environment (`dev-infra`) is optimized for rapid iteration and testing, with relaxed resource
constraints and simplified deployment configurations.

## Configuration Details

### Resource Allocation

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
```

### Deployment Characteristics

- Single replica deployments
- Sync Wave: 0 (First to deploy)
- Allows empty applications
- Fast reconciliation loops

### Use Cases

- Feature development
- Configuration testing
- Integration testing
- Performance profiling

## Validation

```bash
# Run from repository root
./scripts/validate_manifests.sh -d k8s/infra/overlays/dev
```

## Security Notes

- Network policies still enforced
- RBAC with development-appropriate permissions
- Secrets management through Bitwarden SM Operator
