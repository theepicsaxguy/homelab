---
title: Migrating from Longhorn to Proxmox CSI
sidebar_position: 10
---

# Migrating from Longhorn to Proxmox CSI Storage

## ⚠️ Breaking Change Notice

This guide documents the migration from Longhorn to Proxmox CSI storage class. This is a **breaking change** that requires careful planning and execution.

**Migration completed**: December 29, 2025
**Affected storage**: ~550Gi across 24 applications in 16 namespaces

## Why We Migrated

After using Longhorn for initial homelab storage, we encountered several issues that led us to migrate to Proxmox CSI:

### Longhorn Challenges

1. **Instability Issues**: Longhorn experienced periodic stability problems, particularly with replica synchronization and volume attachment failures
2. **Resource Overhead**: Longhorn's replica system consumed significant disk space (3x data size for 3 replicas)
3. **Disk Wear**: Continuous replication and write amplification hammered our NVMe drives - our last drive reached 100% wear level in just 8 months
4. **Complexity**: Longhorn's distributed storage features were overkill for our single-node/single-disk homelab setup

### Why Proxmox CSI Works Better for Us

✅ **Simplicity**: Direct storage provisioning without replication overhead
✅ **Space Efficiency**: Gained 3x usable storage capacity (no replicas needed)
✅ **Reduced Disk Wear**: Single-write operations instead of replicated writes
✅ **Better Fit**: Since all our data was on the same disk and node anyway, Proxmox CSI provides the same availability with less overhead
✅ **Stability**: More predictable behavior with direct CSI provisioning

### Learning Experience

Longhorn was an excellent learning platform for understanding distributed storage, CSI drivers, and Kubernetes storage primitives. It served us well as a starting point, but we outgrew its complexity for our use case.

## Prerequisites

Before starting this migration, ensure you have:

### Required Infrastructure

- ✅ **Velero installed and configured** - See [Velero Setup](../controllers/velero-backup.md)
- ✅ **Proxmox CSI installed and healthy** - See [Proxmox CSI Setup](../controllers/proxmox-csi.md)
- ✅ **Storage class mapping ConfigMap deployed** - See [Velero Storage Class Mapping](../controllers/velero-storage-class-mapping.md)
- ✅ **Sufficient storage capacity** - Verify Proxmox has enough space for all your data

### Required Tools

- `kubectl` with cluster admin access
- `velero` CLI installed
- Access to Proxmox node with adequate storage

### Required Knowledge

- Understanding of Kubernetes PVCs and storage classes
- Familiarity with Velero backup/restore operations
- Knowledge of which applications are stateful vs declarative

## Migration Overview

This migration uses **Velero with Kopia filesystem backups** to migrate data from Longhorn to Proxmox CSI. The process is:

1. **Backup** all namespaces using Velero (with Kopia filesystem backup)
2. **Delete** namespaces to release Longhorn PVCs
3. **Restore** namespaces with automatic storage class transformation (longhorn → proxmox-csi)
4. **Verify** all applications are functional
5. **Update** k8s manifests to reference proxmox-csi
6. **Uninstall** Longhorn

### How Storage Class Mapping Works

Velero's storage class mapping feature automatically transforms PVC storage class references during restore. This is configured via a ConfigMap:

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

Once deployed, **all Velero restores automatically map `longhorn` → `proxmox-csi`** without additional flags.

## Pre-Migration Checklist

Complete these steps before starting the migration:

```bash
# 1. Verify Velero is operational
velero backup get
kubectl get pods -n velero

# 2. Verify Proxmox CSI is healthy
kubectl get pods -n csi-proxmox
kubectl get storageclass proxmox-csi

# 3. Verify storage class mapping ConfigMap exists
kubectl get configmap -n velero change-storage-class-config -o yaml

# 4. Check available Proxmox storage capacity
# Ensure you have enough space for all your data + overhead

# 5. Document current state
kubectl get pvc -A -o wide > ~/pre-migration-pvcs-$(date +%Y%m%d).txt
kubectl get pods -A > ~/pre-migration-pods-$(date +%Y%m%d).txt

# 6. Create results directory
mkdir -p ~/migrations
```

## Configuring Velero Exclusions

**Important**: Exclude resources that shouldn't be backed up to reduce backup size and restore time.

### Exclude NFS/External Storage

For NFS mounts or manually provisioned volumes (like shared media libraries), add this annotation to prevent Velero from backing up the volume data:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: media-share
  namespace: media
  annotations:
    backup.velero.io/backup-volumes: ""  # Exclude from pod volume backups
spec:
  storageClassName: ""  # Manually provisioned
  volumeName: media-share
```

Apply the annotation to existing PVCs:
```bash
kubectl annotate pvc <pvc-name> -n <namespace> backup.velero.io/backup-volumes=""
```

### Exclude Declarative Workloads

Deployments that are created declaratively from GitOps manifests don't need their data backed up:

**Examples of declarative workloads**:
- frigate (Deployment)
- sabnzbd (Deployment)
- whisperasr (Deployment)

**Strategy**: Only backup StatefulSets (stateful apps) and exclude Deployments:

```bash
# When creating manual backups, exclude Deployments
velero backup create <backup-name> \
  --include-resources statefulsets,persistentvolumeclaims,services,configmaps,secrets \
  --exclude-resources deployments,replicasets,pods
```

Or use a label-based approach in your scheduled backups to only backup resources with `backup.velero.io/enable: "true"` label.

## Step-by-Step Migration Procedure

### Phase 1: Identify Applications to Migrate

List all PVCs using Longhorn storage class:

```bash
kubectl get pvc -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STORAGECLASS:.spec.storageClassName | grep longhorn
```

**Categorize applications**:
- **Critical data**: Applications with important data (databases, photo libraries, etc.)
- **Declarative**: Applications deployed via GitOps (can be recreated from manifests)
- **Disposable**: Applications without important data (can be deleted/recreated)

### Phase 2: Delete Disposable Applications

Delete namespaces for applications without important data:

```bash
# Example - adjust based on your applications
kubectl delete namespace <disposable-app-1>
kubectl delete namespace <disposable-app-2>

# Verify deletions
kubectl get pv | grep <namespace>
# Should show Released or be deleted
```

### Phase 3: Create Comprehensive Backup

Create a Velero backup of **all remaining namespaces** to migrate:

```bash
# Create backup with filesystem backup enabled
velero backup create longhorn-to-proxmox-migration-$(date +%Y%m%d-%H%M%S) \
  --include-namespaces <namespace1>,<namespace2>,<namespace3> \
  --default-volumes-to-fs-backup \
  --wait

# Example for our migration:
velero backup create longhorn-to-proxmox-migration-$(date +%Y%m%d-%H%M%S) \
  --include-namespaces media,open-webui,gpt-researcher,qdrant,opencode,unifi,babybuddy,karakeep,immich \
  --default-volumes-to-fs-backup \
  --wait
```

**Verify backup completion**:

```bash
velero backup describe <backup-name> --details

# Critical checks:
# - Phase: Completed (or PartiallyFailed is OK if only missing namespaces)
# - Errors: 0 (or only "namespace not found" errors)
# - Pod Volume Backups - kopia: Completed (shows number of PVCs backed up)
```

**Expected output**:
```
Phase:  Completed
Backup Volumes:
  Pod Volume Backups - kopia:
    Completed:  62  # Number of PVCs backed up
```

### Phase 4: Delete Namespaces

Delete all namespaces being migrated:

```bash
# Delete namespaces (adjust based on your backup)
kubectl delete namespace media
kubectl delete namespace open-webui
kubectl delete namespace gpt-researcher
kubectl delete namespace qdrant
kubectl delete namespace opencode
kubectl delete namespace unifi
kubectl delete namespace babybuddy
kubectl delete namespace karakeep
kubectl delete namespace immich

# Verify PVs are released
kubectl get pv | grep -E "media|open-webui|gpt-researcher"
# Should show Released status
```

**If namespace stuck in Terminating**:

```bash
# Force remove finalizers
kubectl get namespace <stuck-namespace> -o json | \
  jq '.spec.finalizers = []' | \
  kubectl replace --raw /api/v1/namespaces/<stuck-namespace>/finalize -f -
```

### Phase 5: Restore with Storage Class Migration

Restore all namespaces - **storage class mapping happens automatically**:

```bash
# Restore from backup
velero restore create longhorn-to-proxmox-restore-$(date +%Y%m%d-%H%M%S) \
  --from-backup <backup-name> \
  --include-namespaces <namespace1>,<namespace2>,<namespace3> \
  --wait

# Example:
velero restore create longhorn-to-proxmox-restore-$(date +%Y%m%d-%H%M%S) \
  --from-backup longhorn-to-proxmox-migration-20251229-204740 \
  --include-namespaces media,open-webui,gpt-researcher,qdrant,opencode,unifi,babybuddy,karakeep,immich \
  --wait
```

**Monitor restore progress**:

```bash
# Watch restore status
velero restore describe <restore-name>

# Watch PVCs being created
watch kubectl get pvc -A

# Check pod volume restore progress
kubectl get podvolumerestores -n velero | grep <restore-name>
```

**Expected restore phases**:
1. **New** → **InProgress** (Kubernetes resources being restored)
2. **PVCs created** with `proxmox-csi` storage class
3. **Kopia restores running** (data being restored from S3 to PVCs)
4. **Pods starting** once data restore completes
5. **Completed** (all resources and data restored)

### Phase 6: Verify Migration Success

#### 6.1 Verify Storage Class Transformation

```bash
# Check all PVCs are using proxmox-csi
kubectl get pvc -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STORAGECLASS:.spec.storageClassName | grep -v proxmox-csi

# Should return empty (all using proxmox-csi)

# Verify PV provisioner
kubectl get pv -o custom-columns=NAME:.metadata.name,STORAGECLASS:.spec.storageClassName,PROVISIONER:.spec.csi.driver | grep proxmox-csi

# Expected provisioner: csi.proxmox.sinextra.dev
```

#### 6.2 Verify Critical Applications

For each critical application:

```bash
# Check pod status
kubectl get pods -n <namespace>
kubectl wait --for=condition=ready pod/<pod-name> -n <namespace> --timeout=300s

# Check PVC status
kubectl get pvc -n <namespace>
# All should show: STATUS=Bound, STORAGECLASS=proxmox-csi

# Verify data integrity
kubectl exec -n <namespace> <pod-name> -- ls -la <data-path>
kubectl exec -n <namespace> <pod-name> -- du -sh <data-path>

# Test application functionality
# - Login and verify data access
# - Check recent data exists
# - Test core workflows
```

**Example for critical apps**:

```bash
# qdrant (vector database)
kubectl get pods -n qdrant
kubectl get pvc -n qdrant
# Verify qdrant API is accessible

# Photo library (immich)
kubectl get pods -n immich
kubectl get pvc -n immich | grep library
# Verify photos are accessible via web UI

# Database (PostgreSQL)
kubectl exec -n <namespace> <postgres-pod> -- psql -U postgres -c "SELECT COUNT(*) FROM <table>;"
```

#### 6.3 Check for Failed Pod Volume Restores

```bash
# List failed restores
kubectl get podvolumerestores -n velero -l velero.io/restore-name=<restore-name> -o jsonpath='{range .items[?(@.status.phase=="Failed")]}{.metadata.name}{"\n"}{end}'

# Describe failed restore
kubectl describe podvolumerestore -n velero <failed-restore-name>

# Check logs
kubectl logs -n velero -l name=node-agent | grep <namespace>
```

### Phase 7: Update Kubernetes Manifests

Update all k8s manifest files to reference `proxmox-csi` instead of `longhorn`:

```bash
# Find all files with longhorn storage class references
grep -r "storageClassName: longhorn" k8s/applications/

# Update each file:
# Change: storageClassName: longhorn
# To:     storageClassName: proxmox-csi

# Remove Longhorn backup labels:
# Remove these labels from PVCs and volumeClaimTemplates:
# - recurring-job.longhorn.io/source: enabled
# - recurring-job-group.longhorn.io/daily: enabled
# - recurring-job-group.longhorn.io/weekly: enabled
# - recurring-job-group.longhorn.io/gfs: enabled
```

**Files to update** (adjust based on your applications):
- `k8s/applications/*/statefulset.yaml` - volumeClaimTemplates
- `k8s/applications/*/pvc.yaml` - standalone PVCs

**Example changes**:

```yaml
# Before:
volumeClaimTemplates:
  - metadata:
      name: data
      labels:
        recurring-job.longhorn.io/source: enabled
        recurring-job-group.longhorn.io/daily: enabled
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: longhorn
      resources:
        requests:
          storage: 10Gi

# After:
volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: proxmox-csi
      resources:
        requests:
          storage: 10Gi
```

**Commit changes**:

```bash
git add .
git commit -m "feat(storage): migrate from Longhorn to Proxmox CSI

- Update all storage class references to proxmox-csi
- Remove Longhorn backup labels (Velero handles backups now)
- Migration completed: $(date +%Y%m%d)
- Total data migrated: ~550Gi across 24 applications

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

### Phase 8: Uninstall Longhorn

Once migration is verified successful and all applications are functioning:

**Important**: Wait at least 7 days after migration before uninstalling Longhorn to ensure Velero backups are verified and no issues surface.

```bash
# 1. Verify no PVCs still using Longhorn
kubectl get pvc -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STORAGECLASS:.spec.storageClassName | grep longhorn
# Should return empty

# 2. Delete Longhorn volumes (if any remain)
kubectl -n longhorn-system get volumes
kubectl -n longhorn-system delete volumes --all

# 3. Uninstall Longhorn
# Follow official Longhorn uninstall guide:
# https://longhorn.io/docs/1.10.1/deploy/uninstall/

# If installed via Helm:
helm uninstall longhorn -n longhorn-system

# If installed via kubectl:
kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v1.10.1/deploy/longhorn.yaml

# 4. Clean up namespace
kubectl delete namespace longhorn-system

# 5. Remove Longhorn CRDs (if needed)
kubectl get crd | grep longhorn.io
kubectl delete crd <longhorn-crds>
```

**Verify cleanup**:

```bash
# No Longhorn resources should remain
kubectl get pods -n longhorn-system
kubectl get pv | grep longhorn
kubectl get storageclass longhorn
```

### Phase 9: Document Migration Results

Save migration results for future reference:

```bash
# Save final PVC state
kubectl get pvc -A -o wide > ~/migrations/post-migration-pvcs-$(date +%Y%m%d).txt

# Save restore results
velero restore describe <restore-name> > ~/migrations/migration-results-$(date +%Y%m%d).txt

# Document metrics:
cat > ~/migrations/migration-summary-$(date +%Y%m%d).md <<EOF
# Longhorn to Proxmox CSI Migration Summary

**Date**: $(date)
**Duration**: <total time>
**Data Migrated**: ~<total Gi>
**Applications Migrated**: <count>
**Namespaces Affected**: <count>

## Results
- Total PVCs migrated: <count>
- Failed restores: <count>
- Critical apps verified: <list>
- Space gained: <calculate 3x savings>

## Issues Encountered
<list any issues>

## Lessons Learned
<document insights>
EOF
```

## Troubleshooting

### Issue: Restore Shows PartiallyFailed

**Symptom**: Backup or restore status is "PartiallyFailed"

**Diagnosis**:
```bash
velero backup describe <backup-name>
velero restore describe <restore-name>
```

**Common causes**:
- Namespaces that don't exist (ignore if intentional)
- Pods in Failed state (data still backed up from running replicas)
- Warnings about missing resources (usually benign)

**Resolution**: Check errors vs warnings - warnings are usually OK if pod volume backups completed.

### Issue: PVC Stuck in Pending

**Symptom**: PVC shows "Pending" status after restore

**Diagnosis**:
```bash
kubectl describe pvc -n <namespace> <pvc-name>
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

**Common causes**:
- Proxmox CSI not running
- Insufficient storage capacity
- Pod volume restore still in progress

**Resolution**:
```bash
# Check Proxmox CSI
kubectl get pods -n csi-proxmox

# Check pod volume restore progress
kubectl get podvolumerestores -n velero | grep <namespace>

# Check Proxmox storage capacity
# Verify enough space is available
```

### Issue: Pod Won't Start After Restore

**Symptom**: Pod stuck in Pending, CrashLoopBackOff, or Error

**Diagnosis**:
```bash
kubectl describe pod -n <namespace> <pod-name>
kubectl logs -n <namespace> <pod-name>
```

**Common causes**:
- PVC still being provisioned (data restore in progress)
- Missing PodSecurity labels on namespace
- ExternalSecret not synced

**Resolution**:
```bash
# Wait for PVC to bind
kubectl get pvc -n <namespace>

# Add PodSecurity labels if needed (for privileged apps)
kubectl label namespace <namespace> \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged
```

### Issue: Data Not Restored to PVC

**Symptom**: PVC is bound but empty or incomplete

**Diagnosis**:
```bash
# Check pod volume restore status
velero restore describe <restore-name> --details | grep -A 20 "Pod Volume Restores"

# Check Kopia logs
kubectl logs -n velero -l name=node-agent | grep <namespace>

# Verify backup included pod volume backups
velero backup describe <backup-name> --details | grep -A 5 "Pod Volume"
```

**Common causes**:
- Backup didn't include pod volume backups (`defaultVolumesToFsBackup: false`)
- Kopia restore failed (check logs)
- Pod started before data restore completed

**Resolution**: Wait for pod volume restore to complete, or restore again with `--default-volumes-to-fs-backup` flag.

### Issue: Disk Space Exhausted During Migration

**Symptom**: PVCs pending, "no space left on device" errors

**Resolution**:
```bash
# Free up space by deleting old Longhorn PVs (after backup!)
kubectl get pv | grep Released
kubectl delete pv <released-pv-names>

# Check Proxmox storage capacity
# Ensure adequate space before continuing
```

### Issue: Manually Provisioned PVs Not Restored

**Symptom**: Pods stuck in Pending with "pod has unbound immediate PersistentVolumeClaims" error

**Diagnosis**:
```bash
# Check for PVCs without storageClassName
kubectl get pvc -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STORAGECLASS:.spec.storageClassName | grep '""'

# Describe the pending PVC
kubectl describe pvc -n <namespace> <pvc-name>
# Look for: "no storage class is set"
```

**Common causes**:
- PVC has `storageClassName: ""` (manually provisioned PV)
- NFS mounts or other external storage
- PVs were not included in Velero backup (only PVCs were)

**Resolution**:
```bash
# 1. Check if PV/PVC are defined in your git repository
find k8s/ -name "*.yaml" -exec grep -l "<pvc-name>" {} \;

# 2. Reapply the PV and PVC definitions
kubectl apply -f k8s/path/to/pv.yaml
kubectl apply -f k8s/path/to/pvc.yaml

# 3. Verify PVC binds
kubectl get pvc -n <namespace> <pvc-name>
```

**Example**: In our migration, `media-share` (NFS volume for actual media files) wasn't migrated by Velero because it had no storageClassName. We had to reapply the NFS PV and PVC manually from our git repository.

### Issue: WaitForFirstConsumer Pods Stuck Pending

**Symptom**: PVCs in Pending state, waiting for pod to be scheduled, but pod won't schedule because PVC is unbound

**Diagnosis**:
```bash
# Check storage class binding mode
kubectl get storageclass proxmox-csi -o yaml | grep volumeBindingMode
# If shows: volumeBindingMode: WaitForFirstConsumer

# Describe PVC
kubectl describe pvc -n <namespace> <pvc-name>
# Look for: "waiting for pod <pod-name> to be scheduled"

# Describe pod
kubectl describe pod -n <namespace> <pod-name>
# Look for: "pod has unbound immediate PersistentVolumeClaims"
```

**Cause**: Chicken-and-egg problem where PVC won't bind until pod is scheduled, but pod won't schedule until PVC is bound.

**Resolution**:
```bash
# Annotate PVC with selected node
kubectl annotate pvc -n <namespace> <pvc-name> volume.kubernetes.io/selected-node=<node-name>

# Or delete and recreate the pod to trigger rescheduling
kubectl delete pod -n <namespace> <pod-name>
```

## ReadWriteMany (RWX) Considerations

**Important**: Proxmox CSI **only supports ReadWriteOnce (RWO)**, not ReadWriteMany (RWX).

If you have PVCs using RWX access mode:

1. **Verify RWX is actually needed** - Many applications claim RWX but work fine with RWO
2. **Refactor to RWO** - Use pod affinity to keep pods on the same node
3. **Deploy NFS storage** - For true multi-writer needs, deploy an NFS-based storage class

During our migration, we converted all RWX PVCs to RWO without issues.

## Migration Metrics

Our migration results (December 2025):

- **Total Storage**: ~550Gi migrated
- **Applications**: 24 applications across 16 namespaces
- **PVCs**: 37 PersistentVolumeClaims
- **Duration**: ~2 hours (backup + restore + verification)
- **Space Gained**: 3x usable capacity (no Longhorn replicas)
- **Success Rate**: 100% (all applications functional)
- **Critical Apps**: qdrant, prowlarr, immich photo library, PostgreSQL databases
- **Downtime**: ~30-60 minutes per application

## References

- [Velero Setup](../controllers/velero-backup.md)
- [Velero Storage Class Mapping](../controllers/velero-storage-class-mapping.md)
- [Proxmox CSI Setup](../controllers/proxmox-csi.md)
- [Test Restore Procedure](../../disaster/test-restore-procedure.md)
- [Longhorn Uninstall Guide](https://longhorn.io/docs/1.10.1/deploy/uninstall/)
- [Velero Official Documentation](https://velero.io/docs/)

## Support

If you encounter issues during migration:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review Velero logs: `kubectl logs -n velero deployment/velero`
3. Check Proxmox CSI logs: `kubectl logs -n csi-proxmox -l app=proxmox-csi-controller`
4. Open an issue in the repository with:
   - Velero backup/restore describe output
   - Pod/PVC describe output
   - Relevant logs
