---
sidebar_position: 2
title: "Scenario 2: Disk Failure"
---

# Scenario 2: Disk Failure

## Symptoms

- Disk errors appearing in Proxmox host system logs
- Longhorn storage pool showing degraded status
- Smart monitoring alerts indicating disk health issues
- PVC mount failures or read/write errors
- Longhorn UI showing volumes with degraded replicas
- Node showing disk space issues or I/O errors
- Worker or control plane node reporting storage problems
- Applications experiencing persistent storage failures

## Impact Assessment

- **Recovery Time Objective (RTO)**: 2-4 hours
- **Recovery Point Objective (RPO)**: 1-24 hours (depends on backup age)
- **Data Loss Risk**: Minimal if Longhorn replicas are healthy, moderate if all replicas are on the failed disk
- **Service Availability**: Applications using affected volumes will be unavailable or degraded

## Prerequisites

- Physical access to Proxmox host (host3.peekoff.com) for disk replacement
- Replacement disk of equal or greater capacity
- `kubectl` access to the cluster with admin privileges
- Access to Longhorn UI (LoadBalancer IP or `longhorn.peekoff.com`)
- Access to backup storage locations (TrueNAS MinIO or B2)
- Velero CLI installed for PVC restoration if needed

## Recovery Procedure

### Step 1: Assess Disk Failure Impact

First, determine the scope of the disk failure and which resources are affected.

**Check Proxmox Host:**

```bash
# SSH to Proxmox host
ssh root@host3.peekoff.com

# Check disk status with smartctl
smartctl -a /dev/sdX  # Replace X with the failing disk

# Check dmesg for disk errors
dmesg | grep -i "error\|fail" | grep sdX

# Check ZFS pool status (if using ZFS)
zpool status

# Check filesystem health
df -h
lsblk
```

**Check Longhorn Status:**

```bash
# Check Longhorn volumes
kubectl -n longhorn-system get volumes

# Check node status
kubectl -n longhorn-system get nodes

# Check replica health
kubectl -n longhorn-system get replicas
```

**Access Longhorn UI:**

Navigate to the Longhorn UI and check:
- **Dashboard**: Overall system health status
- **Node**: Which node has the failing disk
- **Volume**: Which volumes have degraded replicas

### Step 2: Identify Affected Volumes and Applications

Determine which volumes and applications are impacted:

```bash
# List all PVCs and their status
kubectl get pvc -A

# Check for pending or failed PVCs
kubectl get pvc -A | grep -v Bound

# Identify pods using affected PVCs
for ns in $(kubectl get pvc -A --no-headers | grep -v Bound | awk '{print $1}' | sort -u); do
  echo "=== Namespace: $ns ==="
  kubectl -n $ns get pods
done

# Check pod events for volume mount errors
kubectl get events -A --sort-by='.lastTimestamp' | grep -i volume
```

### Step 3: Enable Longhorn Node Evacuation (Optional)

If the disk is still partially functional, evacuate replicas to healthy nodes:

**Via Longhorn UI:**

1. Navigate to **Node** section
2. Select the node with the failing disk
3. Click **Edit Node**
4. Set **Eviction Requested** to `true`
5. Set **Scheduling** to `Disabled`
6. Click **Save**

**Via kubectl:**

```bash
# Get the node name
FAILING_NODE="work-00"  # Replace with actual node name

# Disable scheduling on the node
kubectl -n longhorn-system patch node $FAILING_NODE \
  --type merge \
  --patch '{"spec":{"allowScheduling":false}}'

# Request eviction
kubectl -n longhorn-system patch node $FAILING_NODE \
  --type merge \
  --patch '{"spec":{"evictionRequested":true}}'

# Monitor replica migration
kubectl -n longhorn-system get replicas -w
```

Wait for replicas to migrate to healthy nodes. This may take 15-60 minutes depending on data size.

### Step 4: Cordone and Drain the Kubernetes Node

Prevent new workloads from scheduling on the affected node:

```bash
# Cordone the node (prevent new pods)
kubectl cordon $FAILING_NODE

# Drain the node (evict existing pods)
kubectl drain $FAILING_NODE \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force \
  --grace-period=300

# Verify node is drained
kubectl get nodes
kubectl get pods -A -o wide | grep $FAILING_NODE
```

### Step 5: Replace the Failed Disk

**Physical Disk Replacement:**

1. Shut down the affected Proxmox host (if required for hot-swap):
   ```bash
   # On Proxmox host
   shutdown -h now
   ```

2. Replace the failed disk with a new disk of equal or greater capacity

3. Boot the Proxmox host

4. Initialize the new disk:
   ```bash
   # Identify the new disk
   lsblk

   # If using ZFS, add disk to pool
   zpool replace <pool-name> /dev/sdX /dev/sdY

   # Or create new filesystem
   mkfs.ext4 /dev/sdY
   mount /dev/sdY /var/lib/longhorn
   ```

### Step 6: Verify Longhorn Storage Recovery

**Via Longhorn UI:**

1. Navigate to **Node** section
2. Verify the node shows healthy disk status
3. Re-enable scheduling on the node:
   - Click **Edit Node**
   - Set **Scheduling** to `Enabled`
   - Set **Eviction Requested** to `false`
   - Click **Save**

**Via kubectl:**

```bash
# Re-enable scheduling
kubectl -n longhorn-system patch node $FAILING_NODE \
  --type merge \
  --patch '{"spec":{"allowScheduling":true,"evictionRequested":false}}'

# Uncordon the Kubernetes node
kubectl uncordon $FAILING_NODE

# Check Longhorn node status
kubectl -n longhorn-system get nodes
```

### Step 7: Restore Affected PVCs (If Needed)

If volumes were completely lost (all replicas on failed disk), restore from backup:

**List Available Backups:**

```bash
# Check Longhorn backups
# Via Longhorn UI: Navigate to Backup section

# Or use Velero for PVC restore
velero backup get

# Check specific backup contents
velero backup describe <backup-name> --details
```

**Restore from Longhorn Backup (via UI):**

1. Navigate to **Backup** section
2. Find the backup for the lost volume
3. Click **Restore Latest Backup**
4. Use the **exact PVC name** as the volume name
5. Click **OK**
6. Monitor restoration in **Volume** section

**Restore from Velero:**

```bash
# Restore specific PVC from Velero backup
velero restore create restore-disk-failure-$(date +%Y%m%d-%H%M%S) \
  --from-backup <backup-name> \
  --include-resources persistentvolumeclaims,persistentvolumes \
  --include-namespaces <namespace> \
  --selector app=<app-name>

# Monitor restore progress
velero restore get
velero restore describe restore-disk-failure-<timestamp>
velero restore logs restore-disk-failure-<timestamp>
```

### Step 8: Restart Affected Applications

After volumes are restored and healthy:

```bash
# Restart deployments
kubectl -n <namespace> rollout restart deployment/<deployment-name>

# Or restart statefulsets
kubectl -n <namespace> rollout restart statefulset/<statefulset-name>

# Monitor pod startup
kubectl -n <namespace> get pods -w
```

## Validation

### Check Longhorn Health

**Via Longhorn UI:**

1. **Dashboard**: All metrics should be green
2. **Node**: All nodes should show `Schedulable` status
3. **Volume**: All volumes should show `Healthy` status
4. **Replica**: Replicas should be evenly distributed

**Via kubectl:**

```bash
# Check Longhorn system status
kubectl -n longhorn-system get pods
kubectl -n longhorn-system get nodes
kubectl -n longhorn-system get volumes
kubectl -n longhorn-system get replicas

# Verify no degraded volumes
kubectl -n longhorn-system get volumes -o json | \
  jq -r '.items[] | select(.status.robustness != "healthy") | .metadata.name'
```

### Check PVC Status

```bash
# All PVCs should be Bound
kubectl get pvc -A

# Check for any pending PVCs
kubectl get pvc -A | grep -v Bound

# Verify volume attachments
kubectl get volumeattachments
```

### Check Application Status

```bash
# Verify all pods are running
kubectl get pods -A | grep -v Running | grep -v Completed

# Check application logs for errors
kubectl -n <namespace> logs <pod-name> --tail=50

# Test application connectivity
kubectl -n <namespace> port-forward svc/<service-name> 8080:80
# Access http://localhost:8080
```

### Verify Data Integrity

For critical applications, verify data is intact:

**For PostgreSQL:**

```bash
kubectl -n <namespace> exec -it <postgres-pod> -- psql -U postgres

# Check database size
SELECT pg_database_size('<database-name>');

# Check table row counts
SELECT schemaname, tablename, n_live_tup
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;

# Verify latest data
SELECT MAX(created_at) FROM <your_table>;
```

**For Applications:**

- Login and verify functionality
- Check critical data exists
- Test CRUD operations
- Verify file uploads/downloads work

## Post-Recovery Tasks

### 1. Document the Incident

```bash
# Create incident report
cat > docs/incidents/disk-failure-$(date +%Y%m%d).md <<EOF
# Disk Failure Incident

**Date**: $(date)
**Affected Node**: $FAILING_NODE
**Failed Disk**: /dev/sdX
**Volumes Affected**: <list>
**Recovery Time**: <duration>
**Data Loss**: <none/minimal/description>

## What Happened
<description of the failure>

## Recovery Steps Taken
1. Identified failing disk via smartctl and Longhorn UI
2. Evacuated replicas to healthy nodes
3. Replaced physical disk
4. Restored volumes from backup (if needed)
5. Verified application functionality

## Root Cause
<hardware failure details>

## Prevention Measures
<monitoring improvements, spare disk inventory, etc.>
EOF
```

### 2. Review Longhorn Replica Strategy

Ensure future failures don't cause data loss:

```bash
# Check current replica settings
kubectl -n longhorn-system get settings.longhorn.io default-replica-count -o yaml

# Update if needed (default should be 3)
kubectl -n longhorn-system patch settings.longhorn.io default-replica-count \
  --type merge \
  --patch '{"value":"3"}'

# For critical volumes, set higher replica count
# Via Longhorn UI: Volume → Edit → Number of Replicas
```

### 3. Enable or Verify Monitoring

Ensure disk health monitoring is active:

```bash
# Check if Prometheus is scraping Longhorn metrics
kubectl -n monitoring get servicemonitor | grep longhorn

# Verify Longhorn alerts exist
kubectl -n monitoring get prometheusrule | grep longhorn

# Test alert (optional)
# Manually trigger a test alert to verify notification works
```

### 4. Schedule Regular Backup Verification

```bash
# Verify backup schedules are running
kubectl -n velero get schedules

# Check last backup times
velero backup get

# Verify Longhorn backups
# Via Longhorn UI: Settings → Backup Target
# Confirm connection to MinIO and B2 is active
```

### 5. Update Hardware Inventory

Document the disk replacement:

- Record new disk serial number
- Update hardware inventory spreadsheet
- Note disk warranty information
- Update Proxmox notes with disk replacement date

## Troubleshooting

### Volume Stuck in Degraded State

```bash
# Check replica status
kubectl -n longhorn-system get replicas | grep <volume-name>

# Identify which replicas are unhealthy
kubectl -n longhorn-system describe replica <replica-name>

# Force rebuild of degraded replica (via Longhorn UI)
# Volume → <volume-name> → Salvage

# Or delete unhealthy replica to trigger rebuild
kubectl -n longhorn-system delete replica <replica-name>
```

### Replicas Not Migrating During Eviction

```bash
# Check if there's enough space on other nodes
kubectl -n longhorn-system get nodes -o json | \
  jq -r '.items[] | "\(.metadata.name): \(.status.diskStatus)"'

# Check for scheduling issues
kubectl -n longhorn-system describe node <node-name>

# Manually move replica (via Longhorn UI)
# Volume → <volume-name> → Update Replicas Count
# Then select specific nodes for placement
```

### PVC Fails to Bind After Restore

```bash
# Check PVC and PV status
kubectl -n <namespace> get pvc <pvc-name> -o yaml
kubectl get pv

# Check if PV exists with matching claim
kubectl get pv -o yaml | grep -A 10 <pvc-name>

# Delete and recreate PVC if needed
kubectl -n <namespace> delete pvc <pvc-name>
# Recreate from manifest or Velero restore
```

### Longhorn Node Shows "Scheduling Disabled"

```bash
# Check node status
kubectl -n longhorn-system get node <node-name> -o yaml

# Re-enable scheduling
kubectl -n longhorn-system patch node <node-name> \
  --type merge \
  --patch '{"spec":{"allowScheduling":true}}'
```

### Disk Not Detected After Replacement

```bash
# On Proxmox host, rescan SCSI bus
echo "- - -" > /sys/class/scsi_host/host0/scan

# Check if disk appears
lsblk
dmesg | tail -50

# Verify disk is healthy
smartctl -a /dev/sdX

# If using hardware RAID, check RAID controller
# (Commands vary by controller type)
```

## Related Scenarios

- [Scenario 1: Accidental Deletion](01-accidental-deletion.md) - If volumes were accidentally deleted
- [Scenario 3: Host Failure](03-host-failure.md) - If the entire Proxmox host failed
- [Scenario 8: Data Corruption](08-data-corruption.md) - If restored data is corrupt

## Reference

- [Longhorn Node Maintenance Documentation](https://longhorn.io/docs/latest/volumes-and-nodes/maintenance/)
- [Longhorn Replica Management](https://longhorn.io/docs/latest/high-availability/node-failure/)
- [Longhorn Backup and Restore](https://longhorn.io/docs/latest/snapshots-and-backups/backup-and-restore/)
- Main disaster recovery guide: [Disaster Recovery Overview](../disaster-recovery.md)
