# Recovering from Disaster: Migrating Zalando PostgreSQL to CloudNativePG After Total Data Loss

**Author's Note:** This is a real recovery story from a homelab disaster. I fucked up during a Longhorn upgrade debug session and accidentally deleted all volumes. Everything. Gone. POOF. What follows is the exact steps we took to recover a PostgreSQL database from a Longhorn backup that was stuck "waiting for leader" and migrate it to CloudNativePG. This was debugged while tired, made mistakes along the way, but eventually succeeded. Your mileage may vary.

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

Longhorn has its own native snapshots (`longhorn.io/v1beta2`), but CNPG needs standard Kubernetes VolumeSnapshots (`snapshot.storage.k8s.io/v1`).

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
  type: snap  # Use 'snap' for in-cluster snapshots
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
  namespace: pinepods  # Your namespace
spec:
  volumeSnapshotClassName: longhorn-snapshot-vsc
  source:
    persistentVolumeClaimName: backup-567d31d88427438f  # Your restored PVC
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

## Step 5: Create MinIO ObjectStore for Backups (Optional but Recommended)

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

## Step 6: Create CNPG Cluster with Recovery Bootstrap

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
    storageClass: longhorn

  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "256MB"

  plugins:
  - name: barman-cloud.cloudnative-pg.io
    isWALArchiver: true
    parameters:
      barmanObjectName: pinepods-minio-store

  resources:
    requests:
      cpu: "250m"
      memory: "512Mi"
    limits:
      memory: "1Gi"
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

## Step 7: Troubleshooting - Volume Not Ready

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

## Step 8: Verify Database Recovery

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

## Step 9: Fix User Permissions

**Problem we hit:** The restored database had the `app` user from Zalando, but it lacked the proper role memberships for CNPG.

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

## Step 10: Fix Password Mismatch

**Problem we hit:** CNPG generated a new password in the `pinepods-db-app` secret, but the database still had Zalando's old password.

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

## Step 11: Remove Bootstrap Section from Cluster Manifest

**Critical step!** Once recovery is complete, you MUST remove the `bootstrap` section from your cluster manifest. It's only for initial creation.

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
    storageClass: longhorn

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

## Step 13: Fix Database Name in Application Secret

**The gotcha that almost killed us:** The CNPG-generated secret defaulted to `dbname: app`, but our actual data was in the `pinepods` database.

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

## Step 14: Restart Your Application

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

## Lessons Learned

1. **Don't debug Longhorn upgrades when tired** - That's how you delete all volumes
2. **Longhorn backups are worth their weight in gold** - Even degraded ones
3. **Zalando/Spilo is powerful but complex** - Sometimes simpler is better
4. **CNPG is fantastic** - Clean recovery from volume snapshots just works
5. **Always check the database name in secrets** - Cost us 30 minutes of debugging
6. **CSI snapshots are different from native Longhorn snapshots** - Know the difference
7. **Test your backups BEFORE disaster strikes** - We got lucky

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
    storageClass: longhorn

  monitoring:
    enablePodMonitor: false

  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "256MB"

  plugins:
  - name: barman-cloud.cloudnative-pg.io
    isWALArchiver: true
    parameters:
      barmanObjectName: pinepods-minio-store

  resources:
    requests:
      cpu: "250m"
      memory: "512Mi"
    limits:
      memory: "1Gi"

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

**Final status:** Application fully operational with all data intact, running on CloudNativePG instead of Zalando, with proper backups configured to MinIO.

---

*This documentation was created from a real recovery scenario in a homelab environment. Your situation may differ. Always test in a non-production environment first. And for the love of all that is holy, don't delete your volumes when you're tired.*
