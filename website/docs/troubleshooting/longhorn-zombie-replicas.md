# Longhorn Replica Rebuilding Stuck - Zombie Replicas

## Problem Summary

Longhorn volumes remained in "degraded" state for 24+ hours despite having available storage, online nodes, and
accessible disks. The error message was:

```
precheck new replica failed: disks are unavailable
```

No replicas were being rebuilt, and the degraded volume count stayed constant at 28.

## Environment

- Longhorn v1.10.1
- 4 worker nodes (work-00, work-01, work-02, work-03)
- ~236GB storage per node
- `storage-over-provisioning-percentage: 200`

## Investigation Timeline

### Hypothesis 1: Disk Pressure (Partially Correct)

**What we checked:**

```bash
kubectl get nodes.longhorn.io -n longhorn-system -o yaml
```

**Findings:**

- `work-02` had `DiskPressure` condition
- `storageScheduled` (531GB) exceeded `ProvisionedLimit` (472GB)
- The provisioned limit is calculated as: `storageMaximum × (storage-over-provisioning-percentage / 100)`

**Action taken:**

- Increased `storage-over-provisioning-percentage` from 200 to 300 in `values.yaml`
- This raised the limit from 472GB to 708GB

**Result:** DiskPressure resolved, but volumes still not rebuilding.

### Hypothesis 2: Anti-Affinity Rules Blocking Placement

**What we checked:**

```bash
kubectl get setting replica-soft-anti-affinity -n longhorn-system
kubectl get setting replica-disk-soft-anti-affinity -n longhorn-system
```

**Findings:**

- `replica-soft-anti-affinity: false` (strict - no replicas on same node)
- `replica-disk-soft-anti-affinity: false` (strict - no replicas on same disk)
- Some volumes already had replicas on 2 of 4 nodes, limiting placement options

**Assessment:** This contributed to scheduling difficulties but wasn't the root cause.

### Hypothesis 3: Concurrent Rebuild Limit Too Low

**What we checked:**

```bash
kubectl get setting concurrent-replica-rebuild-per-node-limit -n longhorn-system
```

**Findings:**

- Limit was set to 1 (later 2)
- Logs showed replicas being blocked: "reaches or exceeds the concurrent limit value 2"

**Action taken:**

- Increased `concurrentReplicaRebuildPerNodeLimit` to 5 in `values.yaml`

**Result:** More replicas could theoretically rebuild, but still no progress.

### Hypothesis 4: Replicas Not Actually Rebuilding (THE ROOT CAUSE)

**What we checked:**

```bash
# Check for replicas in rebuilding state
kubectl get replicas.longhorn.io -n longhorn-system -o json | \
  jq '[.items[] | select(.status.currentState=="rebuilding")] | length'
# Result: 0

# Check engine replica modes for WO (Write-Only/syncing)
kubectl get engines.longhorn.io -n longhorn-system -o json | \
  jq '.items[].status.replicaModeMap | to_entries[] | select(.value=="WO")'
# Result: empty
```

**Critical finding:** Zero replicas in "rebuilding" state, zero replicas syncing. Rebuilding was NOT happening at all.

### Root Cause: Zombie Replicas

**Discovery:**

```bash
# Check what's blocking the concurrent limit
kubectl logs -n longhorn-system -l app=longhorn-manager --tail=500 | \
  grep "Replica rebuildings for map"
```

Output showed the same two replicas blocking for hours:

```
Replica rebuildings for map[pvc-cb025be6...-r-2536b561:{} pvc-d8697236...-r-015d0264:{}]
are in progress on this node, which reaches or exceeds the concurrent limit value 2
```

**Investigated the "blocking" replicas:**

```bash
kubectl get replica pvc-cb025be6-5bbc-47d3-8d1c-72b8fedd6ee8-r-2536b561 -n longhorn-system -o json | \
  jq '{state: .status.currentState, healthy: .spec.healthyAt, retryCount: .spec.rebuildRetryCount}'
```

```json
{
  "state": "running",
  "healthy": null,
  "retryCount": 5
}
```

**The zombie state:**

- Replicas were "running" as processes
- But `healthyAt: null` - never became healthy
- `rebuildRetryCount: 5` - failed 5 times
- NOT connected to their engine (checked `replicaModeMap`)
- Counting against the concurrent rebuild limit
- Blocking ALL other replicas from rebuilding

## The Fix

Delete the zombie replicas to unblock the rebuild queue:

```bash
kubectl delete replica pvc-cb025be6-5bbc-47d3-8d1c-72b8fedd6ee8-r-2536b561 -n longhorn-system
kubectl delete replica pvc-d8697236-169f-48c6-bc89-29f53cc61ebc-r-015d0264 -n longhorn-system
```

After deletion, rebuilding immediately started and volumes began recovering.

## How to Detect Zombie Replicas

```bash
# Find replicas that are "running" but never became healthy and have high retry count
kubectl get replicas.longhorn.io -n longhorn-system -o json | \
  jq -r '.items[] | select(
    .status.currentState=="running" and
    .spec.healthyAt==null and
    .spec.rebuildRetryCount >= 3
  ) | "\(.metadata.name) on \(.spec.nodeID): retryCount=\(.spec.rebuildRetryCount)"'
```

## Prevention

### 1. PrometheusRule Alerts

Added alerts in `k8s/infrastructure/storage/longhorn/prometheusrule.yaml`:

| Alert                         | Trigger                          | Description             |
| ----------------------------- | -------------------------------- | ----------------------- |
| `LonghornVolumeDegraded`      | 30 min degraded                  | Early warning           |
| `LonghornVolumeStuckDegraded` | 2 hours degraded                 | Likely zombie replicas  |
| `LonghornRebuildStalled`      | Queue empty but volumes degraded | Catches zombie scenario |
| `LonghornNodeDiskPressure`    | Node not schedulable             | Disk space issues       |

### 2. Recommended Settings

```yaml
# values.yaml
defaultSettings:
  storageOverProvisioningPercentage: 300 # Generous headroom
  concurrentReplicaRebuildPerNodeLimit: 5 # Faster rebuilding
  replicaReplenishmentWaitInterval: 60 # Quicker retry (was 600)
  replicaAutoBalance: least-effort # Auto-rebalance replicas
```

## What Wasn't The Issue

| Suspected Issue      | Why It Wasn't                            |
| -------------------- | ---------------------------------------- |
| Disk space           | Nodes had 200GB+ available               |
| Network connectivity | Replicas could start, just couldn't sync |
| Node failures        | All 4 nodes were online and healthy      |
| Storage backend      | Longhorn system was operational          |
| Snapshot buildup     | Snapshots were being cleaned up normally |

## Key Learnings

1. **"Running" doesn't mean "working"** - Replicas can be running as processes but fail to connect to their engine
2. **Concurrent limits create hidden blockers** - A stuck replica consumes a slot indefinitely
3. **Longhorn doesn't auto-cleanup zombie replicas** - No built-in setting to evict replicas with high retry counts
4. **Check the rebuild queue** - If `longhorn_workqueue_depth{name="longhorn-volume-rebuilding"}` is 0 but volumes are
   degraded, something is blocking
5. **Look at the manager logs** - The "Replica rebuildings for map[...]" message reveals which replicas are holding the
   slots

## Useful Commands Reference

```bash
# Count degraded volumes
kubectl get volumes.longhorn.io -n longhorn-system -o json | \
  jq '[.items[] | select(.status.robustness=="degraded")] | length'

# Check rebuild queue per node
kubectl get replicas.longhorn.io -n longhorn-system -o json | \
  jq '[.items[] | select(.spec.desireState=="running" and .status.currentState=="stopped") | .spec.nodeID] | group_by(.) | map({node: .[0], queued: length})'

# Check engine replica connections
kubectl get engines.longhorn.io -n longhorn-system -o json | \
  jq '.items[] | "\(.metadata.name): \(.status.replicaModeMap)"'

# View concurrent rebuild limit
kubectl get setting concurrent-replica-rebuild-per-node-limit -n longhorn-system -o jsonpath='{.value}'
```

## Related Documentation

- [Longhorn Backup Strategy](../storage/backup-strategy.md)
- [Disaster Recovery](../disaster/disaster-recovery.md)

