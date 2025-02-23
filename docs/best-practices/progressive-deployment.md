# Progressive Deployment Strategy

## Overview

This document outlines our GitOps deployment strategy using ArgoCD, which implements:

1. PR-based preview deployments
2. Progressive promotion through environments
3. Automated health checks and rollbacks

## PR Preview Deployments

- PRs are deployed only when tagged with `DeployPR`
- Each PR gets an isolated namespace (`pr-{number}`)
- Preview environments are automatically cleaned up when PRs are closed
- Uses dev environment configuration as base

## Progressive Deployment Flow

### Wave Order and Health Checks

1. PR Previews (Wave -2)
2. Infrastructure Components
   - Dev (Wave 0, 30s health check)
   - Staging (Wave 1, 60s health check)
   - Production (Wave 2, 300s health check)
3. Applications
   - Dev (Wave 3, 30s health check)
   - Staging (Wave 4, 60s health check)
   - Production (Wave 5, 300s health check)

### Environment Characteristics

#### Development

- Allows empty applications
- Single replica deployments
- Quick health checks (30s)
- Fast iteration cycle

#### Staging

- No empty applications allowed
- 2 replica minimum
- Extended health checks (60s)
- Production-like validation

#### Production

- Strict no-empty policy
- 3 replica minimum for HA
- Thorough health validation (300s)
- Automated rollback on failure

## Promotion Requirements

1. Changes must be healthy in current environment
2. Previous environment must be stable
3. Health checks must pass within timeout
4. Required replica count must be met

## Rollback Behavior

- Automatic rollback on health check failure
- 3 revision history maintained
- Failed promotions prevent downstream environment updates
- Orphaned resources generate warnings

## Best Practices

1. Always test changes in dev first
2. Use `DeployPR` tag for feature validation
3. Monitor promotion progress in ArgoCD UI
4. Check application health metrics before production promotion
