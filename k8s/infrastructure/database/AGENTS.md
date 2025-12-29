# Database Infrastructure - Component Guidelines

SCOPE: PostgreSQL database management with CloudNativePG operator
INHERITS FROM: /k8s/AGENTS.md
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
Cluster manifest defines PostgreSQL configuration including instances, image version, storage allocation, WAL storage, PostgreSQL parameters, and monitoring settings. Specify storage class as proxmox-csi for new clusters or longhorn for legacy clusters.

### Auto-Generated Credentials (Preferred)

**Pattern**: Let CNPG auto-generate credentials instead of using ExternalSecrets.

**How It Works**:
CNPG automatically creates `<cluster-name>-app` secret containing username, password, dbname, host, port, and URI. Applications reference this secret directly. No circular dependencies with ExternalSecrets.

**Application Usage**:
Application deployments reference the secret via environment variable with secretKeyRef pointing to the URI key in the auto-generated secret.

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
Create ExternalSecret referencing Bitwarden ClusterSecretStore with target template using engineVersion v2. Map AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to corresponding Bitwarden keys.

**Bitwarden Requirements**:
- Separate entry for `backblaze-b2-cnpg-access-key-id`
- Separate entry for `backblaze-b2-cnpg-secret-access-key`
- No `property` field (not supported)
- Use `engineVersion: v2` under `spec.target.template`

**Backup Configuration in Cluster**:
Configure cluster backup with barmanObjectStore pointing to Backblaze B2 endpoint. Set S3 credentials to reference ExternalSecret. Enable gzip compression and AES256 encryption for both WAL and data. Set retention policy to 30 days.

**Scheduled Backups**:
Create ScheduledBackup resource referencing cluster name. Set cron schedule (e.g., Sundays at 02:00). Set backupOwnerReference to Application kind with application name.

**WAL Archiving**:
Configure barman-cloud.cloudnative-pg.io plugin with isWALArchiver enabled. Set barmanObjectName to target store name.

### External Clusters (Recovery)

**Purpose**: Enable recovery from either backup location.

Configure externalClusters in spec with two entries: one for Backblaze B2 and one for MinIO. Each uses barmanObjectStore with destinationPath, endpointURL, and S3 credentials referencing respective ExternalSecrets. Enable gzip compression and AES256 encryption for WAL.

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
Enable monitoring in cluster spec by setting enablePodMonitor to true.

**Metrics Exposed**:
- Connection counts
- Query performance
- Replication lag
- Storage usage
- WAL metrics

## DISASTER RECOVERY

### Cluster Restoration

**From Backblaze B2**:
List available backups to identify target backup ID. Create new Cluster manifest with bootstrap recovery configuration referencing externalClusterName and backupID. Apply via kubectl.

**From MinIO (Local)**:
List available backups. Create new Cluster manifest with bootstrap recovery configuration referencing minio-backup externalClusterName and backupID. Apply via kubectl.

**Point-in-Time Recovery (PITR)**:
Configure bootstrap recovery with targetTime parameter specifying precise recovery timestamp. Use externalClusterName to identify backup source.

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
