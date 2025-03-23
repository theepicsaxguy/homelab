# Network Architecture

## Overview

The network architecture is built around Cilium as the primary networking component, providing CNI, service mesh, load
balancing, and security features.

## Core Components

### CNI (Cilium)

- **Version**: Latest stable (managed by Renovate)
- **Features**:
  - eBPF-based networking
  - Kubernetes native service handling
  - Built-in monitoring capabilities (future)
  - Transparent encryption with WireGuard
  - Service mesh with mTLS

### Load Balancing

- **Cilium LB IPAM**: Replaces traditional MetalLB
- **BGP Control Plane**: For external route advertisement
- **Service Types**:
  - LoadBalancer: External services
  - ClusterIP: Internal services
  - NodePort: Limited use cases

### DNS Architecture

- **CoreDNS**: Primary DNS service
- **Service Discovery**: Native Kubernetes DNS
- **External Resolution**: Configured via CoreDNS forward zones
- **Split DNS**: Internal/external name resolution

### Gateway API

- Native Kubernetes Gateway API implementation
- Cilium-managed Gateway controller
- Support for HTTP, HTTPS, and TCP routes
- TLS termination via cert-manager

## Network Policies

### Default Policies

- Deny-all by default
- Explicit allow rules required
- Environment-specific policies
- Service-to-service communication rules

### Security Groups

- Application-based grouping
- Environment isolation
- Cross-namespace communication control
- Egress control for external services

## Service Mesh Features

Currently implemented features:

- Transparent mTLS between services
- Basic traffic management
- L7 policy enforcement
- Connection tracking

Planned but not implemented:

- Advanced traffic shaping
- Circuit breaking
- Rate limiting
- Detailed metrics collection

## Current Limitations

1. No current monitoring integration
2. Basic traffic metrics only
3. Manual policy verification required
4. Limited automated testing of policies

## Performance Considerations

### Resource Allocation

- Cilium agent resources per node
- CoreDNS scaling based on cluster size
- Gateway API controller resources

### High Availability

- Multiple Cilium replicas
- CoreDNS redundancy
- Gateway API controller failover
- Load balancer redundancy

## Troubleshooting

### Common Issues

1. DNS resolution problems
2. Network policy conflicts
3. Gateway API configuration issues
4. Load balancer IP allocation

### Debug Tools

- cilium CLI tools
- hubble UI and CLI
- kubectl debug capabilities
- Network policy analyzer

## Related Documentation

- [Cilium Configuration](cilium.md)
- [DNS Setup](dns.md)
- [Network Policies](policies.md)
- [Gateway Configuration](gateway.md)
- [Load Balancer Setup](loadbalancer.md)
