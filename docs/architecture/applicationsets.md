# ApplicationSets Hierarchy

This document describes the complete hierarchy of ApplicationSets in our homelab infrastructure, from bootstrap to
application deployment.

## 1. Bootstrap Layer

The bootstrap layer consists of three critical components that initialize the entire infrastructure:

### 1.1 Root Project Configuration

```yaml
metadata:
  name: app-of-apps
spec:
  sourceRepos:
    - 'https://github.com/theepicsaxguy/homelab'
  destinations:
    - namespace: '*'
      server: 'https://kubernetes.default.svc'
```

### 1.2 Core Applications

- Infrastructure ApplicationSet
- Applications ApplicationSet
- ArgoCD ApplicationSet

## 2. Infrastructure Layer

### 2.1 Environment Progression

```yaml
Sync Waves:
- Wave 0: Development (dev-infra)
  - Basic resource allocation
  - Single replica deployments
  - Fast iterations

- Wave 1: Staging (staging-infra)
  - Production-like setup
  - Multiple replicas
  - Full testing environment

- Wave 2: Production (prod-infra)
  - Full HA configuration
  - Strict resource requirements
  - Production-grade security
```

### 2.2 Component Sets

#### Network Components

- Cilium CNI and Service Mesh
- Gateway API Implementation
- DNS Services (CoreDNS)

#### Storage Components

- Longhorn Storage
- CSI Drivers
- Storage Classes

#### Authentication

- Authelia SSO
- LLDAP Directory
- OAuth/OIDC Providers

#### Core Controllers

- Cert Manager
- External Secrets Operator
- Node Feature Discovery

#### Security Components

- Network Policies
- Pod Security Standards
- RBAC Configurations

## 3. Applications Layer

### 3.1 Environment Management

```yaml
Sync Waves:
- Wave 3: Development (dev-apps)
  - Allows empty applications
  - Minimal resource requirements
  - Development-specific configurations

- Wave 4: Staging (staging-apps)
  - Production-like environment
  - Multiple replicas
  - Full testing capabilities

- Wave 5: Production (prod-apps)
  - Strict validation requirements
  - Full HA deployment
  - Production resource allocation
```

### 3.2 Application Categories

#### Media Applications

- Plex
- Jellyfin
- \*arr stack (Sonarr, Radarr, etc.)

#### Development Tools

- Debug utilities
- Testing frameworks
- Development environments

#### External Services

- Third-party integrations
- External APIs
- Cloud service connectors

## 4. Label Management

### 4.1 Infrastructure Components

```yaml
labels:
  app.kubernetes.io/part-of: infrastructure
  app.kubernetes.io/managed-by: argocd
```

### 4.2 User Applications

```yaml
labels:
  app.kubernetes.io/part-of: applications
  app.kubernetes.io/managed-by: argocd
```

## 5. Deployment Flow

1. Bootstrap ApplicationSet: Core Components
2. Infrastructure ApplicationSet: Waves 0-2
3. Applications ApplicationSet: Waves 3-5

Each wave ensures dependencies are met before proceeding.

## 6. Best Practices

### 6.1 ApplicationSet Structure

- Consistent naming conventions
- Proper labels and annotations
- Explicit sync policies
- Appropriate retry mechanisms

### 6.2 Resource Management

- Explicit resource requests/limits
- Environment-appropriate replicas
- Health check implementation
- Meaningful probes

### 6.3 High Availability

- Production: 3+ replicas
- Pod anti-affinity rules
- PodDisruptionBudgets
- Topology spread constraints

### 6.4 Security

- Least privilege principle
- Network policy enforcement
- Secure pod contexts
- RBAC compliance

## 7. Validation and Testing

### 7.1 Current Capabilities

- ArgoCD health checks
- Basic HTTP endpoint checks
- Manual policy validation
- Configuration verification

### 7.2 Planned Improvements

- Automated testing
- Policy validation
- Security scanning
- Performance testing

## 8. Troubleshooting

### 8.1 Common Issues

- Sync failures
- Resource conflicts
- Permission issues
- Network policies

### 8.2 Resolution

1. Check ArgoCD logs
2. Verify resources
3. Validate policies
4. Review RBAC

## 9. Maintenance

### 9.1 Regular Tasks

- Sync status review
- Resource monitoring
- Documentation updates
- Configuration validation

### 9.2 Update Process

1. Development first
2. Testing validation
3. Staging promotion
4. Production deployment

## 10. Future Considerations

### 10.1 Scalability

- Multi-cluster support
- Cross-cluster resources
- Federation capabilities
- Enhanced monitoring

### 10.2 Improvements

- Automated testing
- Disaster recovery
- Backup automation
- Enhanced validation
