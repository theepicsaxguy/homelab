# Network Architecture

## Core Network Decisions

### CNI Selection

**Decision:** Use Cilium as the primary CNI and service mesh

**Rationale:**

- eBPF provides significant performance benefits over iptables
- Single control plane for networking, security, and observability
- Native Gateway API support eliminates separate ingress controller
- Built-in service mesh removes Istio complexity

**Trade-offs:**

- Higher complexity in debugging network issues
- Requires newer kernel versions
- More resource intensive than basic CNIs

### Ingress Strategy

**Decision:** Use Gateway API instead of Ingress resources

**Rationale:**

- More powerful routing capabilities
- Better security model through explicit policies
- Native TLS handling and cert management
- Future-proof API design vs legacy Ingress

**Trade-offs:**

- Newer standard with less ecosystem support
- More complex configuration
- Limited legacy application support

### Service Mesh Implementation

**Decision:** Use Cilium's built-in service mesh capabilities

**Rationale:**

- Avoids additional control plane overhead
- Native integration with CNI layer
- Lower resource requirements than Istio
- Sufficient feature set for current needs

**Trade-offs:**

- Fewer advanced features than dedicated mesh
- Limited ecosystem integrations
- Less granular traffic control

## Security Model

### Current Implementation

**Decision:** Zero-trust network model with default deny

**Rationale:**

- All traffic explicitly allowed through policies
- Identity-based security instead of IP-based
- Encrypted pod-to-pod communication
- Granular access control at L7

**Trade-offs:**

- More complex initial setup
- Higher learning curve
- Additional policy maintenance

## Known Limitations

1. Basic traffic monitoring
2. Limited policy automation
3. Manual certificate management
4. Simple load balancing

## Next Steps

Priority improvements:

1. Enhanced traffic visibility
2. Automated policy generation
3. Advanced load balancing
4. Certificate automation

## Related Documents

- [Network Policies](policies.md)
- [DNS Configuration](dns.md)
- [Load Balancing](load-balancing.md)
