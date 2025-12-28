# Velero Backup Strategy

## Overview

This cluster uses **Velero with Kopia filesystem backups** for disaster recovery. We explicitly chose **NOT** to use CSI volume snapshots despite initially exploring that option.

## Why No CSI Snapshots?

### Investigation Summary

We investigated using Proxmox CSI volume snapshots with Velero but discovered:

1. **Proxmox CSI snapshot feature is experimental** and requires `root@pam` credentials
2. **API tokens cannot perform snapshot operations** - the CSI driver needs root-level access for disk copy operations
3. **Snapshots create full disk copies**, not incremental deltas
4. **Additional permissions would be needed** that are too broad for an automation user

### Decision Rationale

**Velero's Kopia data mover is superior for our use case:**

✅ **No CSI snapshots needed** - Direct filesystem backup to S3
✅ **True disaster recovery** - All data in S3, not dependent on Proxmox storage
✅ **More secure** - No need for root-level Proxmox credentials
✅ **Incremental backups** - Kopia deduplicates and compresses data efficiently
✅ **Simpler architecture** - Fewer moving parts, easier to maintain

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
| `weekly-offsite` | Weekly Sun 3:00 AM | Backblaze B2 | 90 days | Long-term disaster recovery |

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
   - No intermediate snapshots needed
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

## Monitoring

- **Prometheus metrics** exposed via ServiceMonitor
- **Backup failures** trigger alerts
- **Storage location validation** runs hourly
- Check backup status: `velero get backups`

## References

- [Velero Documentation](https://velero.io/docs/)
- [Kopia Uploader](https://velero.io/docs/main/file-system-backup/)
- [Proxmox CSI Driver](https://github.com/sergelogvinov/proxmox-csi-plugin)
