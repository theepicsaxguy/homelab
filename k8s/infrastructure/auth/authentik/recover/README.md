# Authentik PostgreSQL Recovery - Zalando to CloudNativePG Migration

<<<<<<< Updated upstream
This directory contains the complete **fully automated** recovery process for migrating Authentik's PostgreSQL database
from Zalando PostgreSQL to CloudNativePG (CNPG) after a disaster.

## Prerequisites

- PVC `pvc-d90367da-3a78-4f7f-b112-4fbcb13cb7f4` has been restored from Zalando Spilo backup and exists in the `auth`
  namespace
=======
This directory contains the complete **fully automated** recovery process for migrating Authentik's PostgreSQL database from Zalando PostgreSQL to CloudNativePG (CNPG) after a disaster.

## Prerequisites

- Longhorn backup `backup-14c8704f5cbd43d0` exists (from 2025-12-02, ~16GB PostgreSQL data)
>>>>>>> Stashed changes
- CloudNativePG operator 1.28.0+ installed
- Longhorn CSI snapshot support (VolumeSnapshot CRDs and snapshot-controller)
- MinIO credentials secret `longhorn-minio-credentials` in the `auth` namespace

## Recovery Process Overview

<<<<<<< Updated upstream
This optimized recovery process: 0. **Verification Phase**: Verifies the restored PVC exists and is ready

1. **Preparation Phase**: Creates snapshots for safety
=======
This optimized recovery process:
0. **Restore Phase**: Restores Longhorn backup to a PVC
1. **Preparation Phase**: Creates snapshots and temporary workspace
>>>>>>> Stashed changes
2. **Data Transformation Phase**: Restructures, fixes permissions, and removes Zalando artifacts
3. **Inspection Phase**: Verifies database structure before migration
4. **Migration Phase**: Creates clean snapshot and bootstraps CNPG cluster
5. **Configuration Phase**: ONE consolidated job handles all post-cluster setup

**Key Improvements:**
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
- Zero manual steps - everything via `kubectl apply`
- Consolidated post-cluster configuration into ONE efficient job
- Proper ordering - all data manipulation happens BEFORE cluster creation
- Reduced complexity - removed redundant database connections
- Better error handling and verification

## Complete Recovery Steps

Execute these commands **in order**. Each step includes the wait command to ensure completion before proceeding.

<<<<<<< Updated upstream
### Step 0: Verify Restored PVC

This verifies that the PVC restored from Zalando Spilo backup exists and is ready for recovery.
=======
### Step 0: Restore Longhorn Backup to PVC
This restores the backup from December 2nd (before the disaster) to a new PVC.
>>>>>>> Stashed changes

```bash
kubectl apply -f 00-restore-longhorn-backup.yaml

<<<<<<< Updated upstream
# Wait for verification job to complete
kubectl wait --for=condition=complete --timeout=120s job/verify-restored-pvc -n auth

# Check job logs
kubectl logs -n auth job/verify-restored-pvc

# Verify PVC status
kubectl get pvc pvc-d90367da-3a78-4f7f-b112-4fbcb13cb7f4 -n auth
```

### Step 1: Create VolumeSnapshotClass

=======
# Wait for the PVC to be bound (this may take 5-15 minutes for a 16GB restore)
kubectl wait --for=jsonpath='{.status.phase}'=Bound \
  pvc/backup-14c8704f5cbd43d0 -n auth --timeout=900s

# Check Longhorn volume status
kubectl get volume -n longhorn-system -l pvc=backup-14c8704f5cbd43d0
```

### Step 1: Create VolumeSnapshotClass
>>>>>>> Stashed changes
```bash
kubectl apply -f 01-volumesnapshotclass.yaml
```

### Step 2: Create Initial Snapshot from Restored Backup
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
```bash
kubectl apply -f 02-volumesnapshot.yaml

# Wait for snapshot to be ready
kubectl wait --for=jsonpath='{.status.readyToUse}'=true \
  volumesnapshot/auth-postgres-recovery -n auth --timeout=300s
```

### Step 3: Verify Backup Data Structure
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
```bash
kubectl apply -f 03-verify-backup-data-job.yaml

# Wait and check logs
kubectl wait --for=condition=complete --timeout=120s job/verify-backup-data -n auth
kubectl logs -n auth job/verify-backup-data
```

### Step 4: Create Temporary PVC for Data Manipulation
<<<<<<< Updated upstream

**⚠️ SKIPPED**: Longhorn's CSI driver doesn't support creating PVCs from Kubernetes VolumeSnapshots. Instead, we work
directly on the restored PVC (`pvc-d90367da-3a78-4f7f-b112-4fbcb13cb7f4`) since we already have a snapshot
(`auth-postgres-recovery`) for safety.

The transformation jobs (Steps 5-7) now work directly on the restored PVC. This is safe because:

1. We have a snapshot (`auth-postgres-recovery`) created in Step 2
2. The restored PVC can be modified safely
3. After transformation, we create a new snapshot in Step 9

**No action needed for Step 4.**

### Step 5: Restructure PostgreSQL Data Directory

=======
```bash
kubectl apply -f 04-temp-restore-pvc.yaml

# Wait for PVC to be bound (may take several minutes while Longhorn restores data)
kubectl wait --for=jsonpath='{.status.phase}'=Bound \
  pvc/temp-postgres-fix -n auth --timeout=600s
```

### Step 5: Restructure PostgreSQL Data Directory
>>>>>>> Stashed changes
Moves data from Zalando's `/pgroot/data` structure to CNPG's `/pgdata` structure.

```bash
kubectl apply -f 05-restructure-pgdata-job.yaml

# Wait and verify
kubectl wait --for=condition=complete --timeout=300s job/restructure-pgdata -n auth
kubectl logs -n auth job/restructure-pgdata
```

### Step 6: Fix File Permissions
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
Sets correct ownership (postgres 26:26) and permissions (700).

```bash
kubectl apply -f 06-fix-permissions-job.yaml

# Wait and verify
kubectl wait --for=condition=complete --timeout=300s job/fix-pgdata-permissions -n auth
kubectl logs -n auth job/fix-pgdata-permissions
```

### Step 7: Clean Up Zalando Artifacts
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
Removes Zalando-specific PostgreSQL extensions (bg_mon) and Patroni configuration.

```bash
kubectl apply -f 07-cleanup-zalando-artifacts-job.yaml

# Wait and verify
kubectl wait --for=condition=complete --timeout=300s job/fix-postgresql-conf -n auth
kubectl logs -n auth job/fix-postgresql-conf
```

### Step 8: Inspect Database (Optional but Recommended)
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
Temporarily starts PostgreSQL to inspect database structure, users, and tables.

```bash
kubectl apply -f 08-inspect-database-job.yaml

# Wait and review what's in the database
kubectl wait --for=condition=complete --timeout=300s job/inspect-postgres-database -n auth
kubectl logs -n auth job/inspect-postgres-database

# Look for:
# - Database name (should be 'authentik')
# - User name (might be 'app' from Zalando or 'authentik_user')
# - Tables in the authentik database
```

### Step 9: Create Final Snapshot with Clean Data
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
```bash
kubectl apply -f 09-volumesnapshot-fixed.yaml

# Wait for snapshot to be ready
kubectl wait --for=jsonpath='{.status.readyToUse}'=true \
  volumesnapshot/auth-postgres-recovery-fixed -n auth --timeout=300s
```

### Step 10: Create MinIO ObjectStore for Backups
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
```bash
kubectl apply -f 10-objectstore.yaml
```

### Step 11: Bootstrap CNPG Cluster from Fixed Snapshot
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
```bash
kubectl apply -f 11-cluster-recovery.yaml

# Watch the recovery process
kubectl get pods -n auth -w
# Press Ctrl+C once you see authentik-postgresql-1 running

# Wait for the cluster pod to be ready
kubectl wait --for=condition=ready --timeout=600s pod/authentik-postgresql-1 -n auth

# Verify database is running
kubectl logs -n auth authentik-postgresql-1 | grep "database system is ready"
```

### Step 12: Run Post-Cluster Configuration (ONE CONSOLIDATED JOB)
<<<<<<< Updated upstream

This single job handles:

=======
This single job handles:
>>>>>>> Stashed changes
- Detecting and renaming user if needed (app → authentik_user)
- Granting CNPG-required permissions
- Syncing database password with CNPG secret
- Fixing database name in secret
- Complete verification

```bash
kubectl apply -f 12-post-cluster-configuration-job.yaml

# Wait for job to complete
kubectl wait --for=condition=complete --timeout=300s job/authentik-post-recovery-config -n auth

# Review the complete configuration output
kubectl logs -n auth job/authentik-post-recovery-config
```

## Verification

After all steps complete:

```bash
# Check cluster status
kubectl get cluster -n auth authentik-postgresql

# Verify the database
kubectl exec -n auth authentik-postgresql-1 -- psql -U postgres -d authentik -c "\dt"

# Check secret configuration
echo "Database: $(kubectl get secret -n auth authentik-postgresql-app -o jsonpath='{.data.dbname}' | base64 -d)"
echo "Username: $(kubectl get secret -n auth authentik-postgresql-app -o jsonpath='{.data.username}' | base64 -d)"
echo "Host: $(kubectl get secret -n auth authentik-postgresql-app -o jsonpath='{.data.host}' | base64 -d)"
```

## Cleanup

Once the CNPG cluster is running and verified:

```bash
<<<<<<< Updated upstream
# Note: temp-postgres-fix PVC is not created (Step 4 skipped due to Longhorn limitation)

# Delete all completed jobs
kubectl delete job -n auth verify-restored-pvc
=======
# Delete temporary PVC
kubectl delete pvc temp-postgres-fix -n auth

# Delete all completed jobs
>>>>>>> Stashed changes
kubectl delete job -n auth verify-backup-data
kubectl delete job -n auth restructure-pgdata
kubectl delete job -n auth fix-pgdata-permissions
kubectl delete job -n auth fix-postgresql-conf
kubectl delete job -n auth inspect-postgres-database
kubectl delete job -n auth authentik-post-recovery-config

# Delete RBAC for post-recovery job
kubectl delete serviceaccount -n auth authentik-post-recovery
kubectl delete role -n auth authentik-post-recovery
kubectl delete rolebinding -n auth authentik-post-recovery

# Keep snapshots for disaster recovery:
<<<<<<< Updated upstream
# - auth-postgres-recovery (original from restored PVC)
# - auth-postgres-recovery-fixed (cleaned and ready for re-use)

# Optional: Delete the restored PVC after successful migration (only if you're certain)
# kubectl delete pvc pvc-d90367da-3a78-4f7f-b112-4fbcb13cb7f4 -n auth
=======
# - auth-postgres-recovery (original)
# - auth-postgres-recovery-fixed (cleaned and ready for re-use)
>>>>>>> Stashed changes
```

## Post-Recovery Steps

### 1. Update database.yaml
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
Remove the `bootstrap` section from `../database.yaml`:

```yaml
# Remove this entire section:
<<<<<<< Updated upstream
bootstrap:
  initdb:
    database: authentik
    owner: authentik_user
```

### 2. Add Managed Roles (Recommended)

=======
  bootstrap:
    initdb:
      database: authentik
      owner: authentik_user
```

### 2. Add Managed Roles (Recommended)
>>>>>>> Stashed changes
Add to `../database.yaml` for future user management:

```yaml
spec:
  instances: 2

  managed:
    roles:
      - name: authentik_user
        ensure: present
        login: true
        passwordSecret:
          name: authentik-postgresql-app
        inRoles:
          - pg_read_all_data
          - pg_write_all_data

  # ... rest of config
```

### 3. Scale to 2 Instances (Optional)
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
```bash
kubectl patch cluster -n auth authentik-postgresql --type='json' \
  -p='[{"op": "replace", "path": "/spec/instances", "value": 2}]'
```

### 4. Restart Authentik Application
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
```bash
kubectl rollout restart deployment -n auth authentik-server
kubectl rollout restart deployment -n auth authentik-worker

# Watch logs to ensure successful connection
kubectl logs -n auth -l app.kubernetes.io/name=authentik-server -f
```

## Troubleshooting

### Job Fails
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
```bash
# Check job logs
kubectl logs -n auth job/<job-name>

# Get detailed info
kubectl describe job -n auth <job-name>

# Delete and rerun
kubectl delete job -n auth <job-name>
kubectl apply -f <step-number>-<filename>.yaml
```

### VolumeSnapshot Stuck
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
```bash
# Check snapshot status
kubectl describe volumesnapshot -n auth <snapshot-name>

# Check Longhorn UI for volume clone status
# Look for: copy-in-progress, copy-completed-awaiting-healthy, completed
```

### CNPG Cluster Won't Start
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
```bash
# Check pod logs
kubectl logs -n auth authentik-postgresql-1

# Check cluster events
kubectl describe cluster -n auth authentik-postgresql

# Check recovery job logs (if exists)
kubectl logs -n auth -l cnpg.io/cluster=authentik-postgresql,role=bootstrap
```

### Post-Recovery Job Fails
<<<<<<< Updated upstream

The job is designed to be idempotent - it can be safely re-run:

=======
The job is designed to be idempotent - it can be safely re-run:
>>>>>>> Stashed changes
```bash
kubectl delete job -n auth authentik-post-recovery-config
kubectl apply -f 12-post-cluster-configuration-job.yaml
```

## File Manifest

<<<<<<< Updated upstream
| File                                     | Purpose                                                                              |
| ---------------------------------------- | ------------------------------------------------------------------------------------ |
| `00-restore-longhorn-backup.yaml`        | Verifies restored PVC `pvc-d90367da-3a78-4f7f-b112-4fbcb13cb7f4` exists and is ready |
| `01-volumesnapshotclass.yaml`            | VolumeSnapshotClass for Longhorn in-cluster snapshots                                |
| `02-volumesnapshot.yaml`                 | Initial snapshot from restored PVC (safety backup)                                   |
| `03-verify-backup-data-job.yaml`         | Verifies restored PVC contains PostgreSQL data                                       |
| `04-temp-restore-pvc.yaml`               | **SKIPPED** - Longhorn limitation, jobs work directly on restored PVC                |
| `05-restructure-pgdata-job.yaml`         | Converts Zalando → CNPG directory structure                                          |
| `06-fix-permissions-job.yaml`            | Fixes ownership to postgres (26:26) and chmod 700                                    |
| `07-cleanup-zalando-artifacts-job.yaml`  | Removes bg_mon extension and patroni.dynamic.json                                    |
| `08-inspect-database-job.yaml`           | Inspects database/user structure before migration                                    |
| `09-volumesnapshot-fixed.yaml`           | Final snapshot with all fixes applied                                                |
| `10-objectstore.yaml`                    | MinIO backup configuration for CNPG                                                  |
| `11-cluster-recovery.yaml`               | CNPG cluster bootstrap from fixed snapshot                                           |
| `12-post-cluster-configuration-job.yaml` | **Consolidated** user/password/secret configuration                                  |
=======
| File | Purpose |
|------|---------|
| `00-restore-longhorn-backup.yaml` | **NEW**: Restores Longhorn backup to PVC via VolumeSnapshot |
| `01-volumesnapshotclass.yaml` | VolumeSnapshotClass for Longhorn in-cluster snapshots |
| `02-volumesnapshot.yaml` | Initial snapshot from restored backup PVC |
| `03-verify-backup-data-job.yaml` | Verifies backup PVC contains PostgreSQL data |
| `04-temp-restore-pvc.yaml` | Temporary PVC for data manipulation |
| `05-restructure-pgdata-job.yaml` | Converts Zalando → CNPG directory structure |
| `06-fix-permissions-job.yaml` | Fixes ownership to postgres (26:26) and chmod 700 |
| `07-cleanup-zalando-artifacts-job.yaml` | Removes bg_mon extension and patroni.dynamic.json |
| `08-inspect-database-job.yaml` | Inspects database/user structure before migration |
| `09-volumesnapshot-fixed.yaml` | Final snapshot with all fixes applied |
| `10-objectstore.yaml` | MinIO backup configuration for CNPG |
| `11-cluster-recovery.yaml` | CNPG cluster bootstrap from fixed snapshot |
| `12-post-cluster-configuration-job.yaml` | **Consolidated** user/password/secret configuration |
>>>>>>> Stashed changes

## Design Principles

1. **Zero Manual Steps** - Everything via `kubectl apply` commands
2. **Fail Fast** - Each job checks preconditions and exits with clear errors
3. **Idempotent** - Jobs can be safely re-run if they fail
4. **Consolidated** - Related operations grouped into single jobs to reduce complexity
5. **Observable** - Clear logging at each step for easy troubleshooting
6. **Clean** - TTL on jobs for automatic cleanup after success

## Migration Time Estimate

<<<<<<< Updated upstream
| Phase                           | Time               |
| ------------------------------- | ------------------ |
| Verification (Step 0)           | < 1 minute         |
| Snapshots (Steps 1-2)           | 3-5 minutes        |
| Data verification (Step 3)      | 1-2 minutes        |
| Data transformation (Steps 5-7) | 2-3 minutes        |
| Inspection (Step 8)             | 1-2 minutes        |
| Final snapshot (Step 9)         | 3-5 minutes        |
| Cluster bootstrap (Steps 10-11) | 5-10 minutes       |
| Post-config (Step 12)           | 1-2 minutes        |
| **Total**                       | **~17-26 minutes** |

_Times may vary based on data size and storage performance_

## Success Criteria

✅ All jobs completed successfully (check with `kubectl get jobs -n auth`) ✅ Cluster shows 1/1 ready instances ✅
Database "authentik" exists and contains tables ✅ User "authentik_user" has correct permissions ✅ Secret has database
name "authentik" ✅ Authentik application can connect and function
=======
| Phase | Time |
|-------|------|
| Snapshots (Steps 1-4) | 5-10 minutes |
| Data transformation (Steps 5-7) | 2-3 minutes |
| Inspection (Step 8) | 1-2 minutes |
| Final snapshot (Step 9) | 3-5 minutes |
| Cluster bootstrap (Steps 10-11) | 5-10 minutes |
| Post-config (Step 12) | 1-2 minutes |
| **Total** | **~20-30 minutes** |

*Times may vary based on data size and storage performance*

## Success Criteria

✅ All jobs completed successfully (check with `kubectl get jobs -n auth`)
✅ Cluster shows 1/1 ready instances
✅ Database "authentik" exists and contains tables
✅ User "authentik_user" has correct permissions
✅ Secret has database name "authentik"
✅ Authentik application can connect and function
>>>>>>> Stashed changes

## References

- [CloudNativePG Bootstrap Documentation](https://cloudnative-pg.io/documentation/current/bootstrap/)
- [Longhorn CSI Snapshot Support](https://longhorn.io/docs/latest/snapshots-and-backups/csi-snapshot-support/)
- Parent documentation: `../../../website/docs/disaster/zalando-to-cnpg.md`
