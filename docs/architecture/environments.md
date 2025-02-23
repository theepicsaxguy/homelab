# Environment Architecture

## Overview

This document describes the environment architecture patterns used in our infrastructure, covering development, staging,
and production environments.

## Environment Structure

### Base Configuration

All environments inherit from a common base configuration in `k8s/infra/base/` which contains the core infrastructure
components.

### Environment-Specific Components

#### Development (k8s/infra/dev)

- Purpose: Feature development and testing
- Characteristics:
  - Lower resource limits
  - Debug logging enabled
  - Rapid deployment cycles
  - Development-specific tools

#### Staging (k8s/infra/staging)

- Purpose: Pre-production validation
- Characteristics:
  - Production-like configuration
  - Moderate resource allocation
  - Standard logging levels
  - Integration testing focus

#### Production (k8s/infra/prod)

- Purpose: Live workloads
- Characteristics:
  - High resource limits
  - Optimized for reliability
  - Warning-level logging
  - Maximum replication

## Configuration Management

### Patch Strategy

Each environment manages its configurations through targeted patches:

```yaml
patches:
  - path: monitoring-patch.yaml # Component-specific patches
    target:
      kind: ConfigMap
      name: monitoring-config
  - path: network-patch.yaml # Network configurations
    target:
      kind: ConfigMap
      name: network-config
```

### Resource Allocation Guidelines

| Resource Type | Development | Staging | Production |
| ------------- | ----------- | ------- | ---------- |
| Storage       | 100Gi       | 100Gi   | 500Gi      |
| Retention     | 7d          | 14d     | 30d        |
| Replicas      | 1           | 2       | 3          |
| Log Level     | debug       | info    | warn       |

## GitOps Workflow

1. Changes start in development
2. Promoted to staging for validation
3. Finally deployed to production
4. All changes tracked in Git
5. ArgoCD ensures state reconciliation

## Best Practices

1. Always use separate patch files for different components
2. Maintain consistent naming across environments
3. Document resource requirements per environment
4. Use progressive sync waves for dependencies
5. Implement proper validation at each stage

## Validation Requirements

Each environment must pass:

1. Kustomize build validation
2. Resource configuration checks
3. Security policy compliance
4. Network policy verification

## Monitoring and Alerting

Different thresholds and retention periods per environment:

- Development: Focused on debugging
- Staging: Testing alert configurations
- Production: Critical alerts only
