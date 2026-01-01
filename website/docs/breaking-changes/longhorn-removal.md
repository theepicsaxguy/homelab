---
title: 'Longhorn Storage Removal'
---

Longhorn storage provider has been deprecated and removed from the homelab cluster. All workloads have migrated to Proxmox CSI for improved performance and simplified backup management.

:::danger BREAKING CHANGE
Longhorn has been completely removed. Applications referencing `storageClassName: longhorn` will fail to provision volumes. Ensure all workloads use `proxmox-csi` StorageClass before pulling this update.
:::

## Background

Longhorn provided distributed storage with replication across nodes, but introduced operational complexity:

- Manual backup label management for each PVC
- Network overhead from multi-replica synchronization
- Resource consumption for replicas on each node
- Complex migration procedures for volume expansion and recovery

Proxmox CSI leverages ZFS storage on Proxmox hosts directly, offering:

- Automatic backup integration with Velero
- Higher performance via local SSD storage
- Simplified operations (no manual label management)
- Native Proxmox integration

## Prerequisites

Before uninstalling Longhorn, verify all applications have migrated to Proxmox CSI:

```bash
# Check for any remaining Longhorn PVCs
kubectl get pvc -A | grep longhorn

# Check Longhorn volumes
kubectl get volumes -n longhorn-system
```

All PVCs should reference `storageClassName: proxmox-csi`. If any workloads still use Longhorn, migrate them first (see Migration Guide below).

## Uninstalling Longhorn

Follow the official Longhorn uninstall procedure from the [Longhorn documentation](https://longhorn.io/docs/1.10.1/deploy/uninstall/).

### Step 1: Enable Deletion Confirmation

Set the `deleting-confirmation-flag` to allow uninstallation:

```bash
kubectl -n longhorn-system patch settings.longhorn.io deleting-confirmation-flag \
  -p '{"value": "true"}' --type merge
```

### Step 2: Run Uninstall Job

Apply the official Longhorn uninstall manifest:

```bash
kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v1.10.1/uninstall/uninstall.yaml
```

### Step 3: Monitor Uninstall Progress

Watch the uninstall job:

```bash
kubectl get job/longhorn-uninstall -n longhorn-system -w
```

Check uninstall logs:

```bash
kubectl logs -n longhorn-system job/longhorn-uninstall --tail=50
```

The uninstall process removes:

- Longhorn manager and UI pods
- CSI driver components
- Volume data and replicas
- RecurringJob resources
- Engine images

### Step 4: Clean Up Resources

After the uninstall job completes, remove remaining resources:

```bash
# Delete the uninstall job and RBAC resources
kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v1.10.1/uninstall/uninstall.yaml

# Verify namespace is empty
kubectl get all -n longhorn-system

# Delete the namespace
kubectl delete namespace longhorn-system
```

### Step 5: Remove Longhorn Manifests

Remove Longhorn configuration from the repository:

```bash
# Remove Longhorn from storage kustomization
# Edit k8s/infrastructure/storage/kustomization.yaml
# Remove "- longhorn" from resources list

# Delete Longhorn directory
rm -rf k8s/infrastructure/storage/longhorn
```

Update Argo CD to sync the changes:

```bash
argocd app sync storage --prune
```

## Migration Guide

If you have workloads still using Longhorn, migrate them to Proxmox CSI before uninstalling.

### Step 1: Create Backup

Before migrating, back up Longhorn volumes using Longhorn's built-in backup feature or Velero.

**Longhorn Backup**:

```bash
# Trigger manual backup via Longhorn UI
# Or use kubectl to create backup resource

kubectl -n longhorn-system create -f - <<EOF
apiVersion: longhorn.io/v1beta2
kind: Backup
metadata:
  name: <volume-name>-backup
spec:
  snapshotName: <volume-name>
  labels:
    backup.longhorn.io/source-volume: <volume-name>
EOF
```

### Step 2: Scale Down Application

Stop the application using the Longhorn volume:

```bash
kubectl scale deployment <deployment-name> -n <namespace> --replicas=0
# or
kubectl scale statefulset <statefulset-name> -n <namespace> --replicas=0
```

### Step 3: Create Proxmox CSI PVC

Create a new PVC using `proxmox-csi` StorageClass:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: <app>-data-proxmox
  namespace: <namespace>
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-csi
  resources:
    requests:
      storage: <size>
```

Apply the PVC:

```bash
kubectl apply -f <pvc-file>.yaml
```

### Step 4: Migrate Data

Create a temporary pod with both volumes mounted to copy data:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: data-migration
  namespace: <namespace>
spec:
  containers:
    - name: migrate
      image: busybox
      command:
        - sh
        - -c
        - |
          echo "Starting data migration..."
          cp -av /source/. /dest/
          echo "Migration complete"
          sleep 3600
      volumeMounts:
        - name: longhorn-volume
          mountPath: /source
        - name: proxmox-volume
          mountPath: /dest
  volumes:
    - name: longhorn-volume
      persistentVolumeClaim:
        claimName: <old-longhorn-pvc>
    - name: proxmox-volume
      persistentVolumeClaim:
        claimName: <new-proxmox-pvc>
  restartPolicy: Never
```

Apply the migration pod:

```bash
kubectl apply -f migration-pod.yaml
```

Monitor the migration:

```bash
kubectl logs -n <namespace> data-migration -f
```

### Step 5: Update Application Manifest

Update the application deployment or statefulset to reference the new PVC:

```yaml
volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: proxmox-csi
      resources:
        requests:
          storage: <size>
```

Commit changes and sync via Argo CD, or apply directly:

```bash
kubectl apply -f <app-manifest>.yaml
```

### Step 6: Scale Application Back Up

Restore application replicas:

```bash
kubectl scale deployment <deployment-name> -n <namespace> --replicas=1
# or
kubectl scale statefulset <statefulset-name> -n <namespace> --replicas=1
```

### Step 7: Verify Application

Confirm the application functions correctly with the new volume:

```bash
kubectl get pods -n <namespace>
kubectl logs -n <namespace> <pod-name>
```

Test application functionality through its UI or API.

### Step 8: Clean Up

After verifying the migration succeeded, delete the old Longhorn PVC and the migration pod:

```bash
kubectl delete pvc <old-longhorn-pvc> -n <namespace>
kubectl delete pod data-migration -n <namespace>
```

## Troubleshooting

### Uninstall Job Fails

If the uninstall job fails, check logs for specific errors:

```bash
kubectl logs -n longhorn-system job/longhorn-uninstall
```

Common issues:

**Deletion confirmation not set**:

```bash
kubectl -n longhorn-system patch settings.longhorn.io deleting-confirmation-flag \
  -p '{"value": "true"}' --type merge
```

**Volumes still attached**:

Ensure all workloads using Longhorn volumes are scaled down or deleted.

**Stuck finalizers**:

Remove finalizers from Longhorn resources:

```bash
kubectl patch -n longhorn-system <resource-type> <resource-name> \
  -p '{"metadata":{"finalizers":[]}}' --type merge
```

### PVCs Stuck in Terminating

If Longhorn PVCs remain stuck in `Terminating`:

```bash
# Force remove finalizer
kubectl patch pvc <pvc-name> -n <namespace> \
  -p '{"metadata":{"finalizers":[]}}' --type merge
```

### Namespace Won't Delete

If `longhorn-system` namespace remains after uninstall:

```bash
# Check remaining resources
kubectl api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 kubectl get --show-kind --ignore-not-found -n longhorn-system

# Force delete namespace (last resort)
kubectl delete namespace longhorn-system --force --grace-period=0
```

## Post-Migration Benefits

After migrating to Proxmox CSI:

- **Automatic backups**: Velero handles all backup scheduling without manual labels
- **Better performance**: Direct access to SSD storage via CSI driver
- **Simplified operations**: No replica management or backup job configuration
- **Consistent backup strategy**: All storage uses Velero with Kopia data mover

## References

- [Longhorn Uninstall Documentation](https://longhorn.io/docs/1.10.1/deploy/uninstall/)
- [Proxmox CSI Driver](https://github.com/sergelogvinov/proxmox-csi-plugin)
- [Velero Backup Strategy](../infrastructure/controllers/velero-backup.md)
