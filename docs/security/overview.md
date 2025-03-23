# Security Architecture

## Design Philosophy

### Why Zero Trust?

We implement zero trust because:

- Traditional perimeter security isn't sufficient for modern threats
- Microservices require fine-grained access control
- Dynamic environments need identity-based security
- GitOps requires strict change control

### Why Authelia?

Selected as our authentication provider because:

- Native Kubernetes integration
- Simple SSO implementation
- OIDC support for automation
- Lower resource usage than Keycloak

### Why LLDAP?

Chose LLDAP over other directory services because:

- Lightweight implementation
- Simple user management
- Sufficient feature set
- Easy backup/restore

## Security Layers

### Infrastructure Security

**Talos Linux**

- Immutable system design
- Automated patching
- Minimal attack surface
- Built-in hardening

**Network Security**

- Cilium network policies
- Service mesh encryption
- Gateway API controls
- Default-deny stance

### Application Security

**Container Hardening**

- Non-root execution
- Read-only filesystems
- Dropped capabilities
- Resource limits

**Access Control**

- Centralized authentication
- RBAC enforcement
- Namespace isolation
- Secret management

## Current State

### Implemented

- Zero-trust network model
- Service mesh encryption
- Centralized authentication
- RBAC policies

### Limitations

1. Basic audit logging
2. Manual policy verification
3. Limited security scanning
4. Basic monitoring only

## Critical Workflows

### Access Management

1. All requests authenticated
2. Permissions via RBAC
3. Network policies enforce
4. Actions logged

### Secret Handling

1. Encrypted at rest
2. Limited access scope
3. Regular rotation
4. Backup protection

## Related Documentation

- [Network Security](network-security.md)
- [Access Control](access-control.md)
- [Secret Management](secrets-management.md)
