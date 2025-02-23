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
│   │   ├── kustomization.yaml
│   │   └── patches/  # All environment patches
│   ├── staging/     # Staging environment
│   │   ├── kustomization.yaml
│   │   └── patches/  # All environment patches
│   └── prod/        # Production environment
│       ├── kustomization.yaml
│       └── patches/  # All environment patches
└── application-set.yaml  # Infrastructure ApplicationSet

```

## Component Architecture

Each infrastructure component follows a standardized structure:

- Base configuration in `base/<component>`
- All environment-specific patches are centralized in `overlays/<env>/patches/`
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
2. Add patches in each environment's centralized patches directory:

   ```
   overlays/<env>/patches/<component>.yaml
   ```

3. Update the environment's kustomization.yaml to reference the new patch
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

- Traffic optimization through Cilium
- Efficient resource utilization
- Load balancing and auto-scaling

## Resource Requirements

Graduated across environments:

- Development: Basic resources
- Staging: Moderate HA setup
- Production: Full HA with anti-affinity

## Security Implementation

- Zero-trust network policies
- Strict pod security standards
- Automated secret management

## High Availability

- Component replication (staging/prod)
- Pod anti-affinity rules
- Topology spread constraints

## Monitoring Integration

- Prometheus metrics
- Grafana dashboards
- Alert manager rules

## Best Practices

1. Follow GitOps principles
2. Use declarative configurations
3. Implement proper resource limits
4. Enable security policies
5. Configure monitoring/alerts

## Known Limitations

- Single cluster deployment
- Manual secret rotation
- Limited multi-region support

## Troubleshooting

1. Check ArgoCD sync status
2. Validate Kustomize builds
3. Review component logs
4. Check resource constraints

## Future Enhancements

- Multi-cluster federation
- Automated secret rotation
- Enhanced disaster recovery
