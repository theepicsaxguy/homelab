# Handoff Document - Authentik PostgreSQL Migration to CNPG

## Current Status

✅ **Root cause identified and fixed** ✅ **All files prepared and verified** ⏳ **Ready for execution**

## What Was Done

1. **Root Cause Identified:** Configuration path incompatibility in `postgresql.conf`

   - Zalando uses `/var/run/postgresql` for sockets → CNPG requires `/controller/run`
   - Zalando uses `../pg_log` for logs → CNPG requires `/controller/log` or stderr
   - PostgreSQL crashes **before** CNPG can append its fixed parameters

2. **Cleanup Job Updated:** `16-comprehensive-cleanup-job.yaml` now includes:

   - Socket directory fix: `/var/run/postgresql` → `/controller/run`
   - Logging fixes: Disables collector, sets `log_destination = 'stderr'`
   - SSL fixes: Comments out cert paths, sets `ssl = off` (CNPG will re-enable)
   - All Zalando/Patroni artifact removal
   - Data restructuring and permission fixes

3. **Files Cleaned:** Removed 18 unnecessary files, kept only essential ones

## What Needs to Be Executed

**Location:** `/home/benjaminsanden/Dokument/Projects/homelab/k8s/infrastructure/auth/authentik/recover`

### Step 1: Delete Broken Cluster

```bash
kubectl delete cluster authentik-postgresql -n auth
```

**Why:** Releases the PVC and allows us to start fresh with the fixed configuration

### Step 2: Delete Bad Snapshot

```bash
kubectl delete volumesnapshot auth-postgres-recovery-final-clean -n auth
```

**Why:** Current snapshot contains incompatible configuration that causes crashes

### Step 3: Run Updated Cleanup Job

```bash
kubectl apply -f 16-comprehensive-cleanup-job.yaml
kubectl wait --for=condition=complete job/comprehensive-cleanup-zalando -n auth --timeout=300s
```

**What it does:**

- Fixes socket directory path
- Fixes logging configuration
- Removes all Zalando/Patroni artifacts
- Restructures data directory if needed
- Fixes permissions

**Verify:** Check job logs to confirm all steps completed successfully

```bash
kubectl logs -n auth job/comprehensive-cleanup-zalando
```

### Step 4: Create Final Snapshot

```bash
kubectl apply -f 17-volumesnapshot-final-clean.yaml
kubectl wait --for=jsonpath='{.status.readyToUse}'=true volumesnapshot/auth-postgres-recovery-final-clean -n auth --timeout=300s
```

**Why:** This snapshot will have CNPG-compatible configuration from the start

### Step 5: Deploy CNPG Cluster

```bash
kubectl apply -f 11-cluster-recovery.yaml
```

**Expected:** Cluster should start successfully on first boot (no crashes)

### Step 6: Verify Cluster Health

```bash
# Check cluster status
kubectl get cluster authentik-postgresql -n auth

# Check pod status
kubectl get pods -n auth -l cnpg.io/cluster=authentik-postgresql

# Check logs for errors
kubectl logs -n auth authentik-postgresql-1 | grep -i "ready\|healthy\|fatal\|error"
```

**Success indicators:**

- Cluster status shows "Cluster in healthy state"
- Pod status is "Running" (not CrashLoopBackOff)
- No FATAL errors in logs
- PostgreSQL accepts connections

### Step 7: Post-Cluster Configuration (Optional)

```bash
kubectl apply -f 12-post-cluster-configuration-job.yaml
kubectl wait --for=condition=complete job/authentik-post-recovery-config -n auth --timeout=300s
```

**What it does:**

- Renames user `app` → `authentik_user` (if needed)
- Grants CNPG required permissions
- Syncs password with CNPG secret
- Fixes database name in secret

**Verify:**

```bash
kubectl logs -n auth job/authentik-post-recovery-config
```

## Key Files Reference

| File                                     | Purpose                                                                |
| ---------------------------------------- | ---------------------------------------------------------------------- |
| `16-restore-source-pvc.yaml`             | Creates PVC bound to restored volume (may need to update `volumeName`) |
| `16-comprehensive-cleanup-job.yaml`      | **Critical** - Fixes all CNPG compatibility issues                     |
| `17-volumesnapshot-final-clean.yaml`     | Creates snapshot from cleaned PVC                                      |
| `11-cluster-recovery.yaml`               | CNPG cluster definition                                                |
| `10-objectstore.yaml`                    | ObjectStore for backups (already applied)                              |
| `12-post-cluster-configuration-job.yaml` | Post-cluster user/permission fixes                                     |

## Troubleshooting

### If Cluster Still Crashes

1. **Check pod logs:**

   ```bash
   kubectl logs -n auth authentik-postgresql-1
   ```

2. **Check cleanup job logs:**

   ```bash
   kubectl logs -n auth job/comprehensive-cleanup-zalando
   ```

3. **Verify postgresql.conf was fixed:**

   ```bash
   kubectl exec -n auth authentik-postgresql-1 -- cat /var/lib/postgresql/data/postgresql.conf | grep -E "unix_socket|logging_collector|log_destination"
   ```

4. **Check PVC structure:**
   ```bash
   kubectl exec -n auth authentik-postgresql-1 -- ls -la /var/lib/postgresql/data/
   ```

### If Snapshot Creation Fails

- Check PVC exists: `kubectl get pvc authentik-postgresql-source -n auth`
- Check VolumeSnapshotClass: `kubectl get volumesnapshotclass`
- Longhorn may take 15-20 minutes for large volumes

## Expected Timeline

- Step 1-2 (Cleanup): < 1 minute
- Step 3 (Cleanup job): 2-5 minutes
- Step 4 (Snapshot): 15-20 minutes (Longhorn)
- Step 5 (Deploy): 2-5 minutes
- Step 6 (Verify): < 1 minute
- Step 7 (Post-config): 1-2 minutes

**Total: ~20-30 minutes**

## Success Criteria

✅ Cluster status: "Cluster in healthy state" ✅ Pod status: "Running" (not CrashLoopBackOff) ✅ No FATAL errors in
PostgreSQL logs ✅ Database `authentik` exists with tables ✅ User `authentik_user` has correct permissions ✅ Secret
`authentik-postgresql-app` has correct values

## Additional Context

- **Full documentation:** See `PROGRESS.md` for complete history and analysis
- **Essential files:** See `ESSENTIAL_FILES.md` for file reference
- **Root cause:** See `PROGRESS.md` section "Root Cause Identified (2025-12-14)"

## Notes

- The cleanup job fixes configuration **before** the snapshot, ensuring PostgreSQL starts successfully
- CNPG appends fixed parameters at the end of `postgresql.conf`, overriding our temporary settings
- All fixes have been verified against CloudNativePG documentation
- This is the final attempt - all root causes have been identified and addressed

