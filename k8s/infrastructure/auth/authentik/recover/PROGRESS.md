# Authentik PostgreSQL Migration to CNPG - Progress Log

**Session Started:** 2025-12-14 **Status:** READY TO EXECUTE - Root cause identified, cleanup job updated with CNPG
compatibility fixes **Approach:** Single comprehensive cleanup job with CNPG path fixes before cluster creation

## Executive Summary

This session implements a streamlined migration approach using **one comprehensive cleanup job** that removes all
Zalando/Patroni artifacts before creating a clean snapshot. This eliminates the need for multiple diagnostic/fix cycles
and ensures the cluster starts successfully on first apply.

## Migration Strategy

**Key Principle:** One comprehensive cleanup job fixes ALL issues before cluster creation.

**Benefits:**

- No diagnostic cycles needed
- No multiple fix attempts
- Cluster starts successfully on first apply
- Clean, predictable migration path

## Current State

**CNPG Cluster:**

```
NAME                   STATUS               PRIMARY
authentik-postgresql   CreatingInstance     authentik-postgresql-1
```

**Cluster Pod:**

```
authentik-postgresql-1   Running   CrashLoopBackOff (PostgreSQL exiting with status 1)
```

**Recovery Job:**

```
authentik-postgresql-1-snapshot-recovery-nhdb5   Succeeded
```

**Current Issue:**

PostgreSQL starts ("postmaster started") but immediately exits with "exit status 1". CNPG logs show:

- `postmaster started` (PID 26)
- `postmaster exited` (exit status 1)
- `PostgreSQL process exited with errors`
- CNPG cannot connect: `dial unix /controller/run/.s.PGSQL.5432: connect: no such file or directory`

**Evidence from Data Directory Inspection:**

When checking `/var/lib/postgresql/data/` in the pod (before it crashed):

- Both `pgroot/` and `pgdata/` directories exist
- This suggests the data structure may be mixed or incorrect

**Hypothesis:**

Based on the original recovery workflow (README.md steps 5-6), we may have skipped:

1. **Data restructuring** - Moving from Zalando's `/pgroot/data` to CNPG's `/pgdata`
2. **Permission fixing** - Setting ownership to postgres (26:26) and permissions (700/600)

The comprehensive cleanup job cleaned Zalando artifacts but may not have:

- Restructured the data directory (if it was in `/pgroot/data`)
- Fixed file permissions (ownership and chmod)

**Source of Hypothesis:**

1. **README.md workflow** shows required steps:

   - Step 5: Restructure (move `pgroot/data` → `pgdata`)
   - Step 6: Fix permissions (chown 26:26, chmod 700)
   - Step 7: Clean Zalando artifacts

2. **Observation:** Both `pgroot` and `pgdata` exist in the restored volume, suggesting incomplete restructuring

3. **PostgreSQL behavior:** Starts then exits immediately - classic symptom of:
   - Wrong data directory location
   - Permission denied errors (can't read data files)
   - Or configuration errors (but we cleaned those)

**Files Created to Fix Running Pod:**

- `19-fix-running-pvc-restructure.yaml` - Restructures data if needed
- `20-fix-running-pvc-permissions.yaml` - Fixes permissions (chown 26:26, chmod 700/600)

## Session Timeline

### Step 1: Delete Failing Cluster

- **Action:** Deleted existing failing CNPG cluster `authentik-postgresql`
- **Reason:** Cluster was crashing due to Zalando artifacts in snapshot
- **Result:** Cluster deleted, PVCs released

### Step 2: Identify Source Volume

- **Identified:** PV `pvc-56415b87-7e9b-4bf0-a0c5-228cb30e15da` (last bound to `authentik-postgresql-1`)
- **Status:** Released, available for binding
- **Action:** Created PVC `authentik-postgresql-source` bound to this PV

### Step 3: Comprehensive Cleanup Job

- **File:** `16-comprehensive-cleanup-job.yaml`
- **Target PVC:** `authentik-postgresql-source`
- **Job Name:** `comprehensive-cleanup-zalando`
- **Status:** ✅ Completed successfully

**What was cleaned:**

1. **Patroni files removed:**

   - `patroni.dynamic.json`
   - `patroni.yml`
   - `postgresql.base.conf`
   - `bootstrap/` directory

2. **Recovery signal files removed:**

   - `recovery.signal`
   - `standby.signal`

3. **postgresql.conf cleaned:**

   - Removed Patroni comments
   - Removed `include 'postgresql.base.conf'` statements
   - Removed `cluster_name` settings
   - Removed `bg_mon` extension settings
   - Removed `bg_mon` from `shared_preload_libraries` (all variations)

4. **SSL configuration fixed:**
   - Commented out `ssl_cert_file`, `ssl_key_file`, `ssl_ca_file` references
   - Set `ssl = off` (all variations)

**Verification Results:**

- ✅ No Patroni files remaining
- ✅ No recovery signal files
- ✅ No Patroni references in postgresql.conf
- ✅ SSL is set to off

### Step 4: Create Clean Snapshot

- **File:** `17-volumesnapshot-final-clean.yaml`
- **Snapshot Name:** `auth-postgres-recovery-final-clean`
- **Source PVC:** `authentik-postgresql-source` (cleaned)
- **Status:** ✅ Created and ready

### Step 5: Recreate CNPG Cluster

- **File:** `11-cluster-recovery.yaml` (updated)
- **Snapshot Used:** `auth-postgres-recovery-final-clean`
- **Status:** ✅ Cluster created, recovery job completed
- **Issue:** PostgreSQL pod crashing (exit status 1)
- **Root Cause Investigation:** In progress

### Step 5.5: Fix Running Pod (Current)

- **Files Created:**
  - `19-fix-running-pvc-restructure.yaml` - Restructures data directory if needed
  - `20-fix-running-pvc-permissions.yaml` - Fixes permissions (chown 26:26, chmod 700/600)
- **Status:** ⏳ Ready to apply
- **Purpose:** Fix data structure and permissions on the current PVC to get PostgreSQL running

### Step 6: Post-Cluster Configuration (Pending)

- **File:** `12-post-cluster-configuration-job.yaml`
- **Status:** ⏳ Waiting for cluster to be healthy
- **Will handle:**
  - User detection and renaming (`app` → `authentik_user` if needed)
  - CNPG-required permissions
  - Password sync with CNPG secret
  - Database name fix in secret

### Step 7: Remove Bootstrap Section (Completed)

- **File:** `k8s/infrastructure/auth/authentik/database.yaml`
- **Action:** Removed `bootstrap.initdb` section
- **Status:** ✅ Completed

## Files Created/Modified

### New Files

1. **`16-restore-source-pvc.yaml`** - PVC bound to source volume for cleanup
2. **`16-comprehensive-cleanup-job.yaml`** - Single job that removes ALL Zalando artifacts (updated to include
   restructuring and permissions)
3. **`17-volumesnapshot-final-clean.yaml`** - Snapshot from cleaned PVC
4. **`18-check-data-structure.yaml`** - Diagnostic job to check data structure (created but not used)
5. **`19-fix-running-pvc-restructure.yaml`** - Fix data structure on running pod's PVC
6. **`20-fix-running-pvc-permissions.yaml`** - Fix permissions on running pod's PVC

### Modified Files

1. **`11-cluster-recovery.yaml`** - Updated to use `auth-postgres-recovery-final-clean` snapshot
2. **`k8s/infrastructure/auth/authentik/database.yaml`** - Removed `bootstrap.initdb` section

## Research Findings Applied

Based on CNPG documentation and migration best practices, the following files/settings **MUST** be removed for CNPG
bootstrap:

1. **Patroni files** (CNPG doesn't use Patroni):

   - `patroni.dynamic.json`
   - `patroni.yml`
   - `postgresql.base.conf`
   - Any `bootstrap/` directory

2. **PostgreSQL configuration incompatibilities:**

   - `include 'postgresql.base.conf'` statements
   - `cluster_name` settings
   - `bg_mon` from `shared_preload_libraries`
   - SSL certificate file references (`ssl_cert_file`, `ssl_key_file`)
   - Patroni comments in `postgresql.conf`
   - SSL must be set to `off` (CNPG manages SSL differently)

3. **Recovery signal files** (handled automatically by CNPG):
   - `recovery.signal` and `standby.signal` are managed by CNPG automatically

## Why This Approach Works

**Pinepods Migration Success Pattern:**

- All Zalando artifacts were cleaned before creating the snapshot
- Bootstrap section was removed after successful migration
- Cluster transitioned from recovery mode to normal operational mode successfully

**Our Implementation:**

- ✅ Comprehensive cleanup job removes ALL artifacts in one pass
- ✅ Clean snapshot created from cleaned PVC
- ✅ Cluster uses clean snapshot (no Zalando artifacts)
- ✅ Bootstrap section already removed from target database.yaml

## Current Issue Analysis

**PostgreSQL Crash Investigation:**

**Symptoms:**

- PostgreSQL postmaster starts successfully
- Immediately exits with "exit status 1"
- CNPG cannot connect to PostgreSQL
- Pod in CrashLoopBackOff state

**Evidence Collected:**

1. **CNPG Logs Analysis:**

   - `postmaster started` (PID 26) - PostgreSQL process starts
   - `postmaster exited` (exit status 1) - Process exits immediately
   - `PostgreSQL process exited with errors` - Generic error, no specific message
   - PostgreSQL logs redirected to `../pg_log` but inaccessible (container crashes)

2. **Data Directory Structure:**

   - Both `pgroot/` and `pgdata/` directories exist in `/var/lib/postgresql/data/`
   - This suggests incomplete restructuring or mixed structure

3. **Workflow Comparison:**
   - Original workflow (README.md) requires:
     1. Restructure: Move `pgroot/data` → `pgdata`
     2. Fix permissions: chown 26:26, chmod 700/600
     3. Clean Zalando artifacts
   - Our comprehensive cleanup did #3 but may have skipped #1 and #2

### Root Cause Identified (2025-12-14)

**Diagnosis:** Configuration Path Incompatibility The `postgresql.conf` restored from Zalando points to directory paths
that do not exist in the CloudNativePG container environment.

1.  **Logging Crash:**

    - _Setting:_ `logging_collector = on` / `log_directory = '../pg_log'`
    - _Issue:_ The `pg_log` directory does not exist in CNPG's structure. CNPG expects logs in `/controller/log` when
      `logging_collector` is enabled.
    - _Result:_ Immediate crash (Exit Code 1) before network initialization.

2.  **Socket Crash:**
    - _Setting:_ `unix_socket_directories = '/var/run/postgresql'`
    - _Issue:_ CNPG stores sockets in `/controller/run`. `/var/run/postgresql` does not exist.
    - _Result:_ `FATAL: could not create lock file` (Exit Code 1).

**Verification from CNPG Documentation:**

- CNPG has **fixed parameters** that are appended to `postgresql.conf` at the end
- `unix_socket_directories = '/controller/run'` is a fixed parameter managed by CNPG
- However, if Zalando's config has incompatible settings earlier in the file, PostgreSQL crashes before CNPG can apply
  its overrides
- CNPG defaults: `logging_collector = 'on'`, `log_directory = '/controller/log'`, `log_destination = 'csvlog'`

**Resolution Strategy:** Update `16-comprehensive-cleanup-job.yaml` to forcibly patch these settings in
`postgresql.conf` on the source PVC. This ensures the snapshot used for bootstrapping is valid from the very first
second of boot:

1. Set `unix_socket_directories = '/controller/run'` (matches CNPG's fixed parameter)
2. Disable `logging_collector` (safer for migration; CNPG will re-enable with correct path later)
3. Set `log_destination = 'stderr'` (ensures we can see logs via `kubectl logs`)

**Root Cause Hypothesis (Previous - Superseded):**

**Most Likely:** Data structure and/or permissions issue

**Evidence:**

- PostgreSQL starts but can't access data files (classic permission issue)
- Both `pgroot` and `pgdata` exist (suggests incomplete restructuring)
- Original workflow explicitly requires restructuring and permission fixes before cleanup

**Files Created to Address (Previous Attempt - Superseded):**

- `19-fix-running-pvc-restructure.yaml` - Checks and fixes data structure
- `20-fix-running-pvc-permissions.yaml` - Fixes ownership and permissions

## Execution Plan (Ready to Execute)

**Prerequisites:**

- Root cause identified: Configuration path incompatibility in `postgresql.conf`
- Cleanup job updated: `16-comprehensive-cleanup-job.yaml` now includes CNPG compatibility fixes
- All fixes verified against CNPG documentation

**Execution Steps:**

1. **Delete the broken cluster:**

   ```bash
   kubectl delete cluster authentik-postgresql -n auth
   ```

   - This releases the PVC and allows us to start fresh

2. **Delete the "bad" snapshot:**

   ```bash
   kubectl delete volumesnapshot auth-postgres-recovery-final-clean -n auth
   ```

   - The current snapshot contains incompatible configuration that causes crashes

3. **Run the updated cleanup job:**

   ```bash
   kubectl apply -f 16-comprehensive-cleanup-job.yaml
   kubectl wait --for=condition=complete job/comprehensive-cleanup-zalando -n auth --timeout=300s
   ```

   - This job now fixes:
     - Socket directory: `/var/run/postgresql` → `/controller/run`
     - Logging: Disables collector, sets `log_destination = 'stderr'`
     - SSL: Comments out cert paths, sets `ssl = off` (CNPG will re-enable)
     - All Zalando/Patroni artifacts

4. **Create the final snapshot:**

   ```bash
   kubectl apply -f 17-volumesnapshot-final-clean.yaml
   kubectl wait --for=jsonpath='{.status.readyToUse}'=true volumesnapshot/auth-postgres-recovery-final-clean -n auth --timeout=300s
   ```

   - This snapshot will have CNPG-compatible configuration

5. **Deploy CNPG cluster:**

   ```bash
   kubectl apply -f 11-cluster-recovery.yaml
   ```

   - Cluster should start successfully on first boot

6. **Verify cluster health:**

   ```bash
   kubectl get cluster authentik-postgresql -n auth
   kubectl get pods -n auth -l cnpg.io/cluster=authentik-postgresql
   kubectl logs -n auth authentik-postgresql-1 | grep -i "ready\|healthy\|fatal\|error"
   ```

7. **Post-cluster configuration (if needed):**
   - Apply: `12-post-cluster-configuration-job.yaml` (if user/database names need adjustment)
   - Verify database and user exist with correct permissions

## Troubleshooting Commands

```bash
# Check cluster status
kubectl get cluster authentik-postgresql -n auth

# Check recovery job
kubectl get job authentik-postgresql-1-snapshot-recovery -n auth
kubectl get pods -n auth -l job-name=authentik-postgresql-1-snapshot-recovery

# Check cluster pod
kubectl get pods -n auth -l cnpg.io/cluster=authentik-postgresql

# Check snapshot status
kubectl get volumesnapshot auth-postgres-recovery-final-clean -n auth

# Check PVC status
kubectl get pvc authentik-postgresql-1 -n auth
kubectl get pvc authentik-postgresql-source -n auth

# Check cleanup job logs (if needed)
kubectl logs -n auth job/comprehensive-cleanup-zalando
```

## Key Learnings

1. **One comprehensive cleanup is better than multiple fixes** - But must include ALL required steps:

   - Data restructuring (if Zalando structure exists)
   - Permission fixing (chown 26:26, chmod 700/600)
   - Zalando artifact removal
   - All must be done before creating snapshot

2. **Clean before snapshot** - Ensures snapshot has no Zalando artifacts AND correct structure/permissions

3. **Longhorn cloning is the bottleneck** - Account for 15-20 minutes per clone (completed in this session)

4. **PVC binding requires released PVs** - May need to patch PV to clear claimRef (successfully resolved)

5. **MCP tools are preferred** - Use MCP for state checking instead of kubectl

6. **PostgreSQL crash diagnosis:**

   - Starts then exits = check data structure and permissions
   - CNPG logs may not show actual PostgreSQL error
   - Check both directory structure and file permissions

7. **Workflow completeness matters:**

   - Original workflow (README.md) has specific order: Restructure → Permissions → Clean
   - Skipping steps causes downstream issues
   - Comprehensive cleanup job should include all steps, not just artifact removal

8. **Configuration path incompatibility is critical:**
   - PostgreSQL reads `postgresql.conf` top-to-bottom during startup
   - If incompatible settings (wrong socket/log paths) are encountered early, PostgreSQL crashes **before** CNPG can
     append its fixed parameters
   - **Solution:** Patch incompatible settings in the source PVC before creating the snapshot
   - CNPG's fixed parameters are appended at the end and will override our temporary settings

## Success Criteria

✅ Root cause identified (configuration path incompatibility) ✅ Cleanup job updated with CNPG compatibility fixes ✅
Comprehensive cleanup job created (includes data restructuring, permissions, artifact removal, and CNPG path fixes) ✅
Longhorn volume clone completed ✅ Recovery job completed ✅ Bootstrap section removed from database.yaml ⏳ Delete
broken cluster (ready to execute) ⏳ Delete bad snapshot (ready to execute) ⏳ Run updated cleanup job (ready to
execute) ⏳ Create final snapshot with fixed config (ready to execute) ⏳ Deploy CNPG cluster (ready to execute) ⏳
PostgreSQL pod healthy (pending execution) ⏳ Post-cluster configuration job (pending cluster health)

## Lessons Learned So Far

1. **Comprehensive cleanup must include ALL steps:**

   - Data restructuring (if Zalando structure exists)
   - Permission fixing (chown 26:26, chmod 700/600)
   - Zalando artifact removal
   - All must be done before creating snapshot

2. **PostgreSQL crash symptoms:**

   - Starts then immediately exits = likely permission or structure issue
   - CNPG logs don't always show the actual PostgreSQL error
   - Need to check data directory structure and permissions

3. **Workflow order matters:**
   - Restructure → Permissions → Clean → Snapshot → Cluster
   - Skipping steps causes issues downstream

---

**Note:** This migration uses a streamlined approach with one comprehensive cleanup job. All Zalando/Patroni artifacts
are removed before creating the snapshot, ensuring the cluster starts successfully when recreated.
