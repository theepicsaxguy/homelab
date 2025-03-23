# Network Architecture

## Overview

The network infrastructure is built on Cilium CNI with integrated service mesh capabilities and Gateway API support.

## Core Components

### Cilium (v1.17+)

```yaml
cilium:
  hubble:
    enabled: true
    metrics:
      enabled: true
      serviceMonitor:
        enabled: true

  kubeProxyReplacement: strict
  hostServices:
    enabled: true

  gatewayAPI:
    enabled: true
    routeNamespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: gateway-system

  envoy:
    enabled: true
    prometheus:
      serviceMonitor:
        enabled: true
```

### Gateway API Configuration

#### External Gateway

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: external-gateway
  namespace: gateway-system
spec:
  gatewayClassName: cilium
  listeners:
    - name: http
      protocol: HTTP
      port: 80
    - name: https
      protocol: HTTPS
      port: 443
      tls:
        mode: Terminate
        certificateRefs:
          - name: wildcard-cert
```

#### Internal Gateway

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: internal-gateway
  namespace: gateway-system
spec:
  gatewayClassName: cilium
  listeners:
    - name: http
      protocol: HTTP
      port: 8080
    - name: grpc
      protocol: HTTP
      port: 9090
```

## Network Policies

### Default Policies

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: default-deny
spec:
  endpointSelector: {}
  ingress: []
  egress: []
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-system
spec:
  endpointSelector: {}
  ingress:
    - fromEndpoints:
        - matchLabels:
            io.kubernetes.pod.namespace: kube-system
  egress:
    - toEndpoints:
        - matchLabels:
            io.kubernetes.pod.namespace: kube-system
```

### Environment-Specific Policies

#### Development

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: dev-environment
spec:
  endpointSelector:
    matchLabels:
      environment: dev
  ingress:
    - fromEndpoints:
        - matchLabels:
            environment: dev
  egress:
    - toEndpoints:
        - matchLabels: {}
```

#### Production

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: prod-environment
spec:
  endpointSelector:
    matchLabels:
      environment: prod
  ingress:
    - fromEndpoints:
        - matchLabels:
            environment: prod
    - fromEndpoints:
        - matchLabels:
            io.kubernetes.pod.namespace: monitoring
```

## Service Mesh Features

### Traffic Management

- L7 load balancing
- Traffic splitting
- Circuit breaking
- Retry policies

### Security

- mTLS encryption
- Identity-based authentication
- Authorization policies
- Traffic encryption

### Observability

- Distributed tracing
- Traffic visualization
- Performance metrics
- Health checks

## Monitoring Integration

### Hubble Metrics

```yaml
metrics:
  flows:
    - source_namespace
    - destination_namespace
    - source_workload
    - destination_workload
    - verdict
  http:
    - reporter
    - protocol
    - status_code
    - method
  tcp:
    - reporter
    - protocol
    - flags
```

### Envoy Metrics

```yaml
metrics:
  endpoints:
    - path: /stats/prometheus
      port: 9901
  serviceMonitor:
    enabled: true
    interval: 15s
```

## Performance Considerations

### Resource Requirements

```yaml
resources:
  cilium-agent:
    requests:
      cpu: 100m
      memory: 512Mi
    limits:
      cpu: 500m
      memory: 1Gi

  hubble-relay:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
```

### Optimization Settings

```yaml
optimization:
  kubeProxyReplacement: strict
  hostRouting: true
  bpfMasquerade: true
  autoDirectNodeRoutes: true
  tunnel: disabled
```

## High Availability

### Control Plane

- Multiple Cilium operator replicas
- Leader election enabled
- Cross-node communication
- Failure detection

### Data Plane

- Redundant gateways
- Load balancing
- Automatic failover
- Health monitoring

## Troubleshooting

### Common Issues

1. Connectivity Problems

   - Check Cilium agent status
   - Verify network policies
   - Review gateway configurations
   - Check DNS resolution

2. Performance Issues
   - Monitor BPF map usage
   - Check connection tracking
   - Analyze traffic patterns
   - Review resource usage

### Debugging Tools

```yaml
diagnostic_tools:
  - cilium status
  - cilium-health
  - hubble observe
  - tcpdump
  - connectivity test
```
