# Web Applications - Category Guidelines

SCOPE: Web-based productivity and utility applications
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: BabyBuddy, Pinepods, HeadlessX, Kiwix, Pedrobot

## CATEGORY CONTEXT

Purpose:
Deploy and manage web-based applications for personal productivity, podcast management, offline content access, and bot services.

Boundaries:
- Handles: Web applications for personal use
- Does NOT handle: Media services (see media/), automation (see automation/)
- Integrates with: network/ (Gateway API), storage/ (PVCs), auth/ (Authentik SSO)

## INHERITED PATTERNS

For general Kubernetes patterns, see k8s/AGENTS.md:
- Storage: proxmox-csi (all new web applications)
- Network: Gateway API for external access
- Authentication: Authentik SSO where supported
- Database: CNPG for PostgreSQL with auto-generated credentials
- Backup: Velero automatic backups for proxmox-csi PVCs
- Large Storage: Exclude from backups if re-downloadable (Kiwix)

## WEB-SPECIFIC PATTERNS

### Browser Automation Pattern
HeadlessX runs headless browser tasks with network policy restrictions. Requires OAuth2 via Authentik. Isolated namespace for security.

### Podcast Management Pattern
Pinepods uses CNPG PostgreSQL with Valkey (Redis-compatible) for caching. Supports OAuth2 via Authentik. Large PVC for podcast data.

### Offline Content Pattern
Kiwix stores large offline content (Wikipedia ZIM files, 200GB+). Exclude from Velero backups via pod annotation. Content can be re-downloaded.

### Bot Service Pattern
Pedrobot uses MongoDB StatefulSet (not CNPG). External secrets for bot API credentials. No OAuth2 support.

## APPLICATION-SPECIFIC GUIDANCE

### BabyBuddy

**Purpose**: Baby tracking application for infant care logging.

**Deployment**:
- StatefulSet with single replica
- PVC for application data and SQLite database
- Gateway API route for external access
- OAuth2 via Authentik for SSO

**Resources**:
- CPU: 0.5 core
- Memory: 512Mi
- Storage: 5Gi PVC (proxmox-csi)

**External Secrets**:
- `babybuddy-external-secret`: OAuth2 credentials (if using Authentik SSO)

**Database**: SQLite embedded in PVC

### Pinepods

**Purpose**: Self-hosted podcast management and synchronization.

**Deployment**:
- Deployment with single replica
- CNPG PostgreSQL database (2 instances)
- Valkey (Redis-compatible) for caching
- PVC for podcast data
- Gateway API route for external access
- Optional OAuth2 via Authentik

**Components**:
- **pinepods**: Main application API and web UI
- **pinepods-postgresql**: CNPG database cluster
- **valkey**: Caching layer for podcast metadata

**Database Configuration**:
- Cluster: 2 instances with PodAntiAffinity
- Storage: 10Gi (proxmox-csi)
- WAL Storage: 2Gi (proxmox-csi)
- Auto-generated credentials in `pinepods-postgresql-app` secret

**Backup Strategy**:
- **Local MinIO**: Fast recovery from NAS
- **Backblaze B2**: Offsite disaster recovery
- **Scheduled Backups**: Weekly to B2
- **Retention**: 30 days

**External Secrets Required**:
- `pinepods-externalsecret`: OAuth2 credentials (if using Authentik SSO)

**Resources**:
- CPU: 1 core
- Memory: 1Gi
- Storage: 20Gi PVC for podcast data (proxmox-csi)

### HeadlessX

**Purpose**: Browser automation service for headless browser tasks.

**Deployment**:
- Deployment with single replica
- PVC for browser profile and data
- Gateway API route for external access
- Network policy for restricted egress
- OAuth2 via Authentik for SSO

**Security**:
- **Network Policy**: Restricts egress to required domains only
- **Authentication**: Authentik SSO required for access
- **Isolation**: Separate namespace for security

**Resources**:
- CPU: 2 cores
- Memory: 2Gi
- Storage: 10Gi PVC (proxmox-csi)

**External Secrets**:
- `headlessx-external-secret`: OAuth2 credentials (if using Authentik SSO)

### Kiwix

**Purpose**: Offline Wikipedia and content reader.

**Deployment**:
- Deployment with single replica
- Large PVC for offline content (200GB+ Wikipedia)
- Gateway API route for external access
- No external authentication required (public or VPN access)

**Content**:
- **Wikipedia**: Full English Wikipedia dump
- **Offline Only**: No external connectivity required for content
- **Update Strategy**: Manual updates via PVC refresh

**Resources**:
- CPU: 1 core
- Memory: 2Gi
- Storage: 200Gi+ PVC (proxmox-csi)

**Backup Considerations**:
- Large storage (200GB+): Exclude from Velero backups
- Content can be re-downloaded
- Add exclusion annotation: `backup.velero.io/exclude-from-backup: "true"`

### Pedrobot

**Purpose**: Bot service for web automation and integration.

**Deployment**:
- Deployment with single replica
- MongoDB StatefulSet for data storage
- PVC for MongoDB data
- Gateway API route for external access
- External secrets for authentication

**Database**:
- **MongoDB**: StatefulSet (not CNPG)
- Embedded in application manifests
- Auto-generated or external secret for credentials
- No CNPG backup strategy

**Resources**:
- CPU: 1 core
- Memory: 1Gi
- Storage: 5Gi PVC for MongoDB data (proxmox-csi)

**External Secrets**:
- `pedro-bot-external-secret`: Bot API credentials or authentication

## BACKUP STRATEGY

### Critical Data (Automatic)

**Pinepods Database**:
- CNPG PostgreSQL cluster
- Weekly scheduled backups to Backblaze B2
- Continuous WAL archiving to B2
- Local MinIO backup for fast recovery
- Automatic Velero backups for proxmox-csi PVCs

**BabyBuddy**:
- SQLite database embedded in PVC
- Automatic Velero backups for proxmox-csi PVC

**HeadlessX**:
- Browser profile and data in PVC
- Automatic Velero backups for proxmox-csi PVC

**Pedrobot MongoDB**:
- MongoDB StatefulSet data in PVC
- Automatic Velero backups for proxmox-csi PVC

### Large Storage (Excluded)

**Kiwix Wikipedia**:
- 200GB+ offline content
- Exclude from Velero backups via pod annotation
- Content can be re-downloaded
- Backup: Manual or offsite sync

**Pinepods Podcasts**:
- Large audio files in PVC
- Automatic Velero backups for proxmox-csi PVCs
- Consider exclusion if storage becomes too large

## TESTING

### Web Application Validation

```bash
# Build web applications
kustomize build --enable-helm k8s/applications/web

# Validate specific application
kustomize build --enable-helm k8s/applications/web/<app>

# Check application pods
kubectl get pods -n <namespace>

# Check application logs
kubectl logs -n <namespace> -l app=<app> -f

# Verify Gateway route
kubectl get httproute -n <namespace> <app>-route
kubectl describe httproute -n <namespace> <app>-route

# Verify external access
curl -H "Host: <app>.peekoff.com" https://<gateway-ip>
```

### Database Validation (Pinepods)

```bash
# Check CNPG cluster status
kubectl get cluster -n pinepods

# Check database pods
kubectl get pods -n pinepods -l cnpg.io/podRole=instance

# Verify auto-generated secret
kubectl get secret pinepods-postgresql-app -n pinepods

# Test database connection
kubectl exec -n pinepods -l cnpg.io/podRole=instance -- psql -U pinepods -d pinepods -c "SELECT version();"
```

## OPERATIONAL PATTERNS

### Application Updates

**Version Updates**:
- Update image tags in Deployment/StatefulSet manifests
- Apply via GitOps (commit and push)
- Argo CD auto-syncs changes
- Monitor application logs for migration issues

**Database Migrations**:
- Pinepods: Automatic schema migrations on startup
- Check logs for migration errors
- Create database snapshot before major version upgrades

### Content Updates (Kiwix)

**Update Wikipedia Content**:
1. Download latest ZIM file from Kiwix website
2. Stop Kiwix deployment: `kubectl scale deployment kiwix -n kiwix --replicas=0`
3. Mount new ZIM file to PVC (via temporary pod or hostPath)
4. Start Kiwix deployment: `kubectl scale deployment kiwix -n kiwix --replicas=1`
5. Verify new content loads correctly

**Automate** (optional):
- Use CronJob to periodically download and update ZIM files
- Store ZIM files in shared NFS storage (not PVC)

## ANTI-PATTERNS

Never use Longhorn for web applications. Use proxmox-csi for better performance and automatic backups.

Never skip OAuth2 configuration when available. Use Authentik SSO for better security.

Never backup Kiwix Wikipedia content via Velero. Exclude large content to save backup storage.

Never use embedded databases for production workloads. Use CNPG for new applications requiring databases.

Never expose web applications without authentication when sensitive data is involved. Use Authentik SSO.

Never allocate insufficient storage for podcast or media content. Scale PVCs based on content growth.

## SECURITY BOUNDARIES

Never expose HeadlessX to public internet without restrictions. Use network policies to limit egress.

Never use weak passwords for web applications. Use Authentik SSO or strong secrets.

Never commit OAuth2 client secrets to manifests. Use ExternalSecrets for all sensitive data.

Never allow unrestricted network policies for web applications. Explicitly define required egress rules.

## REFERENCES

For Kubernetes domain patterns, see k8s/AGENTS.md

For storage patterns, see k8s/infrastructure/storage/AGENTS.md

For network patterns (Gateway API), see k8s/infrastructure/network/AGENTS.md

For authentication patterns (Authentik), see k8s/infrastructure/auth/authentik/AGENTS.md

For CNPG database patterns, see k8s/infrastructure/database/AGENTS.md

For commit message format, see root AGENTS.md
