# Core Infrastructure Components

The beating heart of our cluster. Here lives the critical infrastructure that keeps everything running smoothly. 🏗️

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
