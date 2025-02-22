# DNS Configuration

## Overview

The DNS infrastructure uses a multi-layered approach with Unbound as the primary resolver and AdGuard as a filtering DNS
server.

## DNS Architecture

### Primary DNS (Unbound)

- IP: 10.25.150.252
- Features:
  - DNSSEC validation
  - DNS-over-TLS support
  - Caching resolver
  - Forward secrecy

### Secondary DNS (AdGuard)

- IP: 10.25.150.253
- Features:
  - Ad blocking
  - Custom filtering rules
  - DNS-over-HTTPS support
  - Query logging

### Internal DNS (CoreDNS)

- Service discovery
- Pod DNS resolution
- External DNS integration
- Custom DNS records

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
```

## External DNS Integration

- Automatic DNS record management
- Integration with ingress controllers
- Domain validation support
- TTL management

## Monitoring

- DNS query metrics
- Response time monitoring
- Error rate tracking
- Cache hit ratios
