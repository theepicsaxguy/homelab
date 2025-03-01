# Network Architecture Overview

## Core Network Design

The cluster network infrastructure is built on Cilium, providing advanced networking capabilities and security features
through eBPF technology with Gateway API integration.

## Components

1. **Cilium** - Primary CNI provider

   - Service mesh functionality with Hubble UI
   - Native Gateway API implementation
   - Load balancing and traffic management
   - Network policies with L7 visibility
   - Direct routing optimization
   - eBPF-based security features

2. **Gateway API** - Modern Ingress Management

   - External Gateway (Internet-facing services)
   - Internal Gateway (Cluster-local services)
   - TLS Passthrough Gateway (Direct TLS termination)
   - Native certificate management
   - Standardized HTTP/HTTPS routing

3. **DNS Architecture**
   - Primary: Unbound DNS (`10.25.150.252`)
   - Secondary: AdGuard DNS (`10.25.150.253`)
   - Internal service discovery via CoreDNS
   - Automatic external DNS updates

## Network Topology

```yaml
gateways:
  external:
    class: cilium
    addresses: ['10.25.150.240/29']
    routes:
      - argocd
      - grafana
      - prometheus
      - jellyfin
      - home-assistant
  internal:
    class: cilium
    addresses: ['10.25.150.248/29']
    routes:
      - metrics
      - monitoring
      - auth
  tls-passthrough:
    class: cilium
    routes:
      - proxmox
      - truenas
```

## Network Ranges

```yaml
cluster_network:
  pod_cidr: '10.42.0.0/16'
  service_cidr: '10.43.0.0/16'
external_services:
  gateway_range: '10.25.150.240/29' # External Gateway
  internal_range: '10.25.150.248/29' # Internal Gateway
  service_range: '10.25.150.0/24' # Legacy Services
```

## Service Access Points

### Domain-based Access

All services are exposed through `*.kube.pc-tips.se` subdomains with authentication handled by Authelia.

Key service endpoints:

- Core Infrastructure:
  - `argocd.pc-tips.se` (Gateway: external)
  - `proxmox.pc-tips.se` (Gateway: tls-passthrough)
  - `truenas.pc-tips.se` (Gateway: tls-passthrough)
  - `argocd.kube.pc-tips.se`
  - `proxmox.kube.pc-tips.se`
  - `truenas.kube.pc-tips.se`
- Monitoring:
  - `grafana.pc-tips.se` (Gateway: external)
  - `prometheus.pc-tips.se` (Gateway: external)
  - `hubble.pc-tips.se` (Gateway: internal)
  - `grafana.kube.pc-tips.se`
  - `prometheus.kube.pc-tips.se`
  - `hubble.kube.pc-tips.se`
- Applications:
  - `haos.pc-tips.se` (Gateway: external)
  - Various media services (Gateway: external)
  - `haos.kube.pc-tips.se`
  - Various media services (Jellyfin, Radarr, etc.)

### IP-based Services

Critical infrastructure services with dedicated IPs:

- DNS Services:
  - Unbound: `10.25.150.252`
  - AdGuard: `10.25.150.253`
- Gateway Services:
  - External Gateway: `10.25.150.240/29`
  - Internal Gateway: `10.25.150.248/29`
- Legacy Services:
  - Torrent: `10.25.150.225`
  - Whoami: `10.25.150.223`

## Detailed Documentation

- [Cilium Configuration](cilium.md)
- [DNS Setup and Configuration](dns.md)
- [Gateway API Configuration](gateway.md)
- [Network Policies](policies.md)
