# Database Infrastructure - Component Guidelines

SCOPE: PostgreSQL database management with CloudNativePG operator
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: CloudNativePG (CNPG), PostgreSQL, MinIO, Backblaze B2, S3-compatible storage

## COMPONENT CONTEXT

Purpose: Deploy and manage PostgreSQL database clusters using CloudNativePG operator, including high availability, backup, and disaster recovery.

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
- **Basic Structure**: Cluster manifest defines PostgreSQL configuration, instances, image version, storage allocation, WAL storage, PostgreSQL parameters, and monitoring settings
- **Storage Class**: Use `proxmox-csi` for new clusters
- **Minimum Requirements**: 2 instances for high availability, separate storage for data and WAL

### Auto-Generated Credentials (Preferred)
- **Pattern**: Let CNPG auto-generate credentials instead of using ExternalSecrets
- **How It Works**: CNPG automatically creates `<cluster-name>-app` secret containing username, password, dbname, host, port, and URI
- **Application Usage**: Applications reference this secret directly via environment variable with secretKeyRef
- **When to Use ExternalSecrets**: Only for backup credentials (Backblaze B2, MinIO), never for application database credentials

### Backup Configuration

**Backup Strategy**: Continuous WAL → MinIO (plugin), weekly base backups → B2 (backup section), both in externalClusters for recovery flexibility.

**Dual Backup Strategy**:

**1. Local MinIO (Fast Recovery)**:
- ObjectStore: S3-compatible endpoint (TrueNAS MinIO)
- Use case: Fast restores from local NAS
- Connection: `https://truenas.peekoff.com:9000`
- Bucket: `homelab-postgres-backups/<namespace>/<cluster>`

**2. Backblaze B2 (Disaster Recovery)**:
- ObjectStore: S3-compatible endpoint (Backblaze B2)
- Use case: Offsite disaster recovery
- Connection: `https://s3.us-west-002.backblazeb2.com`
- Bucket: `homelab-cnpg-b2/<namespace>/<cluster>`

**Key Configuration**:
- Retention Policy: Set `retentionPolicy: "30d"` in both ObjectStore specs
- ExternalSecrets: Create separate Bitwarden entries for access-key-id and secret-access-key
- Backup Configuration: Use barmanObjectStore pointing to Backblaze B2 endpoint
- Scheduled Backups: Create ScheduledBackup resource with cron schedule (e.g., Sundays at 02:00)
- WAL Archiving: Configure barman-cloud.cloudnative-pg.io plugin with isWALArchiver enabled
- **Critical**: Only plugin architecture (ObjectStore CRD + barman-cloud plugin) is supported

### External Clusters (Recovery)
- **Purpose**: Enable recovery from either backup location
- **Configuration**: Configure externalClusters in spec with two entries (Backblaze B2 and MinIO)
- Each uses barmanObjectStore with destinationPath, endpointURL, and S3 credentials
- Enable gzip compression and AES256 encryption for WAL

## CLUSTER OPERATIONS

### Creating a New Cluster
**Steps**:
1. Create ExternalSecrets for backup credentials (2 separate Bitwarden entries)
2. Create ObjectStore resources for MinIO and Backblaze B2 with `retentionPolicy: "30d"`
3. Create Cluster manifest with backup configuration
4. Create ScheduledBackup resource
5. Apply via GitOps

### Cluster Scaling
**Increase Instances**:
1. Update `spec.instances` in Cluster manifest
2. Apply via GitOps
3. Monitor pod rollout and verify health

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
4. Monitor upgrade logs and verify application compatibility

**CNPG Operator Upgrade**:
1. Update Helm chart version in `cloudnative-pg/kustomization.yaml`
2. Review release notes for breaking changes
3. Apply via GitOps
4. Monitor operator pods and verify cluster health

## DATABASE TUNING

### PostgreSQL Parameters
**Memory Configuration**:
- `shared_buffers`: 25% of RAM (shared memory for queries)
- `effective_cache_size`: 50% of RAM (operating system cache)
- `work_mem`: Memory per operation (default 4MB)
- `maintenance_work_mem`: Memory for maintenance operations (default 64MB)

**Performance Tuning**:
- `random_page_cost`: Cost for random page access (default 4.0, set 1.1 for SSD)
- `effective_io_concurrency`: Concurrent I/O operations (default 200)
- `default_statistics_target`: Statistics accuracy (default 100)

### Monitoring
- **PodMonitor**: Enable monitoring in cluster spec by setting enablePodMonitor to true
- **Metrics Exposed**: Connection counts, query performance, replication lag, storage usage, WAL metrics

## DISASTER RECOVERY

### Cluster Restoration
**From Backblaze B2**: List available backups to identify target backup ID. Create new Cluster manifest with bootstrap recovery configuration referencing externalClusterName and backupID.

**From MinIO (Local)**: List available backups. Create new Cluster manifest with bootstrap recovery configuration referencing minio-backup externalClusterName and backupID.

**Point-in-Time Recovery (PITR)**: Configure bootstrap recovery with targetTime parameter specifying precise recovery timestamp.

## TROUBLESHOOTING

### Cluster Not Starting
**Check Pods**:
```bash
kubectl get pods -n <namespace> -l cnpg.io/podRole=instance
kubectl logs -n <namespace> <instance-pod>
```

**Common Issues**: Storage not bound, resource limits, configuration error

### Backup Failures
**Check Backup Status**:
```bash
kubectl get backup -n <namespace>
kubectl describe backup <backup-name> -n <namespace>
```

**Common Issues**: S3 credentials invalid, network issue, insufficient storage

### Replication Issues
**Check Replication Status**:
```bash
kubectl get cluster <name> -n <namespace> -o yaml
kubectl describe cluster <name> -n <namespace>
```

**Common Issues**: Network latency, storage performance, resource exhaustion

## DATABASE-DOMAIN ANTI-PATTERNS

### Credentials Management
- Never use ExternalSecrets for application database credentials - let CNPG auto-generate `<cluster-name>-app` secret
- Never create separate Bitwarden entries for database credentials - CNPG generates credentials automatically
- Never commit database credentials to manifests - use CNPG auto-generated secrets or ExternalSecrets for backup credentials only
- Never share Bitwarden entries across applications - create separate entries for each secret value

### Configuration & Operations
- **NEVER use legacy barman object storage deployment - ONLY plugin architecture (ObjectStore CRD + barman-cloud plugin) is supported**
- Never skip backup configuration for production clusters - configure MinIO and Backblaze B2 backups
- Never use shared databases across applications - create separate CNPG clusters for each application
- Never skip WAL archiving for production workloads - enable WAL archiving to Backblaze B2 for point-in-time recovery
- Never use `latest` PostgreSQL version - pin to specific version for reproducibility
- Never delete old backups without archiving - maintain retention policy for disaster recovery

### Security
- Never use weak PostgreSQL passwords - let CNPG auto-generate strong passwords
- Never expose database pods to public internet - keep databases internal-only
- Never skip network policies for database access - restrict access to application namespaces only

## REFERENCES

For Kubernetes patterns: k8s/AGENTS.md
For storage patterns: k8s/infrastructure/storage/AGENTS.md
For Velero backup integration: k8s/infrastructure/controllers/velero/BACKUP_STRATEGY.md
For CNPG documentation: https://cloudnative-pg.io/documentation/
For Immich CNPG example: k8s/applications/media/immich/immich-server/database.yaml
For Pinepods CNPG example: k8s/applications/web/pinepods/database.yaml
For commit format: /AGENTS.md