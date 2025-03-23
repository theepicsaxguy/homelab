# Service Registry

## Core Infrastructure Services

### Authentication & Authorization

| Service  | Status | Description    | URL                            |
| -------- | ------ | -------------- | ------------------------------ |
| Authelia | Active | SSO Provider   | `https://auth.kube.pc-tips.se` |
| LLDAP    | Active | LDAP Directory | Internal only                  |

### Network Services

| Service     | Status | Description        | Access        |
| ----------- | ------ | ------------------ | ------------- |
| CoreDNS     | Active | DNS Services       | Internal only |
| Cilium      | Active | CNI & Service Mesh | Cluster-wide  |
| Gateway API | Active | Ingress Controller | Cluster-wide  |

### Storage Services

| Service  | Status | Description     | Access        |
| -------- | ------ | --------------- | ------------- |
| Longhorn | Active | Primary Storage | Internal only |
| Restic   | Active | Backup Solution | S3 Backend    |

### Certificate Management

| Service      | Status | Description            | Access       |
| ------------ | ------ | ---------------------- | ------------ |
| cert-manager | Active | Certificate Management | Cluster-wide |

## Application Services

### Media Applications

| Service  | Status | Description        | URL                                |
| -------- | ------ | ------------------ | ---------------------------------- |
| Plex     | Active | Media Server       | `https://plex.kube.pc-tips.se`     |
| Jellyfin | Active | Media Server       | `https://jellyfin.kube.pc-tips.se` |
| Sonarr   | Active | TV Management      | `https://sonarr.kube.pc-tips.se`   |
| Radarr   | Active | Movie Management   | `https://radarr.kube.pc-tips.se`   |
| Prowlarr | Active | Indexer Management | `https://prowlarr.kube.pc-tips.se` |

### Development Tools

| Service | Status | Description       | Access                           |
| ------- | ------ | ----------------- | -------------------------------- |
| ArgoCD  | Active | GitOps Controller | `https://argocd.kube.pc-tips.se` |

### External Integrations

| Service        | Status | Description        | Access                         |
| -------------- | ------ | ------------------ | ------------------------------ |
| Home Assistant | Active | Home Automation    | `https://hass.kube.pc-tips.se` |
| Proxmox        | Active | VM Management      | External                       |
| TrueNAS        | Active | Storage Management | External                       |

## Planned Services

### Monitoring Stack (Future)

| Service      | Status  | Description        | Planned URL                            |
| ------------ | ------- | ------------------ | -------------------------------------- |
| Prometheus   | Planned | Metrics Collection | `https://prometheus.kube.pc-tips.se`   |
| Grafana      | Planned | Visualization      | `https://grafana.kube.pc-tips.se`      |
| Loki         | Planned | Log Aggregation    | Internal only                          |
| Alertmanager | Planned | Alert Management   | `https://alertmanager.kube.pc-tips.se` |

### Security Services (Future)

| Service | Status  | Description           | Access        |
| ------- | ------- | --------------------- | ------------- |
| Falco   | Planned | Runtime Security      | Internal only |
| Trivy   | Planned | Vulnerability Scanner | Internal only |

## Service Dependencies

### Critical Path Services

1. Authentication (Authelia)
2. DNS (CoreDNS)
3. Storage (Longhorn)
4. Network (Cilium)
5. Certificates (cert-manager)

### Service Relationships

- All external services require Gateway API
- All services use Authelia for authentication
- Storage services depend on Longhorn
- External access requires cert-manager

## Access Methods

### Internal Access

- Service mesh communication
- ClusterIP services
- Internal DNS resolution
- RBAC controls

### External Access

- Gateway API routes
- TLS termination
- Authentication enforcement
- Network policies

## Maintenance Windows

### Regular Maintenance

- Updates: Weekly (non-critical)
- Backups: Daily
- Health Checks: Hourly
- Certificate Renewal: Automatic

### Emergency Maintenance

- Security patches: Immediate
- Critical fixes: As needed
- Data recovery: As needed

## Health Monitoring

### Current Implementation

- Basic health probes
- ArgoCD sync status
- Manual verification
- Basic logging

### Future Monitoring

- Prometheus metrics
- Grafana dashboards
- Automated alerts
- Performance tracking

## Documentation Notes

1. Keep this registry updated with service changes
2. Document all new services before deployment
3. Update URLs and access methods as needed
4. Track status changes and migrations
