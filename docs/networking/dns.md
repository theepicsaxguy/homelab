# DNS Configuration

## Overview

The DNS infrastructure uses a multi-layered approach with Unbound as the primary resolver, AdGuard as a filtering DNS
server, and Gateway API integration for service exposure.

## DNS Architecture

### Primary DNS (Unbound)

- IP: 10.25.150.252
- Features:
  - DNSSEC validation
  - DNS-over-TLS support
  - Caching resolver
  - Forward secrecy
  - Gateway API support

### Secondary DNS (AdGuard)

- IP: 10.25.150.253
- Features:
  - Ad blocking
  - Custom filtering rules
  - DNS-over-HTTPS support
  - Query logging
  - Gateway filtering rules

### Internal DNS (CoreDNS)

- Service discovery
- Pod DNS resolution
- Gateway route resolution
- Custom DNS records
- Cilium service discovery

## Gateway Integration

### External Gateway DNS

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: external
  annotations:
    external-dns.alpha.kubernetes.io/hostname: '*.pc-tips.se'
spec:
  addresses:
    - value: '10.25.150.240'
      type: IPAddress
  gatewayClassName: cilium
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
```

### DNS Record Management

- Automatic DNS updates via external-dns
- Gateway-aware hostname resolution
- TLS certificate validation
- Split-horizon DNS support

## Configuration

### Unbound Configuration

```yaml
server:
  interface: 0.0.0.0
  access-control: 10.0.0.0/8 allow
  do-ip4: yes
  do-udp: yes
  do-tcp: yes
  do-tls: yes
  tls-cert-bundle: /etc/ssl/certs/ca-certificates.crt
  # Gateway Support
  local-zone: "gateway.internal" transparent
  local-data: "gateway.internal. IN A 10.25.150.240"
  # DNSSEC
  auto-trust-anchor-file: '/var/lib/unbound/root.key'
  val-clean-additional: yes
```

### AdGuard Configuration

```yaml
dns:
  bind_hosts:
    - 0.0.0.0
  upstream_dns:
    - tcp://10.25.150.252
  bootstrap_dns:
    - 10.25.150.252
  filtering_enabled: true
  safebrowsing_enabled: true
  # Gateway filtering rules
  custom_filtering_rules:
    - '||gateway.internal^$important'
```

## Service Discovery

### Internal Services

- CoreDNS for cluster-local resolution
- Cilium service mesh discovery
- Gateway route resolution
- Custom internal zones

### External Services

- External-dns with Gateway API
- Automatic record management
- Split DNS configuration
- Certificate validation

## Monitoring

### DNS Metrics

- Query performance
- Cache efficiency
- Gateway resolution times
- Error tracking

### Gateway DNS Health

- Route resolution status
- Certificate validity
- DNS propagation times
- Record synchronization

## Troubleshooting

### Common Issues

1. Gateway DNS Resolution

   ```bash
   # Check DNS record sync
   kubectl get gateway external -o yaml
   dig @10.25.150.252 app.pc-tips.se
   ```

2. Certificate Validation

   ```bash
   # Verify cert-manager DNS records
   kubectl get challenges -A
   dig @10.25.150.252 _acme-challenge.app.pc-tips.se
   ```

3. Service Discovery
   ```bash
   # Test internal resolution
   dig @10.25.150.252 service.namespace.svc.cluster.local
   dig @10.25.150.252 gateway.internal
   ```
