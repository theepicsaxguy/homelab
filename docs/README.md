# Homelab Infrastructure Guidelines

## Infrastructure Architecture

### Environments

- [Environment Overview](architecture/environments.md)
- [Development Environment](architecture/environments/dev.md)
- [Staging Environment](architecture/environments/staging.md)
- [Production Environment](architecture/environments/prod.md)

### Core Components

- [ApplicationSets Hierarchy](architecture/applicationsets.md)
- [Network Architecture](architecture/network-architecture.md)
- [Security Architecture](security/overview.md)
- [Storage Architecture](storage-architecture.md)
- [Monitoring Architecture](monitoring-architecture.md)

## Best Practices

### GitOps & Deployment

- [ApplicationSet Patterns](best-practices/applicationset-patterns.md)
- [Manifest Validation](best-practices/manifest-validation.md)
- [GitOps Guidelines](best-practices/gitops.md)
- [Secret Management](security/secrets-management.md)

### Development Workflow

- [Build and Deploy](best-practices/build.md)
- [Resource Management](best-practices/resources.md)
- [Testing Guidelines](best-practices/testing.md)

### Operations

- [Disaster Recovery](operations/disaster-recovery.md)
- [Maintenance](operations/maintenance.md)
- [Troubleshooting](operations/troubleshooting.md)

## Key Principles

- GitOps-only infrastructure management
- Progressive environment deployment (dev → staging → prod)
- Resource graduation across environments
- Mandatory manifest validation
- Zero-trust security model
- Comprehensive monitoring

## References

- [Main README](../README.md)
- [Kubernetes Configuration](../k8s/README.md)
- [Infrastructure Components](../k8s/infrastructure/README.md)
