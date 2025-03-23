# Environment Architecture

## Overview

This document describes our environment architecture and configuration patterns across development, staging, and
production environments.

## Environment Structure

### Development (dev-infra)

#### Purpose

- Fast iteration and testing
- Minimal resource usage
- Development-focused features
- Allows empty applications

#### Configuration

- Single replicas
- Debug capabilities enabled
- Relaxed security policies
- Minimal resource requests

#### Sync Wave: 0

- First environment to receive changes
- Fast sync intervals
- Allows manual intervention
- Basic validation only

### Staging (staging-infra)

#### Purpose

- Pre-production validation
- Performance testing
- Security validation
- Integration testing

#### Configuration

- Two replicas minimum
- Production-like security
- Representative resource allocation
- Full feature testing

#### Sync Wave: 1

- Secondary deployment target
- Automated validation
- Integration testing
- Performance analysis

### Production (prod-infra)

#### Purpose

- Live service delivery
- Maximum stability
- Full security enforcement
- Performance optimization

#### Configuration

- Three replicas minimum
- Strict security policies
- Optimized resource allocation
- Zero-downtime updates

#### Sync Wave: 2

- Final deployment target
- Strict validation
- No direct debugging
- Performance monitoring

## Implementation Details

### Resource Management

#### Development

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

#### Staging

```yaml
resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 512Mi
```

#### Production

```yaml
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 1Gi
```

### High Availability Configuration

#### Development

- Single replica
- Basic health checks
- Manual failover
- Debug access enabled

#### Staging

- Two replicas
- Pod anti-affinity
- Automated failover
- Limited debug access

#### Production

- Three+ replicas
- Strict anti-affinity
- Automated recovery
- No debug access

## ApplicationSet Configuration

### Development

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  syncOptions:
    - CreateNamespace=true
    - ApplyOutOfSyncOnly=true
```

### Staging/Production

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  syncOptions:
    - CreateNamespace=true
    - ApplyOutOfSyncOnly=true
    - RespectIgnoreDifferences=true
    - PruneLast=true
```

## GitOps Workflow

### Development

1. Push changes to main branch
2. Automatic sync to dev
3. Basic validation
4. Manual testing

### Staging

1. Promote from dev
2. Automated testing
3. Performance analysis
4. Security validation

### Production

1. Promote from staging
2. Full validation
3. Gradual rollout
4. Performance monitoring

## Validation Requirements

### Development

- Basic linting
- Resource validation
- Health checks
- Configuration testing

### Staging

- Full test suite
- Performance testing
- Security scanning
- Integration testing

### Production

- Complete validation
- Load testing
- Security audit
- Compliance checks

## Best Practices

### General Guidelines

- Use environment overlays
- Maintain parity where possible
- Document all differences
- Use common components

### Security Guidelines

- Enforce least privilege
- Use network policies
- Enable audit logging
- Implement RBAC

### Resource Guidelines

- Define explicit limits
- Use resource quotas
- Implement autoscaling
- Monitor usage

## Known Limitations

1. No automated promotion
2. Manual validation steps
3. Basic monitoring only
4. Limited automation

## Future Improvements

1. Automated environment promotion
2. Enhanced monitoring
3. Automated testing
4. Advanced validation

## Related Documentation

- [ApplicationSet Configuration](applicationsets.md)
- [Resource Management](../best-practices/resources.md)
- [Security Guidelines](../security/overview.md)
- [Network Architecture](../networking/overview.md)
