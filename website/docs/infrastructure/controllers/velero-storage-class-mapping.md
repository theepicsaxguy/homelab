---
title: Velero Storage Class Mapping
sidebar_position: 6
---

# Velero Storage Class Mapping During Restore

## Overview

When restoring Velero backups to different storage infrastructure (e.g., from Longhorn to Proxmox CSI, or during disaster recovery to a new cluster), you need to map the original storage classes to the target storage classes. Velero supports this through ConfigMap-based storage class mapping.

## Why Storage Class Mapping is Needed

Common scenarios requiring storage class mapping:

1. **Storage Migration**: Moving from one storage provider to another (Longhorn → Proxmox CSI)
2. **Disaster Recovery**: Restoring to a cluster with different storage infrastructure
3. **Cloud Migration**: Moving from on-premises to cloud or vice versa
4. **Storage Class Deprecation**: Migrating away from deprecated storage classes
5. **Testing**: Restoring production backups to test environments with different storage

## How It Works

Velero's storage class mapping works by creating a ConfigMap in the `velero` namespace that instructs Velero to transform storage class references during restore operations. When Velero encounters a PersistentVolumeClaim (PVC) with a storage class listed in the mapping, it automatically replaces it with the target storage class.

**Important**: This works with Velero's Kopia filesystem backups (used in this cluster). It does NOT require CSI snapshots.

## Method 1: ConfigMap-Based Mapping (Recommended)

This is the recommended approach for persistent storage class mappings.

### Creating the Storage Class Mapping ConfigMap

Create a ConfigMap in the `velero` namespace with the storage class mappings:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: change-storage-class-config
  namespace: velero
  labels:
    velero.io/plugin-config: ""
    velero.io/change-storage-class: RestoreItemAction
data:
  # Format: source-storage-class: target-storage-class
  longhorn: proxmox-csi
  old-storage-class: new-storage-class
```

**Key Points**:
- The ConfigMap MUST be named with a descriptive name (e.g., `change-storage-class-config`)
- The ConfigMap MUST be in the `velero` namespace
- The label `velero.io/change-storage-class: RestoreItemAction` is REQUIRED
- The label `velero.io/plugin-config: ""` is REQUIRED
- Each line in `data:` maps `source: target` storage classes

### Applying the ConfigMap

Save the ConfigMap to a file and apply it:

```bash
# Save to file
cat > /path/to/homelab/k8s/infrastructure/controllers/velero/storage-class-mapping.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: change-storage-class-config
  namespace: velero
  labels:
    velero.io/plugin-config: ""
    velero.io/change-storage-class: RestoreItemAction
data:
  longhorn: proxmox-csi
EOF

# Apply it
kubectl apply -f /path/to/homelab/k8s/infrastructure/controllers/velero/storage-class-mapping.yaml
```

### Using the Mapping During Restore

Once the ConfigMap exists, **all Velero restore operations automatically apply the mapping**:

```bash
# Normal restore - mapping applies automatically
velero restore create my-restore \
  --from-backup my-backup \
  --include-namespaces my-namespace
```

The storage class transformation happens automatically without any additional flags.

### Verifying the Mapping

After restore, verify the storage class was transformed:

```bash
# Check PVC storage class
kubectl get pvc -n <namespace> -o yaml | grep storageClassName

# Check PV provisioner
kubectl get pv | grep <namespace>
kubectl get pv <pv-name> -o yaml | grep provisioner
```

Expected results:
- PVC `storageClassName` should show the **target** storage class (e.g., `proxmox-csi`)
- PV `provisioner` should match the target storage class driver (e.g., `csi.proxmox.sinextra.dev`)

### Removing the Mapping

To remove the storage class mapping:

```bash
kubectl delete configmap -n velero change-storage-class-config
```

**When to remove**:
- After completing a one-time migration
- When the mapping is no longer needed
- When you want restores to use original storage classes

**When to keep**:
- If you want all future restores to apply the same mapping
- During an ongoing migration period
- For permanent infrastructure changes (e.g., Longhorn → Proxmox CSI)

## Method 2: Restore Resource Modifiers (Advanced)

For more granular control or conditional transformations, use Restore Resource Modifiers:

### Creating a Resource Modifier ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: restore-resource-modifiers
  namespace: velero
  labels:
    velero.io/plugin-config: ""
    velero.io/restore-resource-modifiers: RestoreItemAction
data:
  resourceModifierRules: |
    version: v1
    resourceModifierRules:
    # Rule 1: Change PVC storage class for specific namespaces
    - conditions:
        groupResource: persistentvolumeclaims
        resourceNameRegex: ".*"
        namespaces:
        - home-assistant
        - media
      patches:
      - operation: replace
        path: "/spec/storageClassName"
        value: "proxmox-csi"

    # Rule 2: Change PV storage class
    - conditions:
        groupResource: persistentvolumes
        resourceNameRegex: ".*"
      patches:
      - operation: replace
        path: "/spec/storageClassName"
        value: "proxmox-csi"
```

### Using Resource Modifiers

Specify the ConfigMap during restore:

```bash
velero restore create my-restore \
  --from-backup my-backup \
  --resource-modifier-configmap restore-resource-modifiers
```

**When to use Resource Modifiers**:
- Need conditional storage class changes (specific namespaces, name patterns)
- Want to modify other resource fields during restore
- Need different mappings per namespace
- Temporary one-time transformations

## Common Migration Scenarios

### Longhorn to Proxmox CSI

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: change-storage-class-config
  namespace: velero
  labels:
    velero.io/plugin-config: ""
    velero.io/change-storage-class: RestoreItemAction
data:
  longhorn: proxmox-csi
```

### Proxmox CSI to Longhorn

```yaml
data:
  proxmox-csi: longhorn
```

### Migrating to Default Storage Class

If your target cluster has a different default storage class:

```yaml
data:
  old-default: new-default
  longhorn: proxmox-csi
```

### Multiple Storage Class Mappings

```yaml
data:
  longhorn: proxmox-csi
  nfs-client: proxmox-csi
  local-path: proxmox-csi
```

## Storage Class Compatibility

### Compatible Migrations

These migrations are tested and supported:

| Source | Target | Compatible | Notes |
|--------|--------|------------|-------|
| longhorn | proxmox-csi | ✅ Yes | Tested with Kopia filesystem backups |
| proxmox-csi | longhorn | ✅ Yes | Use storage class mapping ConfigMap |
| longhorn | default (proxmox-csi) | ✅ Yes | Target cluster's default storage class |
| Any | Any | ⚠️ Maybe | Check access modes and features match |

### Access Mode Compatibility

Ensure source and target storage classes support the same access modes:

- **ReadWriteOnce (RWO)**: Single node read/write - Most common
- **ReadOnlyMany (ROX)**: Multiple nodes read-only
- **ReadWriteMany (RWX)**: Multiple nodes read/write - Requires special storage

Both **Longhorn** and **Proxmox CSI** support **ReadWriteOnce (RWO)**, making them compatible for most workloads.

### Feature Differences

| Feature | Longhorn | Proxmox CSI |
|---------|----------|-------------|
| Snapshots | ✅ Yes | ⚠️ Experimental |
| Expansion | ✅ Yes | ✅ Yes |
| Cloning | ✅ Yes | ✅ Yes |
| Backup Integration | ✅ S3 | ❌ None |
| Replication | ✅ Yes | ❌ None |

**Important**: Velero uses Kopia filesystem backups in this cluster, which are **storage-class agnostic**. Data is backed up at the filesystem level, not via storage snapshots, so migrations work seamlessly.

## Troubleshooting

### ConfigMap Not Applied

**Symptom**: Restore completes but PVCs still use old storage class

**Solutions**:
```bash
# Verify ConfigMap exists and has correct labels
kubectl get configmap -n velero change-storage-class-config -o yaml

# Check labels are present:
# velero.io/plugin-config: ""
# velero.io/change-storage-class: RestoreItemAction

# Verify data section has mappings
kubectl get configmap -n velero change-storage-class-config -o jsonpath='{.data}'
```

### PVC Won't Bind After Restore

**Symptom**: PVC shows `Pending` status after restore

**Solutions**:
```bash
# Check target storage class exists
kubectl get storageclass

# Check storage provisioner is healthy
kubectl get pods -n <storage-namespace>

# Check PVC events for errors
kubectl describe pvc -n <namespace> <pvc-name>

# Common issues:
# - Target storage class doesn't exist
# - Storage provisioner not running
# - Insufficient storage capacity
# - Access mode not supported
```

### Data Not Restored to PVC

**Symptom**: PVC is bound but empty

**Solutions**:
```bash
# Check Velero restore details
velero restore describe <restore-name> --details

# Look for Pod Volume Restores section - should show "Completed"
# If missing or failed, check:

# 1. Velero node-agent logs
kubectl logs -n velero -l name=node-agent --tail=100

# 2. Check for Kopia errors
kubectl logs -n velero -l name=node-agent | grep -i error

# 3. Verify backup included pod volume backups
velero backup describe <backup-name> --details | grep -A 5 "Pod Volume"
```

### Wrong Storage Class After Restore

**Symptom**: PVC uses unexpected storage class

**Solutions**:
```bash
# Check if multiple ConfigMaps exist
kubectl get configmap -n velero -l velero.io/change-storage-class=RestoreItemAction

# Check mapping is correct
kubectl get configmap -n velero change-storage-class-config -o yaml

# Verify no typos in storage class names
kubectl get storageclass
```

## Testing Storage Class Mapping

Always test storage class mapping before using in production:

### Test Restore Procedure

1. **Create mapping ConfigMap** (as shown above)

2. **Create test namespace**:
   ```bash
   kubectl create namespace <app>-test
   kubectl label namespace <app>-test test=disaster-recovery

   # If app needs privileged mode (like Home Assistant):
   kubectl label namespace <app>-test \
     pod-security.kubernetes.io/enforce=privileged \
     pod-security.kubernetes.io/audit=privileged \
     pod-security.kubernetes.io/warn=privileged
   ```

3. **Execute test restore**:
   ```bash
   velero restore create test-restore-$(date +%Y%m%d-%H%M%S) \
     --from-backup <backup-name> \
     --include-namespaces <source-namespace> \
     --namespace-mappings <source-namespace>:<app>-test \
     --wait
   ```

4. **Verify storage class transformation**:
   ```bash
   # Check PVC storage class
   kubectl get pvc -n <app>-test -o yaml | grep storageClassName
   # Should show target storage class (e.g., proxmox-csi)

   # Check PV provisioner
   kubectl get pvc -n <app>-test
   kubectl get pv <pv-name> -o yaml | grep provisioner
   # Should show target provisioner (e.g., csi.proxmox.sinextra.dev)
   ```

5. **Verify data integrity**:
   ```bash
   # Check pod is running
   kubectl get pods -n <app>-test

   # Verify data exists
   kubectl exec -n <app>-test <pod-name> -- ls -la <data-path>
   ```

6. **Cleanup**:
   ```bash
   kubectl delete namespace <app>-test
   ```

For a complete test restore procedure with verification steps, see [Test Restore Procedure](../../disaster/test-restore-procedure.md).

## Best Practices

1. **Keep ConfigMap in Git**: Store the storage class mapping ConfigMap in your GitOps repository alongside Velero configuration

2. **Test Before Production**: Always test storage class mapping with a test namespace before applying to production

3. **Document Mappings**: Clearly document which storage classes are mapped and why

4. **Verify After Restore**: Always verify storage class transformation after restore operations

5. **Use Descriptive Names**: Name your mapping ConfigMaps clearly (e.g., `longhorn-to-proxmox-mapping`)

6. **Monitor Restore Logs**: Check Velero restore logs for any transformation warnings or errors

7. **Validate Compatibility**: Ensure source and target storage classes have compatible features before mapping

## Related Documentation

- [Velero Backup Setup](velero-backup.md)
- [Disaster Recovery Scenarios](../../disaster/scenarios/index.md)
- [Test Restore Procedure](../../disaster/test-restore-procedure.md)
- [Velero Official Documentation](https://velero.io/docs/main/restore-reference/)

## References

- [Velero Restore Reference](https://velero.io/docs/main/restore-reference/)
- [Velero Restore Resource Modifiers](https://velero.io/docs/main/restore-resource-modifiers/)
- [Storage Class Change Plugin](https://github.com/vmware-tanzu/velero/pull/1621)
