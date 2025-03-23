# ApplicationSets Hierarchy

This document describes the complete hierarchy of ApplicationSets in our homelab infrastructure, from bootstrap to
application deployment.

## 1. Bootstrap Layer (k8s/sets/)

The bootstrap layer is the foundation of our GitOps deployment strategy. It consists of three critical components that
initialize the entire infrastructure:

### 1.1 Root Project (sets/project.yaml)

```yaml
# Root project that enables management of all other components
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

- **Infrastructure Set**: Manages all infrastructure components
- **Applications Set**: Handles all user applications
- **ArgoCD Set**: Manages ArgoCD itself

## 2. Infrastructure Layer (k8s/infrastructure/)

The infrastructure layer follows a hierarchical deployment pattern with environment-specific configurations.

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

Each infrastructure domain has its own ApplicationSet that inherits from the environment configuration:

#### Network Components (network/application-set.yaml)

- Cilium CNI
- Gateway API
- DNS Services

#### Storage Components (storage/application-set.yaml)

- Longhorn
- CSI Drivers
- Storage Classes

#### Authentication (auth/application-set.yaml)

- Authelia
- LLDAP
- OAuth Providers

#### Core Controllers (controllers/application-set.yaml)

- Cert Manager
- External Secrets
- Node Feature Discovery

#### VPN Services (vpn/application-set.yaml)

- WireGuard
- OpenVPN
- Network Policies

## 3. Applications Layer (k8s/applications/)

The applications layer manages all user workloads with its own environment progression.

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

#### Media Applications (media/application-set.yaml)

- Plex
- Jellyfin
- \*arr stack (Sonarr, Radarr, etc.)

#### Development Tools (tools/application-set.yaml)

- Debugging tools
- Development utilities
- Testing frameworks

#### External Services (external/application-set.yaml)

- Third-party integrations
- External APIs
- Cloud service connectors

## 4. Label Management

### 4.1 Infrastructure Components

All infrastructure components must include:

```yaml
labels:
  app.kubernetes.io/part-of: infrastructure
  app.kubernetes.io/managed-by: argocd
```

### 4.2 User Applications

All applications must include:

```yaml
labels:
  app.kubernetes.io/part-of: applications
  app.kubernetes.io/managed-by: argocd
```

## 5. Deployment Flow

1. Bootstrap ApplicationSet applies core components
2. Infrastructure ApplicationSet deploys in waves (0-2)
3. Applications ApplicationSet deploys in waves (3-5)
4. Each wave ensures dependencies are met before proceeding

## 6. Best Practices

### 6.1 ApplicationSet Structure

- Use consistent naming conventions
- Include proper labels and annotations
- Define explicit sync policies
- Configure appropriate retry mechanisms

### 6.2 Resource Management

- Define explicit resource requests/limits
- Use appropriate replica counts per environment
- Implement proper health checks
- Configure meaningful liveness/readiness probes

### 6.3 High Availability

- Production environments require multiple replicas
- Use pod anti-affinity rules
- Implement proper PodDisruptionBudgets
- Configure appropriate topology spread constraints

### 6.4 Security Considerations

- Follow least privilege principle
- Implement proper network policies
- Use secure pod security contexts
- Configure appropriate RBAC rules

## 7. Validation Requirements

### 7.1 Sync Status

Monitor sync status through:

- ArgoCD dashboard
- Status endpoint health checks
- Application state reconciliation

### 7.2 Health Checks

Implement comprehensive health checks:

- Liveness probes
- Readiness probes
- Startup probes where applicable

## 8. Troubleshooting

### 8.1 Common Issues

- Sync failures
- Resource conflicts
- Permission issues
- Network policy conflicts

### 8.2 Resolution Steps

1. Check ArgoCD logs
2. Verify resource definitions
3. Validate network policies
4. Review RBAC permissions

## 9. Maintenance and Updates

### 9.1 Regular Tasks

- Review sync status
- Monitor resource usage
- Update documentation
- Validate configurations

### 9.2 Update Process

1. Update development first
2. Validate changes
3. Progress to staging
4. Deploy to production

## 10. Future Considerations

### 10.1 Scalability

- Multi-cluster support
- Cross-cluster resources
- Federation capabilities
- Monitoring stack deployment

### 10.2 Improvements

- Automated testing
- Disaster recovery
- Backup solutions
- Enhanced observability
