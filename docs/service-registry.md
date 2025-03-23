# Service Registry

## Core Infrastructure

### Critical Path Services

These services must be operational for the cluster to function:

**Authentication & Network**

- Authelia: Identity provider, SSO gateway
- Cilium: CNI, service mesh, network policies
- CoreDNS: Service discovery, name resolution
- Gateway API: External access management

**Storage & State**

- Longhorn: Primary storage provider
- Restic: Backup management
- cert-manager: Certificate lifecycle

Dependencies flow: Network → Auth → Storage → Apps

## Application Services

### Media Stack

**Core:** Plex, Jellyfin **Management:** Sonarr, Radarr, Prowlarr

- Requires: Storage, Authentication
- Optional: External IP for remote access

### Development Tools

**ArgoCD**

- Critical for GitOps workflow
- Requires: Authentication, Git access
- Manages: All other deployments

### External Integration

**Home Assistant**

- Home automation hub
- Requires: Storage, Network access
- Optional: External device discovery

## Health Status

### Monitoring

- Currently: Basic health checks only
- Planned: Full monitoring stack (Q2 2025)
- Critical need: Service metrics, alerts

### Backup Status

- Daily application backups
- Weekly full cluster backup
- Monthly archives

## Security Context

### Authentication

All services require:

- Authelia SSO integration
- RBAC configuration
- Network policies

### External Access

Services exposed via:

- Gateway API routes
- TLS termination
- Authentication enforcement

## Known Issues

1. Manual backup verification
2. Basic monitoring only
3. Limited automated recovery
4. Manual failover for some services

## Related Info

- [Security Model](security/overview.md)
- [Network Architecture](networking/overview.md)
- [Backup Configuration](storage/backup.md)
