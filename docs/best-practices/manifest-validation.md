# Manifest Validation Guidelines

## Overview

These guidelines define the validation requirements for all Kubernetes manifests in our GitOps-managed infrastructure.

## Pre-Commit Validation

### Required Checks

1. YAML Syntax

   - No syntax errors
   - Proper indentation
   - Valid YAML structure
   - No duplicate keys

2. Resource Schema

   - Valid API versions
   - Required fields present
   - Correct field types
   - Valid enum values

3. Kustomize Validation
   - Base resources exist
   - Valid patches
   - Correct references
   - Resource generation

## Static Analysis

### Resource Requirements

1. Metadata

   ```yaml
   metadata:
     labels:
       app.kubernetes.io/name: <app-name>
       app.kubernetes.io/part-of: <component>
       app.kubernetes.io/managed-by: argocd
   ```

2. Resource Limits

   ```yaml
   resources:
     requests:
       cpu: <required>
       memory: <required>
     limits:
       cpu: <required>
       memory: <required>
   ```

3. Health Checks
   ```yaml
   livenessProbe:
     # Required for all containers
   readinessProbe:
     # Required for all containers
   ```

### Security Requirements

1. Pod Security

   ```yaml
   securityContext:
     runAsNonRoot: true
     readOnlyRootFilesystem: true
     allowPrivilegeEscalation: false
   ```

2. Network Policies
   - Default deny
   - Explicit allows
   - Named ports
   - Valid selectors

## Environment Validation

### Development

- Basic schema validation
- Resource presence
- Security context
- Network policies

### Staging

- Full validation
- Resource limits
- Health checks
- Security compliance

### Production

- Strict validation
- HA requirements
- Security hardening
- Performance checks

## ApplicationSet Validation

### Required Fields

1. Project Configuration

   ```yaml
   spec:
     project: <project-name>
     source:
       repoURL: <git-repo>
       targetRevision: <branch/tag>
       path: <path>
   ```

2. Sync Policy
   ```yaml
   spec:
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
       syncOptions:
         - CreateNamespace=true
         - ApplyOutOfSyncOnly=true
   ```

### Template Validation

- Valid generators
- Required fields
- Path existence
- Source validity

## Validation Tools

### Current Tools

- kubeval
- conftest
- kustomize build
- ArgoCD validation

### Future Tools

- Policy enforcement
- Security scanning
- Custom validators
- Automated testing

## Common Issues

### Resource Issues

1. Missing limits
2. Invalid probes
3. Security context
4. Network policies

### Template Issues

1. Invalid paths
2. Wrong API versions
3. Missing fields
4. Invalid references

## Best Practices

### Resource Management

- Explicit requests/limits
- Appropriate replicas
- Anti-affinity rules
- Update strategies

### Security

- Non-root containers
- Read-only filesystem
- Limited capabilities
- Network isolation

### High Availability

- Multiple replicas
- Pod anti-affinity
- PodDisruptionBudgets
- Rolling updates

## Documentation Requirements

### Resource Documentation

- Purpose description
- Dependencies list
- Configuration notes
- Security requirements

### Change Documentation

- Change description
- Impact assessment
- Testing results
- Rollback plan

## Validation Workflow

### New Resources

1. Create manifest
2. Run static analysis
3. Test in development
4. Review security
5. Update documentation

### Changes

1. Update manifest
2. Validate changes
3. Test impact
4. Update docs
5. Review security

## Environment Specifics

### Development

- Basic validation
- Quick iteration
- Debug enabled
- Local testing

### Staging

- Full validation
- Integration tests
- Performance tests
- Security scans

### Production

- Strict validation
- Zero-downtime
- Full security
- Performance requirements

## Related Documentation

- [GitOps Guidelines](gitops.md)
- [Security Guidelines](../security/overview.md)
- [Resource Management](resources.md)
- [ApplicationSet Configuration](../architecture/applicationsets.md)
