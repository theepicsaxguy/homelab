# Infrastructure Architecture

## Introduction

This document provides a comprehensive overview of the homelab infrastructure, built on GitOps principles with
Kubernetes (Talos), OpenTofu, and ArgoCD.

## Core Components

### Cluster Architecture

- **Kubernetes Version**: 1.32.3
- **Node Configuration**:
  - Control Plane: 3 nodes (4 CPU, 4GB RAM each)
  - Workers: Dynamically scaled based on workload
- **Base Infrastructure**: Proxmox VMs managed by OpenTofu

### Network Architecture

See [Network Architecture Overview](networking/overview.md) for details on:

- **CNI**: Cilium v1.17+ with service mesh capabilities
- **Gateway API**: Modern ingress management with:
  - External gateway (Internet-facing services)
  - Internal gateway (Cluster-local services)
  - TLS passthrough gateway
- **DNS**: CoreDNS with custom domain integration
- **Security**: Zero-trust network model with Cilium network policies

### Security Architecture

See [Security Architecture Overview](security/overview.md) for details on:

- **Authentication**: Authelia for SSO
- **Authorization**: RBAC with least privilege
- **Secret Management**: Bitwarden SM Operator
- **Network Security**: Cilium-based zero-trust model
- **Infrastructure Hardening**: Talos Linux security baseline
- **Compliance**: Automated policy enforcement via Gatekeeper

### Storage Architecture

See [Storage Architecture Overview](storage/overview.md) for details on:

- **Primary Storage**: Longhorn v1.8.1
- **Backup Storage**: Restic with S3 backend
- **Performance Tiers**:
  - fast-storage: SSD-backed for databases
  - standard: General purpose storage
  - archive: Cold storage for backups

### Monitoring and Observability

See [Monitoring Architecture Overview](monitoring/overview.md) for details on:

- **Metrics**: Prometheus with custom dashboards
- **Logging**: Loki with structured logging
- **Tracing**: OpenTelemetry integration
- **Alerting**: AlertManager with severity-based routing

## GitOps Workflow

### Deployment Process

1. **Infrastructure Layer** (OpenTofu)

   - Cluster provisioning
   - Network configuration
   - Storage setup

2. **Platform Layer** (ArgoCD)

   - Core services deployment
   - Monitoring stack
   - Security components

3. **Application Layer** (ArgoCD ApplicationSets)
   - Service deployments
   - Configuration management
   - Progressive delivery

### Environment Strategy

#### Development

- Fast iteration cycles
- Reduced resource requirements
- Debug logging enabled
- 30s rollout analysis

#### Staging

- Production-like configuration
- Full HA testing
- 60s rollout analysis
- Complete monitoring

#### Production

- Strict validation requirements
- Zero-downtime deployments
- 300s rollout analysis
- Full audit logging

## Resource Management

### Standard Requirements

```yaml
control_plane:
  cpu: 4 cores per node
  memory: 4GB per node
  nodes: 3 (HA setup)
workers:
  cpu: varies by workload
  memory: varies by workload
  nodes: dynamically scaled
```

### High Availability

- Pod anti-affinity rules
- Topology spread constraints
- Rolling update strategies
- Readiness gates

## Disaster Recovery

1. **Infrastructure Recovery**:

   - All configuration in Git
   - OpenTofu state backed up
   - Automated recovery procedures

2. **Application Recovery**:

   - GitOps-based deployment
   - Persistent storage backup
   - Application-specific backup solutions

3. **Data Recovery**:
   - Regular storage snapshots
   - Off-site backup copies
   - Validated restore procedures

## Version Control and Updates

- Infrastructure changes through pull requests
- Automated updates via Renovate
- Semantic versioning for changes
- Changelog maintenance

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

- [Service Registry](service-registry.md)
- [Network Architecture](networking/overview.md)
- [Storage Architecture](storage/overview.md)
- [Security Architecture](security/overview.md)
- [Monitoring Architecture](monitoring/overview.md)
