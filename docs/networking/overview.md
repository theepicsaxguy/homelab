# Network Architecture

## Key Decisions

### Why Cilium?

We chose Cilium over other CNIs because:

- eBPF-based networking provides better performance than iptables
- Native Gateway API support eliminates need for separate ingress controller
- Built-in service mesh avoids Istio complexity
- Identity-based security policies are more maintainable than IP-based

### Why Gateway API?

Selected over Ingress because:

- More expressive routing capabilities
- Better security model
- Native TLS handling
- Future-proof API design

### Why Service Mesh?

Using Cilium's built-in service mesh because:

- Simpler than dedicated service mesh
- Lower resource overhead
- Native integration with CNI
- Sufficient features for our needs

## Current Implementation

### Network Flow

1. External traffic → Gateway API
2. Gateway → Authelia for auth
3. Authelia → Backend services
4. Inter-service via service mesh

### Security Model

- Default deny-all
- Explicit allow rules
- Identity-based policies
- Encrypted pod traffic

## Known Limitations

1. Basic traffic metrics only
2. Manual policy verification
3. Limited automated testing
4. Basic monitoring integration

## Planned Improvements

Focusing on immediate needs:

1. Enhanced monitoring
2. Policy testing
3. Traffic analysis
4. Performance optimization

## Related Decisions

- [Security Architecture](../security/overview.md)
- [Service Registry](../service-registry.md)
- [Load Balancing](load-balancing.md)
