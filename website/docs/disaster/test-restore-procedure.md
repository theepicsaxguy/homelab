---
title: Test Restore Procedure
sidebar_position: 10
---

# Velero Test Restore Procedure

## Overview

Regular testing of backup restores is **critical** for disaster recovery readiness. This procedure provides a non-disruptive method to verify backups are restorable and complete.

## Why Test Restores?

- **Validate backup integrity** - Ensure backups actually contain recoverable data
- **Verify storage class migrations** - Test restoring to different storage infrastructure
- **Practice DR procedures** - Keep team familiar with restore operations
- **Catch issues early** - Discover backup problems before a real disaster
- **Measure RTO/RPO** - Understand actual recovery time and data loss windows

## Testing Schedule

**Recommended frequency**:
- **Monthly**: Test restore of critical applications (Home Assistant, databases, auth)
- **Quarterly**: Full cluster restore test to staging environment
- **After major changes**: Test after storage migrations, Velero upgrades, or infrastructure changes

## Test Restore Procedure

### Prerequisites

- `velero` CLI installed
- `kubectl` access to cluster with admin privileges
- Recent backup to test (verify with `velero backup get`)
- Storage class mapping ConfigMap (if testing storage class migration)

### Step 1: Select Backup to Test

```bash
# List available backups
velero backup get

# Choose a recent completed backup
velero backup describe <backup-name>

# Verify backup includes Pod Volume Backups
velero backup describe <backup-name> --details | grep -A 5 "Pod Volume"
```

**Look for**:
- ✅ Phase: `Completed`
- ✅ Errors: `0`
- ✅ Pod Volume Backups: `Completed`

### Step 2: Prepare Test Namespace

Create an isolated test namespace to avoid impacting production:

```bash
# Create test namespace
kubectl create namespace <app>-test

# Label for easy identification
kubectl label namespace <app>-test test=disaster-recovery

# Add PodSecurity labels if application requires privileged mode
# (e.g., Home Assistant needs hostNetwork, NET_ADMIN capabilities)
kubectl label namespace <app>-test \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged
```

**When to add PodSecurity labels**:
- Application uses `hostNetwork: true`
- Application requires special capabilities (NET_ADMIN, NET_RAW, etc.)
- Application uses hostPorts
- Check production namespace labels: `kubectl get namespace <app> --show-labels`

### Step 3: Configure Storage Class Mapping (Optional)

If testing storage class migration (e.g., longhorn → proxmox-csi):

```bash
# Create or verify storage class mapping ConfigMap
kubectl apply -f /path/to/homelab/k8s/infrastructure/controllers/velero/storage-class-mapping.yaml

# Verify ConfigMap exists
kubectl get configmap -n velero change-storage-class-config -o yaml
```

See [Velero Storage Class Mapping](../infrastructure/controllers/velero-storage-class-mapping.md) for detailed configuration.

### Step 4: Execute Test Restore

```bash
# Restore to test namespace with namespace mapping
velero restore create <app>-test-restore-$(date +%Y%m%d-%H%M%S) \
  --from-backup <backup-name> \
  --include-namespaces <source-namespace> \
  --namespace-mappings <source-namespace>:<app>-test \
  --wait

# Example for Home Assistant:
velero restore create ha-test-restore-$(date +%Y%m%d-%H%M%S) \
  --from-backup home-assistant-manual-20251229-162851 \
  --include-namespaces home-assistant \
  --namespace-mappings home-assistant:home-assistant-test \
  --wait
```

**Command breakdown**:
- `<app>-test-restore-$(date +%Y%m%d-%H%M%S)` - Unique restore name with timestamp
- `--from-backup <backup-name>` - Source backup to restore from
- `--include-namespaces <source-namespace>` - Namespace to restore
- `--namespace-mappings <source>:<target>` - Map to test namespace (non-disruptive)
- `--wait` - Block until restore completes

### Step 5: Monitor Restore Progress

```bash
# Check restore status
velero restore get

# Describe restore (watch for completion)
watch -n 5 'velero restore describe <restore-name> | head -30'

# Watch resources being created
kubectl get all,pvc -n <app>-test -w

# Check for errors
velero restore logs <restore-name>
```

**Expected phases**:
1. `New` → `InProgress` (resources being created)
2. PVC creation and binding
3. Pod Volume Restore (Kopia data restore)
4. `Completed` (all resources restored)

### Step 6: Verify Restore Success

#### 6.1 Verify Restore Completion

```bash
# Check final status
velero restore describe <restore-name>
```

**Expected output**:
- ✅ Phase: `Completed`
- ✅ Errors: `0`
- ✅ Warnings: `0` (or only minor warnings about existing resources)
- ✅ Items restored: `X/X` (all items)
- ✅ kopia Restores - Completed: `X` (matching number of PVCs)

#### 6.2 Verify Storage Class Transformation (If Testing Migration)

```bash
# Check PVC storage class
kubectl get pvc -n <app>-test

# Verify storage class in PVC spec
kubectl get pvc -n <app>-test -o yaml | grep storageClassName
# Expected: storageClassName: <target-storage-class> (e.g., proxmox-csi)

# Verify PV provisioner
kubectl get pvc -n <app>-test -o jsonpath='{.items[0].spec.volumeName}'
kubectl get pv <pv-name> -o yaml | grep -E "provisioner|storageClassName"
# Expected: provisioner: <target-csi-driver> (e.g., csi.proxmox.sinextra.dev)
```

**Critical checks**:
- [ ] PVC uses target storage class (NOT source storage class)
- [ ] PV provisioned by correct CSI driver
- [ ] PVC status is `Bound`
- [ ] No errors in PVC events

#### 6.3 Verify Resource Creation

```bash
# List all restored resources
kubectl get all,pvc,configmap,secret,serviceaccount -n <app>-test

# Check pod status
kubectl get pods -n <app>-test

# Wait for pod to be ready
kubectl wait --for=condition=ready pod/<pod-name> -n <app>-test --timeout=300s
```

**Expected resources** (varies by application):
- StatefulSet or Deployment
- Pods (Running status)
- Services
- PVCs (Bound status)
- ConfigMaps
- Secrets (may need ExternalSecret sync)
- ServiceAccounts

#### 6.4 Verify Data Integrity

```bash
# Check pod is running
kubectl get pods -n <app>-test

# Exec into pod to verify data
kubectl exec -n <app>-test <pod-name> -- ls -la <data-path>

# Check data size matches expected size
kubectl exec -n <app>-test <pod-name> -- du -sh <data-path>

# For applications with databases, verify critical files exist
kubectl exec -n <app>-test <pod-name> -- ls -la <data-path>/.storage
kubectl exec -n <app>-test <pod-name> -- ls -la <data-path>/*.db
```

**Application-specific checks**:

**Home Assistant**:
```bash
# Verify .storage directory (contains HA state)
kubectl exec -n home-assistant-test home-assistant-0 -- ls -la /config/.storage

# Check database exists
kubectl exec -n home-assistant-test home-assistant-0 -- ls -lh /config/home-assistant_v2.db

# Verify automations
kubectl exec -n home-assistant-test home-assistant-0 -- cat /config/automations.yaml | head -20
```

**PostgreSQL (CNPG)**:
```bash
# Check cluster status
kubectl get cluster -n <namespace>-test

# Verify database is ready
kubectl wait --for=condition=ready cluster/<cluster-name> -n <namespace>-test --timeout=300s

# Connect and verify data
kubectl exec -n <namespace>-test <cluster-pod> -- psql -U postgres -c "SELECT COUNT(*) FROM <table>;"
```

#### 6.5 Compare with Production (Optional)

```bash
# Compare resource counts
echo "Production:" && kubectl get all -n <source-namespace> | wc -l
echo "Test:" && kubectl get all -n <app>-test | wc -l

# Compare file counts (if applicable)
echo "Production files:" && kubectl exec -n <source-namespace> <pod> -- find <path> -type f | wc -l
echo "Test files:" && kubectl exec -n <app>-test <pod> -- find <path> -type f | wc -l

# Compare data sizes
echo "Production size:" && kubectl exec -n <source-namespace> <pod> -- du -sh <path>
echo "Test size:" && kubectl exec -n <app>-test <pod> -- du -sh <path>
```

### Step 7: Document Test Results

```bash
# Save restore details
velero restore describe <restore-name> > ~/test-restore-results-$(date +%Y%m%d).txt

# Add verification results
cat >> ~/test-restore-results-$(date +%Y%m%d).txt <<EOF

## Verification Results
- Restore Phase: Completed
- Errors: 0
- Storage Class: <verified-storage-class>
- PVC Status: Bound
- Pod Status: Running
- Data Size: <verified-size>
- Duration: <total-time>

## Issues Encountered
<any issues or none>

## Conclusion
<success or issues to address>
EOF
```

### Step 8: Cleanup Test Resources

```bash
# Delete test namespace (removes all resources)
kubectl delete namespace <app>-test

# Verify PVs are cleaned up
kubectl get pv | grep <app>-test
# Should show Released or be deleted (depending on reclaim policy)

# Delete test restore (optional)
velero restore delete <restore-name> --confirm
```

**When to keep test namespace**:
- Issues found during testing (investigate before cleanup)
- Performance testing needed
- User wants to manually validate application functionality

## Troubleshooting

### Restore Stuck InProgress

**Symptoms**: Restore doesn't complete, stays in InProgress phase

**Diagnosis**:
```bash
# Check Velero server logs
kubectl logs -n velero deployment/velero --tail=100

# Check node-agent logs (handles Kopia restore)
kubectl logs -n velero -l name=node-agent --tail=100 | grep -i error

# Check PVC binding status
kubectl get pvc -n <app>-test
kubectl describe pvc -n <app>-test <pvc-name>
```

**Common causes**:
- PVC pending (storage provisioner issue)
- Node-agent pod not running
- Kopia repository connection issues
- Insufficient storage capacity

### PVC Won't Bind

**Symptoms**: PVC shows `Pending` status after restore

**Diagnosis**:
```bash
# Check storage class exists
kubectl get storageclass <target-storage-class>

# Check storage provisioner pods
kubectl get pods -n csi-proxmox  # or longhorn-system

# Check PVC events
kubectl describe pvc -n <app>-test <pvc-name>
```

**Common causes**:
- Target storage class doesn't exist
- Storage provisioner not running
- Insufficient storage capacity
- Storage class access mode not supported

### Pod Won't Start

**Symptoms**: Pod stuck in Pending, CrashLoopBackOff, or Error state

**Diagnosis**:
```bash
# Check pod status and events
kubectl describe pod -n <app>-test <pod-name>

# Check pod logs
kubectl logs -n <app>-test <pod-name>

# Check PodSecurity violations
kubectl get events -n <app>-test --field-selector reason=FailedCreate
```

**Common causes**:
- Missing PodSecurity labels on namespace
- ExternalSecret not synced yet
- ConfigMap or Secret missing
- Resource quotas exceeded
- Image pull errors

### Data Not Restored

**Symptoms**: PVC is bound but empty or incomplete

**Diagnosis**:
```bash
# Check Pod Volume Restore status
velero restore describe <restore-name> --details | grep -A 10 "Pod Volume Restores"

# Check Kopia logs
kubectl logs -n velero -l name=node-agent | grep -i <namespace>

# Verify backup included pod volume backups
velero backup describe <backup-name> --details | grep -A 5 "Pod Volume"
```

**Common causes**:
- Backup didn't include pod volume backups (`defaultVolumesToFsBackup: false`)
- Kopia restore failed (check logs)
- Pod started before data restore completed
- Volume mount path mismatch

### Manually Provisioned PVs Not Restored

**Symptoms**: Pods stuck in Pending with "pod has unbound immediate PersistentVolumeClaims" error, PVC shows "no storage class is set"

**Diagnosis**:
```bash
# Check for PVCs without storageClassName
kubectl get pvc -n <app>-test -o custom-columns=NAME:.metadata.name,STORAGECLASS:.spec.storageClassName | grep '""'

# Describe the pending PVC
kubectl describe pvc -n <app>-test <pvc-name>
# Look for: "no storage class is set"
```

**Cause**: PVC has `storageClassName: ""` (manually provisioned PV like NFS mounts). Velero restores PVCs but not manually provisioned PVs - those must be reapplied from your git repository.

**Resolution**:
```bash
# 1. Check if PV/PVC are defined in your git repository
find k8s/ -name "*.yaml" -exec grep -l "<pvc-name>" {} \;

# 2. Reapply the PV and PVC definitions
kubectl apply -f k8s/path/to/pv.yaml
kubectl apply -f k8s/path/to/pvc.yaml

# 3. If PV is in Released state, clear the claimRef
kubectl patch pv <pv-name> -p '{"spec":{"claimRef":null}}'

# 4. Verify PVC binds
kubectl get pvc -n <app>-test <pvc-name>
```

**Example**: NFS volume `media-share` in media namespace requires manual PV/PVC application:
```bash
kubectl apply -f k8s/applications/media/nfs-pv.yaml
kubectl apply -f k8s/applications/media/media-share-pvc.yaml
kubectl patch pv media-share -p '{"spec":{"claimRef":null}}'
```

**Prevention**: Document all manually provisioned PVs and include them in your disaster recovery runbook.

## Best Practices

1. **Test Regularly**: Monthly for critical apps, quarterly for full cluster
2. **Use Namespace Mapping**: Always restore to test namespace first
3. **Document Results**: Keep records of test restore outcomes
4. **Measure Time**: Track RTO (how long restores take)
5. **Rotate Backups**: Test different backup dates (not always the latest)
6. **Test Failures**: Intentionally test restore scenarios (partial restores, specific resources)
7. **Automate Testing**: Create scripts or CronJobs for automated testing
8. **Verify Completely**: Don't just check pod status - verify actual data

## Automated Testing

For automated monthly testing:

```yaml
# Example: CronJob for automated test restore
apiVersion: batch/v1
kind: CronJob
metadata:
  name: test-restore-home-assistant
  namespace: velero
spec:
  schedule: "0 4 1 * *"  # First day of month at 4 AM
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: velero
          containers:
          - name: test-restore
            image: velero/velero:latest
            command:
            - /bin/sh
            - -c
            - |
              # Test restore script
              BACKUP=$(velero backup get --selector=app=home-assistant -o json | jq -r '.items[0].metadata.name')
              velero restore create ha-test-$(date +%Y%m%d) \
                --from-backup $BACKUP \
                --include-namespaces home-assistant \
                --namespace-mappings home-assistant:home-assistant-test
              # Verify and cleanup
              sleep 300
              kubectl delete namespace home-assistant-test
          restartPolicy: OnFailure
```

## Related Documentation

- [Velero Storage Class Mapping](../infrastructure/controllers/velero-storage-class-mapping.md)
- [Velero Backup Setup](../infrastructure/controllers/velero-backup.md)
- [Disaster Recovery Scenarios](scenarios/index.md)
- [Scenario 01: Accidental Deletion](scenarios/01-accidental-deletion.md)

## Metrics and Reporting

Track these metrics for each test restore:

- **RTO (Recovery Time Objective)**: How long did the restore take?
- **RPO (Recovery Point Objective)**: How old was the backup?
- **Data Integrity**: Was all data restored correctly?
- **Success Rate**: What percentage of test restores succeed?
- **Issues Found**: What problems were discovered during testing?

Create a tracking spreadsheet or dashboard to monitor trends over time.
