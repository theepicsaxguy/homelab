# Cilium Configuration

## Overview

Cilium serves as the primary CNI provider and Gateway API implementation, leveraging eBPF for enhanced networking,
security, and ingress capabilities.

## Gateway API Integration

### Gateway Classes

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: cilium
spec:
  controllerName: io.cilium/gateway-controller
```

### Gateway Types

1. **External Gateway**

   - Internet-facing services
   - Load balancing with HTTPS
   - Automatic cert management
   - Authentication integration

2. **Internal Gateway**

   - Cluster-local services
   - Service mesh integration
   - Metrics and monitoring
   - Internal DNS resolution

3. **TLS Passthrough Gateway**
   - Direct TLS termination
   - Minimal latency
   - End-to-end encryption
   - Special use-cases (Proxmox, TrueNAS)

## Core Configuration

### Network Policy Enforcement

```yaml
networking:
  enablePolicy: 'default' # Default deny
  enableRemoteNodeIdentity: true
  enableL7Proxy: true
  enableGatewayAPI: true
  gatewayAPI:
    enabled: true
    enableMetrics: true

security:
  enableIPv4: true
  enableIPv6: false
  enableEncryption: true
  enableWireguard: true
```

### Service Mesh Features

- L7 visibility with protocol awareness
- Service maps and topology
- Transparent encryption (Wireguard)
- Advanced load balancing
- HTTP/gRPC-aware policies
- Gateway API implementation

### Performance Optimizations

- Direct routing where possible
- eBPF-accelerated forwarding
- XDP for enhanced packet processing
- Optimized service handling
- Gateway-specific optimizations

## Hubble Integration

- Real-time network monitoring
- Flow visibility and service maps
- Performance metrics
- Security observability
- Gateway traffic analysis
- Service dependency mapping

## Network Policies

Example base policy with Gateway API awareness:

```yaml
apiVersion: 'cilium.io/v2'
kind: CiliumNetworkPolicy
metadata:
  name: 'gateway-access'
spec:
  endpointSelector:
    matchLabels:
      io.cilium.k8s.policy.gateway: 'true'
  ingress:
    - fromEndpoints:
        - matchLabels:
            io.kubernetes.pod.namespace: kube-system
    - fromEndpoints:
        - matchLabels:
            io.cilium.k8s.policy.gateway: 'true'
```

## Monitoring Integration

### Metrics

- Prometheus metrics with Gateway API stats
- Grafana dashboards for gateway performance
- Hubble UI visualization
- Gateway-specific alerts

### Gateway Monitoring

- Route status and health
- Certificate management
- Load balancing metrics
- Traffic distribution
- Error rates and latencies

## Troubleshooting

### Gateway API Issues

```bash
# Check gateway status
kubectl get gateway -A

# Verify route attachments
kubectl get httproute -A

# Debug gateway controller
kubectl -n kube-system logs -l app.kubernetes.io/name=cilium -c cilium-gateway

# View gateway events
kubectl describe gateway <gateway-name>
```

### Common Problems

1. Route Attachment Issues

   - Verify GatewayClass exists and is valid
   - Check HTTPRoute listener references
   - Validate TLS certificate configuration

2. Certificate Management

   - Verify cert-manager integration
   - Check certificate status
   - Validate DNS records

3. Performance Issues
   - Monitor gateway metrics
   - Check connection tracking
   - Verify eBPF map status
