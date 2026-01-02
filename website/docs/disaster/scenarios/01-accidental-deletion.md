---
sidebar_position: 1
title: 'Scenario 1: Accidental Deletion'
---

# Scenario 1: Accidental Deletion

## Symptoms

- A namespace, deployment, PVC, or database was accidentally deleted
- A recent configuration change broke an application
- Need to restore to a previous working state
- User error or automation mistake deleted critical resources

## Impact Assessment

- **Recovery Time Objective (RTO)**: 15-30 minutes
- **Recovery Point Objective (RPO)**: Up to 24 hours (daily backup) or 1 hour (GFS hourly backup)
- **Data Loss Risk**: Minimal to none (depends on backup age)
- **Service Availability**: Application down during restore

## Prerequisites

- `kubectl` access to the cluster with admin privileges
- Velero CLI installed (`velero` command available)
- Access to backup storage locations (MinIO or B2)
- Knowledge of what was deleted and when

## Recovery Procedure

### Step 1: Assess the Damage

First, identify what was deleted and when:

```bash
# Check recent events for deletion activity
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | grep -i delete

# List what's currently running (to see what's missing)
kubectl get pods,deployments,statefulsets -A

# Check PVC status
kubectl get pvc -A
```

### Step 2: List Available Backups

Choose the appropriate backup location:

**Option A: Local backups (faster, use when TrueNAS is available)**

```bash
# List all local backups
velero backup get

# List backups for specific namespace
velero backup get --selector includesNamespace=<namespace>

# Show backup details
velero backup describe <backup-name> --details
```

**Option B: Offsite backups (use when local infrastructure is unavailable)**

```bash
# List B2 offsite backups
velero backup get --storage-location backblaze-b2

# Check backup from specific date
velero backup get --storage-location backblaze-b2 --selector backup-type=weekly-offsite
```

### Step 3: Choose Recovery Scope

Select the appropriate restoration method based on what was deleted.

**Storage Class Considerations**

If restoring to different storage infrastructure than the original backup (e.g., from `longhorn` to `proxmox-csi`), you
need to configure storage class mapping. See
[Velero Storage Class Mapping](../../infrastructure/controllers/velero-storage-class-mapping.md) for complete
instructions.

Quick setup:

```bash
# Create storage class mapping ConfigMap
kubectl apply -f /path/to/homelab/k8s/infrastructure/controllers/velero/storage-class-mapping.yaml

# Verify mapping exists
kubectl get configmap -n velero change-storage-class-config
```

Once configured, all restores automatically apply the storage class transformation.

#### Option A: Restore Entire Namespace

Use this when a complete namespace was deleted or all resources in a namespace need restoration.

```bash
# Create restore from specific backup
velero restore create <restore-name> \
  --from-backup <backup-name> \
  --include-namespaces <namespace-name>

# Example: Restore the 'auth' namespace from daily backup
velero restore create restore-auth-$(date +%Y%m%d-%H%M%S) \
  --from-backup daily-20241227-020000 \
  --include-namespaces auth
```

**Monitor restoration progress:**

```bash
# Watch restore status
velero restore get <restore-name> -w

# Check restore logs
velero restore logs <restore-name>

# Describe restore for detailed status
velero restore describe <restore-name>
```

#### Option B: Restore Specific Resources

Use when only specific resources (PVC, deployment, etc.) were deleted.

```bash
# Restore specific PVCs only
velero restore create <restore-name> \
  --from-backup <backup-name> \
  --include-namespaces <namespace> \
  --include-resources persistentvolumeclaims,persistentvolumes

# Restore specific deployment
velero restore create <restore-name> \
  --from-backup <backup-name> \
  --include-namespaces <namespace> \
  --include-resources deployments \
  --selector app=<app-name>
```

#### Option C: Restore PostgreSQL Database Only

Use when only database data needs to be recovered (CNPG clusters).

**Recovery from B2:**

```yaml
# Create file: restore-database.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: <cluster-name>
  namespace: <namespace>
spec:
  instances: 2

  bootstrap:
    recovery:
      source: b2-backup
      recoveryTarget:
        # Option 1: Restore to specific timestamp
        # targetTime: "2024-12-27 10:00:00"

        # Option 2: Restore to latest backup
        targetImmediate: true

  externalClusters:
    - name: b2-backup
      barmanObjectStore:
        destinationPath: s3://homelab-cnpg-b2/<namespace>/<cluster-name>
        endpointURL: https://s3.us-west-002.backblazeb2.com
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

  storage:
    size: 20Gi
    storageClass: proxmox-csi # Use your cluster's default storage class
```

**Note**: If restoring to a different storage class than the original backup, see
[Velero Storage Class Mapping](../../infrastructure/controllers/velero-storage-class-mapping.md).

Apply the recovery:

```bash
# Delete the existing broken cluster (if exists)
kubectl -n <namespace> delete cluster <cluster-name>

# Apply recovery cluster
kubectl apply -f restore-database.yaml

# Monitor recovery
kubectl -n <namespace> get cluster <cluster-name> -w

# Check recovery logs
kubectl -n <namespace> logs -l cnpg.io/cluster=<cluster-name> -c postgres --tail=100
```

### Step 4: Validate Restoration

After restoration completes, verify the resources:

**Check Pod Status:**

```bash
# Verify all pods are running
kubectl -n <namespace> get pods

# Check for any issues
kubectl -n <namespace> describe pods
```

**Check PVC Status:**

```bash
# All PVCs should be Bound
kubectl -n <namespace> get pvc

# Verify volume attachments
kubectl -n <namespace> get volumeattachments
```

**Application-Specific Validation:**

```bash
# Check application logs
kubectl -n <namespace> logs <pod-name>

# Test application connectivity
kubectl -n <namespace> port-forward svc/<service-name> 8080:80
# Then access http://localhost:8080

# For databases, verify data
kubectl -n <namespace> exec -it <postgres-pod> -- psql -U postgres -c "SELECT COUNT(*) FROM <table>;"
```

### Step 5: Verify Data Integrity

Perform application-specific data checks:

**For PostgreSQL:**

```bash
kubectl -n <namespace> exec -it <postgres-pod> -- bash
# Inside container:
psql -U postgres

# Check database size
SELECT pg_database_size('<database-name>');

# Check table counts
SELECT schemaname, tablename, n_live_tup
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;

# Verify latest data timestamp
SELECT MAX(created_at) FROM <your_table>;
```

**For Application Data:**

- Login to application and verify functionality
- Check critical data exists
- Verify user accounts are accessible
- Test key workflows

## Post-Recovery Tasks

### 1. Document the Incident

Create an incident report:

```bash
# Create incident documentation
cat > docs/incidents/accidental-deletion-$(date +%Y%m%d).md <<EOF
# Accidental Deletion Incident

**Date**: $(date)
**Affected Namespace**: <namespace>
**Resources Deleted**: <list>
**Recovery Time**: <duration>
**Backup Used**: <backup-name>
**Data Loss**: <none/minimal/description>

## What Happened
<description of the incident>

## Recovery Steps Taken
1. <steps performed>

## Root Cause
<what led to the deletion>

## Prevention Measures
<what we're doing to prevent this>
EOF
```

### 2. Review RBAC Permissions

If deletion was accidental by a user/service account:

```bash
# Review who has delete permissions
kubectl auth can-i delete <resource> --as=<user> -n <namespace>

# Check role bindings
kubectl get rolebindings,clusterrolebindings -A | grep <user-or-sa>

# Consider adding resource quotas or RBAC restrictions
```

### 3. Enable Resource Safeguards

Consider adding finalizers or webhooks to prevent accidental deletion of critical resources:

```yaml
# Example: Add finalizer to critical PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: critical-data
  finalizers:
    - kubernetes.io/pvc-protection
```

### 4. Test Restore Procedure

Schedule regular restore tests to verify backups work:

```bash
# Create test namespace
kubectl create namespace restore-test

# Restore to test namespace
velero restore create test-restore-$(date +%Y%m%d) \
  --from-backup <backup-name> \
  --include-namespaces <source-namespace> \
  --namespace-mappings <source-namespace>:restore-test

# Validate, then cleanup
kubectl delete namespace restore-test
```

## Troubleshooting

### Restore Stuck in "InProgress"

```bash
# Check restore logs
velero restore logs <restore-name>

# Check Velero pod logs
kubectl -n velero logs deployment/velero

# Check for PVC binding issues
kubectl get pvc -A | grep Pending

# If Longhorn volumes are degraded
kubectl -n longhorn-system get volumes
```

### PVCs Not Binding After Restore

```bash
# Check Longhorn UI for volume health
# Manually scale volume replicas if needed

# Or force recreate volume
kubectl -n <namespace> delete pvc <pvc-name>
velero restore create ... # Re-run restore for that PVC
```

### Database Won't Start After Recovery

```bash
# Check PostgreSQL logs
kubectl -n <namespace> logs <postgres-pod> -c postgres

# Common issues:
# - Permissions: Check PVC ownership
# - Configuration: Verify cluster spec
# - WAL corruption: Try recovery from earlier backup

# Reset and try again
kubectl -n <namespace> delete cluster <cluster-name>
# Edit recovery spec to use earlier backup
kubectl apply -f restore-database.yaml
```

## Related Scenarios

- [Scenario 8: Data Corruption](08-data-corruption.md) - If restored data is corrupt
- [Scenario 7: Bad Config Change](07-bad-config-change.md) - If deletion was caused by automation

## Reference

- [Velero Restore Documentation](https://velero.io/docs/main/restore-reference/)
- [CNPG Recovery Documentation](https://cloudnative-pg.io/documentation/current/recovery/)
- Main disaster recovery guide: [Disaster Recovery Overview](../disaster-recovery.md)
