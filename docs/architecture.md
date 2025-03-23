# Infrastructure Architecture

## Core Design Decisions

### Why Talos Linux

- Immutable, security-first design reduces attack surface
- Automated updates with rollback capability
- Built-in Kubernetes optimization
- Minimal maintenance overhead

### Why Cilium

- eBPF-based networking provides better performance than traditional solutions
- Native Gateway API support eliminates need for separate ingress controller
- Built-in service mesh capabilities without Istio complexity
- Strong security through identity-based policies

### Why ArgoCD

- GitOps-only infrastructure prevents configuration drift
- Automatic drift detection and correction
- Clear audit trail through Git history
- Multi-cluster support for future expansion

## Current Architecture

### Infrastructure Layer (Wave 0-2)

- Base cluster services deploy first
- Network and storage foundations before applications
- Security components early in process

### Application Layer (Wave 3-5)

- Progressive deployment through environments
- Validation gates between stages
- Resource limits increase with promotion

## Known Limitations

1. No current monitoring implementation
2. Manual promotion between environments
3. Basic security scanning only
4. Limited automated testing

## Planned Improvements

- Monitoring stack implementation (Q2 2025)
- Automated environment promotion
- Enhanced security controls
- Expanded testing framework

## Related Decisions

- [Network Design](networking/overview.md)
- [Storage Choices](storage/overview.md)
- [Security Model](security/overview.md)
