---
sidebar_position: 1
title: PostgreSQL Backups
description: Dual backup strategy using CloudNativePG, Barman Cloud, MinIO, and Backblaze B2
---

# CloudNativePG Backup Strategy

CloudNativePG provides native backup support through the official Barman Cloud Plugin. Our homelab uses a **dual backup architecture** with both local MinIO storage for fast recovery and offsite Backblaze B2 for disaster recovery.

## Backup Architecture

Each PostgreSQL cluster managed by CloudNativePG uses **two backup destinations**:

1. **Local MinIO (Fast Recovery)**
   - Destination: `s3://homelab-postgres-backups/<namespace>/<cluster-name>`
   - Endpoint: `https://truenas.peekoff.com:9000`
   - Purpose: Quick restores from local NAS
   - Retention: Managed by backup job schedules
   - Use Case: Non-disaster recovery scenarios requiring fast data access

2. **Backblaze B2 (Disaster Recovery)**
   - Destination: `s3://homelab-cnpg-b2/<namespace>/<cluster-name>`
   - Endpoint: `https://s3.us-west-000.backblazeb2.com`
   - Purpose: Offsite disaster recovery
   - Retention: 30 days (configurable per cluster)
   - Use Case: Catastrophic data loss scenarios

## Why Dual Backups?

**Primary (B2) vs Secondary (MinIO) Roles:**

- **Backblaze B2 is primary**: All base backups and WAL archiving target B2 for offsite safety
- **MinIO is secondary**: Additional recovery option for local fast restores
- **WAL archiving**: Continuous WAL shipping to B2 enables point-in-time recovery (PITR)
- **Base backups**: Weekly full backups to B2 provide complete recovery points
- **Recovery flexibility**: Can restore from either destination based on scenario

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                   CloudNativePG Cluster                      │
│                  (PostgreSQL Database)                        │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ├───► WAL Archiving (Continuous)
                     │    │
                     │    └───► Backblaze B2 (Offsite, PITR)
                     │
                     └───► Scheduled Base Backups (Weekly)
                          │
                          └───► Backblaze B2 (Offsite, Full)

┌─────────────────────────────────────────────────────────────────┐
│              ExternalCluster Definitions                       │
│              (Recovery Sources)                             │
├─────────────────────────────────────────────────────────────────┤
│ • <cluster-name>-b2-backup     (B2 Primary)             │
│ • <cluster-name>-minio-backup    (MinIO Secondary)        │
└─────────────────────────────────────────────────────────────────┘
```

## Required Components

### 1. ExternalSecret for B2 Credentials

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
  data:
    - secretKey: AWS_ACCESS_KEY_ID
      remoteRef:
        key: backblaze-b2-cnpg-offsite
        property: AWS_ACCESS_KEY_ID
    - secretKey: AWS_SECRET_ACCESS_KEY
      remoteRef:
        key: backblaze-b2-cnpg-offsite
        property: AWS_SECRET_ACCESS_KEY
```

**Purpose**: Syncs B2 credentials from Bitwarden (`backblaze-b2-cnpg-offsite` item) to Kubernetes secret. Each namespace creates its own B2 credentials secret.

### 2. ObjectStore Resources (2 per Cluster)

**Local MinIO ObjectStore:**

```yaml
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: <cluster-name>-minio-store
  namespace: <namespace>
spec:
  configuration:
    destinationPath: s3://homelab-postgres-backups/<namespace>/<cluster-name>
    endpointURL: https://truenas.peekoff.com:9000
    s3Credentials:
      accessKeyId:
        name: longhorn-minio-credentials
        key: AWS_ACCESS_KEY_ID
      secretAccessKey:
        name: longhorn-minio-credentials
        key: AWS_SECRET_ACCESS_KEY
```

**Backblaze B2 ObjectStore:**

```yaml
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: <cluster-name>-b2-store
  namespace: <namespace>
spec:
  configuration:
    destinationPath: s3://homelab-cnpg-b2/<namespace>/<cluster-name>
    endpointURL: https://s3.us-west-000.backblazeb2.com
    s3Credentials:
      accessKeyId:
        name: b2-cnpg-credentials
        key: AWS_ACCESS_KEY_ID
      secretAccessKey:
        name: b2-cnpg-credentials
        key: AWS_SECRET_ACCESS_KEY
```

**Purpose**: Defines S3-compatible backup destinations. ObjectStore resources are referenced by Cluster configuration for backup operations.

### 3. Cluster Configuration with Plugin

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: <cluster-name>
  namespace: <namespace>
spec:
  instances: 1
  imageName: ghcr.io/cloudnative-pg/postgresql:17

  storage:
    size: 20Gi
    storageClass: proxmox-csi

  # Plugin configuration for WAL archiving
  plugins:
  - name: barman-cloud.cloudnative-pg.io
    isWALArchiver: true
    parameters:
      barmanObjectName: <cluster-name>-b2-store

  # Backup configuration (base backups to B2)
  backup:
    barmanObjectStore:
      destinationPath: s3://homelab-cnpg-b2/<namespace>/<cluster-name>
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
    retentionPolicy: "30d"

  # External clusters for recovery
  externalClusters:
    - name: <cluster-name>-b2-backup
      barmanObjectStore:
        destinationPath: s3://homelab-cnpg-b2/<namespace>/<cluster-name>
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
    - name: <cluster-name>-minio-backup
      barmanObjectStore:
        destinationPath: s3://homelab-postgres-backups/<namespace>/<cluster-name>
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

  postgresql:
    parameters:
      max_connections: "100"
      shared_buffers: "256MB"
```

**Key Configuration Points:**

- **`plugins` section**: Enables `barman-cloud.cloudnative-pg.io` plugin with `isWALArchiver: true`, referencing the B2 ObjectStore for continuous WAL archiving
- **`backup.barmanObjectStore` section**: Configures base backup destination to B2 with compression and encryption
- **`retentionPolicy`**: Defines how long backups are retained (default: 30 days)
- **`externalClusters`**: Defines both B2 and MinIO as recovery sources for PITR scenarios

### 4. ScheduledBackup Resource

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:
  name: <cluster-name>-backup
  namespace: <namespace>
spec:
  schedule: "0 0 2 * * 0"  # Weekly on Sundays at 02:00
  backupOwnerReference: self
  cluster:
    name: <cluster-name>
  method: plugin
  pluginConfiguration:
    name: barman-cloud.cloudnative-pg.io
```

**Purpose**: Triggers weekly base backups to B2 using the plugin architecture. The schedule uses cron syntax:
- `0 0 2 * * 0` = Sunday at 02:00 UTC (weekly)
- `0 3 * * *` = Daily at 03:00 UTC (daily backup example)

## How It Works

### Backup Flow

1. **Continuous WAL Archiving**
   - Barman Cloud Plugin ships WAL files to B2 continuously
   - Enables point-in-time recovery to any point within retention window
   - WAL files are compressed (gzip) and encrypted (AES256)

2. **Weekly Base Backups**
   - ScheduledBackup triggers full base backup to B2 on Sundays at 02:00
   - Base backup provides complete database snapshot
   - Combined with WAL files, enables PITR to any point

3. **Retention Management**
   - Old backups automatically deleted after 30 days
   - WAL files retained as needed for restore points
   - Storage costs managed via retention policy

### Recovery Flow

1. **Choose Recovery Source** (B2 or MinIO)
   - B2: Use for disaster recovery scenarios (primary)
   - MinIO: Use for fast local recovery (secondary)

2. **Select Recovery Point**
   - Choose specific base backup from available backups
   - Specify target time for PITR (if using WAL archiving)

3. **Create Recovery Cluster**
   - Configure `bootstrap.recovery.source` to point to external cluster
   - Specify `recoveryTarget` for PITR if needed
   - Cluster will restore from backup and apply WAL files

## Complete Example: Authentik Database

```yaml
---
# 1. ExternalSecret for B2 credentials
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: b2-cnpg-credentials
  namespace: auth
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: bitwarden-backend
    kind: ClusterSecretStore
  target:
    name: b2-cnpg-credentials
    creationPolicy: Owner
  data:
    - secretKey: AWS_ACCESS_KEY_ID
      remoteRef:
        key: backblaze-b2-cnpg-offsite
        property: AWS_ACCESS_KEY_ID
    - secretKey: AWS_SECRET_ACCESS_KEY
      remoteRef:
        key: backblaze-b2-cnpg-offsite
        property: AWS_SECRET_ACCESS_KEY

---
# 2. Local MinIO ObjectStore
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: authentik-minio-store
  namespace: auth
spec:
  configuration:
    destinationPath: s3://homelab-postgres-backups/auth/authentik-postgresql
    endpointURL: https://truenas.peekoff.com:9000
    s3Credentials:
      accessKeyId:
        name: longhorn-minio-credentials
        key: AWS_ACCESS_KEY_ID
      secretAccessKey:
        name: longhorn-minio-credentials
        key: AWS_SECRET_ACCESS_KEY

---
# 3. Backblaze B2 ObjectStore
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: authentik-b2-store
  namespace: auth
spec:
  configuration:
    destinationPath: s3://homelab-cnpg-b2/auth/authentik-postgresql
    endpointURL: https://s3.us-west-000.backblazeb2.com
    s3Credentials:
      accessKeyId:
        name: b2-cnpg-credentials
        key: AWS_ACCESS_KEY_ID
      secretAccessKey:
        name: b2-cnpg-credentials
        key: AWS_SECRET_ACCESS_KEY

---
# 4. Cluster with backup configuration
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: authentik-postgresql
  namespace: auth
spec:
  instances: 2
  imageName: ghcr.io/cloudnative-pg/postgresql:17
  storage:
    size: 20Gi
    storageClass: longhorn

  plugins:
  - name: barman-cloud.cloudnative-pg.io
    isWALArchiver: true
    parameters:
      barmanObjectName: authentik-b2-store

  backup:
    barmanObjectStore:
      destinationPath: s3://homelab-cnpg-b2/auth/authentik-postgresql
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
    retentionPolicy: "30d"

  externalClusters:
    - name: authentik-b2-backup
      barmanObjectStore:
        destinationPath: s3://homelab-cnpg-b2/auth/authentik-postgresql
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
    - name: authentik-minio-backup
      barmanObjectStore:
        destinationPath: s3://homelab-postgres-backups/auth/authentik-postgresql
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

---
# 5. ScheduledBackup (weekly to B2)
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:
  name: authentik-postgresql-backup
  namespace: auth
spec:
  schedule: "0 0 2 * * 0"
  backupOwnerReference: self
  cluster:
    name: authentik-postgresql
  method: plugin
  pluginConfiguration:
    name: barman-cloud.cloudnative-pg.io
```

## Backup Verification

Check backup status:

```bash
# List backups for a cluster
kubectl get backup -n <namespace>

# Check ScheduledBackup status
kubectl get scheduledbackup -n <namespace>

# View cluster backup status
kubectl describe cluster <cluster-name> -n <namespace> | grep -A 20 "Backup Status:"

# View last successful backup
kubectl get backup -n <namespace> -o jsonpath='{.items[0].metadata.name}'

# Check WAL archiving status
kubectl describe cluster <cluster-name> -n <namespace> | grep -A 10 "WAL Archiving:"
```

## Adding a New Database Cluster

When creating a new PostgreSQL cluster with CloudNativePG:

1. **Create ExternalSecret** for B2 credentials in the namespace
2. **Create two ObjectStore resources** (MinIO and B2)
3. **Configure Cluster** with plugin and backup settings
4. **Create ScheduledBackup** for weekly base backups
5. **Add externalClusters** for recovery options

**Example pattern:**

```bash
# Copy existing database.yaml and modify
cp k8s/infrastructure/auth/authentik/database.yaml \
   k8s/applications/<category>/<app>/database.yaml

# Update namespace, cluster name, and paths
# Ensure both minio-store and b2-store ObjectStores are defined
# Add externalClusters for both backup locations
```

## Security Best Practices

- **Never commit credentials**: Use ExternalSecrets from Bitwarden
- **Always encrypt backups**: Use `encryption: AES256` for both WAL and data
- **Compress backups**: Use `compression: gzip` to reduce storage costs
- **Regular rotation**: Rotate B2 access keys in Bitwarden periodically
- **Access control**: Limit B2 bucket access to CNPG pods only

## Cost Considerations

**Backblaze B2 Storage:**
- **Storage cost**: $0.005/GB/month
- **Download cost**: Free (no egress fees)
- **Upload cost**: Free
- **Example**: 20GB PostgreSQL cluster = ~$0.10/month

**MinIO Storage:**
- **Storage cost**: Local NAS (no monthly fee)
- **Network cost**: Local LAN only (no internet egress)
- **Use case**: Fast recovery without internet dependency

**Total cost per database**: Minimal (~$0.10-0.20/month for B2 storage)

## Troubleshooting

### Backup Not Running

1. **Check ScheduledBackup status**:
   ```bash
   kubectl get scheduledbackup -n <namespace>
   ```

2. **Check cluster backup configuration**:
   ```bash
   kubectl describe cluster <cluster-name> -n <namespace> | grep -A 30 "Backup:"
   ```

3. **Verify ObjectStore exists**:
   ```bash
   kubectl get objectstore -n <namespace>
   ```

### WAL Archiving Failed

1. **Check plugin status**:
   ```bash
   kubectl describe cluster <cluster-name> -n <namespace> | grep -A 10 "plugins"
   ```

2. **Verify B2 credentials**:
   ```bash
   kubectl get secret b2-cnpg-credentials -n <namespace> -o yaml
   ```

3. **Check CNPG operator logs**:
   ```bash
   kubectl logs -n cnpg-system deployment/cnpg-controller-manager --tail=50
   ```

### Cannot Restore from Backup

1. **Verify externalCluster configuration**:
   ```bash
   kubectl get cluster <cluster-name> -n <namespace> -o yaml | grep -A 20 "externalClusters"
   ```

2. **Check backup list**:
   ```bash
   kubectl get backup -n <namespace>
   ```

3. **Test restore with new cluster**:
   ```yaml
   apiVersion: postgresql.cnpg.io/v1
   kind: Cluster
   metadata:
     name: <recovery-cluster-name>
   spec:
     instances: 1
     bootstrap:
       recovery:
         source: <external-cluster-name>
         recoveryTarget:
           targetTime: "2025-01-15 12:00:00+00"
   ```

## Related Documentation

- [CloudNativePG Operator Setup](./cloudnative-pg.md)
- [PostgreSQL Restore from PVC](./postgres-restore-from-pvc.md)
- [Velero Backup Strategy](../controllers/velero-backup.md)
- [Storage Overview](../overview.md)
