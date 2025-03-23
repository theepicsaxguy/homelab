# ApplicationSet Design

## Design Philosophy

### Why ApplicationSets?

We use ApplicationSets instead of individual Applications because:

- Automated application lifecycle management
- Consistent configuration across environments
- Reduced maintenance overhead
- Easier multi-environment promotion

### Why Sync Waves?

Our sync wave strategy:

- Infrastructure first (0-2)
- Applications later (3-5)
- Ensures dependencies exist
- Prevents race conditions

## Core Patterns

### Bootstrap Pattern

Essential infrastructure components:

1. CRDs and operators
2. Core networking
3. Storage providers
4. Security services

### Progressive Delivery

Environment promotion flow:

1. Development testing
2. Staging validation
3. Production deployment

### Resource Graduation

Resource scaling strategy:

- Dev: Single replica
- Staging: Basic HA (2 replicas)
- Prod: Full HA (3+ replicas)

## Current Implementation

### Infrastructure Layer

**Wave 0-2:** Core Services

- Network (Cilium)
- Storage (Longhorn)
- Security (Authelia)
- Gateway API

### Application Layer

**Wave 3-5:** Workloads

- External services
- Media applications
- Development tools
- Monitoring (planned)

## Best Practices

### Project Structure

- Clear component separation
- Consistent naming
- Explicit dependencies
- Version pinning

### Security

- Least privilege RBAC
- Network isolation
- Secret management
- Access controls

## Known Limitations

1. Manual promotion
2. Basic validation
3. Limited automation
4. Simple rollback

## Related Docs

- [Environment Strategy](environments.md)
- [Resource Management](../best-practices/resources.md)
- [Deployment Guide](../deployment/progressive-delivery.md)
