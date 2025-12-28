# Database Infrastructure - Component Guidelines

SCOPE: PostgreSQL database management with CloudNativePG operator
INHERITS FROM: ../AGENTS.md
TECHNOLOGIES: CloudNativePG (CNPG), PostgreSQL, MinIO, Backblaze B2, S3-compatible storage

## COMPONENT CONTEXT

Purpose:
Deploy and manage PostgreSQL database clusters using CloudNativePG operator, including high availability, backup, and disaster recovery.

Boundaries:
- Handles: PostgreSQL clusters via CNPG, database backups, WAL archiving
- Does NOT handle: Application databases (see applications/), storage providers (see storage/)
- Integrates with: storage/ (for PVCs), controllers/ (for Velero backup integration)

## QUICK-START COMMANDS

```bash
# Build database infrastructure
kustomize build --enable-helm k8s/infrastructure/database

# Check CNPG clusters
kubectl get cluster -A

# Check database pods
kubectl get pods -n <namespace> -l cnpg.io/podRole=instance

# Describe cluster status
kubectl describe cluster <name> -n <namespace>

# Get auto-generated credentials
kubectl get secret <cluster-name>-app -n <namespace>

# Check backup status
kubectl get backup -n <namespace>
kubectl get scheduledbackup -n <namespace>

# Verify storage
kubectl get pvc -n <namespace>
```

## CLOUDNATIVEPG PATTERNS

### Cluster Configuration

**Basic Cluster Structure**:
```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: <cluster-name>
  namespace: <namespace>
spec:
  instances: <number>              # Number of database instances
  imageName: <postgres-image>        # PostgreSQL version
  storage:
    size: <size>                    # Main storage size
    storageClass: <storage-class>     # proxmox-csi or longhorn
  walStorage:
    size: <size>                    # WAL storage size
    storageClass: <storage-class>     # proxmox-csi or longhorn
  postgresql:
    parameters:
      <postgresql-param>: <value>   # PostgreSQL configuration
  monitoring:
    enablePodMonitor: true/false
```

### Auto-Generated Credentials (Preferred)

**Pattern**: Let CNPG auto-generate credentials instead of using ExternalSecrets.

**How It Works**:
- CNPG automatically creates `<cluster-name>-app` secret
- Secret contains: username, password, dbname, host, port, uri
- Applications reference this secret directly
- No circular dependencies with ExternalSecrets

**Secret Contents**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: <cluster-name>-app
  namespace: <namespace>
type: Opaque
data:
  username: <base64-encoded>
  password: <base64-encoded>
  dbname: <base64-encoded>
  host: <base64-encoded>
  port: <base64-encoded>
  uri: <base64-encoded> # postgresql://username:password@host:port/dbname
```

**Application Usage**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: <namespace>
spec:
  template:
    spec:
      containers:
        - name: app
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: <cluster-name>-app
                  key: uri
```

**When to Use ExternalSecrets**:
- Never for application database credentials
- Only for backup credentials (Backblaze B2, MinIO)
- Create separate Bitwarden entries for each secret value

### Backup Configuration

**Dual Backup Strategy**:

**1. Local MinIO (Fast Recovery)**:
- ObjectStore: S3-compatible endpoint (TrueNAS MinIO)
- Use case: Fast restores from local NAS
- Connection: `https://truenas.peekoff.com:9000`
- Bucket: `homelab-postgres-backups/<namespace>/<cluster>`

**2. Backblaze B2 (Disaster Recovery)**:
- ObjectStore: S3-compatible endpoint (Backblaze B2)
- Use case: Offsite disaster recovery
- Connection: `https://s3.us-west-000.backblazeb2.com`
- Bucket: `homelab-cnpg-b2/<namespace>/<cluster>`

**ExternalSecrets for Backup Credentials**:
```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: b2-cnpg-credentials
  namespace: <namespace>
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: bitwarden-backend
    kind: ClusterSecretStore
  target:
    name: b2-cnpg-credentials
    creationPolicy: Owner
    template:
      engineVersion: v2
      data:
        - secretKey: AWS_ACCESS_KEY_ID
          remoteRef:
            key: backblaze-b2-cnpg-access-key-id
        - secretKey: AWS_SECRET_ACCESS_KEY
          remoteRef:
            key: backblaze-b2-cnpg-secret-access-key
```

**Bitwarden Requirements**:
- Separate entry for `backblaze-b2-cnpg-access-key-id`
- Separate entry for `backblaze-b2-cnpg-secret-access-key`
- No `property` field (not supported)
- Use `engineVersion: v2` under `spec.target.template`

**Backup Configuration in Cluster**:
```yaml
spec:
  backup:
    barmanObjectStore:
      destinationPath: s3://homelab-cnpg-b2/<namespace>/<cluster>
      endpointURL: https://s3.us-west-000.backblazeb2.com
      s3Credentials:
        accessKeyId:
          name: b2-cnpg-credentials
          key: AWS_ACCESS_KEY_ID
        secretAccessKey:
          name: b2-cnpg-credentials
          key: AWS_SECRET_ACCESS_KEY
      wal:
        compression: gzip
        encryption: AES256
      data:
        compression: gzip
        encryption: AES256
        jobs: 2
    retentionPolicy: "30d"  # 30-day retention
```

**Scheduled Backups**:
```yaml
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:
  name: <cluster>-scheduled-backup
  namespace: <namespace>
spec:
  cluster:
    name: <cluster-name>
  schedule: "0 2 * * 0"  # Sundays at 02:00
  backupOwnerReference:
    kind: Application
    name: <application-name>
```

**WAL Archiving**:
```yaml
spec:
  plugins:
    - name: barman-cloud.cloudnative-pg.io
      isWALArchiver: true
      parameters:
        barmanObjectName: <b2-store-name>
```

### External Clusters (Recovery)

**Purpose**: Enable recovery from either backup location.

```yaml
spec:
  externalClusters:
    - name: <cluster>-b2-backup
      barmanObjectStore:
        destinationPath: s3://homelab-cnpg-b2/<namespace>/<cluster>
        endpointURL: https://s3.us-west-000.backblazeb2.com
        s3Credentials:
          accessKeyId:
            name: b2-cnpg-credentials
            key: AWS_ACCESS_KEY_ID
          secretAccessKey:
            name: b2-cnpg-credentials
            key: AWS_SECRET_ACCESS_KEY
        wal:
          compression: gzip
          encryption: AES256
    - name: <cluster>-minio-backup
      barmanObjectStore:
        destinationPath: s3://homelab-postgres-backups/<namespace>/<cluster>
        endpointURL: https://truenas.peekoff.com:9000
        s3Credentials:
          accessKeyId:
            name: longhorn-minio-credentials
            key: AWS_ACCESS_KEY_ID
          secretAccessKey:
            name: longhorn-minio-credentials
            key: AWS_SECRET_ACCESS_KEY
        wal:
          compression: gzip
          encryption: AES256
```

## CLUSTER OPERATIONS

### Creating a New Cluster

**Minimum Requirements**:
- 2 instances for high availability
- Separate storage for data and WAL
- StorageClass: `proxmox-csi` (new) or `longhorn` (legacy)
- Backup configuration for MinIO and Backblaze B2
- External clusters for recovery

**Steps**:
1. Create ExternalSecrets for backup credentials (2 separate Bitwarden entries)
2. Create ObjectStore resources for MinIO and Backblaze B2
3. Create Cluster manifest with backup configuration
4. Create ScheduledBackup resource
5. Apply via GitOps

### Cluster Scaling

**Increase Instances**:
1. Update `spec.instances` in Cluster manifest
2. Apply via GitOps
3. Monitor pod rollout
4. Verify all instances are healthy

**Increase Storage**:
1. Update `spec.storage.size` in Cluster manifest
2. Apply via GitOps
3. CNPG automatically expands PVCs
4. Verify expansion completed: `kubectl get pvc -n <namespace>`

### Cluster Upgrades

**PostgreSQL Version Upgrade**:
1. Update `spec.imageName` in Cluster manifest
2. Review breaking changes for PostgreSQL version
3. Apply via GitOps
4. Monitor upgrade logs
5. Verify applications are compatible with new version

**CNPG Operator Upgrade**:
1. Update Helm chart version in `cloudnative-pg/kustomization.yaml`
2. Review release notes for breaking changes
3. Apply via GitOps
4. Monitor operator pods
5. Verify cluster health after upgrade

## DATABASE TUNING

### PostgreSQL Parameters

**Memory Configuration**:
- `shared_buffers`: 25% of RAM (shared memory for queries)
- `effective_cache_size`: 50% of RAM (operating system cache)
- `work_mem`: Memory per operation (default 4MB)
- `maintenance_work_mem`: Memory for maintenance operations (default 64MB)

**Connection Configuration**:
- `max_connections`: Maximum simultaneous connections (default 100)
- Adjust based on application requirements

**WAL Configuration**:
- `min_wal_size`: Minimum WAL size (default 1GB)
- `max_wal_size`: Maximum WAL size (default 2GB)
- Larger values for write-heavy workloads

**Performance Tuning**:
- `random_page_cost`: Cost for random page access (default 4.0, set 1.1 for SSD)
- `effective_io_concurrency`: Concurrent I/O operations (default 200)
- `default_statistics_target`: Statistics accuracy (default 100)
- `checkpoint_completion_target`: Checkpoint frequency (default 0.9)

### Monitoring

**PodMonitor**:
```yaml
spec:
  monitoring:
    enablePodMonitor: true
```

**Metrics Exposed**:
- Connection counts
- Query performance
- Replication lag
- Storage usage
- WAL metrics

## DISASTER RECOVERY

### Cluster Restoration

**From Backblaze B2**:
```bash
# List available backups
kubectl get backup -n <namespace>

# Restore from backup
kubectl create -f - <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: <cluster-name>-restored
  namespace: <namespace>
spec:
  bootstrap:
    recovery:
      source: externalCluster
      externalClusterName: <cluster>-b2-backup
      backupID: <backup-id>
EOF
```

**From MinIO (Local)**:
```bash
# Restore using minio-backup external cluster
kubectl create -f - <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: <cluster-name>-restored
  namespace: <namespace>
spec:
  bootstrap:
    recovery:
      source: externalCluster
      externalClusterName: <cluster>-minio-backup
      backupID: <backup-id>
EOF
```

**Point-in-Time Recovery (PITR)**:
```yaml
spec:
  bootstrap:
    recovery:
      source: externalCluster
      externalClusterName: <cluster>-b2-backup
      targetTime: "2025-01-15 12:00:00 UTC"
```

## TROUBLESHOOTING

### Cluster Not Starting

**Check Pods**:
```bash
kubectl get pods -n <namespace> -l cnpg.io/podRole=instance

# Check pod logs
kubectl logs -n <namespace> <instance-pod>
```

**Common Issues**:
- **Storage Not Bound**: Check PVC status
- **Resource Limits**: Verify CPU/memory requests
- **Configuration Error**: Check PostgreSQL parameters syntax

### Backup Failures

**Check Backup Status**:
```bash
kubectl get backup -n <namespace>
kubectl describe backup <backup-name> -n <namespace>

# Check pod logs
kubectl logs -n <namespace> -l cnpg.io/podRole=instance
```

**Common Issues**:
- **S3 Credentials Invalid**: Verify ExternalSecrets exist and have correct keys
- **Network Issue**: Check connectivity to MinIO/Backblaze B2
- **Insufficient Storage**: Check available storage in bucket

### Replication Issues

**Check Replication Status**:
```bash
# Check cluster status
kubectl get cluster <name> -n <namespace> -o yaml

# Describe cluster for replication details
kubectl describe cluster <name> -n <namespace>
```

**Common Issues**:
- **Network Latency**: Check CNI configuration
- **Storage Performance**: Verify storage I/O is sufficient
- **Resource Exhaustion**: Check CPU/memory limits on instances

## ANTI-PATTERNS

Never use ExternalSecrets for application database credentials. Let CNPG auto-generate `<cluster-name>-app` secret.

Never create separate Bitwarden entries for database credentials. CNPG generates credentials automatically.

Never skip backup configuration for production clusters. Configure MinIO and Backblaze B2 backups.

Never use shared databases across applications. Create separate CNPG clusters for each application.

Never skip WAL archiving for production workloads. Enable WAL archiving to Backblaze B2 for point-in-time recovery.

Never use `latest` PostgreSQL version. Pin to specific version for reproducibility.

Never delete old backups without archiving. Maintain retention policy for disaster recovery.

## SECURITY BOUNDARIES

Never commit database credentials to manifests. Use CNPG auto-generated secrets or ExternalSecrets for backup credentials only.

Never share Bitwarden entries across applications. Create separate entries for each secret value.

Never use weak PostgreSQL passwords. Let CNPG auto-generate strong passwords.

Never expose database pods to public internet. Keep databases internal-only.

Never skip network policies for database access. Restrict access to application namespaces only.

## REFERENCES

For Kubernetes domain patterns, see k8s/AGENTS.md

For storage patterns, see k8s/infrastructure/storage/AGENTS.md

For Velero backup integration, see k8s/infrastructure/controllers/velero/BACKUP_STRATEGY.md

For CNPG documentation, see https://cloudnative-pg.io/documentation/

For commit message format, see root AGENTS.md

For Immich CNPG configuration example, see k8s/applications/media/immich/immich-server/database.yaml

For Pinepods CNPG configuration example, see k8s/applications/web/pinepods/database.yaml
