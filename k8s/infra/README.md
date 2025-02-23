# Infrastructure Components

This directory contains the core infrastructure components managed through GitOps. All changes are deployed via ArgoCD
ApplicationSets with environment-specific configurations.

## Directory Structure

```
.
├── base/               # Base infrastructure components
│   ├── network/       # Networking components
│   │   ├── cilium/    # CNI configuration
│   │   ├── dns/       # DNS services
│   │   └── gateway/   # Gateway API controllers
│   ├── storage/       # Storage components
│   │   ├── proxmox-csi/
│   │   └── longhorn/
│   ├── auth/         # Authentication services
│   ├── controllers/  # Core controllers
│   ├── monitoring/   # Observability stack
│   └── vpn/         # VPN services
├── overlays/          # Environment-specific configurations
│   ├── dev/         # Development environment
│   ├── staging/     # Staging environment
│   └── prod/        # Production environment
├── application-set.yaml  # Infrastructure ApplicationSet
└── project.yaml         # ArgoCD project definition

```

## Component Architecture

Each infrastructure component follows a standardized structure:

- Base configuration in `base/<component>`
- Environment-specific patches in `overlays/<env>/patches`
- Graduated resource limits across environments
- High availability in staging/production

## Deployment Strategy

Components are deployed through ArgoCD ApplicationSets with:

- Progressive sync waves (0 → 1 → 2)
- Environment-specific configurations
- Automated pruning and self-healing
- Strict resource management

## Adding New Components

1. Add base configuration in `base/<component>`
2. Create environment patches in `overlays/<env>/patches`
3. Update ApplicationSet if needed
4. Validate with:
   ```bash
   ./scripts/validate_manifests.sh -d k8s/infra
   ```

## Component Overview

### Authentication (auth/)

- Authelia for SSO/2FA
- LLDAP for user management
- Zero-trust implementation

### Network (network/)

```yaml
components:
  cilium:
    mode: 'Direct routing'
    encryption: 'Wireguard'
    features: ['BGP', 'L7 Policy', 'Hubble']

  gateway:
    type: 'Cilium Gateway API'
    features: ['TLS', 'Rate Limiting']

  dns:
    providers: ['CoreDNS', 'External DNS']
    features: ['Split Horizon', 'DoH']
```

### Monitoring (monitoring/)

- Prometheus + Grafana stack
- Hubble network observability
- Alert manager integration

### Storage (storage/)

- Proxmox CSI driver
- Dynamic provisioning
- Multiple storage classes

## Performance Features

### Network Layer

- eBPF for direct routing
- XDP programs for packet processing
- Optimized service mesh

### Storage Layer

- Local path provisioner
- Direct volume binding
- SSD storage classes

### Monitoring Stack

- Efficient metrics collection
- Optimized retention policies
- Grafana caching enabled

## Resource Requirements

| Environment | CPU Request | Memory Request | CPU Limit | Memory Limit |
| ----------- | ----------- | -------------- | --------- | ------------ |
| Dev         | 100m        | 128Mi          | 200m      | 256Mi        |
| Staging     | 500m        | 512Mi          | 1000m     | 1Gi          |
| Production  | 1000m       | 1Gi            | 2000m     | 2Gi          |

| Component  | CPU       | Memory     | Storage | Notes               |
| ---------- | --------- | ---------- | ------- | ------------------- |
| Cilium     | 500m/node | 512Mi/node | -       | Per node            |
| Authelia   | 500m      | 512Mi      | 1Gi     | HA ready            |
| Prometheus | 2C        | 4Gi        | 50Gi    | Scales with metrics |
| CSI Driver | 200m      | 256Mi      | -       | Per node            |

## Security Implementation

1. Network Security

   - Default deny all
   - Explicit allow rules
   - mTLS everywhere

2. Authentication

   - 2FA required
   - Short-lived tokens
   - Audit logging

3. Storage Security
   - Volume encryption
   - Secure mount options
   - Access auditing

## High Availability

All critical components run with:

- Multiple replicas
- Anti-affinity rules
- Pod disruption budgets
- Automatic failover

## Monitoring Integration

Every component exports:

- Health metrics
- Performance data
- Resource usage
- Security events

## Best Practices

- Always use Kustomize overlays for environment customization
- Maintain high availability in staging/production
- Follow GitOps workflow for all changes
- Validate all changes before deployment
- Document component dependencies
- Use resource limits appropriate for environment

## Known Limitations

1. Cilium BGP

   - Requires node networking setup
   - Hardware support needed

2. Storage Performance
   - Limited by Proxmox backend
   - Network bottlenecks possible

## Troubleshooting

### Network Issues

```bash
# Check Cilium status
cilium status
# View Hubble flows
hubble observe
```

### Storage Problems

```bash
# Verify CSI
kubectl get volumeattachment
# Check PV binding
kubectl describe pv <name>
```

## Future Enhancements

- [ ] Enhanced BGP peering
- [ ] Storage replication
- [ ] Advanced audit logging
- [ ] ML-based monitoring

Remember: Infrastructure is like a good joke - timing is everything! ⚡
