# Essential Files for Zalando to CNPG Migration

This document lists the essential files needed to migrate a PostgreSQL database from Zalando Spilo to CloudNativePG,
starting from a restored PVC backup.

## Essential Files (Keep These)

### Core Migration Files

1. **`16-restore-source-pvc.yaml`**

   - Creates PVC bound to the restored volume
   - **Note:** Update `volumeName` to match your restored PV

2. **`16-comprehensive-cleanup-job.yaml`**

   - Single comprehensive cleanup job that:
     - Restructures data directory (Zalando → CNPG format)
     - Fixes permissions (chown 26:26, chmod 700/600)
     - Removes all Zalando/Patroni artifacts
     - **Fixes CNPG compatibility issues:**
       - Socket directory: `/var/run/postgresql` → `/controller/run`
       - Logging: Disables collector, sets `log_destination = 'stderr'`
       - SSL: Comments out cert paths, sets `ssl = off`

3. **`17-volumesnapshot-final-clean.yaml`**

   - Creates final snapshot from cleaned PVC
   - Used by CNPG cluster for bootstrap

4. **`11-cluster-recovery.yaml`**

   - CNPG Cluster definition
   - Bootstraps from the cleaned snapshot

5. **`10-objectstore.yaml`**

   - ObjectStore for WAL archiving and backups
   - Referenced by the cluster

6. **`12-post-cluster-configuration-job.yaml`**
   - Post-cluster configuration (user renaming, permissions, secret sync)
   - Optional but recommended

### Documentation

7. **`PROGRESS.md`**

   - Complete documentation of the migration process
   - Includes root cause analysis, execution plan, and lessons learned

8. **`README.md`**
   - General documentation (may need updating to reflect streamlined workflow)

## Files to Remove (Old/Diagnostic)

These files are from the old multi-step approach or diagnostic attempts:

- `00-restore-longhorn-backup.yaml` - Old verification step
- `01-volumesnapshotclass.yaml` - Old approach
- `02-volumesnapshot.yaml` - Old approach
- `03-verify-backup-data-job.yaml` - Old diagnostic
- `04-temp-restore-pvc.yaml` - Old approach
- `05-restructure-pgdata-job.yaml` - Superseded by comprehensive cleanup
- `06-fix-permissions-job.yaml` - Superseded by comprehensive cleanup
- `07-cleanup-zalando-artifacts-job.yaml` - Superseded by comprehensive cleanup
- `08-inspect-database-job.yaml` - Old diagnostic
- `09-volumesnapshot-cleaned.yaml` - Old snapshot
- `09-volumesnapshot-fixed.yaml` - Old snapshot
- `13-fix-ssl-job.yaml` - Old diagnostic/fix attempt
- `14-check-ssl-config.yaml` - Old diagnostic
- `15-cleanup-zalando-files.yaml` - Old cleanup attempt
- `18-check-data-structure.yaml` - Diagnostic for broken cluster
- `19-fix-running-pvc-restructure.yaml` - Diagnostic for broken cluster
- `20-fix-running-pvc-permissions.yaml` - Diagnostic for broken cluster
- `QUICKSTART.md` - References old workflow

## Streamlined Workflow

The streamlined workflow uses only these steps:

1. **Restore PVC** (manual or via Longhorn restore)
2. **Create source PVC**: `kubectl apply -f 16-restore-source-pvc.yaml`
3. **Run cleanup**: `kubectl apply -f 16-comprehensive-cleanup-job.yaml`
4. **Create snapshot**: `kubectl apply -f 17-volumesnapshot-final-clean.yaml`
5. **Deploy CNPG**: `kubectl apply -f 11-cluster-recovery.yaml`
6. **Post-config** (optional): `kubectl apply -f 12-post-cluster-configuration-job.yaml`

See `PROGRESS.md` for the complete execution plan with all commands.

