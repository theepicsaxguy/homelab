# Homelab Infrastructure Architecture

## Overview

This homelab infrastructure implements a fully GitOps-managed Kubernetes cluster using OpenTofu (previously Terraform) for initial provisioning and ArgoCD for ongoing configuration management.

## Infrastructure Layers

### 1. Provisioning Layer (OpenTofu)

Located in `/tofu/kubernetes/`, this layer handles:

- Proxmox VM provisioning
- Talos OS installation and configuration
- Initial Kubernetes cluster bootstrap
- Base cluster configuration

Key Components:

```yaml
components:
  proxmox:
    purpose: "VM infrastructure provider"
    configuration: "Custom VM templates and resources"
  talos:
    purpose: "Kubernetes-focused OS"
    configuration: "Minimal, secure, immutable"
  kubernetes:
    purpose: "Container orchestration"
    configuration: "High-availability control plane"
```

### 2. Configuration Management Layer (ArgoCD)

Located in `/k8s/`, implements a hierarchical GitOps structure:

- Infrastructure Components (`/k8s/infra/`)
  - Network (Cilium)
  - Storage (Proxmox CSI)
  - Authentication
  - Monitoring
  - Controllers
  - Crossplane CRDs

- Applications (`/k8s/apps/`)
  - Media services
  - Development environments
  - External integrations

### 3. Network Architecture

The cluster uses Cilium for networking, providing:

- Service mesh capabilities
- Network policies
- Load balancing
- Direct routing where possible
- Enhanced security through eBPF

### Services Exposure

#### Services Exposed via Subdomains

- AdGuard: `adguard.pc-tips.se`
- Authelia: `authelia.pc-tips.se`
- Grafana: `grafana.pc-tips.se`
- Hubble: `hubble.pc-tips.se`
- Jellyfin: `jellyfin.pc-tips.se`
- Lidarr: `lidarr.pc-tips.se`
- Prowlarr: `prowlarr.pc-tips.se`
- Prometheus: `prometheus.pc-tips.se`
- Radarr: `radarr.pc-tips.se`
- Sonarr: `sonarr.pc-tips.se`
- Home Assistant: `haos.pc-tips.se`
- Proxmox: `proxmox.pc-tips.se`
- TrueNAS: `truenas.pc-tips.se`
- ArgoCD: `argocd.pc-tips.se`

#### Services Exposed via IPs

- Unbound DNS: `10.25.150.252`
- AdGuard DNS: `10.25.150.253`
- Torrent: `10.25.150.225`
- Whoami: `10.25.150.223`

### 4. Storage Architecture

Implements:

- Proxmox CSI driver for persistent storage
- Dynamic volume provisioning
- Storage classes for different performance tiers

## Security Model

1. Infrastructure Security:
   - Talos OS: Minimal attack surface
   - API authentication using tokens
   - SSH with agent forwarding
   - No password authentication

2. Cluster Security:
   - RBAC enforcement
   - Network policies
   - Secure endpoints with Authelia
   - Secret management via sealed secrets

## Performance Considerations

### Resource Management

- VM resources allocated based on node roles
- Control plane nodes: 2 CPU, 4GB RAM minimum
- Worker nodes: Scalable based on workload

### Network Performance

- Cilium direct routing when possible
- eBPF for optimized networking
- Hubble for network observability

### Storage Performance

- CSI driver with local path provisioner
- Different storage classes for various performance needs

## Monitoring and Operations

Monitoring stack includes:

- Prometheus for metrics
- Grafana for visualization
- Hubble for network monitoring
- Alert manager for notifications

## Disaster Recovery

1. Infrastructure Recovery:
   - All configuration in Git
   - OpenTofu state backed up
   - Reproducible through automation

2. Application Recovery:
   - GitOps-based deployment
   - Persistent storage backup
   - Application-specific backup solutions

## Version Control and Updates

- Infrastructure changes through pull requests
- Automated updates via Renovate
- Semantic versioning for changes
- Changelog maintenance

## Resource Requirements

Minimum cluster requirements:

```yaml
control_plane:
  cpu: 2 cores per node
  memory: 4GB per node
  nodes: 3 (HA setup)
workers:
  cpu: 4 cores per node
  memory: 8GB per node
  nodes: 2+ (scalable)
storage:
  type: "Proxmox storage"
  minimum: "100GB per node"
```

## Known Limitations

1. Single Proxmox instance as infrastructure provider
2. Network dependent on underlying Proxmox network
3. Storage performance tied to Proxmox storage performance

## Future Improvements

1. Multi-cluster federation
2. Enhanced backup solutions
3. Expanded monitoring capabilities
4. Additional storage providers

## Related Documentation

- [Network Architecture](network-architecture.md)
- [Storage Architecture](storage-architecture.md)
- [Security Architecture](security-architecture.md)
- [Monitoring Architecture](monitoring-architecture.md)
