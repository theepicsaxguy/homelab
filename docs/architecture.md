# Infrastructure Architecture

## Key Architectural Decisions

### Single Cluster Strategy

**Decision:** Use a single Kubernetes cluster with strong namespace isolation instead of multiple clusters.

**Rationale:**

- Resource efficiency through shared control plane and worker nodes
- Simplified management and monitoring overhead
- Consistent security policies and controls across environments
- Natural promotion path through namespaces while maintaining identical infrastructure

**Trade-offs:**

- Less physical separation between environments
- Potential for resource contention
- More complex namespace-level security requirements

### Immutable Infrastructure (Talos)

**Decision:** Use Talos Linux as the base operating system.

**Rationale:**

- Zero-trust security model from the ground up
- Automated, atomic updates with built-in rollback
- Reduced attack surface through immutable design
- Kubernetes-native OS eliminates unnecessary complexity

**Trade-offs:**

- Less flexibility for custom system modifications
- Steeper learning curve for operations
- Limited traditional debugging tools

### Network Architecture (Cilium)

**Decision:** Use Cilium for CNI, replacing both traditional networking and service mesh.

**Rationale:**

- Superior performance through eBPF vs iptables-based solutions
- Unified networking eliminates multiple control planes
- Native Gateway API support removes need for separate ingress controller
- Identity-based security simplifies policy management

**Trade-offs:**

- More complex troubleshooting due to eBPF
- Higher resource requirements than basic CNI
- Limited traditional networking tools compatibility

### Deployment Strategy (ArgoCD)

**Decision:** Use ArgoCD as the sole deployment mechanism.

**Rationale:**

- Ensures all changes are tracked in Git
- Automatic drift detection and reconciliation
- Clear audit trail through Git history
- Simplified rollback through version control

**Trade-offs:**

- Initial setup complexity
- Learning curve for GitOps workflows
- More steps for emergency changes

## Current State

### Implemented

- Immutable infrastructure with Talos
- GitOps-based deployment pipeline
- Network security with Cilium
- Gateway API for ingress
- Basic authentication with Authelia

### Known Limitations

1. Manual environment promotion process
2. Limited automated testing
3. Basic monitoring implementation
4. Minimal automated security scanning

## Next Steps

Focus areas that directly address current limitations:

1. Automated promotion between environments
2. Enhanced testing framework
3. Comprehensive monitoring stack
4. Advanced security controls

## Related Documents

- [Network Design](networking/overview.md)
- [Security Model](security/overview.md)
- [Storage Architecture](storage/overview.md)
