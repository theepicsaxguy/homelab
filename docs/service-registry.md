# Service Registry

## Overview

This document provides a central registry of all exposed services in the homelab infrastructure.

## Domain-Based Services

### Core Infrastructure

- ArgoCD: `argocd.kube.pc-tips.se`
- Proxmox: `proxmox.kube.pc-tips.se`
- TrueNAS: `truenas.kube.pc-tips.se`

### Security & Authentication

- Authelia: `authelia.kube.pc-tips.se`
- Hubble: `hubble.kube.pc-tips.se`

### Monitoring & Observability

- Grafana: `grafana.kube.pc-tips.se`
- Prometheus: `prometheus.kube.pc-tips.se`

### Media Services

- Jellyfin: `jellyfin.kube.pc-tips.se`
- Lidarr: `lidarr.kube.pc-tips.se`
- Prowlarr: `prowlarr.kube.pc-tips.se`
- Radarr: `radarr.kube.pc-tips.se`
- Sonarr: `sonarr.kube.pc-tips.se`

### Home Automation

- Home Assistant: `haos.kube.pc-tips.se`

### Network Services

- AdGuard: `adguard.kube.pc-tips.se`

## IP-Based Services

### DNS Services

- Unbound DNS: `10.25.150.252`
- AdGuard DNS: `10.25.150.253`

### Application Services

- Torrent: `10.25.150.225`
- Whoami: `10.25.150.223`

## Service Configuration

### Authentication Requirements

All domain-based services require authentication through Authelia except:

- Authelia itself
- Public endpoints (if any)

### Network Policies

Each service has dedicated network policies controlling:

- Ingress/egress traffic
- Cross-service communication
- External access

### Monitoring Integration

All services are monitored for:

- Availability
- Performance metrics
- Error rates
- Resource usage
