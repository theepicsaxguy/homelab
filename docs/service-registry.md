# Service Registry

## Overview

This document provides a central registry of all exposed services in the homelab infrastructure.

## Domain-Based Services

### Core Infrastructure

- ArgoCD: `argocd.pc-tips.se`
- Proxmox: `proxmox.pc-tips.se`
- TrueNAS: `truenas.pc-tips.se`

### Security & Authentication

- Authelia: `authelia.pc-tips.se`
- Hubble: `hubble.pc-tips.se`

### Monitoring & Observability

- Grafana: `grafana.pc-tips.se`
- Prometheus: `prometheus.pc-tips.se`

### Media Services

- Jellyfin: `jellyfin.pc-tips.se`
- Lidarr: `lidarr.pc-tips.se`
- Prowlarr: `prowlarr.pc-tips.se`
- Radarr: `radarr.pc-tips.se`
- Sonarr: `sonarr.pc-tips.se`

### Home Automation

- Home Assistant: `haos.pc-tips.se`

### Network Services

- AdGuard: `adguard.pc-tips.se`

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
