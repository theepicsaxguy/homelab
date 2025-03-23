# Homelab Infrastructure Guidelines

## Infrastructure Architecture

### Design Principles

We chose a Kubernetes-based infrastructure with GitOps workflow because:

- **GitOps-only changes:** Ensures all changes are tracked, reviewed, and reversible
- **Progressive delivery:** Enables safe testing through dev → staging → prod
- **Zero-trust security:** Implements defense in depth from infrastructure to application level
- **Infrastructure as Code:** Makes the entire stack reproducible and version controlled

### Environment Strategy

Rather than maintaining separate clusters, we use a single cluster with strong namespace isolation:

- **Development:** Fast iterations and testing with minimal resources
- **Staging:** Production-like environment for validation
- **Production:** Fully HA with strict security policies

This approach balances resource efficiency with proper isolation.

### Documentation Structure

Documentation is organized by component rather than alphabetically to help understand relationships:

- **Core designs:** Root `/docs` folder contains main architectural decisions
- **Implementation details:** Component folders contain specific configurations
- **Environment config:** Separate sections for environment-specific choices

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

### Production Ready

- Talos Kubernetes control plane - chosen for security and automation
- ArgoCD-based GitOps - ensures consistent state management
- Cilium networking - provides both CNI and security features
- Longhorn storage - enables distributed persistent storage
- Authelia authentication - centralizes access control
- Gateway API - modern ingress management

### Under Development

The following key components are planned to enhance operations:

- Monitoring stack - for better visibility and alerting
- Automated testing - to validate changes more thoroughly
- Enhanced backup verification - for improved reliability

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
