# Network Architecture Overview

## Core Network Design

The cluster network infrastructure is built on Cilium, providing advanced networking capabilities and security features
through eBPF technology.

## Components

1. **Cilium** - Primary CNI provider

   - Service mesh functionality
   - Load balancing
   - Network policies
   - Direct routing optimization
   - eBPF-based security features

2. **DNS Architecture**

   - Primary: Unbound DNS (`10.25.150.252`)
   - Secondary: AdGuard DNS (`10.25.150.253`)
   - Internal service discovery via CoreDNS

3. **Service Exposure**
   - Ingress-nginx for HTTP/HTTPS traffic
   - MetalLB for bare metal load balancing
   - External DNS for automatic DNS management

## Detailed Documentation

- [Cilium Configuration](cilium.md)
- [DNS Setup and Configuration](dns.md)
- [Ingress Management](ingress.md)
- [Network Policies](policies.md)

## Network Ranges

```yaml
cluster_network:
  pod_cidr: '10.42.0.0/16'
  service_cidr: '10.43.0.0/16'
external_services:
  range: '10.25.150.0/24'
```

## Service Access Points

### Domain-based Access

All services are exposed through `*.kube.pc-tips.se` subdomains with authentication handled by Authelia.

Key service endpoints:

- Core Infrastructure:
  - `argocd.kube.pc-tips.se`
  - `proxmox.kube.pc-tips.se`
  - `truenas.kube.pc-tips.se`
- Monitoring:
  - `grafana.kube.pc-tips.se`
  - `prometheus.kube.pc-tips.se`
  - `hubble.kube.pc-tips.se`
- Applications:
  - `haos.kube.pc-tips.se`
  - Various media services (Jellyfin, Radarr, etc.)

### IP-based Services

Critical infrastructure services with dedicated IPs:

- DNS Services:
  - Unbound: `10.25.150.252`
  - AdGuard: `10.25.150.253`
- Application Services:
  - Torrent: `10.25.150.225`
  - Whoami: `10.25.150.223`
