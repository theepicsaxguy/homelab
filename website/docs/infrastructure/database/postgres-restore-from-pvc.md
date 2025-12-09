---
sidebar_position: 2
title: Restore PostgreSQL From PVC
description: Restore a Zalando Postgres Operator cluster using Patroni when PGDATA exists on a PVC
---

# Restore PostgreSQL From PVC (Zalando Postgres Operator)

This document describes how to restore a Zalando Postgres Operator cluster when the Patroni cluster is stopped but valid PGDATA exists on a PVC. This situation occurs when:
- The cluster failed to bootstrap (e.g., network issues, configuration problems)
- The postgresql CR was recreated and bound to empty PVCs instead of existing data
- Patroni shows replicas as "stopped" with no leader

## Current Situation Analysis

Based on the actual cluster state:
```
+ Cluster: authentik-postgresql (7511307886480003131) ------+----+-----------+
| Member                 | Host         | Role    | State   | TL | Lag in MB |
+------------------------+--------------+---------+---------+----+-----------+
| authentik-postgresql-0 | 10.244.4.222 | Replica | stopped |    |   unknown |
+------------------------+--------------+---------+---------+----+-----------+
```

Issues identified:
- Patroni cluster exists but member is in "stopped" state
- No leader elected (cannot perform `patronictl reinit` without a leader)
- Current PVC `pgdata-authentik-postgresql-0` is empty (new)
- Data exists on old PVC `pgdata-authentik-postgresql-1`

## Prerequisites

- `kubectl` access with permissions to delete/create resources in the target namespace
- The Zalando postgres-operator is running
- You have identified the PVC containing valid PGDATA
- You understand that this procedure will delete and recreate the postgresql CR

## Recovery Strategy

The Zalando operator does not support `patronictl reinit` when no leader exists. The correct procedure is:

1. **Delete the postgresql CR** - This removes the StatefulSet and stops operator reconciliation
2. **Delete the empty PVC(s)** - Remove PVCs that don't contain data
3. **Rename the PVC with data** - Ensure it matches the expected naming pattern
4. **Recreate the postgresql CR** - Operator will discover existing PGDATA and bootstrap from it
5. **Verify Patroni bootstrap** - Confirm cluster starts with existing data

## Step-by-Step Procedure

### 1. Verify which PVC contains data

List PVCs and inspect their mount structure:

```bash
export KUBECONFIG=/home/develop/homelab/config
kubectl get pvc -n auth

# For authentik example:
# pgdata-authentik-postgresql-0 (20Gi) - EMPTY (newly created)
# pgdata-authentik-postgresql-1 (15Gi) - CONTAINS DATA (old cluster)
```

Create an inspection pod to verify PGDATA structure:

```bash
export KUBECONFIG=/home/develop/homelab/config
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: inspect-old-pvc
  namespace: auth
spec:
  restartPolicy: Never
  containers:
  - name: inspect
    image: postgres:17
    command: ["sh", "-c", "ls -la /mnt/pgroot/data/ && cat /mnt/pgroot/data/PG_VERSION 2>/dev/null && sleep 300"]
    volumeMounts:
    - name: olddata
      mountPath: /mnt
  volumes:
  - name: olddata
    persistentVolumeClaim:
      claimName: pgdata-authentik-postgresql-1
EOF

# Watch logs to see directory contents
kubectl logs -n auth inspect-old-pvc -f

# Clean up
kubectl delete pod -n auth inspect-old-pvc
```

Expected output should show `base/`, `global/`, `pg_wal/`, `PG_VERSION`, etc.

### 2. Delete the postgresql CR

This stops the operator from managing the cluster and removes the StatefulSet:

```bash
export KUBECONFIG=/home/develop/homelab/config
kubectl delete postgresql -n auth authentik-postgresql
```

Wait for pods to terminate:

```bash
kubectl get pods -n auth -w
```

### 3. Delete empty PVCs and rename the data PVC

Delete the empty PVC(s):

```bash
export KUBECONFIG=/home/develop/homelab/config
kubectl delete pvc -n auth pgdata-authentik-postgresql-0
```

The operator expects PVCs named `pgdata-<cluster-name>-<ordinal>`. For a 2-replica cluster starting fresh:
- The first replica (pod 0) needs `pgdata-authentik-postgresql-0`
- The second replica (pod 1) needs `pgdata-authentik-postgresql-1`

**Option A: Single replica (recommended for recovery)**

If you want to start with 1 replica, rename the data PVC to match ordinal 0:

```bash
export KUBECONFIG=/home/develop/homelab/config

# Create a VolumeSnapshot if your storage class supports it (recommended for safety)
cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: authentik-pgdata-backup
  namespace: auth
spec:
  volumeSnapshotClassName: longhorn-snapshot
  source:
    persistentVolumeClaimName: pgdata-authentik-postgresql-1
EOF

# Clone the PVC to the expected name
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pgdata-authentik-postgresql-0
  namespace: auth
  labels:
    recurring-job.longhorn.io/source: enabled
    recurring-job-group.longhorn.io/gfs: enabled
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  dataSource:
    name: authentik-pgdata-backup
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  resources:
    requests:
      storage: 20Gi
EOF
```

**Option B: Use existing PVC-1 directly (if keeping 2 replicas)**

If `pgdata-authentik-postgresql-1` already has data and you want 2 replicas, keep it and create a new empty PVC for ordinal 0. The operator will use PVC-1's data as the source for initialization.

### 4. Update the postgresql CR for recovery

Modify `k8s/infrastructure/auth/authentik/database.yaml` to temporarily use 1 replica for bootstrap:

```yaml
apiVersion: "acid.zalan.do/v1"
kind: postgresql
metadata:
  name: authentik-postgresql
  namespace: auth
  labels:
    recurring-job.longhorn.io/source: enabled
    recurring-job-group.longhorn.io/gfs: enabled
spec:
  teamId: "auth"
  volume:
    size: 20Gi
  numberOfInstances: 1  # Changed from 2 to 1 for recovery
  users:
    authentik_user:
      - superuser
      - createdb
  databases:
    authentik: authentik_user
  enableLogicalBackup: false
  postgresql:
    version: "17"
  enableConnectionPooler: false
  resources:
    requests:
      cpu: 200m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1Gi
```

Apply the CR:

```bash
export KUBECONFIG=/home/develop/homelab/config
kubectl apply -f k8s/infrastructure/auth/authentik/database.yaml
```

### 5. Monitor Patroni bootstrap

Watch the pod logs to confirm Patroni discovers existing PGDATA and bootstraps:

```bash
export KUBECONFIG=/home/develop/homelab/config
kubectl logs -n auth authentik-postgresql-0 -f
```

Expected log messages:
- Patroni should detect existing PGDATA
- Bootstrap from existing data directory
- Leader election occurs
- Cluster becomes healthy

Check Patroni cluster status:

```bash
export KUBECONFIG=/home/develop/homelab/config
kubectl exec -n auth authentik-postgresql-0 -- patronictl list
```

Expected output:
```
+ Cluster: authentik-postgresql (7511307886480003131) -------+----+-----------+
| Member                 | Host         | Role   | State    | TL | Lag in MB |
+------------------------+--------------+--------+----------+----+-----------+
| authentik-postgresql-0 | 10.244.x.x   | Leader | running  |  X |           |
+------------------------+--------------+--------+----------+----+-----------+
```

### 6. Verify database contents

Once the cluster is running, verify data integrity:

```bash
export KUBECONFIG=/home/develop/homelab/config
kubectl port-forward -n auth svc/authentik-postgresql 5432:5432 &

# Connect and verify
psql -h localhost -p 5432 -U authentik_user -d authentik -c '\dt'
psql -h localhost -p 5432 -U authentik_user -d authentik -c 'SELECT COUNT(*) FROM authentik_core_user;'
```

### 7. Scale back to 2 replicas (optional)

After confirming the leader is healthy, scale back to 2 replicas:

```bash
# Edit database.yaml and change numberOfInstances back to 2
kubectl apply -f k8s/infrastructure/auth/authentik/database.yaml
```

The second replica will initialize from the leader using `pg_basebackup`.

### 8. Verify application connectivity

Check that authentik pods can connect:

```bash
export KUBECONFIG=/home/develop/homelab/config
kubectl logs -n auth authentik-server-<pod-id> | grep -i database
kubectl logs -n auth authentik-worker-<pod-id> | grep -i database
```

## Troubleshooting

### Patroni shows "waiting for leader to bootstrap"

This means Patroni cannot find valid PGDATA or initialize a new cluster. Causes:
- PVC is empty or PGDATA path is wrong
- Permissions issue (PGDATA not owned by postgres user)
- Postgres version mismatch

Check PGDATA contents:

```bash
kubectl exec -n auth authentik-postgresql-0 -- ls -la /home/postgres/pgdata/pgroot/data/
```

### "cluster doesn't have any members" error

This occurs when trying `patronictl reinit` without a running leader. You cannot reinitialize a completely stopped cluster. Use the delete/recreate procedure above instead.

### PVC clone/snapshot fails

If VolumeSnapshot is not available, use a manual copy:

```bash
export KUBECONFIG=/home/develop/homelab/config

# Create target PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pgdata-authentik-postgresql-0
  namespace: auth
  labels:
    recurring-job.longhorn.io/source: enabled
    recurring-job-group.longhorn.io/gfs: enabled
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 20Gi
EOF

# Copy data
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: copy-pgdata
  namespace: auth
spec:
  restartPolicy: Never
  containers:
  - name: copy
    image: alpine:3.18
    command: ["sh", "-c", "apk add rsync && rsync -av /src/ /dst/ && echo 'Copy complete'"]
    volumeMounts:
    - name: src
      mountPath: /src
    - name: dst
      mountPath: /dst
  volumes:
  - name: src
    persistentVolumeClaim:
      claimName: pgdata-authentik-postgresql-1
  - name: dst
    persistentVolumeClaim:
      claimName: pgdata-authentik-postgresql-0
EOF

# Monitor copy
kubectl logs -n auth copy-pgdata -f

# Clean up
kubectl delete pod -n auth copy-pgdata
```

### Postgres version mismatch

Ensure the `postgresql.version` in the CR matches the `PG_VERSION` file in PGDATA. Check with:

```bash
kubectl exec -n auth inspect-old-pvc -- cat /mnt/pgroot/data/PG_VERSION
```

## Alternative: Restore via logical backup

If you prefer to start completely fresh instead of using existing PGDATA:

1. **Extract data from old PVC**: Mount the old PVC in a standalone Postgres pod and export with `pg_dump`
2. **Create new cluster**: Apply the postgresql CR with empty PVCs
3. **Import backup**: Restore the dump into the new cluster

This approach is safer for major version upgrades or when the existing PGDATA is suspected to be corrupted.

## Summary

The Zalando postgres-operator expects to manage cluster lifecycle through Kubernetes resources. When Patroni fails to bootstrap due to missing or misconfigured PGDATA:

1. **DO NOT** attempt `patronictl reinit` without a running leader
2. **DO** delete and recreate the postgresql CR
3. **DO** ensure PVC naming matches expected pattern: `pgdata-<cluster-name>-<ordinal>`
4. **DO** verify PGDATA exists and matches the Postgres version in the CR
5. **DO** use VolumeSnapshots before making changes to preserve rollback options

The operator will automatically discover existing valid PGDATA and bootstrap Patroni from it.

