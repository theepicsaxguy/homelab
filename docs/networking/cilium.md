# Cilium Configuration

## Overview

Cilium serves as the primary CNI provider, leveraging eBPF for enhanced networking and security capabilities.

## Configuration Details

### Network Policy Enforcement

```yaml
networking:
  enablePolicy: 'default' # Default deny
  enableRemoteNodeIdentity: true
  enableL7Proxy: true

security:
  enableIPv4: true
  enableIPv6: false
  enableEncryption: true
```

### Service Mesh Features

- L7 visibility
- Service maps
- Transparent encryption
- Load balancing
- HTTP-aware policies

### Performance Optimizations

- Direct routing where possible
- eBPF-accelerated forwarding
- XDP for enhanced packet processing
- Optimized service handling

## Hubble Integration

- Real-time network monitoring
- Flow visibility
- Performance metrics
- Security observability

## Network Policies

Example base policy:

```yaml
apiVersion: 'cilium.io/v2'
kind: CiliumNetworkPolicy
metadata:
  name: 'default-deny'
spec:
  endpointSelector:
    matchLabels: {}
  ingress:
    - fromEndpoints:
        - matchLabels:
            io.kubernetes.pod.namespace: kube-system
```

## Monitoring Integration

- Prometheus metrics
- Grafana dashboards
- Hubble UI visualization
- Alert configuration
