---
sidebar_position: 4
title: CNPG Troubleshooting
description: Common issues and solutions for CloudNativePG clusters
---

# CloudNativePG Troubleshooting

This guide covers common issues when running CloudNativePG (CNPG) clusters with Barman backup integration.

## WAL Volume Full - Disk Space Issues

### Symptoms
- Pod stuck in `CrashLoopBackOff` with 1/2 containers ready
- Error logs showing: `"Detected low-disk space condition, avoid starting the instance"`
- Cluster status shows: `"Not enough disk space"` or `"Insufficient disk space detected"`
- Pod cannot start PostgreSQL instance

### Root Causes
1. **WAL files not being archived**: Files accumulate in `/var/lib/postgresql/wal/pg_wal/` when Barman archiving fails
2. **Incorrect Barman configuration**: Wrong `destinationPath` in ObjectStore prevents proper archiving
3. **Timeline mismatch**: Old WAL files from previous timelines not cleaned up after failover

### Diagnosis

Check the pod logs for disk space errors:
```bash
kubectl logs -n <namespace> <pod-name> -c postgres --tail=50
# Look for: "Detected low-disk space condition"
```

Check actual disk usage on a running pod:
```bash
kubectl exec -n <namespace> <pod-name> -c plugin-barman-cloud -- \
  python3 -c "import os; st = os.statvfs('/var/lib/postgresql/wal'); \
  print(f'{st.f_bavail / st.f_blocks * 100:.1f}% free')"
```

Check for stuck WAL files waiting to be archived:
```bash
kubectl exec -n <namespace> <pod-name> -c plugin-barman-cloud -- \
  python3 -c "
import os
wal_dir = '/var/lib/postgresql/wal/pg_wal'
ready_files = len([f for f in os.listdir(f'{wal_dir}/archive_status') if f.endswith('.ready')])
print(f'Files waiting to archive: {ready_files}')
"
```

Check cluster status:
```bash
kubectl get cluster -n <namespace> <cluster-name> -o jsonpath='{.status.phase}'
```

### Solution

#### 1. Fix Barman ObjectStore Configuration

Ensure your MinIO/S3 ObjectStore uses the **cluster name**, not a specific pod name:

**Wrong:**
```yaml
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: my-minio-store
spec:
  configuration:
    destinationPath: s3://bucket/namespace/my-cluster-1  # ❌ Pod-specific
```

**Correct:**
```yaml
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: my-minio-store
spec:
  configuration:
    destinationPath: s3://bucket/namespace/my-cluster  # ✅ Cluster name
```

Apply the fix:
```bash
kubectl apply -f your-database.yaml
```

#### 2. Clean Up Stuck WAL Files

If the replica is stuck with old timeline WAL files:

```bash
# Delete old WAL files from previous timeline (example: timeline 1)
kubectl exec -n <namespace> <pod-name> -c plugin-barman-cloud -- \
  python3 -c "
import os
wal_dir = '/var/lib/postgresql/wal/pg_wal'
archive_status_dir = f'{wal_dir}/archive_status'

# Get files from old timeline (adjust timeline number as needed)
files = [(f, os.path.join(wal_dir, f)) for f in os.listdir(wal_dir)
         if os.path.isfile(os.path.join(wal_dir, f))
         and f.startswith('00000001')  # Timeline 1
         and not f.endswith('.history')]
files.sort(key=lambda x: os.path.getmtime(x[1]))

# Delete oldest files to free space
deleted = 0
for filename, filepath in files[:200]:
    os.remove(filepath)
    deleted += 1
    # Also remove archive_status files
    for ext in ['.ready', '.done']:
        status_file = os.path.join(archive_status_dir, filename + ext)
        if os.path.exists(status_file):
            os.remove(status_file)

print(f'Deleted {deleted} old WAL files')
"
```

#### 3. Rebuild the Replica (if necessary)

If the replica has timeline mismatches or corruption, force a rebuild:

```bash
# Delete the pod
kubectl delete pod -n <namespace> <pod-name>

# If still failing, delete the PVCs to force full rebuild
kubectl delete pvc -n <namespace> <pod-name>
kubectl delete pvc -n <namespace> <pod-name>-wal
```

CNPG will automatically:
1. Create new PVCs
2. Run a join job to bootstrap from the primary
3. Start the new replica pod

### Prevention

#### 1. Properly Size WAL Volumes

In your Cluster spec:
```yaml
spec:
  walStorage:
    size: 4Gi  # Increase if needed based on your WAL generation rate
```

#### 2. Monitor Continuous Archiving

Check the archiving status regularly:
```bash
kubectl get cluster -n <namespace> <cluster-name> \
  -o jsonpath='{.status.conditions[?(@.type=="ContinuousArchiving")]}'
```

Should show:
```json
{
  "status": "True",
  "message": "Continuous archiving is working"
}
```

#### 3. Configure Alerts

Add Prometheus alerts for:
- WAL disk usage > 80%
- Failed WAL archiving
- Cluster not ready

#### 4. Use Correct Retention Policies

```yaml
spec:
  retentionPolicy: "30d"  # Adjust based on your requirements
```

## Replication Lag

### Symptoms
- Cluster status shows high replication lag
- Queries show: `"requested WAL segment has already been removed"`

### Diagnosis
```bash
kubectl get cluster -n <namespace> <cluster-name> -o yaml | grep -A 10 replication
```

### Solution

If a replica is too far behind and the primary has removed needed WAL segments:
1. Delete the replica pod to trigger rebuild
2. Ensure `wal_keep_size` is appropriately configured in cluster spec

## Failed Switchover/Failover

### Symptoms
- Cluster stuck in: `"Primary instance is being restarted without a switchover"`
- Pods showing unhealthy readiness probes

### Solution

```bash
# Force delete stuck primary
kubectl delete pod -n <namespace> <pod-name> --force --grace-period=0

# Wait for cluster to reconcile
kubectl wait --for=condition=Ready cluster/<cluster-name> -n <namespace> --timeout=5m
```

## Useful Commands

### Check cluster health
```bash
kubectl get cluster -n <namespace> <cluster-name> -o json | \
  jq -r '.status | "Phase: \(.phase)\nInstances: \(.instances)\nReady: \(.readyInstances)\nPrimary: \(.currentPrimary)"'
```

### View all instances status
```bash
kubectl get pods -n <namespace> -l cnpg.io/cluster=<cluster-name>
```

### Check WAL archiving on primary
```bash
kubectl logs -n <namespace> <primary-pod> -c plugin-barman-cloud | \
  grep -i archive | tail -20
```

### Verify ObjectStore configuration
```bash
kubectl get objectstore -n <namespace> <store-name> -o yaml
```

## References

- [CloudNativePG Documentation](https://cloudnative-pg.io/documentation/)
- [Barman Cloud Documentation](https://pgbarman.org/)
- [CNPG Monitoring Guide](https://cloudnative-pg.io/documentation/current/monitoring/)
