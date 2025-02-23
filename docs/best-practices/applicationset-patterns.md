# ApplicationSet Patterns

## Overview

This document describes the ApplicationSet patterns used in our infrastructure to manage multi-environment deployments
through GitOps.

## Core Patterns

### Infrastructure ApplicationSet

```yaml
generators:
  - matrix:
      generators:
        - list:
            elements:
              - environment: dev
                namespace: dev-infra
                allowEmpty: true
                syncWave: '0'
              - environment: staging
                namespace: staging-infra
                allowEmpty: false
                syncWave: '1'
              - environment: prod
                namespace: prod-infra
                allowEmpty: false
                syncWave: '2'
        - git:
            directories:
              - path: k8s/infra/overlays/{{environment}}
```

### Progressive Deployment

1. **Development (Wave 0)**

   - First environment to receive changes
   - Allows empty applications for testing
   - Fast reconciliation for rapid iteration

2. **Staging (Wave 1)**

   - Validates changes in production-like setup
   - No empty applications allowed
   - Full HA testing environment

3. **Production (Wave 2)**
   - Final deployment stage
   - Strict validation requirements
   - Full HA with zero-tolerance for empties

## Sync Policies

### Common Configuration

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
    allowEmpty: '{{allowEmpty}}'
  syncOptions:
    - CreateNamespace=true
    - PruneLast=true
    - RespectIgnoreDifferences=true
  retry:
    limit: 5
    backoff:
      duration: '30s'
      factor: 2
      maxDuration: '10m'
```

### Environment-Specific Behaviors

- **Development**:

  - Allows empty applications
  - Quick sync intervals
  - Relaxed pruning policies

- **Staging/Production**:
  - No empty applications
  - Conservative sync intervals
  - Strict pruning policies
  - Extended health checks

## Best Practices

1. **Wave Management**

   - Use consistent wave numbering
   - Allow sufficient time between waves
   - Monitor wave progression

2. **Health Checks**

   - Define appropriate checks per component
   - Include dependency validation
   - Set reasonable timeouts

3. **Error Handling**

   - Configure meaningful retry policies
   - Set appropriate backoff values
   - Document recovery procedures

4. **Resource Management**
   - Use environment-specific patches
   - Maintain consistent labeling
   - Follow namespace conventions

## Validation

Always validate ApplicationSet changes:

```bash
# From repository root
./scripts/validate_manifests.sh -d k8s/infra
```

## Monitoring

Monitor ApplicationSet health through:

1. ArgoCD dashboard
2. Prometheus metrics
3. Status checks
4. Event logging
