# ApplicationSet and Rollout Patterns

## ApplicationSet Management

### Environment-Driven ApplicationSet Structure

All ApplicationSets must follow these patterns:

```yaml
spec:
  generators:
    - list:
        elements:
          - values:
              environment: dev
              namespace: dev-infra # or dev for apps
              minReplicas: '1'
              healthTimeout: '30s'
          # ...staging and prod configurations
```

### Critical Configuration Fields

1. Orphaned Resources:

   - Must be under spec.template.spec
   - Must have both warn and ignore configurations
   - Must ignore default resources (kube-root-ca.crt, default ServiceAccount)

2. Sync Policy:

   - Must include retry configuration
   - Must enable automated prune and selfHeal
   - Must use proper boolean values (not strings)

3. Template References:
   - Must use values.environment notation
   - Must maintain consistent labeling
   - Must use appropriate sync waves

## Rollout Management

### Environment-Specific Requirements

1. Development:

   - Single replica
   - Fast canary progression (30s pauses)
   - Basic resource limits
   - No anti-affinity requirements

2. Staging:

   - Two replicas minimum
   - Moderate canary progression (60s pauses)
   - Preferred pod anti-affinity
   - Production-like resource allocation

3. Production:
   - Three replicas minimum
   - Conservative canary progression (300s pauses)
   - Required pod anti-affinity
   - Full production resource allocation

### Common Rollout Patterns

1. Template Structure:

   ```yaml
   spec:
     revisionHistoryLimit: 3
     selector:
       matchLabels:
         app.kubernetes.io/part-of: [component-type]
     template:
       metadata:
         labels:
           app.kubernetes.io/part-of: [component-type]
   ```

2. Canary Strategy:

   - Start with lower weights in production
   - Include analysis templates
   - Use environment-appropriate pause durations
   - Implement proper health checks

3. Resource Management:
   - Define explicit resource requests and limits
   - Scale appropriately per environment
   - Use consistent memory/CPU ratios

### Anti-Affinity Configuration

1. Staging:

   ```yaml
   affinity:
     podAntiAffinity:
       preferredDuringSchedulingIgnoredDuringExecution:
         - weight: 100
           podAffinityTerm:
             labelSelector:
               matchLabels:
                 app.kubernetes.io/part-of: [component-type]
             topologyKey: kubernetes.io/hostname
   ```

2. Production:
   ```yaml
   affinity:
     podAntiAffinity:
       requiredDuringSchedulingIgnoredDuringExecution:
         - labelSelector:
             matchLabels:
               app.kubernetes.io/part-of: [component-type]
           topologyKey: kubernetes.io/hostname
   ```

## Implementation Checklist

- [ ] Validate ApplicationSet configuration

  - [ ] Proper template references
  - [ ] Correct orphaned resources configuration
  - [ ] Appropriate sync policy settings

- [ ] Verify Rollout configuration

  - [ ] Environment-specific replicas
  - [ ] Correct resource limits
  - [ ] Appropriate anti-affinity rules
  - [ ] Proper canary progression

- [ ] Test deployment progression

  - [ ] Development validation
  - [ ] Staging verification
  - [ ] Production readiness

- [ ] Validate health checks
  - [ ] Timeout configurations
  - [ ] Analysis templates
  - [ ] Rollback behavior

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
    allowEmpty: { { allowEmpty } }
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
