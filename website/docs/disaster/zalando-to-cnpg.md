# Recovering from Disaster: Migrating Zalando PostgreSQL to CloudNativePG After Total Data Loss

**Author's Note:** This is a real recovery story from a homelab disaster. I fucked up during a Longhorn upgrade debug
session and accidentally deleted all volumes. Everything. Gone. POOF. What follows is the exact steps we took to recover
a PostgreSQL database from a Longhorn backup that was stuck "waiting for leader" and migrate it to CloudNativePG. This
was debugged while tired, made mistakes along the way, but eventually succeeded. Your mileage may vary.

## The Disaster

**What happened:**

- Debugging a Longhorn upgrade issue in my homelab
- Accidentally deleted all Longhorn volumes
- Complete data loss across the cluster
- Had Longhorn backups, but the Zalando PostgreSQL cluster was already degraded when backed up
- The restored Zalando cluster was stuck in "waiting for leader" state
- Decided: fuck Spilo/Zalando, time to migrate to CloudNativePG (CNPG)

**Starting point:**

- PostgreSQL 18 data in a Longhorn backup
- Zalando postgres-operator cluster that won't start
- Application (PinePods) completely down
- No easy way forward with Zalando

## Prerequisites

Before starting, make sure you have:

- Longhorn 1.10.1+ with CSI snapshot support
- CloudNativePG operator 1.28.0+ installed
- Kubernetes snapshot controller and CRDs installed
- A Longhorn backup of your PostgreSQL PVC
- Coffee (or your preferred debugging beverage)

## Step 1: Install CSI Snapshot Support

Longhorn has its own native snapshots (`longhorn.io/v1beta2`), but CNPG needs standard Kubernetes VolumeSnapshots
(`snapshot.storage.k8s.io/v1`).

**Check if you have it:**

```bash
kubectl get crd | grep volumesnapshot
```

**If missing, install it:**

```bash
# Install snapshot CRDs (for Longhorn 1.10.1, use external-snapshotter v8.2.0)
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.2.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.2.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.2.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

# Install snapshot controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.2.0/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.2.0/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
```

**Verify:**

```bash
kubectl get deployment -n kube-system | grep snapshot
# Should show snapshot-controller running
```

## Step 2: Restore the Longhorn Backup to a PVC

Using Longhorn UI or CLI, restore your PostgreSQL backup to a new PVC. In my case:

- Original volume: The one I stupidly deleted
- Backup name: Some Longhorn-generated ID
- Restored PVC name: `backup-567d31d88427438f` (in namespace `pinepods`)

**Result:** You should have a PVC with your old PGDATA in it.

## Step 3: Create VolumeSnapshotClass for Longhorn

Create `01-volumesnapshotclass.yaml`:

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: longhorn-snapshot-vsc
driver: driver.longhorn.io
deletionPolicy: Retain
parameters:
  type: snap # Use 'snap' for in-cluster snapshots
```

**Apply it:**

```bash
kubectl apply -f 01-volumesnapshotclass.yaml
```

## Step 4: Create a VolumeSnapshot from the Restored PVC

Create `02-volumesnapshot.yaml`:

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: pinepods-postgres-recovery
  namespace: pinepods # Your namespace
spec:
  volumeSnapshotClassName: longhorn-snapshot-vsc
  source:
    persistentVolumeClaimName: backup-567d31d88427438f # Your restored PVC
```

**Apply it:**

```bash
kubectl apply -f 02-volumesnapshot.yaml
```

**Wait for it to be ready:**

```bash
kubectl wait --for=jsonpath='{.status.readyToUse}'=true \
  volumesnapshot/pinepods-postgres-recovery -n pinepods --timeout=300s
```

**Verify:**

```bash
kubectl get volumesnapshot -n pinepods pinepods-postgres-recovery
# STATUS should show readyToUse: true
```

## Step 5: Clean Zalando/Patroni Artifacts from Restored Data

**CRITICAL:** Before creating a snapshot, you MUST clean all Zalando/Patroni artifacts and fix CNPG compatibility
issues. PostgreSQL will crash immediately if incompatible configuration exists.

### Why This Step is Critical

Zalando PostgreSQL Operator (Spilo) uses different directory structures and configuration paths than CloudNativePG:

- **Socket directory:** Zalando uses `/var/run/postgresql` → CNPG requires `/controller/run`
- **Logging:** Zalando may use `../pg_log` → CNPG requires `/controller/log` or stderr
- **Data structure:** Zalando may use `pgroot/data` → CNPG expects `pgdata` at root
- **Configuration:** Zalando includes Patroni-specific settings that CNPG doesn't understand

**The Problem:** CNPG appends fixed parameters to `postgresql.conf` at the END, but if incompatible settings exist
earlier in the file, PostgreSQL crashes **before** CNPG can apply its overrides.

### Create a Comprehensive Cleanup Job

Create `02-comprehensive-cleanup-job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: comprehensive-cleanup-zalando
  namespace: your-namespace
spec:
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      securityContext:
        runAsNonRoot: true
        runAsUser: 26 # postgres user
        runAsGroup: 26
        fsGroup: 26
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: cleanup
          image: busybox
          command:
            - sh
            - -c
            - |
              set -e
              echo "=== COMPREHENSIVE ZALANDO/PATRONI CLEANUP ==="

              # Step 0: Restructure data directory if needed (Zalando -> CNPG)
              echo "=== Step 0: Checking and restructuring data directory ==="
              if [ -d /data/pgroot/data ] && [ ! -d /data/pgdata ]; then
                echo "⚠️  Zalando structure detected (/data/pgroot/data)"
                echo "Restructuring: moving pgroot/data to pgdata..."
                mv /data/pgroot/data /data/pgdata
                echo "✓ Data restructured to CNPG format"
              elif [ -d /data/pgdata ]; then
                echo "✓ CNPG structure already exists (/data/pgdata)"
              else
                echo "⚠️  WARNING: Neither pgroot/data nor pgdata found!"
                ls -la /data/
                exit 1
              fi

              # Remove any leftover pgroot directory (Zalando artifact)
              if [ -d /data/pgroot ] && [ -d /data/pgdata ]; then
                echo "⚠️  Removing leftover pgroot directory..."
                rm -rf /data/pgroot
                echo "✓ Removed leftover pgroot directory"
              fi

              cd /data/pgdata

              # Step 1: Remove Patroni-specific files
              echo "=== Step 1: Removing Patroni files ==="
              rm -f patroni.dynamic.json
              rm -f patroni.yml
              rm -f postgresql.base.conf
              rm -rf bootstrap 2>/dev/null || true
              echo "✓ Removed: patroni.dynamic.json, patroni.yml, postgresql.base.conf, bootstrap/"

              # Step 2: Remove recovery signal files (CNPG manages these automatically)
              echo "=== Step 2: Removing recovery signal files ==="
              rm -f recovery.signal
              rm -f standby.signal
              echo "✓ Removed: recovery.signal, standby.signal"

              # Step 3: Rewrite postgresql.conf cleanly for CNPG
              echo "=== Step 3: Rewriting postgresql.conf for CNPG compatibility ==="

              # Backup original
              cp postgresql.conf postgresql.conf.zalando-backup

              # Filter out Zalando/Patroni specific lines, preserve legitimate PostgreSQL settings
              awk 'BEGIN {ORS=""} \
                /Do not edit this file manually/ { next } \
                /It will be overwritten by Patroni/ { next } \
                /include.*postgresql.base.conf/ { next } \
                /^cluster_name/ { next } \
                /^bg_mon\./ { next } \
                /^unix_socket_directories/ { next } \
                /^logging_collector/ { next } \
                /^log_destination/ { next } \
                /^log_directory/ { next } \
                /^ssl_cert_file/ { next } \
                /^ssl_key_file/ { next } \
                /^ssl_ca_file/ { next } \
                /^ssl[[:space:]]*=[[:space:]]*on/ { next } \
                /^data_directory.*pgroot/ { next } \
                /^hba_file.*pgroot/ { next } \
                { print $0 "\n" }' postgresql.conf.zalando-backup | \
              sed 's/bg_mon,//g; s/,bg_mon//g; s/bg_mon//g' > postgresql.conf.clean

              # Create clean CNPG-compatible postgresql.conf
              {
                echo "# PostgreSQL configuration - cleaned for CNPG compatibility"
                echo "# Zalando/Patroni artifacts removed"
                echo "# CNPG will append its fixed parameters at the end"
                echo ""
                echo "# CNPG-compatible temporary settings (CNPG will override with fixed parameters)"
                echo "unix_socket_directories = '/controller/run'"
                echo "logging_collector = off"
                echo "log_destination = 'stderr'"
                echo "ssl = off"
                echo ""
              } > postgresql.conf

              # Append preserved legitimate PostgreSQL settings
              if [ -s postgresql.conf.clean ]; then
                echo "# Preserved legitimate PostgreSQL settings" >> postgresql.conf
                cat postgresql.conf.clean >> postgresql.conf
              fi

              rm -f postgresql.conf.clean
              echo "✓ postgresql.conf rewritten for CNPG compatibility"

              # Step 4: Fix permissions (critical for PostgreSQL to start)
              echo "=== Step 4: Fixing permissions ==="
              chown -R 26:26 /data/pgdata 2>&1 || true
              find /data/pgdata -type d -exec chmod 700 {} \; 2>&1 || true
              find /data/pgdata -type f -exec chmod 600 {} \; 2>&1 || true
              chmod 700 /data/pgdata 2>&1 || true
              echo "✓ Permissions fixed: 26:26 (postgres:postgres), dirs 700, files 600"

              echo "=== COMPREHENSIVE CLEANUP COMPLETE ==="
          volumeMounts:
            - name: data
              mountPath: /data
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: your-source-pvc-name # The PVC with restored data
```

**Key Points:**

- **Rewrite postgresql.conf cleanly** - Don't use multiple sed operations, rewrite the entire file
- **Remove pgroot directory** - Zalando structure leaves this behind
- **Fix permissions explicitly** - PostgreSQL requires 26:26 ownership and 700/600 permissions
- **Set CNPG-compatible paths** - Socket, logging, SSL must be fixed before snapshot

**Apply and wait:**

```bash
kubectl apply -f 02-comprehensive-cleanup-job.yaml
kubectl wait --for=condition=complete job/comprehensive-cleanup-zalando -n your-namespace --timeout=300s
kubectl logs -n your-namespace job/comprehensive-cleanup-zalando
```

## Step 6: Create MinIO ObjectStore for Backups (Optional but Recommended)

Create `03-objectstore.yaml`:

```yaml
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: pinepods-minio-store
  namespace: pinepods
spec:
  configuration:
    destinationPath: s3://homelab-postgres-backups/pinepods/pinepods-db
    endpointURL: https://your-minio-endpoint:9000
    s3Credentials:
      accessKeyId:
        name: your-minio-credentials-secret
        key: AWS_ACCESS_KEY_ID
      secretAccessKey:
        name: your-minio-credentials-secret
        key: AWS_SECRET_ACCESS_KEY
```

**Apply it:**

```bash
kubectl apply -f 03-objectstore.yaml
```

## Step 7: Create VolumeSnapshot from Cleaned PVC

**IMPORTANT:** The snapshot must be created from the cleaned PVC. The source volume must exist in Longhorn for the
snapshot to work.

Create `03-volumesnapshot-final-clean.yaml`:

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: your-postgres-recovery-final-clean
  namespace: your-namespace
spec:
  volumeSnapshotClassName: longhorn-snapshot-vsc
  source:
    persistentVolumeClaimName: your-source-pvc-name # The cleaned PVC
```

**Apply and wait:**

```bash
kubectl apply -f 03-volumesnapshot-final-clean.yaml
kubectl wait --for=jsonpath='{.status.readyToUse}'=true \
  volumesnapshot/your-postgres-recovery-final-clean -n your-namespace --timeout=1200s
```

**Note:** Longhorn snapshots can take 15-20 minutes for large volumes (20GB+). Be patient.

## Step 8: Create CNPG Cluster with Recovery Bootstrap

Create `04-cluster-recovery.yaml`:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: pinepods-db
  namespace: pinepods
spec:
  instances: 1
  imageName: ghcr.io/cloudnative-pg/postgresql:18
  enablePDB: false

  # THIS IS THE MAGIC - Bootstrap from volume snapshot
  bootstrap:
    recovery:
      volumeSnapshots:
        storage:
          name: pinepods-postgres-recovery
          kind: VolumeSnapshot
          apiGroup: snapshot.storage.k8s.io

  storage:
    size: 20Gi
    storageClass: proxmox-csi

  postgresql:
    parameters:
      max_connections: '200'
      shared_buffers: '256MB'

  plugins:
    - name: barman-cloud.cloudnative-pg.io
      isWALArchiver: true
      parameters:
        barmanObjectName: pinepods-minio-store

  resources:
    requests:
      cpu: '250m'
      memory: '512Mi'
    limits:
      memory: '1Gi'
```

**Apply it:**

```bash
kubectl apply -f 04-cluster-recovery.yaml
```

**Watch the recovery:**

```bash
kubectl get pods -n pinepods -w
```

You'll see:

1. `pinepods-db-1-snapshot-recovery-xxxxx` pod start (this does the recovery)
2. It completes
3. `pinepods-db-1` pod starts (your actual database)

**Check logs during recovery:**

```bash
kubectl logs -n pinepods pinepods-db-1-snapshot-recovery-xxxxx
```

## Step 9: Troubleshooting

### Volume Not Ready

**If you see:** `volume pvc-xxxxx is not ready for workloads`

This is normal! Longhorn is:

1. Creating a new volume from the snapshot
2. Copying/restoring data
3. Marking it ready

**Check the Longhorn volume status:**

```bash
kubectl get volume -n longhorn-system <volume-name> -o jsonpath='{.status.cloneStatus.state}'
```

Possible states:

- `copy-in-progress` - Still copying, be patient
- `copy-completed-awaiting-healthy` - Waiting for replicas
- `completed` - Ready to go

**If stuck on replica issues:**

```bash
# Temporarily reduce replicas to 1
kubectl patch volume -n longhorn-system <volume-name> \
  --type merge -p '{"spec":{"numberOfReplicas":1}}'
```

**Wait it out.** For a 20GB database, this can take several minutes.

### PostgreSQL Crashes Immediately (Exit Code 1)

**Symptoms:**

- PostgreSQL postmaster starts but exits immediately
- Pod in CrashLoopBackOff
- Logs show: `FATAL: could not load /home/postgres/pgdata/pgroot/data/pg_hba.conf`

**Root Cause:** Incompatible configuration paths in `postgresql.conf` or leftover Zalando directory structure.

**Solutions:**

1. **Check for pgroot directory:**

   ```bash
   kubectl exec -n your-namespace your-pod -- ls -la /var/lib/postgresql/data/
   ```

   If `pgroot` exists alongside `pgdata`, the cleanup job didn't remove it.

2. **Check postgresql.conf for old paths:**

   ```bash
   kubectl exec -n your-namespace your-pod -- grep -E "data_directory|hba_file|pgroot" /var/lib/postgresql/data/postgresql.conf
   ```

   If found, these must be removed.

3. **Verify socket and logging paths:**
   ```bash
   kubectl exec -n your-namespace your-pod -- grep -E "unix_socket|logging_collector|log_directory" /var/lib/postgresql/data/postgresql.conf
   ```
   Should show CNPG-compatible paths (`/controller/run`, etc.)

**Fix:** Re-run the cleanup job on the source PVC before creating a new snapshot.

### Longhorn Can't Find Source Volume

**Error:** `failed to verify data source: volume.longhorn.io "pvc-xxxxx" not found`

**Root Cause:** The snapshot references a source volume that no longer exists. Longhorn needs the source volume to exist
to restore from the snapshot.

**Solution:**

1. Identify which volume has your cleaned data
2. Recreate the source PVC pointing to that volume
3. Create a new snapshot from the recreated PVC
4. Deploy CNPG cluster from the new snapshot

**Prevention:** Don't delete the source PVC/volume until after the CNPG cluster is fully operational.

## Step 10: Verify Database Recovery

Once `pinepods-db-1` is running:

**Check PostgreSQL started:**

```bash
kubectl logs -n pinepods pinepods-db-1 | grep "database system is ready"
```

**List databases:**

```bash
kubectl exec -n pinepods pinepods-db-1 -- psql -U postgres -c "\l"
```

**List users:**

```bash
kubectl exec -n pinepods pinepods-db-1 -- psql -U postgres -c "\du"
```

**Check your data:**

```bash
kubectl exec -n pinepods pinepods-db-1 -- psql -U postgres -d pinepods -c "\dt"
kubectl exec -n pinepods pinepods-db-1 -- psql -U postgres -d pinepods -c "SELECT COUNT(*) FROM your_table;"
```

## Step 11: Fix User Permissions

**Problem we hit:** The restored database had the `app` user from Zalando, but it lacked the proper role memberships for
CNPG.

**Check current permissions:**

```bash
kubectl exec -n pinepods pinepods-db-1 -- psql -U postgres -c "\du app"
```

**Grant required permissions:**

```bash
kubectl exec -n pinepods pinepods-db-1 -- psql -U postgres <<EOF
GRANT pg_read_all_data TO app;
GRANT pg_write_all_data TO app;
GRANT CREATE ON DATABASE pinepods TO app;
ALTER USER app CREATEDB;
EOF
```

**Verify:**

```bash
kubectl exec -n pinepods pinepods-db-1 -- psql -U postgres -c "SELECT r.rolname, m.rolname as member_of FROM pg_roles r LEFT JOIN pg_auth_members am ON r.oid = am.member LEFT JOIN pg_roles m ON am.roleid = m.oid WHERE r.rolname = 'app';"
```

Should show:

```
 rolname |     member_of
---------+-------------------
 app     | pg_read_all_data
 app     | pg_write_all_data
```

## Step 12: Fix Password Mismatch

**Problem we hit:** CNPG generated a new password in the `pinepods-db-app` secret, but the database still had Zalando's
old password.

**Check for mismatch:**

```bash
# Get the secret password
kubectl get secret -n pinepods pinepods-db-app -o jsonpath='{.data.password}' | base64 -d
echo ""

# Get the database password hash
kubectl exec -n pinepods pinepods-db-1 -- psql -U postgres -c "SELECT rolpassword FROM pg_authid WHERE rolname='app';"
```

**Update database to match secret:**

```bash
NEW_PASSWORD=$(kubectl get secret -n pinepods pinepods-db-app -o jsonpath='{.data.password}' | base64 -d)

kubectl exec -n pinepods pinepods-db-1 -- psql -U postgres -c "ALTER USER app WITH PASSWORD '$NEW_PASSWORD';"
```

## Step 13: Remove Bootstrap Section from Cluster Manifest

**Critical step!** Once recovery is complete, you MUST remove the `bootstrap` section from your cluster manifest. It's
only for initial creation.

**Edit your cluster YAML and remove:**

```yaml
bootstrap:
  recovery:
    volumeSnapshots:
      storage:
        name: pinepods-postgres-recovery
        kind: VolumeSnapshot
        apiGroup: snapshot.storage.k8s.io
```

**Your cluster spec should now look like:**

```yaml
spec:
  instances: 1
  imageName: ghcr.io/cloudnative-pg/postgresql:18
  enablePDB: false

  storage:
    size: 20Gi
    storageClass: proxmox-csi

  # ... rest of your config
```

**Reapply:**

```bash
kubectl apply -f 04-cluster.yaml
```

## Step 12: Add Managed Roles (Optional but Recommended)

Add the `managed.roles` section to your cluster for future user management:

```yaml
spec:
  instances: 1
  imageName: ghcr.io/cloudnative-pg/postgresql:18

  managed:
    roles:
      - name: app
        ensure: present
        login: true
        passwordSecret:
          name: pinepods-db-app
        inRoles:
          - pg_read_all_data
          - pg_write_all_data

  # ... rest
```

## Step 15: Fix Database Name in Application Secret

**The gotcha that almost killed us:** The CNPG-generated secret defaulted to `dbname: app`, but our actual data was in
the `pinepods` database.

**Check the secret:**

```bash
kubectl get secret -n pinepods pinepods-db-app -o jsonpath='{.data.dbname}' | base64 -d
echo ""
```

**If it says `app` but your database is named something else, patch it:**

```bash
kubectl patch secret -n pinepods pinepods-db-app --type='json' -p='[
  {"op": "replace", "path": "/data/dbname", "value": "'$(echo -n "pinepods" | base64)'"}
]'
```

**Verify:**

```bash
kubectl get secret -n pinepods pinepods-db-app -o jsonpath='{.data.dbname}' | base64 -d
echo ""
# Should show: pinepods
```

## Step 16: Restart Your Application

**Finally, restart your app to pick up all the changes:**

```bash
kubectl rollout restart deployment -n pinepods pinepods
kubectl logs -n pinepods -l app.kubernetes.io/name=pinepods -f
```

**Watch for:**

```
Database setup completed successfully!
Database validation complete
```

## Step 15: Verify Everything Works

**Access your application and verify:**

- You can log in with your old credentials
- Your data is there (podcasts, episodes, etc.)
- New data can be created

**Check database activity:**

```bash
kubectl exec -n pinepods pinepods-db-1 -- psql -U postgres -d pinepods -c "SELECT COUNT(*) FROM \"Users\";"
kubectl exec -n pinepods pinepods-db-1 -- psql -U postgres -d pinepods -c "SELECT COUNT(*) FROM \"Podcasts\";"
kubectl exec -n pinepods pinepods-db-1 -- psql -U postgres -d pinepods -c "SELECT COUNT(*) FROM \"Episodes\";"
```

## Critical Learnings from Authentik Migration (2025-12-14)

### Workflow Order is Critical

**The correct order MUST be:**

1. **Restore backup to PVC** (or identify existing restored volume)
2. **Clean the PVC** (remove Zalando artifacts, fix config, fix permissions)
3. **Create snapshot** from cleaned PVC
4. **Deploy CNPG cluster** from snapshot

**File naming matters:** Use numbered prefixes (01-, 02-, 03-, 04-) to ensure correct execution order.

### CNPG Compatibility Issues

**PostgreSQL crashes immediately if incompatible configuration exists:**

1. **Socket directory path:**

   - Zalando: `unix_socket_directories = '/var/run/postgresql'`
   - CNPG: `unix_socket_directories = '/controller/run'`
   - **Fix:** Set to `/controller/run` before snapshot

2. **Logging configuration:**

   - Zalando: `logging_collector = on` with `log_directory = '../pg_log'`
   - CNPG: Expects `/controller/log` or stderr
   - **Fix:** Disable collector temporarily, set `log_destination = 'stderr'`

3. **SSL configuration:**

   - Zalando: May have cert file paths that don't exist in CNPG
   - **Fix:** Comment out cert paths, set `ssl = off` (CNPG will re-enable)

4. **Data directory structure:**

   - Zalando: May use `pgroot/data` structure
   - CNPG: Expects `pgdata` at root
   - **Fix:** Move `pgroot/data` → `pgdata`, remove `pgroot` directory

5. **Configuration file references:**
   - Zalando: May have `data_directory` or `hba_file` pointing to `pgroot` paths
   - **Fix:** Remove these settings (CNPG manages paths)

### Clean postgresql.conf Properly

**Don't use multiple sed operations** - rewrite the entire file cleanly:

- Filter out Zalando/Patroni-specific lines
- Preserve legitimate PostgreSQL settings
- Add CNPG-compatible temporary settings at the top
- CNPG will append its fixed parameters at the end

### Permissions Are Critical

PostgreSQL requires:

- **Ownership:** `26:26` (postgres:postgres)
- **Directories:** `700` (drwx------)
- **Files:** `600` (rw-------)

**Fix explicitly** in the cleanup job - don't rely on fsGroup alone.

### Longhorn Snapshot Requirements

**Critical:** The source volume must exist in Longhorn for the snapshot to work. When CNPG tries to restore from a
snapshot, Longhorn needs the source volume to verify/restore from it.

**If you see:** `failed to verify data source: volume.longhorn.io "pvc-xxxxx" not found`

**Solution:** Ensure the source PVC and its underlying volume exist before creating the snapshot.

## Lessons Learned

1. **Don't debug Longhorn upgrades when tired** - That's how you delete all volumes
2. **Longhorn backups are worth their weight in gold** - Even degraded ones
3. **Zalando/Spilo is powerful but complex** - Sometimes simpler is better
4. **CNPG is fantastic** - Clean recovery from volume snapshots just works
5. **Always check the database name in secrets** - Cost us 30 minutes of debugging
6. **CSI snapshots are different from native Longhorn snapshots** - Know the difference
7. **Test your backups BEFORE disaster strikes** - We got lucky
8. **Workflow order matters** - Clean before snapshot, snapshot before deploy
9. **Rewrite config files cleanly** - Multiple sed operations are error-prone
10. **CNPG compatibility must be fixed BEFORE snapshot** - PostgreSQL crashes before CNPG can apply fixes
11. **Longhorn needs source volume to exist** - Snapshots reference source volumes
12. **Permissions must be explicit** - Don't assume fsGroup handles everything

## Final Cluster Configuration

Here's the complete, working CNPG cluster manifest after recovery:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: pinepods-db
  namespace: pinepods
  labels:
    recurring-job.longhorn.io/source: enabled
    recurring-job-group.longhorn.io/gfs: enabled
spec:
  instances: 1
  imageName: ghcr.io/cloudnative-pg/postgresql:18
  enablePDB: false

  managed:
    roles:
      - name: app
        ensure: present
        login: true
        passwordSecret:
          name: pinepods-db-app
        inRoles:
          - pg_read_all_data
          - pg_write_all_data

  storage:
    size: 20Gi
    storageClass: proxmox-csi

  monitoring:
    enablePodMonitor: false

  postgresql:
    parameters:
      max_connections: '200'
      shared_buffers: '256MB'

  plugins:
    - name: barman-cloud.cloudnative-pg.io
      isWALArchiver: true
      parameters:
        barmanObjectName: pinepods-minio-store

  resources:
    requests:
      cpu: '250m'
      memory: '512Mi'
    limits:
      memory: '1Gi'

  affinity:
    enablePodAntiAffinity: true
    topologyKey: kubernetes.io/hostname
```

## Summary

**Total recovery time:** ~2 hours (including debugging, mistakes, and head-scratching)

**What we recovered:**

- 2 users
- 22 podcasts
- 5,993 episodes
- All application state and settings

**What we learned:**

- Never give up on your data
- Longhorn + CNPG is a powerful combination
- Sometimes the best solution is to migrate rather than fix
- Always double-check database names in secrets
- Coffee helps, but rest helps more

**Final status:** Application fully operational with all data intact, running on CloudNativePG instead of Zalando, with
proper backups configured to MinIO.

## Workflow Checklist

Use this checklist to ensure correct execution order:

- [ ] **Step 1:** Restore backup to PVC (or identify existing restored volume)
- [ ] **Step 2:** Create source PVC bound to restored volume
- [ ] **Step 3:** Run comprehensive cleanup job (removes Zalando artifacts, fixes config, fixes permissions)
- [ ] **Step 4:** Verify cleanup job logs show all steps completed
- [ ] **Step 5:** Create snapshot from cleaned PVC
- [ ] **Step 6:** Wait for snapshot to be ready (15-20 minutes for large volumes)
- [ ] **Step 7:** Deploy CNPG cluster from snapshot
- [ ] **Step 8:** Verify cluster health and PostgreSQL starts successfully
- [ ] **Step 9:** Fix user permissions if needed
- [ ] **Step 10:** Fix password mismatch if needed
- [ ] **Step 11:** Remove bootstrap section from cluster manifest
- [ ] **Step 12:** Verify application connects and data is accessible

## File Organization

**Recommended file naming (numbered for correct order):**

- `01-restore-source-pvc.yaml` - Creates PVC bound to restored volume
- `02-comprehensive-cleanup-job.yaml` - Cleans Zalando artifacts and fixes CNPG compatibility
- `03-volumesnapshot-final-clean.yaml` - Creates snapshot from cleaned PVC
- `04-cluster-recovery.yaml` - Deploys CNPG cluster from snapshot
- `10-objectstore.yaml` - ObjectStore for backups (can be created anytime)
- `12-post-cluster-configuration-job.yaml` - Optional post-cluster fixes

**Why numbering matters:** The workflow must be executed in order. Numbered files make it clear which step comes next.

---

_This documentation was created from real recovery scenarios in a homelab environment. Your situation may differ. Always
test in a non-production environment first. And for the love of all that is holy, don't delete your volumes when you're
tired._
