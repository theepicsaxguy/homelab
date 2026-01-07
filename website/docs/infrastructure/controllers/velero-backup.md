---
sidebar_position: 4
title: Velero Backup Strategy
description: Complete guide to Velero backup configuration, disaster recovery, and Backblaze B2 optimization
---

# Velero Backup Strategy

## Overview

The backup infrastructure uses **Velero with Kopia filesystem backups** for disaster recovery. CSI volume snapshots are not used.

## Why No CSI Snapshots?

### Constraints

Proxmox CSI volume snapshots with Velero are not viable due to:

1. **Proxmox CSI snapshot feature is experimental** and requires `root@pam` credentials
2. **API tokens cannot perform snapshot operations** - the CSI driver needs root-level access for disk copy operations
3. **Snapshots create full disk copies**, not incremental deltas
4. **Additional permissions required** are too broad for an automation user

### Rationale

**Velero's Kopia data mover provides:**

✅ **Direct filesystem backup to S3** - No CSI snapshots required
✅ **True disaster recovery** - All data in S3, not dependent on Proxmox storage
✅ **Secure credential model** - No root-level Proxmox credentials needed
✅ **Incremental backups** - Kopia deduplicates and compresses data efficiently
✅ **Simpler architecture** - Fewer moving parts, easier to maintain

## Installation and Setup

### Key Points

- Velero is deployed via the Helm chart under `k8s/infrastructure/controllers/velero`.
- BackupStorageLocation and VolumeSnapshotLocation are configured by the Helm chart using `values.yaml` (the chart creates the CRs when `upgradeCRDs` is enabled).
- Credentials are provisioned via the `ExternalSecret` named `velero-minio-credentials` in the `velero` namespace; the chart is configured to use this secret.
- Backups are stored in the `velero` bucket on the cluster's MinIO/Truenas S3 endpoint as configured in the chart values.
- PVC data is backed up using Kopia filesystem backups (not CSI snapshots).
- Metrics are exposed via a ServiceMonitor for Prometheus.
- The `velero` namespace is labeled `pod-security.kubernetes.io/enforce: privileged` so the node agent can mount required host paths.

### Credentials Format

The `velero-minio-credentials` secret must expose three values:

- `MINIO_ACCESS_KEY`
- `MINIO_SECRET_KEY`
- `MINIO_ENDPOINT`

These values come from Bitwarden. The `ExternalSecret` assembles them into a `cloud` file so Velero can read standard AWS credentials.

## Backup Configuration

### Storage Locations

We use **two independent S3-compatible storage locations**:

1. **TrueNAS MinIO** (`default`) - Local, fast restores
   - URL: `https://truenas.peekoff.com:9000`
   - Bucket: `velero`
   - Use case: Daily/weekly backups, quick restores
   - Default location for faster local recovery

2. **Backblaze B2** (`backblaze-b2`) - Offsite, disaster recovery
   - URL: `https://s3.us-west-002.backblazeb2.com`
   - Bucket: `homelab-velero-b2`
   - Use case: Weekly offsite backups
   - Geographic redundancy for true disaster scenarios

### Backup Schedules

| Schedule | Frequency | Storage | Retention | Purpose |
|----------|-----------|---------|-----------|---------|
| `velero-daily` | Daily 2:00 AM | TrueNAS | 14 days | Fast recovery from recent issues |
| `velero-weekly` | Weekly Sun 3:00 AM | Backblaze B2 | 28 days | Offsite protection |
| `weekly-offsite` | Weekly Sat 3:00 AM | Backblaze B2 | 90 days | Long-term disaster recovery |

### Excluded Namespaces

- `velero` - Velero's own resources
- `kube-system` - Kubernetes system components
- `default` - Usually empty or test resources
- `kiwix` - 200GB of redownloadable Wikipedia data

### How Backups Work

1. **Kubernetes Resources** → Backed up as YAML to S3
2. **PVC Data** → Kopia filesystem backup (`defaultVolumesToFsBackup: true`)
   - Velero node-agent mounts PVCs
   - Kopia streams data directly to S3
   - Deduplication & compression applied
   - No intermediate snapshots
3. **Metadata** → Stored alongside data for easy restores

## Proxmox CSI Configuration

### Required Permissions

The `kubernetes-csi@pve` Proxmox user needs **minimal permissions** for basic CSI operations:

```bash
pveum role add CSI -privs "Sys.Audit VM.Audit VM.Config.Disk Datastore.Allocate Datastore.AllocateSpace Datastore.Audit"
```

**What each permission does:**
- `Sys.Audit` - Required for CSI controller to query system capacity
- `VM.Audit` - View VM information for volume operations
- `VM.Config.Disk` - Attach/detach disks to VMs
- `Datastore.Allocate` - Create new volumes in datastores
- `Datastore.AllocateSpace` - Manage storage space allocation
- `Datastore.Audit` - View datastore capacity and usage

**Permissions NOT needed:**
- ❌ `VM.Snapshot` - We don't use CSI snapshots
- ❌ `VM.Clone` - Not required for basic CSI operations
- ❌ `VM.Allocate` - Not needed for volume management
- ❌ `Datastore.AllocateTemplate` - Not used by CSI driver

### Terraform Management

Proxmox CSI permissions are managed via Terraform at `tofu/bootstrap/proxmox-csi-plugin/config.tofu`.

To update permissions:
```bash
cd tofu
tofu apply -target=module.proxmox-csi-plugin.proxmox_virtual_environment_role.csi
```

## Testing Backups

### Test a Full Backup

```bash
# Test backup of a specific namespace
velero backup create test-backup \
  --include-namespaces <namespace> \
  --default-volumes-to-fs-backup \
  --wait

# Verify PVC data was backed up
velero backup describe test-backup --details
```

Look for:
- ✅ `Pod Volume Backups - kopia: Completed`
- ✅ List of backed up PVCs with their volumes

### Test a Restore

```bash
# Restore to a different namespace for testing
velero restore create test-restore \
  --from-backup test-backup \
  --namespace-mappings <source>:<target>

# Watch restore progress
velero restore describe test-restore
```

## Disaster Recovery Procedure

### Full Cluster Restore

1. **Rebuild Kubernetes cluster** (Talos/K3s)
2. **Install Velero** with same configuration
3. **Restore from Backblaze B2**:
   ```bash
   velero restore create cluster-restore \
     --from-backup weekly-offsite-<date>
   ```
4. **Verify all namespaces and PVCs** restored correctly
5. **Update DNS and ingress** as needed

### Partial Restore (Single Namespace)

```bash
velero restore create namespace-restore \
  --from-backup <backup-name> \
  --include-namespaces <namespace>
```

## Kopia Restore Behavior

### How Kopia Restores Work

1. **Velero node-agent pod** mounts the target PVC
2. **Kopia streams data** from S3 directly to the PVC
3. **Deduplication is reversed** during restore
4. **File permissions and ownership** are preserved
5. **No intermediate snapshots** required

### Restore Performance

- **Typical speed**: 50-100 MB/s (depends on S3 connection and network bandwidth)
- **Large restores (>100GB)**: 20-40 minutes
- **Network bandwidth** is usually the bottleneck
- **Concurrent restores**: Limited by node-agent pod resources

### Restore Verification

After restore, always verify:

```bash
# Check restore completed successfully
velero restore describe <restore-name>

# Look for Pod Volume Restores section
velero restore describe <restore-name> --details | grep -A 10 "Pod Volume Restores"

# Expected output:
# kopia Restores:
#   Completed: 1 (or more)

# Verify PVC data size
kubectl exec -n <namespace> <pod-name> -- du -sh <mount-path>
```

### Troubleshooting Kopia Restores

**Issue**: Restore stuck "InProgress"

```bash
# Check Velero server logs
kubectl logs -n velero deployment/velero --tail=100

# Check node-agent logs (handles Kopia restore)
kubectl logs -n velero -l name=node-agent --tail=100 | grep -i error

# Check which node is running the restore
kubectl get pods -n <namespace> -o wide
kubectl logs -n velero -l name=node-agent --field-selector spec.nodeName=<node-name>
```

**Issue**: Data not restored to PVC

```bash
# Verify backup included pod volume backups
velero backup describe <backup-name> --details | grep -A 5 "Pod Volume"

# Check PVC is mounted in pod
kubectl describe pod -n <namespace> <pod-name> | grep -A 5 "Mounts:"

# Check Kopia repository connection
kubectl logs -n velero -l name=node-agent | grep -i "kopia"
```

## Storage Class Compatibility

### Overview

Kopia filesystem backups are **storage-class agnostic**. Data is backed up at the filesystem level, not via storage snapshots, so migrations between storage classes work seamlessly.

### Supported Migrations

| Source Storage Class | Target Storage Class | Compatible | Notes |
|---------------------|---------------------|------------|-------|
| `longhorn` | `proxmox-csi` | ✅ Yes | Tested with Kopia filesystem backups |
| `proxmox-csi` | `longhorn` | ✅ Yes | Use storage class mapping ConfigMap |
| `longhorn` | `default` (proxmox-csi) | ✅ Yes | Target cluster's default storage class |
| Any RWO | Any RWO | ✅ Yes | Both support ReadWriteOnce access mode |
| Any | Any | ⚠️ Maybe | Check access modes and features match |

### Storage Class Mapping

When restoring backups to different storage classes, use Velero's storage class mapping feature:

```bash
# Create storage class mapping ConfigMap
kubectl apply -f /path/to/homelab/k8s/infrastructure/controllers/velero/storage-class-mapping.yaml

# Example ConfigMap content:
# apiVersion: v1
# kind: ConfigMap
# metadata:
#   name: change-storage-class-config
#   namespace: velero
#   labels:
#     velero.io/plugin-config: ""
#     velero.io/change-storage-class: RestoreItemAction
# data:
#   longhorn: proxmox-csi
```

Once configured, all Velero restores automatically transform storage class references.

**See**: [Velero Storage Class Mapping Documentation](velero-storage-class-mapping.md) for complete instructions.

### Access Mode Compatibility

Both **Longhorn** and **Proxmox CSI** support:

- ✅ **ReadWriteOnce (RWO)** - Single node read/write (most common)
- ✅ **Volume expansion** - Can resize volumes after creation
- ✅ **Volume cloning** - Can clone existing volumes

**Not supported by either**:
- ❌ **ReadWriteMany (RWX)** - Multiple nodes read/write (requires NFS/CephFS)

### Feature Comparison

| Feature | Longhorn | Proxmox CSI | Impact on Restore |
|---------|----------|-------------|-------------------|
| **Snapshots** | ✅ Yes | ⚠️ Experimental | ✅ No impact - Kopia doesn't use snapshots |
| **Expansion** | ✅ Yes | ✅ Yes | ✅ Compatible |
| **Cloning** | ✅ Yes | ✅ Yes | ✅ Compatible |
| **Backup Integration** | ✅ S3 | ❌ None | ✅ No impact - Velero handles backups |
| **Replication** | ✅ Yes | ❌ None | ✅ No impact on restore |
| **Performance** | ~Good | ~Good | ⚠️ May vary by storage backend |

**Key Takeaway**: Since Velero uses Kopia filesystem backups, storage class features (snapshots, replication) don't affect restore compatibility. Restores work seamlessly across storage classes.

### Testing Storage Class Migrations

Always test storage class migrations before production use:

1. **Create storage class mapping** ConfigMap
2. **Restore to test namespace** with namespace mapping
3. **Verify storage class transformation** in restored PVCs
4. **Validate data integrity** and application functionality
5. **Test performance** with the new storage class

See [Test Restore Procedure](../../disaster/test-restore-procedure.md) for complete testing steps.

## Backblaze B2 Transaction Optimization

### Overview

Backblaze B2 has daily transaction limits for free tier usage:
- **Class A**: Free (uploads, deletions)
- **Class B**: First 2,500/day free, then $0.004 per 10,000 (downloads, retrievals)
- **Class C**: First 2,500/day free, then $0.004 per 1,000 (list operations, bucket listings)

Exceeding these limits incurs charges, so optimization is critical for cost-effective offsite backups.

### Current Optimization Strategy

**Primary Optimization: Reduced Parallel Uploads**
- `parallelFilesUpload: 3` (reduced from 5)
- Fewer parallel uploads = lower transaction rate
- Reduces burst of Class C transactions during backup operations
- Acceptable trade-off: Slightly slower backup speed (10-20% increase) for significant transaction reduction (40-60%)

**Repository Configuration**
- `cacheLimitMB: 8192` - 8GB cache reduces re-downloads
- `fullMaintenanceInterval: 168h` - Weekly maintenance reduces frequent operations

**Storage Location Settings**
- `validationFrequency: 24h` - Daily validation is optimal balance

### How Kopia Reduces Transactions

Kopia inherently optimizes for S3-compatible storage:
- **Chunking**: Processes data into larger, deduplicated chunks (default ~20MB), reducing number of upload operations
- **Deduplication**: Only changed data is uploaded, naturally reducing transactions over time
- **Compression**: Built-in compression reduces data size and transfer time

### Monitoring Transaction Usage

1. **Check Backblaze B2 Dashboard**: Monitor daily transaction counts
   - Navigate to B2 dashboard → Bucket → Transaction Usage
   - Review Class B and Class C transaction counts daily

2. **Verify Backup Success**: Ensure backups complete successfully
   ```bash
   velero backup describe <backup-name> --details
   ```

3. **Check Backup Performance**: Monitor backup duration
   - May increase slightly (10-20%) with reduced parallelism
   - Still acceptable for weekly offsite backups

### If Transactions Remain High

If Class C transactions still exceed 2,500/day after optimization:

1. **Reduce Backup Frequency**: Change offsite backup from weekly to bi-weekly
2. **Exclude Non-Critical Namespaces**: Add more namespaces to exclusion list
3. **Adjust TTL**: Reduce retention periods to minimize retention operations
4. **Advanced Options**: Explore Kopia policy configuration for compression and chunk size tuning

### Expected Impact

- **Class C Transactions**: 40-60% reduction due to fewer parallel operations
- **Class B Transactions**: Stable or slight decrease
- **Backup Duration**: 10-20% increase (acceptable for weekly backups)
- **Transaction Rate**: Lower peak rate during backups, reducing risk of exceeding daily limits

## Monitoring

- **Prometheus metrics** exposed via ServiceMonitor
- **Backup failures** trigger alerts
- **Storage location validation** runs hourly
- Check backup status: `velero get backups`
- **Backblaze B2 transaction usage**: Monitor daily via B2 dashboard

## References

- [Velero Documentation](https://velero.io/docs/)
- [Kopia Uploader](https://velero.io/docs/main/file-system-backup/)
- [Proxmox CSI Driver](https://github.com/sergelogvinov/proxmox-csi-plugin)
- [Backblaze B2 Transaction Pricing](https://www.backblaze.com/cloud-storage/transaction-pricing)
