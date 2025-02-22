# Infrastructure Overview

## Introduction

This document provides a high-level overview of the homelab infrastructure. For detailed documentation on specific
components, please refer to the dedicated sections linked below.

## Core Components

### Network Architecture

See [Network Architecture Overview](networking/overview.md) for details on:

- Cilium-based networking
- Service mesh capabilities
- DNS architecture
- Network policies
- Gateway API implementation

### Security Architecture

See [Security Architecture Overview](security/overview.md) for details on:

- Authentication and authorization
- Network security policies
- Secret management
- Infrastructure hardening
- Compliance and auditing

### Storage Architecture

See [Storage Architecture Overview](storage/overview.md) for details on:

- Proxmox CSI implementation
- Longhorn distributed storage
- Backup strategies
- Performance considerations

### Monitoring and Observability

See [Monitoring Architecture Overview](monitoring/overview.md) for details on:

- Metrics collection
- Logging infrastructure
- Alerting system
- Dashboard setup

## Resource Requirements

```yaml
control_plane:
  cpu: 2 cores per node
  memory: 4GB per node
  nodes: 3 (HA setup)
workers:
  cpu: 4 cores per node
  memory: 8GB per node
  nodes: 2+ (scalable)
```

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
