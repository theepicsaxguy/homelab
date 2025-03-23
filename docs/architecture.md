# Infrastructure Architecture

## Introduction

This document provides a comprehensive overview of the homelab infrastructure, built on GitOps principles with
Kubernetes (Talos), OpenTofu, and ArgoCD.

## Core Components

### Cluster Architecture

- **Control Plane**: Talos Linux-based Kubernetes control plane
- **Node Management**: Fully automated through Talos machine configs
- **Workload Distribution**: Pod anti-affinity and topology spread constraints
- **Environment Isolation**: Strict namespace-based separation

### Network Architecture

- **CNI**: Cilium (replacing Talos default CNI)
- **Service Mesh**: Cilium service mesh with mTLS
- **DNS**: CoreDNS with custom configurations
- **Ingress**: Gateway API with Cilium
- **Load Balancing**: Cilium LB IPAM + BGP Control Plane

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

## GitOps Workflow

Our GitOps workflow follows strict principles:

1. **Source of Truth**: All infrastructure defined in Git
2. **Deployment Mechanism**: ArgoCD is the only deployment tool
3. **Change Management**:
   - No direct kubectl applies
   - Changes must be committed to Git
   - Automated validation and testing

## Resource Management

### Resource Allocation

- **Development**: Minimal resources, single replicas
- **Staging**: Production-like with HA (2 replicas)
- **Production**: Full HA (3+ replicas)

### High Availability

- Pod anti-affinity rules
- Topology spread constraints
- PodDisruptionBudgets
- Rolling update strategies

## Disaster Recovery

Current disaster recovery capability includes:

1. Git-based infrastructure restoration
2. Talos machine config backups
3. Application state backups via Restic
4. Documentation of recovery procedures

## Version Control and Updates

- **Container Images**: Managed via Renovate
- **Kubernetes**: Controlled upgrades via Talos
- **Infrastructure Components**: Version pinning in Git

## Known Limitations

1. No current monitoring stack implementation (planned)
2. Manual backup verification required
3. Limited automated testing coverage

## Future Improvements

1. Monitoring stack implementation (Phase 1)
2. Automated backup verification
3. Enhanced testing framework
4. Multi-cluster federation

## Related Documentation

- [Network Architecture](networking/overview.md)
- [Security Architecture](security/overview.md)
- [Storage Architecture](storage/overview.md)
- [Planned Monitoring](planned-features/monitoring-implementation.md)
