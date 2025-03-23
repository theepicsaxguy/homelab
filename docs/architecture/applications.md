# Application Architecture

## Overview

This document describes the application deployment architecture in our homelab infrastructure, following GitOps
principles and using ArgoCD as the deployment mechanism.

## Structure

```
k8s/applications/
├── base/                 # Base configurations
│   ├── external/        # External service integrations
│   ├── media/          # Media applications
│   └── tools/          # Development tools
└── overlays/            # Environment-specific configurations
    ├── dev/            # Development environment
    ├── staging/        # Staging environment
    └── prod/           # Production environment
```

## Deployment Strategy

### Environment Progression

1. Development (Wave 3)

   - Initial deployment target
   - Fast iteration cycle
   - Minimal resource requirements
   - Basic validation

2. Staging (Wave 4)

   - Pre-production validation
   - Representative resources
   - Full feature testing
   - Integration validation

3. Production (Wave 5)
   - Final deployment target
   - Full resource allocation
   - Zero-downtime updates
   - Complete validation

### High Availability Requirements

#### Development

- Single replica acceptable
- Basic health checks
- Debug capabilities
- Fast recovery

#### Staging

- Two replicas minimum
- Pod anti-affinity
- Automated recovery
- Health monitoring

#### Production

- Three replicas minimum
- Strict anti-affinity
- Zero-downtime updates
- Full monitoring (planned)

## Application Categories

### External Services

#### Proxmox Integration

- Health monitoring
- API integration
- Resource management
- Metrics collection (planned)

#### TrueNAS Integration

- Storage provisioning
- Backup coordination
- Data management
- Performance monitoring (planned)

#### Home Assistant Integration

- Automation control
- Device management
- State monitoring
- Event handling

### Media Applications

#### Core Components

- Plex media server
- Jellyfin alternative
- arr-stack (Sonarr, Radarr, etc.)
- Media management tools

#### Configuration

- Persistent storage
- Transcoding support
- Hardware acceleration
- Network optimization

### Development Tools

#### Debug Tools

- Network utilities
- Diagnostic containers
- Testing frameworks
- Monitoring tools (planned)

#### Utility Containers

- Build environments
- CI/CD tools
- Development services
- Testing platforms

## Security Considerations

### Authentication

- Authelia SSO integration
- OIDC authentication
- Role-based access
- MFA enforcement

### Authorization

- Kubernetes RBAC
- Network policies
- Pod security
- Resource quotas

### Data Protection

- Encrypted storage
- Secure communications
- Backup encryption
- Access auditing

## Resource Management

### Default Limits

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

#### Staging/Production

```yaml
resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 512Mi
```

### Storage Configuration

- Dynamic provisioning
- Capacity planning
- Performance tiers
- Backup integration

## Current Limitations

1. Basic health monitoring
2. Manual scaling
3. Limited automation
4. Basic metrics only

## Security Policies

### Network Security

- Default deny-all
- Explicit allows only
- Namespace isolation
- Service mesh mTLS

### Pod Security

- Non-root execution
- Read-only root filesystem
- Dropped capabilities
- Resource constraints

### High Availability

- Pod anti-affinity
- Topology spread
- Disruption budgets
- Recovery automation

## Future Enhancements

1. Monitoring stack integration
2. Automated scaling
3. Enhanced automation
4. Advanced metrics
5. Performance optimization

## Related Documentation

- [Environment Configuration](environments.md)
- [Security Guidelines](../security/overview.md)
- [Network Architecture](../networking/overview.md)
- [Storage Configuration](../storage/overview.md)
