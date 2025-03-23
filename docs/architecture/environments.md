# Environment Strategy

## Design Philosophy

We chose a single cluster with strong namespace isolation over multiple clusters because:

1. **Resource Efficiency**

   - Shared control plane reduces overhead
   - Better resource utilization across environments
   - Simplified management and monitoring

2. **Consistent Security**

   - Same security policies across environments
   - Unified authentication and RBAC
   - Consistent network policies

3. **Progressive Delivery**
   - Natural promotion path through namespaces
   - Identical underlying infrastructure
   - Real validation of production configs

## Environment Characteristics

### Development

**Purpose:** Fast iteration and testing

- Single replicas to save resources
- Debug capabilities enabled
- Relaxed network policies
- Minimal resource requests

**Why:** Developers need quick feedback and easy debugging

### Staging

**Purpose:** Production validation

- Two replicas for basic HA testing
- Limited debug access
- Production-like security
- Representative data

**Why:** Validate changes in a production-like environment without risk

### Production

**Purpose:** Reliable service delivery

- Full HA with three+ replicas
- No debug access
- Strict security enforcement
- Real user data

**Why:** Ensure reliable, secure service delivery

## Key Differences

### Security Policies

- Dev: Basic policies, debug allowed
- Staging: Production policies, some debug
- Prod: Strict policies, no debug

### Resource Management

- Dev: Minimal guaranteed resources
- Staging: Representative allocation
- Prod: Full production sizing

### Access Controls

- Dev: Team-wide access
- Staging: Limited team access
- Prod: Restricted access

## Common Elements

These remain consistent across environments:

- Base infrastructure services
- Network architecture
- Storage classes
- Authentication methods

## Promotion Process

### Current Flow

1. Changes tested in development
2. Manually promoted to staging
3. Validated in staging
4. Manually promoted to production

### Known Limitations

1. Manual promotion steps
2. Basic validation only
3. No automated testing
4. Limited rollback automation

## Future Improvements

Near-term improvements focus on validation:

1. Automated security scanning
2. Performance testing
3. Configuration validation
4. Promotion automation

## Related Documentation

- [Security Policies](../security/policies.md)
- [Resource Management](../best-practices/resources.md)
- [Network Architecture](../networking/overview.md)
