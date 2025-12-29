# Infrastructure Storage - Component Guidelines

SCOPE: Cluster storage providers and volume management
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: Proxmox CSI Driver, Longhorn, StorageClasses, PVCs, Volume Snapshots

## COMPONENT CONTEXT

Purpose:
Manage persistent storage for Kubernetes workloads, including dynamic provisioning, volume backups, and storage class selection.

Boundaries:
- Handles: StorageClass configuration, CSI driver installation, volume backups, PVC management
- Does NOT handle: Database backups (see database/ for CNPG), application PVCs (see applications/)
- Integrates with: tofu/ (for Proxmox CSI permissions), controllers/ (for Velero backup integration)

Architecture:
- `proxmox-csi/` - Proxmox CSI driver for dynamic provisioning from Proxmox ZFS
- `longhorn/` - Longhorn distributed storage with replication and backups (legacy)

## QUICK-START COMMANDS

```bash
# Build all storage components
kustomize build --enable-helm k8s/infrastructure/storage

# Build specific storage provider
kustomize build --enable-helm k8s/infrastructure/storage/<provider>

# Check StorageClasses
kubectl get storageclass

# Check Longhorn volumes
kubectl get volumes -n longhorn-system

# Check Proxmox CSI volumes
kubectl get pv -A
```

## STORAGE STRATEGY

### Primary Storage: Proxmox CSI

**Purpose**: Dynamic provisioning from Proxmox Nvme1 ZFS datastore.

**StorageClass**: `proxmox-csi`
- **Cache Mode**: `writethrough` - Balanced performance and data integrity
- **Filesystem**: `ext4`
- **Reclaim Policy**: `Retain` - Persistent data preserved after pod deletion
- **SSD**: `true` - Optimized for SSD performance
- **Mount Options**: `noatime` - Reduce disk writes
- **Default**: `true` - Default StorageClass for new PVCs

**When to Use**:
- All new workloads
- Stateful applications requiring high performance
- Single-node storage (no replication needed)

**Backup Strategy**:
- Automatically backed up by Velero CSI snapshots (no annotations needed)
- Velero schedules: Daily (TrueNAS), Weekly (Backblaze B2)
- No Longhorn backup labels required

**Permissions**:
- Managed via Terraform at `tofu/bootstrap/proxmox-csi-plugin/`
- Proxmox user: `kubernetes-csi@pve`
- Minimal permissions: VM.Audit, VM.Config.Disk, Datastore.Allocate, Datastore.Audit

### Legacy Storage: Longhorn

**Purpose**: Distributed storage with replication and scheduled backups.

**StorageClass**: `longhorn`
- **Replication Factor**: Configurable (default: 3 replicas)
- **Reclaim Policy**: `Retain`
- **Backups**: Enabled via RecurringJob resources

**When to Use**:
- Legacy workloads already using Longhorn
- Applications requiring multi-node replication
- Critical stateful applications (migrating to proxmox-csi)

**Backup Strategy**:
- Requires backup labels on PVCs (manual configuration)
- GFS (Grandfather-Father-Son): Hourly/daily/weekly backups for critical data
- Daily: Standard backups for regular apps
- Weekly: Basic backups for less critical data
- Backup target: TrueNAS MinIO via S3-compatible API

**Backup Labels** (apply to PVCs):
```yaml
# GFS tier - Critical databases and stateful apps
recurring-job.longhorn.io/source: enabled
recurring-job-group.longhorn.io/gfs: enabled

# Daily tier - Standard applications
recurring-job.longhorn.io/source: enabled
recurring-job-group.longhorn.io/daily: enabled

# Weekly tier - Less critical data
recurring-job.longhorn.io/source: enabled
recurring-job-group.longhorn.io/weekly: enabled

# No backup - Ephemeral data
# (no labels)
```

**Migration Note**: New workloads should use `proxmox-csi` StorageClass. Migrate legacy Longhorn volumes when convenient.

## STORAGE PATTERNS

### PVC Creation Pattern

**Proxmox CSI (New Workloads)**:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myapp-data
  namespace: myapp
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-csi  # Primary storage
  resources:
    requests:
      storage: 10Gi
```

**Longhorn (Legacy)**:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myapp-data
  namespace: myapp
  labels:
    # Add backup labels for Longhorn
    recurring-job.longhorn.io/source: enabled
    recurring-job-group.longhorn.io/daily: enabled
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn  # Legacy storage
  resources:
    requests:
      storage: 10Gi
```

### Storage Class Selection

| StorageClass | Use Case | Replication | Backup | Performance |
|-------------|-----------|-------------|---------|-------------|
| `proxmox-csi` | New workloads | None (single-node) | Velero auto | High (SSD) |
| `longhorn` | Legacy, critical | Multi-node (3 replicas) | Manual labels | Medium (network) |

### Volume Expansion

**Proxmox CSI**:
- Resize PVC: Update `resources.requests.storage` in PVC spec
- K8s automatically expands volume (online expansion supported)
- Verify expansion: `kubectl describe pvc <name>`

**Longhorn**:
- Resize PVC: Update `resources.requests.storage` in PVC spec
- Longhorn automatically expands underlying volume
- May require pod restart for resize to take effect

## BACKUP STRATEGIES

### Proxmox CSI Backups (Velero)

**Automatic Backup**:
- Velero automatically backs up all `proxmox-csi` PVCs
- Kopia data mover streams filesystem data to S3
- No annotations or labels required

**Storage Locations**:
- TrueNAS MinIO: Fast local restores, daily backups
- Backblaze B2: Offsite disaster recovery, weekly backups

**Exclusion Pattern** (optional):
```yaml
# Exclude specific volume from backup
spec:
  template:
    metadata:
      annotations:
        backup.velero.io/backup-volumes-excludes: "cache-volume"
```

### Longhorn Backups (RecurringJob)

**GFS (Grandfather-Father-Son)** - Critical Data:
- **Son Tier**: Hourly backups, 2-day retention (48 hourly)
- **Father Tier**: Daily backups at 02:00, 2-week retention
- **Grandfather Tier**: Weekly backups on Sunday 03:00, 2-month retention

**Daily** - Standard Data:
- Daily backups at 02:00, 2-week retention

**Weekly** - Basic Data:
- Weekly backups on Sunday 03:00, 1-month retention

**Snapshot Cleanup**:
- Runs every 6 hours
- Removes temporary snapshots from all backup groups

**RecurringJob Definitions**:
Located in `k8s/infrastructure/storage/longhorn/recurringjob.yaml`

## OPERATIONAL PATTERNS

### Storage Provider Upgrades

**Proxmox CSI Upgrade**:
1. Update Helm chart version in `proxmox-csi/kustomization.yaml`
2. Review values.yaml for breaking changes
3. Apply via GitOps
4. Monitor CSI pods: `kubectl get pods -n kube-system -l app=proxmox-csi`
5. Test PVC creation: Create test PVC to verify provisioning works

**Longhorn Upgrade**:
1. Update Helm chart version in `longhorn/kustomization.yaml`
2. Review values.yaml for breaking changes
3. Apply via GitOps
4. Monitor Longhorn pods: `kubectl get pods -n longhorn-system`
5. Check volume health: `kubectl get volumes -n longhorn-system`

### Storage Troubleshooting

**Proxmox CSI Issues**:
```bash
# Check CSI pods
kubectl get pods -n kube-system -l app=proxmox-csi

# Check CSI logs
kubectl logs -n kube-system -l app=proxmox-csi-plugin -c provisioner

# Check StorageClass
kubectl describe storageclass proxmox-csi

# Check PVC status
kubectl describe pvc <name> -n <namespace>

# Check PV details
kubectl describe pv <pv-name>
```

**Longhorn Issues**:
```bash
# Check Longhorn manager pods
kubectl get pods -n longhorn-system -l app=longhorn-manager

# Check Longhorn UI
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80

# Check volume health
kubectl get volumes -n longhorn-system

# Check backup status
kubectl get backups.backup.volume -n longhorn-system

# Check volume replicas
kubectl get replicas -n longhorn-system
```

**Volume Stuck in Terminating**:
```bash
# Remove finalizer from PVC (last resort)
kubectl patch pvc <name> -n <namespace> -p '{"metadata":{"finalizers":[]}}'

# For Longhorn volumes, check volume replicas and detach manually
```

**Proxmox CSI Permission Errors**:
1. Verify Proxmox user has correct permissions via Terraform
2. Check Terraform state: `tofu show module.proxmox-csi-plugin`
3. Update permissions: `tofu apply -target=module.proxmox-csi-plugin.proxmox_virtual_environment_role.csi`

## TESTING

### Storage Validation

```bash
# Test Proxmox CSI provisioning
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-csi-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-csi
  resources:
    requests:
      storage: 1Gi
EOF

# Verify PVC bound
kubectl get pvc test-csi-pvc

# Test pod with PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-storage-pod
spec:
  containers:
    - name: test
      image: busybox
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: test-csi-pvc
EOF

# Verify pod can write to volume
kubectl exec test-storage-pod -- sh -c "echo 'test' > /data/test.txt && cat /data/test.txt"
```

### Backup Validation

**Proxmox CSI (Velero)**:
```bash
# Verify Velero scheduled backups exist
velero get schedules -n velero

# Test backup
velero backup create test-backup --include-namespaces <namespace> --default-volumes-to-fs-backup --wait

# Verify PVC backed up
velero backup describe test-backup --details | grep -A 10 "Pod Volume Backups"
```

**Longhorn**:
```bash
# Check recurring jobs
kubectl get recurringjob -n longhorn-system

# Check backup status
kubectl get backups.backup.volume -n longhorn-system

# Trigger manual backup
kubectl exec -n longhorn-system <manager-pod> -- /bin/bash -c "longhorn-manager --backup-volume <volume-name>"
```

## ANTI-PATTERNS

Never use `longhorn` StorageClass for new workloads. Use `proxmox-csi` for better performance and automatic backups.

Never skip backup labels on Longhorn PVCs for critical data. Apply appropriate tier labels.

Never delete PVCs without verifying data is backed up. Check backup status before deletion.

Never assume Proxmox CSI permissions are correct. Verify Terraform state if provisioning fails.

Never resize Longhorn volumes without checking replica health. Ensure all replicas are healthy before expansion.

Never use Longhorn for ephemeral or cache data. Use `proxmox-csi` with no backup labels for temporary data.

Never manually modify Proxmox storage volumes outside of Kubernetes. Let CSI driver manage all operations.

## SECURITY BOUNDARIES

Never grant excessive Proxmox permissions to CSI user. Use minimal permissions defined in tofu/bootstrap/.

Never expose Longhorn UI to public internet. Access via port-forward or VPN only.

Never store unencrypted secrets in volumes. Use Kubernetes Secrets or ExternalSecrets for sensitive data.

Never use `Delete` reclaim policy for critical data. Use `Retain` to preserve data after pod deletion.

## MIGRATION NOTES

### Longhorn to Proxmox CSI Migration

When migrating legacy Longhorn volumes to Proxmox CSI:

1. **Create snapshot** of Longhorn volume
2. **Create backup** of Longhorn volume (using GFS tier)
3. **Stop application** using the volume
4. **Create new PVC** using `proxmox-csi` StorageClass
5. **Migrate data**:
   - If application supports migration: Use built-in tools
   - If generic: Create temporary pod with both volumes, copy data
6. **Update application** to use new PVC
7. **Verify application** works correctly
8. **Delete old Longhorn volume** (after verification and grace period)

## REFERENCES

For Kubernetes domain patterns, see k8s/AGENTS.md

For Velero backup strategy, see k8s/infrastructure/controllers/velero/BACKUP_STRATEGY.md

For Proxmox CSI permissions, see tofu/bootstrap/proxmox-csi-plugin/

For CNPG database patterns, see k8s/infrastructure/database/AGENTS.md

For commit message format, see root AGENTS.md

For Proxmox CSI documentation, see https://github.com/sergelogvinov/proxmox-csi-plugin

For Longhorn documentation, see https://longhorn.io/docs/
