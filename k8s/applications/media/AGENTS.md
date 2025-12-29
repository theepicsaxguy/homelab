# Media Applications - Category Guidelines

SCOPE: Media management, streaming, and content discovery applications
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: Jellyfin, Immich, arr-stack (Sonarr, Radarr, Prowlarr, Bazarr), Audiobookshelf, Audiobookrequest, Sabnzbd, WhisperASR

## CATEGORY CONTEXT

Purpose:
Deploy and manage media-related applications including media servers, content automation, photo management, audiobook services, and download managers.

Boundaries:
- Handles: Media streaming, content automation, photo management, audiobook services, download managers
- Does NOT handle: Home automation (see automation/), AI applications (see ai/), web utilities (see web/)
- Integrates with: network/ (Gateway API routes), storage/ (PVCs), auth/ (Authentik SSO)

## INHERITED PATTERNS

For general Kubernetes patterns, see k8s/AGENTS.md:
- Storage: proxmox-csi (new), longhorn (legacy)
- Network: Gateway API for external access
- Authentication: Authentik SSO where supported
- Database: CNPG for PostgreSQL with auto-generated credentials
- Backup: Velero for proxmox-csi, Longhorn labels for legacy
- Shared Storage: NFS PV for media libraries

## MEDIA-SPECIFIC PATTERNS

### Content Automation Pattern
arr-stack (Prowlarr, Sonarr, Radarr, Bazarr) automate content discovery, download, and organization. All arr services use shared NFS mount for media libraries. SQLite databases embedded in application PVCs.

### Photo Management Pattern
Immich uses multi-service architecture with CNPG PostgreSQL, Redis, and ML pod. Supports OAuth2 via Authentik. Dual backup: MinIO (local) + Backblaze B2 (offsite).

### Download Manager Pattern
Sabnzbd manages Usenet downloads. PVC for download storage (proxmox-csi). ExternalSecrets for Usenet server credentials.

### Offline Content Pattern
WhisperASR caches AI models in PVC. No public access. Models can be re-downloaded if needed.

## APPLICATION-SPECIFIC GUIDANCE

### Jellyfin (Media Server)

**Purpose**: Media streaming server for movies, TV shows, and music.

**Deployment**:
- StatefulSet with single replica
- PVC for configuration and cache
- Mounts NFS for media library access
- Timezone: Europe/Stockholm
- Gateway API route for external access

**Resources**:
- CPU: 2 cores
- Memory: 4Gi
- Storage: 10Gi PVC (proxmox-csi or longhorn)
- NFS mount: Media library from shared NFS PV

**Configuration**:
- Environment variables in ConfigMap (TZ, etc.)
- No external secrets required
- SQLite database embedded in PVC

### Immich (Photo Management)

**Purpose**: Self-hosted Google Photos alternative for photo and video management.

**Deployment**:
- Multi-service application (immich-server, immich-ml, immich-redis)
- CNPG PostgreSQL cluster with 2 instances
- ML pod for AI features (face recognition, object detection)
- Redis for caching and job queue
- ExternalSecrets for MinIO and Backblaze B2 credentials

**Components**:
- **immich-server**: Main application API and web UI
- **immich-ml**: Machine learning for smart features
- **immich-redis**: Caching layer
- **immich-postgresql**: CNPG database cluster

**Database Configuration**:
- Cluster: 2 instances with PodAntiAffinity
- Storage: 15Gi (Longhorn, GFS backup tier)
- WAL Storage: 3Gi (Longhorn, GFS backup tier)
- Parameters: Optimized for Immich workload
- Plugins: barman-cloud.cloudnative-pg.io for WAL archiving

**Backup Strategy**:
- **Local MinIO**: Fast recovery from NAS
- **Backblaze B2**: Offsite disaster recovery
- **WAL Archiving**: Continuous to B2
- **Scheduled Backups**: Weekly to B2
- **Retention**: 30 days

**External Secrets Required**:
- `b2-cnpg-credentials`: Backblaze B2 access keys (2 separate Bitwarden entries)
- `minio-credentials`: MinIO credentials (shared secret)
- `immich-config`: Immich application configuration (if using secret-based config)

**Gateway API**: Route for `immich.peekoff.com`

### arr-stack (Content Automation)

**Purpose**: Automated content discovery, download, and management.

**Components**:
- **Prowlarr**: Indexer and tracker management for Usenet and torrents
- **Sonarr**: TV series automation (search, download, organize)
- **Radarr**: Movie automation (search, download, organize)
- **Bazarr**: Subtitle automation for TV and movies

**Deployment**:
- StatefulSet for each arr service
- Shared environment variables (TZ, PUID, PGID)
- PVC for configuration and data
- Gateway API routes for external access
- Shared NFS mount for media library access

**Resources**:
- CPU: 1-2 cores per service
- Memory: 1-2Gi per service
- Storage: 5Gi PVC per service (proxmox-csi or longhorn)
- NFS mount: Media library for download organization

**Configuration**:
- Environment variables: TZ=Europe/Stockholm, PUID=2501, PGID=2501
- No external secrets required
- SQLite databases embedded in PVCs
- API keys for inter-service communication (set in UI)

**Base Patch**: Common configuration applied to all arr services via Kustomize patch

### Jellyseerr

**Purpose**: Media request management system for movies and TV shows.

**Deployment**:
- Deployment with single replica
- PVC for application data
- Gateway API route for external access
- ExternalSecrets for application credentials

**Resources**:
- CPU: 1 core
- Memory: 1Gi
- Storage: 5Gi PVC for application data (proxmox-csi recommended)

**Configuration**:
- Environment variables for timezone and settings
- ExternalSecrets for API keys and authentication
- API keys for arr-stack integration (set in UI)

### Audiobookshelf

**Purpose**: Self-hosted audiobook streaming and management platform.

**Deployment**:
- Deployment with single replica
- PVC for audiobook library and metadata
- Gateway API route for external access
- Optional authentication (OAuth2 via Authentik)

**Resources**:
- CPU: 1 core
- Memory: 1Gi
- Storage: Large PVC for audiobook storage (proxmox-csi recommended)

**Configuration**:
- Environment variables for timezone and configuration
- ExternalSecrets for authentication if using OAuth2

### Audiobookrequest

**Purpose**: Audiobook request management system with web interface.

**Deployment**:
- Deployment with MongoDB backend
- PVC for MongoDB data
- Gateway API route for external access
- ExternalSecrets for application credentials

**Resources**:
- CPU: 1 core
- Memory: 1Gi
- Storage: 5Gi PVC for MongoDB (proxmox-csi recommended)

**Database**:
- MongoDB StatefulSet (not CNPG)
- Embedded in application manifests
- Auto-generated or external secret for credentials

### Sabnzbd (Usenet Downloader)

**Purpose**: Usenet newsreader and download manager.

**Deployment**:
- StatefulSet with single replica
- PVC for configuration and downloads
- Gateway API route for external access
- ExternalSecrets for Usenet server credentials

**Resources**:
- CPU: 1 core
- Memory: 1Gi
- Storage: 100Gi+ PVC for download storage (proxmox-csi recommended)

**Configuration**:
- ExternalSecret for Usenet server credentials (host, username, password, connections)
- SABnzbd password for web UI access

### WhisperASR

**Purpose**: Speech-to-text transcription using Whisper AI model.

**Deployment**:
- Deployment with single replica
- PVC for model cache
- Internal service (no external access required)
- CPU-only or GPU-based inference

**Resources**:
- CPU: 4+ cores for CPU inference
- Memory: 4-8Gi
- GPU: Optional, if available (see k8s/applications/ai/AGENTS.md)
- Storage: 10Gi PVC for model cache (proxmox-csi recommended)

## BACKUP STRATEGY

### Critical Data (GFS Tier)

**Immich**:
- PostgreSQL database: GFS backup tier on Longhorn PVCs
- Weekly backups to Backblaze B2 via CNPG
- Continuous WAL archiving to B2
- Local MinIO backup for fast recovery

### Standard Applications (Daily Tier)

**Jellyfin, arr-stack, Jellyseerr, Audiobookshelf, Sabnzbd**:
- Configuration PVCs: Daily backup tier
- Media libraries: Backed up via TrueNAS/NFS (not via Kubernetes)
- No backup labels for caches/temporary data

### Non-Critical (Weekly or No Backup)

**WhisperASR model cache**:
- Models can be re-downloaded
- No backup or weekly backup tier

**Audiobookrequest MongoDB**:
- Request data (loss acceptable)
- Daily backup tier

## TESTING

### Media Application Validation

```bash
# Build media applications
kustomize build --enable-helm k8s/applications/media

# Validate specific application
kustomize build --enable-helm k8s/applications/media/<app>

# Check application pods
kubectl get pods -n media

# Check application logs
kubectl logs -n media -l app=<app> -f

# Verify Gateway route
kubectl get httproute -n media <app>-route
kubectl describe httproute -n media <app>-route

# Verify external access
curl -H "Host: <app>.peekoff.com" https://<gateway-ip>
```

### Database Validation (Immich)

```bash
# Check CNPG cluster status
kubectl get cluster -n immich

# Check database pods
kubectl get pods -n immich -l cnpg.io/podRole=instance

# Check backup status
kubectl get backup -n immich
kubectl get scheduledbackup -n immich

# Verify external secrets exist
kubectl get externalsecrets -n immich

# Test database connection
kubectl exec -n immich -l cnpg.io/podRole=instance -- psql -U immich -d immich -c "SELECT version();"
```

## OPERATIONAL PATTERNS

### Media Library Management

**NFS Shared Storage**:
- All media applications mount shared NFS PV
- Media library located on TrueNAS
- Applications organize content in subdirectories
- Backup: TrueNAS replication to offsite storage

**Content Workflow**:
1. **Prowlarr**: Discovers new content from indexers
2. **Sabnzbd**: Downloads content from Usenet
3. **arr-stack**: Processes and organizes content
4. **Jellyfin**: Streams content to clients

### Application Updates

**Version Updates**:
- Update image tags in StatefulSet/Deployment manifests
- Apply via GitOps (commit and push)
- Argo CD auto-syncs changes
- Monitor application logs for migration issues

**Database Migrations**:
- Immich: Automatic schema migrations on startup
- arr-stack: Automatic database upgrades
- Check logs for migration errors

## ANTI-PATTERNS

Never use Longhorn for new media applications. Use proxmox-csi for better performance and automatic backups.

Never back up media libraries via Kubernetes. Use TrueNAS/NFS backup strategy instead.

Never skip database backup configuration for Immich. Configure CNPG backups and WAL archiving.

Never use SQLite for critical applications. Use CNPG for production workloads (Immich).

Never expose media applications without authentication. Use Authentik SSO where supported.

Never allocate insufficient storage for media libraries. Scale PVCs based on content growth.

## REFERENCES

For Kubernetes domain patterns, see k8s/AGENTS.md

For storage patterns, see k8s/infrastructure/storage/AGENTS.md

For network patterns (Gateway API), see k8s/infrastructure/network/AGENTS.md

For authentication patterns (Authentik), see k8s/infrastructure/auth/authentik/AGENTS.md

For CNPG database patterns, see k8s/infrastructure/database/AGENTS.md

For commit message format, see root AGENTS.md
