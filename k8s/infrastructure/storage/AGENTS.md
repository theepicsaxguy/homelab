# Infrastructure Storage - Component Guidelines

SCOPE: Cluster storage providers and volume management
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: Proxmox CSI Driver, StorageClasses, PVCs, Volume Snapshots

## COMPONENT CONTEXT

Purpose: Manage persistent storage for Kubernetes workloads, including dynamic provisioning, volume backups, and storage class selection.

Architecture:
- `proxmox-csi/` - Proxmox CSI driver for dynamic provisioning from Proxmox ZFS

## QUICK-START COMMANDS

```bash
# Build all storage components
kustomize build --enable-helm k8s/infrastructure/storage

# Build specific storage provider
kustomize build --enable-helm k8s/infrastructure/storage/<provider>

# Check StorageClasses
kubectl get storageclass

# Check Proxmox CSI volumes
kubectl get pv -A
```

## STORAGE STRATEGY

### Primary Storage: Proxmox CSI

**Purpose**: Dynamic provisioning from Proxmox Nvme1 ZFS datastore.

**StorageClass**: `proxmox-csi`
- Cache Mode: `writethrough` - Balanced performance and integrity
- Filesystem: `ext4`
- Reclaim Policy: `Retain` - Persistent data preserved
- SSD: `true` - Optimized for SSD performance
- Mount Options: `noatime` - Reduce disk writes
- Default: `true` - Default StorageClass for new PVCs

**When to Use**:
- All new workloads
- Stateful applications requiring high performance
- Single-node storage (no replication needed)

**Backup Strategy**:
- Automatically backed up by Velero Kopia filesystem backups
- Velero schedules: Daily, hourly (GFS), weekly
- No annotations required

**Permissions**:
- Managed via Terraform at `tofu/bootstrap/proxmox-csi-plugin/`
- Proxmox user: `kubernetes-csi@pve`
- Minimal permissions: VM.Audit, VM.Config.Disk, Datastore.Allocate, Datastore.Audit

## STORAGE PATTERNS

### PVC Creation Pattern
Create PersistentVolumeClaim with ReadWriteOnce access mode. Set storageClassName to `proxmox-csi`. Specify requested storage size.

### Volume Expansion
- Resize PVC: Update `resources.requests.storage` in PVC spec
- K8s automatically expands volume (online expansion supported)
- Verify expansion: `kubectl describe pvc <name>`

### Volume Exclusion Pattern
Add annotation `backup.velero.io/backup-volumes-excludes: "cache-volume"` to exclude specific volume from backup.

## OPERATIONAL PATTERNS

### Storage Provider Upgrades

**Proxmox CSI Upgrade**:
1. Update Helm chart version in `proxmox-csi/kustomization.yaml`
2. Review values.yaml for breaking changes
3. Apply via GitOps
4. Monitor CSI pods: `kubectl get pods -n kube-system -l app=proxmox-csi`
5. Test PVC creation to verify provisioning works

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

**Proxmox CSI Permission Errors**:
1. Verify Proxmox user permissions via Terraform
2. Check Terraform state: `tofu show module.proxmox-csi-plugin`
3. Update permissions: `tofu apply -target=module.proxmox-csi-plugin.proxmox_virtual_environment_role.csi`

**Volume Stuck in Terminating**:
```bash
# Remove finalizer from PVC (last resort)
kubectl patch pvc <name> -n <namespace> -p '{"metadata":{"finalizers":[]}}'
```

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
```bash
# Verify Velero scheduled backups exist
velero get schedules -n velero

# Test backup
velero backup create test-backup --include-namespaces <namespace> --default-volumes-to-fs-backup --wait

# Verify PVC backed up
velero backup describe test-backup --details | grep -A 10 "Pod Volume Backups"
```

## STORAGE-DOMAIN ANTI-PATTERNS

### Storage Management
- Never use Longhorn - deprecated and removed. Use `proxmox-csi` for all workloads
- Never skip backup configuration - Proxmox CSI volumes automatically backed up by Velero
- Never delete PVCs without verifying backup status
- Never manually modify Proxmox storage volumes outside of Kubernetes
- Never assume Proxmox CSI permissions are correct - verify Terraform state if provisioning fails

### Security & Data Management
- Never grant excessive Proxmox permissions to CSI user - use minimal permissions
- Never store unencrypted secrets in volumes - use Kubernetes Secrets or ExternalSecrets
- Never use `Delete` reclaim policy for critical data - use `Retain` to preserve data

## MIGRATION NOTES

All workloads have been migrated from Longhorn to Proxmox CSI. See website/docs/breaking-changes/longhorn-removal.md for migration details.

## REFERENCES

For Kubernetes patterns: k8s/AGENTS.md
For Velero backup strategy: k8s/infrastructure/controllers/velero/BACKUP_STRATEGY.md
For Proxmox CSI permissions: tofu/bootstrap/proxmox-csi-plugin/
For CNPG database patterns: k8s/infrastructure/database/AGENTS.md
For commit format: /AGENTS.md
For Proxmox CSI documentation: https://github.com/sergelogvinov/proxmox-csi-plugin