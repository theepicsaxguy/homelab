# Media Applications - Specialized Patterns

SCOPE: Media management, streaming, and content automation
INHERITS FROM: /k8s/AGENTS.md

## MEDIA-SPECIFIC PATTERNS

### NFS Media Library Pattern
```yaml
# Shared media mount for arr-stack
apiVersion: v1
kind: PersistentVolume
metadata:
  name: media-nfs
spec:
  capacity:
    storage: 10Ti
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: truenas.peekoff.com
    path: /mnt/media
---
# PVC for application access
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: media
  namespace: media
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Ti
  volumeName: media-nfs
```

**Mount Pattern:**
```yaml
volumeMounts:
- name: media
  mountPath: /media
  subPath: <app-specific-path>  # e.g., movies, tv, music
```

**SubPath Structure:**
- `/media/movies/` - Radarr
- `/media/tv/` - Sonarr  
- `/media/music/` - Lidarr (if added)
- `/media/downloads/` - Sabnzbd
- `/media/audiobooks/` - Audiobookshelf

### arr-stack Service Pattern
```yaml
# Common service configuration for arr-stack
apiVersion: v1
kind: Service
metadata:
  name: <arr-app>
  namespace: media
spec:
  selector:
    app.kubernetes.io/name: <arr-app>
  ports:
  - port: 80
    targetPort: 8983  # Adjust per app
---
# HTTPRoute for external access
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: <arr-app>
  namespace: media
spec:
  parentRefs:
  - name: external
    namespace: gateway
  hostnames:
  - "<arr-app>.peekoff.com"
  rules:
  - matches:
    - path:
        type: Prefix
        value: /
    backendRefs:
    - name: <arr-app>
      port: 80
```

**arr-stack Services:**
- **Sonarr**: Port 8983, manages TV series
- **Radarr**: Port 7878, manages movies  
- **Prowlarr**: Port 9696, manages indexers
- **Bazarr**: Port 6767, manages subtitles

### Immich Multi-Service Pattern
```yaml
# Immich services connection pattern
# Database: immich-postgresql.media.svc.cluster.local
# Redis: immich-redis.media.svc.cluster.local
# ML Service: immich-machine-learning.media.svc.cluster.local

# Environment variables pattern
env:
- name: DB_HOSTNAME
  value: immich-postgresql.media.svc.cluster.local
- name: DB_USERNAME
  valueFrom:
    secretKeyRef:
      name: immich-postgresql-app
      key: username
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: immich-postgresql-app
      key: password
- name: REDIS_HOSTNAME
  value: immich-redis.media.svc.cluster.local
```

**Storage Configuration:**
- Photos/videos: Large PVC with GFS backup tier
- Library: Use proxmox-csi StorageClass
- ML models: Separate PVC for ML service

### Download Manager Pattern (Sabnzbd)
```yaml
# Sabnzbd ExternalSecret
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: sabnzbd-credentials
  namespace: media
spec:
  secretStoreRef:
    name: bitwarden-backend
    kind: ClusterSecretStore
  target:
    creationPolicy: Owner
  data:
  - secretKey: nzb-server-host
    remoteRef:
      key: Usenet Server
  - secretKey: nzb-server-username
    remoteRef:
      key: Usenet Server
  - secretKey: nzb-server-password
    remoteRef:
      key: Usenet Server
  - secretKey: nzb-server-api-key
    remoteRef:
      key: Usenet Server
```

**Storage Pattern:**
```yaml
# Download storage PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sabnzbd-downloads
  namespace: media
  labels:
    backup.velero.io/backup-tier: Daily
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-csi
  resources:
    requests:
      storage: 500Gi
```

### Audiobookshelf Pattern
```yaml
# Audiobookshelf storage
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: audiobookshelf-library
  namespace: media
  labels:
    backup.velero.io/backup-tier: GFS  # Critical audiobook data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-csi
  resources:
    requests:
      storage: 200Gi
```

**Configuration:**
- Mount audiobooks from NFS or dedicated PVC
- Optional Authentik SSO integration
- Gateway API external access

## MEDIA-DOMAIN ANTI-PATTERNS

### Storage Management
- Never backup media libraries via Kubernetes - backed up separately via TrueNAS
- Never use Longhorn for new media applications - use proxmox-csi
- Never skip NFS mounts for arr-stack - required for shared media access
- Never use Daily backup tier for irreplaceable content - use GFS

### Service Configuration
- Never expose WhisperASR externally - internal service only
- Never use SQLite for production databases - use CNPG (Immich pattern)
- Never skip ExternalSecrets for credential management

## VALIDATION COMMANDS

```bash
# Check NFS mount status
kubectl exec -it -n media <arr-pod> -- df -h /media

# Test media file access
kubectl exec -it -n media <arr-pod> -- ls -la /media/movies

# Check arr-stack connectivity
kubectl exec -it -n media <arr-pod> -- curl http://localhost:8983

# Validate ExternalSecrets
kubectl get externalsecret -n media
kubectl describe secret -n media <secret-name>

# Check Immich services
kubectl get pods -n media -l app.kubernetes.io/part-of=immich
kubectl exec -it -n media immich-server-0 -- curl http://immich-postgresql.media.svc.cluster.local:5432
```

## PERFORMANCE TIPS

### Storage Optimization
- Use proxmox-csi for better performance than Longhorn
- Separate PVCs for different workloads (downloads vs library vs config)
- Monitor disk space on media NFS share

### Network Optimization
- arr-stack services communicate with each other via internal DNS
- Use HTTPRoute for external access with proper TLS termination
- Consider bandwidth management for large file transfers

## REFERENCES

For general patterns: `k8s/AGENTS.md`
For external access: `k8s/infrastructure/network/AGENTS.md`
For storage: `k8s/infrastructure/storage/AGENTS.md`
For databases (Immich): `k8s/infrastructure/database/AGENTS.md`