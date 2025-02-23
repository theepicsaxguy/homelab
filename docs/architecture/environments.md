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

## Environment Promotion

### Promotion Process
1. Development to Staging
   - Create feature branch from `main`
   - Make changes in `k8s/infra/dev/`
   - Test and validate in dev environment
   - Create PR to promote to staging
   - Apply changes to `k8s/infra/staging/`
   - Validate in staging environment

2. Staging to Production
   - Ensure all staging tests pass
   - Create promotion PR
   - Apply changes to `k8s/infra/prod/`
   - Validate in production environment
   - Merge to `main`

### Validation Steps
For each promotion:
1. Run manifest validation:
```bash
./scripts/validate_manifests.sh -d k8s/infra/{target-env}
```
2. Review resource allocation changes
3. Verify configuration differences
4. Test dependent services
5. Check monitoring dashboards

### Rollback Procedure
If issues are detected:
1. Revert the promotion commit
2. ArgoCD will automatically sync back
3. Verify services return to previous state
4. Document issues found
5. Update test cases

### Environment Labels
Applications are tracked using labels:
```yaml
labels:
  environment: dev|staging|prod
  app.kubernetes.io/managed-by: argocd
  dev.pc-tips: infrastructure
```

### Sync Wave Order
Infrastructure components sync in this order:
1. CRDs and Operators (wave -1)
2. Core Infrastructure (wave 0)
3. Environment-specific components (wave 1)
4. Applications (wave 2)

## Environment Promotion Examples

### Example: Updating Monitoring Retention

Here's a practical example of promoting a monitoring configuration change:

1. Development Change
```yaml
# k8s/infra/dev/monitoring-patch.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: monitoring-config
  namespace: monitoring
data:
  retention.period: '7d'    # Testing new retention period
  storage.size: '100Gi'
  environment: 'dev'
  log.level: 'debug'
```

2. Staging Validation
```yaml
# k8s/infra/staging/monitoring-patch.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: monitoring-config
  namespace: monitoring
data:
  retention.period: '14d'   # Validate with more data
  storage.size: '100Gi'
  environment: 'staging'
  log.level: 'info'
```

3. Production Deployment
```yaml
# k8s/infra/prod/monitoring-patch.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: monitoring-config
  namespace: monitoring
data:
  retention.period: '30d'   # Final production value
  storage.size: '500Gi'
  environment: 'prod'
  log.level: 'warn'
```

### Promotion Checklist

Before promoting between environments:

1. Resource Impact Assessment
   - Storage requirements
   - CPU/Memory changes
   - Network policy updates
   - Security implications

2. Testing Requirements
   - Unit tests in dev
   - Integration tests in staging
   - Load tests before prod
   - Backup verification

3. Documentation Updates
   - Update change logs
   - Record configuration decisions
   - Update runbooks if needed
   - Document test results

### Common Pitfalls

1. Resource Mismatch
   - Always validate resource quotas
   - Check storage class availability
   - Verify node capacity

2. Configuration Drift
   - Use `kustomize build` to verify changes
   - Compare environment differences
   - Check for missing patches

3. Dependency Management
   - Validate service dependencies
   - Check API versions
   - Verify CRD compatibility

## Environment Migration
