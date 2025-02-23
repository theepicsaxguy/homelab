# Environment Architecture

## Overview

This document describes the environment architecture patterns used in our infrastructure, covering development, staging,
and production environments.

## Environment Structure

### Base Configuration

All environments inherit from a common base configuration in `k8s/infra/base/` which contains the core infrastructure
components.

### Environment-Specific Components

Each environment is managed through ArgoCD ApplicationSets that use a consistent path-based pattern:

- Applications: `k8s/apps/{env}/*`
- Infrastructure: `k8s/infra/{env}/*`

Where `{env}` is one of:

- `dev` - Development environment
- `staging` - Pre-production validation
- `prod` - Production environment

### Resource Management

All resources are labeled with their environment using:

```yaml
labels:
  environment: dev|staging|prod
```

This label is automatically applied by ApplicationSets based on the path structure.

### Development Environment (k8s/apps/dev/, k8s/infra/dev/)

- Purpose: Feature development and testing
- Characteristics:
  - Lower resource limits
  - Debug logging enabled
  - Rapid deployment cycles
  - Development-specific tools

### Staging Environment (k8s/apps/staging/, k8s/infra/staging/)

- Purpose: Pre-production validation
- Characteristics:
  - Production-like configuration
  - Moderate resource allocation
  - Standard logging levels
  - Integration testing focus

### Production Environment (k8s/apps/prod/, k8s/infra/prod/)

- Purpose: Live workloads
- Characteristics:
  - High resource limits
  - Optimized for reliability
  - Warning-level logging
  - Maximum replication

## Environment Promotion

Applications can be promoted between environments by:

1. Testing changes in `dev/`
2. Copying successful configurations to `staging/`
3. After validation, promoting to `prod/`

### Promotion Process

1. Copy the application directory between environments
2. Update environment-specific configurations in kustomization overlays
3. Let ArgoCD detect and apply the changes automatically

## Best Practices

1. Always use environment-specific overlays for configuration
2. Maintain consistent directory structure across environments
3. Use environment labels for resource selection
4. Test all changes in dev before promotion
5. Use GitOps workflow for all environment changes
6. Document environment-specific requirements in each overlay

## ApplicationSet Configuration

Applications and infrastructure are managed by ApplicationSets that:

- Use path-based environment detection
- Apply consistent environment labels
- Handle namespace creation
- Enable automated sync and pruning
- Support server-side apply
