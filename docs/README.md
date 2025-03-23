# Homelab Infrastructure Guidelines

## Infrastructure Architecture

### Core Architecture

- [Infrastructure Overview](architecture.md)
- [ApplicationSets Hierarchy](architecture/applicationsets.md)
- [Network Architecture](networking/overview.md)
- [Security Architecture](security/overview.md)
- [Storage Architecture](storage/overview.md)

### Environments

- [Environment Overview](architecture/environments.md)
- [Development Environment](architecture/environments/dev.md)
- [Staging Environment](architecture/environments/staging.md)
- [Production Environment](architecture/environments/prod.md)

### Component Specific

- [Applications Architecture](architecture/applications.md)
- [Monitoring Implementation Plan](planned-features/monitoring-implementation.md)
- [Service Registry](service-registry.md)

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

## Current Status

### Implemented Components

- Talos Kubernetes Cluster
- ArgoCD-based GitOps
- Cilium Networking
- Longhorn Storage
- Authentication (Authelia)
- Certificate Management
- Secret Management
- Gateway API

### Planned Components

- Monitoring Stack
- Advanced Metrics
- Automated Testing
- Enhanced Backup Verification
- Performance Monitoring

## Key Principles

1. GitOps-Only Infrastructure

   - All changes through Git
   - No manual interventions
   - Automated reconciliation

2. Environment Progression

   - Dev → Staging → Prod
   - Progressive validation
   - Resource graduation

3. Security First

   - Zero-trust model
   - Defense in depth
   - Least privilege access

4. Infrastructure as Code
   - Declarative configurations
   - Version controlled
   - Automated validation

## Documentation Standards

### File Organization

- Core concepts in root /docs
- Detailed docs in subdirectories
- Environment-specific in /environments
- Best practices in /best-practices

### Document Structure

- Clear overview section
- Implementation details
- Current limitations
- Future improvements
- Related documentation

### Maintenance

- Regular updates required
- Version control aligned
- Automated validation
- Clear change history

## References

### Internal

- [Main README](../README.md)
- [Kubernetes Configuration](../k8s/README.md)
- [Infrastructure Components](../k8s/infrastructure/README.md)
- [Application Components](../k8s/applications/README.md)

### External

- [Talos Linux Documentation](https://talos.dev/docs)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Cilium Documentation](https://docs.cilium.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
