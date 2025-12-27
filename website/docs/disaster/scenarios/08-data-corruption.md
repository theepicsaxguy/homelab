---
sidebar_position: 8
title: "Scenario 8: Data Corruption"
---

# Scenario 8: Data Corruption

## Symptoms

- Database queries returning inconsistent or unexpected results
- Application errors about data integrity violations or constraint failures
- PostgreSQL logs showing "invalid page header" or "checksum failure"
- Gradual degradation of service over days or weeks
- Files or database records with garbled content
- Backup verification failures
- Silent corruption discovered during audit or reporting
- Users reporting missing or incorrect historical data

## Impact Assessment

- **Recovery Time Objective (RTO)**: 4-8 hours
- **Recovery Point Objective (RPO)**: Variable (depends on when corruption started)
- **Data Loss Risk**: Moderate to High (may lose data from corruption point forward)
- **Service Availability**: Can operate degraded during investigation, full outage during restore
- **Detection Difficulty**: High (corruption may be subtle and gradual)

## Prerequisites

- Access to multiple backup generations (daily, weekly, monthly)
- CNPG PostgreSQL cluster with point-in-time recovery (PITR) capability
- Velero backups with multiple retention points
- Access to B2 offsite backups with version history
- Test environment to validate old backups
- Knowledge of application data models and expected data patterns
- Monitoring tools to identify when corruption started

## Recovery Procedure

### Step 1: Identify Corruption Scope and Timeline

**CRITICAL: Do NOT restore immediately. First understand the problem.**

```bash
# Document current corruption state
kubectl get all -A > /tmp/corruption-state-$(date +%Y%m%d).txt
kubectl get pvc -A >> /tmp/corruption-state-$(date +%Y%m%d).txt

# Check database health
kubectl get clusters.postgresql.cnpg.io -A

# For each PostgreSQL cluster, check for corruption
kubectl -n <namespace> exec -it <postgres-pod> -- psql -U postgres <<EOF
-- Check for corrupted indexes
REINDEX DATABASE <database_name>;

-- Verify table integrity
SELECT relname, pg_relation_size(oid) as size
FROM pg_class
WHERE relkind = 'r'
ORDER BY size DESC
LIMIT 20;

-- Check for invalid data
SELECT COUNT(*) FROM <critical_table> WHERE <validation_condition>;

-- Look for orphaned records
SELECT * FROM <table> WHERE foreign_key NOT IN (SELECT id FROM parent_table);
EOF

# Check application logs for when errors started
kubectl -n <namespace> logs <app-pod> --since=168h | grep -i "error\|corrupt\|invalid"

# Check PostgreSQL logs for corruption indicators
kubectl -n <namespace> logs <postgres-pod> --since=168h | grep -i "corrupt\|checksum\|invalid page"
```

**Identify when corruption started:**

```bash
# Method 1: Check application metrics/logs
# Look for when error rates increased
# Access Prometheus/Grafana:
kubectl -n monitoring port-forward svc/prometheus 9090:9090
# Query: rate(application_errors[1h])
# Find timestamp when errors started

# Method 2: Check database modification times
kubectl -n <namespace> exec -it <postgres-pod> -- psql -U postgres <<EOF
-- Find when suspicious data appeared
SELECT MIN(created_at), MAX(created_at)
FROM <table>
WHERE <suspicious_condition>;

-- Check for gaps in sequential data
SELECT id, created_at,
  LAG(created_at) OVER (ORDER BY created_at) as previous_time,
  created_at - LAG(created_at) OVER (ORDER BY created_at) as gap
FROM <table>
WHERE gap > interval '1 day'  -- Unusual gaps might indicate corruption point
ORDER BY created_at DESC
LIMIT 100;
EOF

# Method 3: Check Velero backup history
velero backup get --output custom-columns=NAME:.metadata.name,CREATED:.metadata.creationTimestamp,STATUS:.status.phase

# Method 4: Check git commit history for config changes
cd /home/benjaminsanden/Dokument/Projects/homelab
git log --since="30 days ago" --oneline --all -- k8s/
# Look for database config changes that might have introduced corruption
```

### Step 2: Test Historical Backups

**Create test namespace to verify old backups without affecting production:**

```bash
# Create isolated test namespace
kubectl create namespace corruption-test

# Test restoring from different backup dates
# Start with most recent, work backwards

# Test 1: Yesterday's backup
velero restore create test-restore-yesterday \
  --from-backup daily-$(date -d "yesterday" +%Y%m%d)-020000 \
  --include-namespaces <affected-namespace> \
  --namespace-mappings <affected-namespace>:corruption-test

# Wait for restore
velero restore describe test-restore-yesterday

# Verify data in test namespace
kubectl -n corruption-test get pods
kubectl -n corruption-test exec -it <postgres-pod> -- psql -U postgres <<EOF
-- Run data validation queries
SELECT COUNT(*) FROM <critical_table>;
SELECT * FROM <table> WHERE <validation_condition>;
-- Check for corruption indicators
EOF

# If still corrupt, try older backup
kubectl delete namespace corruption-test
kubectl create namespace corruption-test

# Test 2: Last week's backup
velero restore create test-restore-lastweek \
  --from-backup weekly-$(date -d "7 days ago" +%Y%m%d)-020000 \
  --include-namespaces <affected-namespace> \
  --namespace-mappings <affected-namespace>:corruption-test

# Repeat validation
```

### Step 3: Identify Last Known Good Backup

**Document findings from backup testing:**

```bash
# Create investigation log
cat > /tmp/corruption-investigation-$(date +%Y%m%d).md <<EOF
# Data Corruption Investigation

**Date**: $(date)
**Affected Namespace**: <namespace>
**Affected Database**: <cluster-name>

## Corruption Timeline
- First detected: <date/time>
- Likely started: <date/time> (based on logs/data analysis)
- Last known good: <date/time>

## Backup Testing Results
| Backup Date | Status | Notes |
|-------------|--------|-------|
| $(date -d "yesterday" +%Y-%m-%d) | CORRUPT | <details> |
| $(date -d "7 days ago" +%Y-%m-%d) | CORRUPT | <details> |
| $(date -d "14 days ago" +%Y-%m-%d) | CLEAN | ✓ Data validates |
| $(date -d "30 days ago" +%Y-%m-%d) | CLEAN | ✓ Data validates |

## Recommended Recovery Point
**Backup**: weekly-$(date -d "14 days ago" +%Y%m%d)-020000
**Data Loss**: ~14 days of data
**Justification**: <reasoning>

## Recovery Plan
1. <steps>
EOF

cat /tmp/corruption-investigation-$(date +%Y%m%d).md
```

### Step 4: Assess Data Loss Impact

**Determine what data will be lost:**

```bash
# Compare clean backup vs current state
kubectl -n <namespace> exec -it <postgres-pod> -- psql -U postgres <<EOF
-- Get row counts for critical tables
SELECT
  '<table_name>' as table_name,
  COUNT(*) as current_count,
  (SELECT COUNT(*) FROM <table_name> WHERE created_at <= '<recovery_point_date>') as recovery_count,
  COUNT(*) - (SELECT COUNT(*) FROM <table_name> WHERE created_at <= '<recovery_point_date>') as data_loss
FROM <table_name>;

-- List data created after recovery point (will be lost)
SELECT * FROM <table_name>
WHERE created_at > '<recovery_point_date>'
ORDER BY created_at DESC
LIMIT 100;

-- Export critical data created after recovery point
\copy (SELECT * FROM <table> WHERE created_at > '<recovery_point_date>') TO '/tmp/data-after-recovery-point.csv' CSV HEADER
EOF

# Copy exported data out of pod
kubectl -n <namespace> cp <postgres-pod>:/tmp/data-after-recovery-point.csv /tmp/data-after-recovery-point.csv

# Analyze what will be lost
wc -l /tmp/data-after-recovery-point.csv
head /tmp/data-after-recovery-point.csv
```

### Step 5: CNPG Point-in-Time Recovery

**Restore PostgreSQL to specific point in time before corruption:**

```bash
# First, check available backups in B2
kubectl -n <namespace> get cluster <cluster-name> -o yaml

# View backup list from CNPG
kubectl -n <namespace> exec -it <cluster-name>-1 -- bash
barman-cloud-backup-list \
  --endpoint-url https://s3.us-west-000.backblazeb2.com \
  s3://homelab-cnpg-b2/<namespace>/<cluster-name>

# Exit pod and create recovery cluster spec
cat > /tmp/recovery-cluster.yaml <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: <cluster-name>-recovery
  namespace: <namespace>
spec:
  instances: 2

  bootstrap:
    recovery:
      source: original-cluster
      recoveryTarget:
        # Option 1: Recover to specific timestamp (recommended)
        targetTime: "2024-12-10 23:59:59"  # Last known good time

        # Option 2: Recover to specific transaction ID (if known)
        # targetXID: "1234567"

        # Option 3: Recover to named restore point (if created)
        # targetName: "before_corruption"

      # Backup to start recovery from
      # CNPG will automatically select closest backup before targetTime
      backup:
        name: <backup-id>  # Optional: specify backup to use

  externalClusters:
    - name: original-cluster
      barmanObjectStore:
        destinationPath: s3://homelab-cnpg-b2/<namespace>/<cluster-name>
        endpointURL: https://s3.us-west-000.backblazeb2.com
        s3Credentials:
          accessKeyId:
            name: b2-cnpg-credentials
            key: AWS_ACCESS_KEY_ID
          secretAccessKey:
            name: b2-cnpg-credentials
            key: AWS_SECRET_ACCESS_KEY
        wal:
          compression: gzip
          encryption: AES256
          maxParallel: 8

  storage:
    size: 50Gi  # Match or increase original size
    storageClass: longhorn

  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "256MB"
      # Match original cluster parameters

  monitoring:
    enablePodMonitor: true
EOF
```

**Apply recovery (creates new cluster):**

```bash
# Apply recovery cluster (don't delete original yet!)
kubectl apply -f /tmp/recovery-cluster.yaml

# Monitor recovery progress
kubectl -n <namespace> get cluster <cluster-name>-recovery -w

# Watch recovery logs
kubectl -n <namespace> logs -l cnpg.io/cluster=<cluster-name>-recovery -c postgres -f

# Check recovery status
kubectl -n <namespace> get cluster <cluster-name>-recovery -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}'
```

### Step 6: Validate Recovered Data

**Verify the recovered database is clean:**

```bash
# Connect to recovered cluster
kubectl -n <namespace> exec -it <cluster-name>-recovery-1 -- psql -U postgres

# Inside psql:
-- Check database is at correct recovery point
SELECT pg_postmaster_start_time();
SELECT pg_last_xact_replay_timestamp();  -- Should be close to target recovery time

-- Validate data integrity
SELECT COUNT(*) FROM <critical_table>;
-- Compare to expected count from investigation

-- Run application-specific validation queries
SELECT * FROM <table> WHERE <validation_condition>;

-- Check for corruption indicators
SELECT * FROM <table> WHERE <suspicious_pattern>;

-- Verify foreign key integrity
SELECT COUNT(*)
FROM <table> t
LEFT JOIN <parent_table> p ON t.parent_id = p.id
WHERE p.id IS NULL AND t.parent_id IS NOT NULL;
-- Should return 0

-- Check for data consistency
SELECT column_name, COUNT(DISTINCT value) as distinct_values
FROM <table>
GROUP BY column_name
HAVING COUNT(DISTINCT value) > <expected_threshold>;
```

**Test application functionality:**

```bash
# Temporarily point application to recovery cluster
# Option 1: Update service selector
kubectl -n <namespace> patch service <postgres-service> \
  -p '{"spec":{"selector":{"cnpg.io/cluster":"<cluster-name>-recovery"}}}'

# Option 2: Create test application instance
kubectl -n corruption-test create deployment test-app \
  --image=<your-app-image> \
  -- --db-host=<cluster-name>-recovery-rw.<namespace>.svc.cluster.local

# Test application reads/writes
kubectl -n <namespace> port-forward svc/<app-service> 8080:80
# Access http://localhost:8080 and test functionality

# Check application logs for errors
kubectl -n <namespace> logs deployment/test-app
```

### Step 7: Cutover to Recovered Database

**Once validated, switch production to recovered cluster:**

```bash
# Step 1: Put applications in maintenance mode
kubectl -n <namespace> scale deployment <app> --replicas=0

# Step 2: Rename clusters (swap old and new)
# Delete old corrupted cluster
kubectl -n <namespace> delete cluster <cluster-name>

# Rename recovery cluster to original name
kubectl -n <namespace> get cluster <cluster-name>-recovery -o yaml > /tmp/cluster-rename.yaml

# Edit /tmp/cluster-rename.yaml:
# Change metadata.name from "<cluster-name>-recovery" to "<cluster-name>"
sed -i 's/<cluster-name>-recovery/<cluster-name>/g' /tmp/cluster-rename.yaml

# Delete recovery cluster and recreate with correct name
kubectl -n <namespace> delete cluster <cluster-name>-recovery
kubectl apply -f /tmp/cluster-rename.yaml

# Step 3: Verify services are updated
kubectl -n <namespace> get endpoints <postgres-service>
# Should point to new cluster pods

# Step 4: Bring applications back online
kubectl -n <namespace> scale deployment <app> --replicas=<original-count>

# Step 5: Monitor for issues
kubectl -n <namespace> get pods -w
kubectl -n <namespace> logs deployment/<app> -f
```

### Step 8: Attempt Data Recovery from Corrupt Period

**Try to salvage data created after recovery point:**

```bash
# If you exported data earlier (Step 4), attempt to reinsert clean data
kubectl -n <namespace> cp /tmp/data-after-recovery-point.csv <postgres-pod>:/tmp/

kubectl -n <namespace> exec -it <postgres-pod> -- psql -U postgres <<EOF
-- Review exported data
\! head /tmp/data-after-recovery-point.csv

-- Carefully import non-corrupt records
-- Use ON CONFLICT to skip duplicates
COPY <table> FROM '/tmp/data-after-recovery-point.csv' CSV HEADER;

-- Or selectively import:
CREATE TEMP TABLE temp_import (LIKE <table>);
COPY temp_import FROM '/tmp/data-after-recovery-point.csv' CSV HEADER;

-- Validate temp data before inserting
SELECT * FROM temp_import WHERE <validation_checks>;

-- Insert only valid rows
INSERT INTO <table>
SELECT * FROM temp_import
WHERE <validation_conditions>
ON CONFLICT (id) DO NOTHING;

-- Verify
SELECT COUNT(*) FROM <table>;
EOF
```

## Post-Recovery Tasks

### 1. Implement Corruption Detection

```yaml
# Add database integrity checks as CronJob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: db-integrity-check
  namespace: <namespace>
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: integrity-check
            image: postgres:16
            env:
            - name: PGHOST
              value: <cluster-name>-rw
            - name: PGDATABASE
              value: <database>
            - name: PGUSER
              valueFrom:
                secretKeyRef:
                  name: <cluster-name>-app
                  key: username
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: <cluster-name>-app
                  key: password
            command:
            - /bin/sh
            - -c
            - |
              # Run integrity checks
              psql -c "SELECT * FROM pg_stat_database WHERE datname = '$PGDATABASE';"
              psql -c "VACUUM ANALYZE;"

              # Application-specific validation
              psql -c "SELECT COUNT(*) FROM <critical_table>;"

              # Check for orphaned records
              psql -c "SELECT COUNT(*) FROM <table> t LEFT JOIN <parent> p ON t.parent_id = p.id WHERE p.id IS NULL;"

              # Log results
              echo "Integrity check completed at $(date)"
          restartPolicy: OnFailure
---
```

Apply the integrity check:

```bash
kubectl apply -f db-integrity-check.yaml

# Create alerting for check failures
# In Prometheus AlertManager:
cat >> /home/benjaminsanden/Dokument/Projects/homelab/k8s/monitoring/prometheus/alerts/database.yaml <<EOF
- alert: DatabaseIntegrityCheckFailed
  expr: kube_job_status_failed{job_name=~"db-integrity-check.*"} > 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Database integrity check failed"
    description: "Database integrity check job failed in namespace {{ \$labels.namespace }}"
EOF
```

### 2. Enable PostgreSQL Checksums

```bash
# For new databases, enable checksums at creation
# Edit cluster spec:
cat > cluster-with-checksums.yaml <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: <cluster-name>
  namespace: <namespace>
spec:
  instances: 2

  bootstrap:
    initdb:
      database: <database>
      owner: <owner>
      # Enable data checksums
      options:
        - "--data-checksums"

  postgresql:
    parameters:
      # Enable checksum verification
      data_checksums: "on"
      # Log checksum failures
      log_checkpoints: "on"

  # ... rest of spec
EOF

# For existing databases, checksums require pg_rewind or rebuild
# This is done during recovery, so already enabled if you recovered
```

### 3. Implement Backup Verification

```bash
# Create backup validation script
cat > /home/benjaminsanden/Dokument/Projects/homelab/scripts/verify-backups.sh <<'EOF'
#!/bin/bash
set -e

NAMESPACE=$1
CLUSTER=$2

echo "Verifying backups for $NAMESPACE/$CLUSTER"

# Create test namespace
kubectl create namespace backup-verify-$(date +%s) || true
TEST_NS=$(kubectl get ns | grep backup-verify | tail -1 | awk '{print $1}')

# Get latest backup
LATEST_BACKUP=$(kubectl -n $NAMESPACE get backup -l cnpg.io/cluster=$CLUSTER -o jsonpath='{.items[-1:].metadata.name}')

echo "Testing restore of backup: $LATEST_BACKUP"

# Create recovery cluster in test namespace
cat <<YAML | kubectl apply -f -
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: verify-$CLUSTER
  namespace: $TEST_NS
spec:
  instances: 1
  bootstrap:
    recovery:
      source: original
      backup:
        name: $LATEST_BACKUP
  externalClusters:
    - name: original
      barmanObjectStore:
        destinationPath: s3://homelab-cnpg-b2/$NAMESPACE/$CLUSTER
        endpointURL: https://s3.us-west-000.backblazeb2.com
        s3Credentials:
          accessKeyId:
            name: b2-cnpg-credentials
            key: AWS_ACCESS_KEY_ID
          secretAccessKey:
            name: b2-cnpg-credentials
            key: AWS_SECRET_ACCESS_KEY
  storage:
    size: 10Gi
YAML

# Wait for recovery
kubectl -n $TEST_NS wait --for=condition=Ready cluster/verify-$CLUSTER --timeout=600s

# Validate data
echo "Running validation queries..."
kubectl -n $TEST_NS exec -it verify-$CLUSTER-1 -- psql -U postgres -c "SELECT COUNT(*) FROM pg_database;"

# Cleanup
kubectl delete namespace $TEST_NS

echo "Backup verification completed successfully!"
EOF

chmod +x /home/benjaminsanden/Dokument/Projects/homelab/scripts/verify-backups.sh

# Schedule monthly verification
# Add to crontab:
# 0 3 1 * * /home/benjaminsanden/Dokument/Projects/homelab/scripts/verify-backups.sh database postgres-cluster
```

### 4. Document Corruption Event

```bash
cat > /home/benjaminsanden/Dokument/Projects/homelab/docs/incidents/data-corruption-$(date +%Y%m%d).md <<EOF
# Data Corruption Incident

**Date Detected**: $(date)
**Corruption Start**: <estimated-date>
**Affected Database**: <cluster-name>
**Namespace**: <namespace>
**Recovery Completed**: $(date)

## Summary
<Brief description of what happened>

## Timeline
- **T-Xd**: Corruption likely started (based on logs)
- **T+0h**: Corruption detected - <how discovered>
- **T+2h**: Investigation completed, recovery point identified
- **T+4h**: Recovery cluster created
- **T+6h**: Data validation completed
- **T+8h**: Cutover to recovered database
- **T+10h**: Post-recovery verification completed

## Impact
- **Data Loss**: ~X days of data (from <date> to <date>)
- **Downtime**: X hours
- **Records Lost**: ~X records across Y tables
- **Users Affected**: <count/description>

## Root Cause
<What caused the corruption>
- Hardware issue (disk failure, memory corruption)?
- Software bug (application, database, Kubernetes)?
- Configuration error?
- Unknown

## Recovery Process
1. Identified corruption timeline through log analysis
2. Tested backups from multiple dates
3. Found clean backup from <date>
4. Performed CNPG point-in-time recovery to <timestamp>
5. Validated recovered data
6. Cutover production to recovered cluster
7. Attempted to salvage data from corrupt period

## Data Recovered
- <details on what data was successfully recovered>

## Data Lost
- <details on what data could not be recovered>

## Prevention Measures Implemented
- [ ] Enabled PostgreSQL checksums
- [ ] Implemented daily integrity checks
- [ ] Added backup verification automation
- [ ] Increased backup retention
- [ ] Enhanced monitoring and alerting

## Lessons Learned
<What we learned from this incident>

## Action Items
- [ ] <specific tasks to prevent recurrence>
EOF
```

## Troubleshooting

### Cannot Identify Corruption Start Time

```bash
# If logs are insufficient, use binary search approach
# Test backups at increasing intervals

# Test today, 1 week ago, 2 weeks ago, 1 month ago, etc.
for days_ago in 1 7 14 30 60 90; do
  echo "Testing backup from $days_ago days ago"
  # Create test restore and validate
  # Document results
done

# Once you find a range (e.g., corrupt between 14-30 days ago)
# Test intermediate points to narrow down
```

### All Recent Backups Are Corrupt

```bash
# Extend search to older backups
velero backup get | tail -50

# Check B2 for older backups with versioning
b2 ls --recursive --versions b2://homelab-cnpg-b2/<namespace>/<cluster>/

# Consider GFS retention: monthly backups may be clean
velero backup get --selector backup-type=monthly

# If all Velero backups corrupt, check CNPG backups
# They may have longer retention
```

### Recovery Cluster Won't Start

```bash
# Check recovery logs
kubectl -n <namespace> logs <cluster-name>-recovery-1 -c postgres

# Common issues:
# 1. Target time is too far back (beyond WAL retention)
# Solution: Use older base backup or different target time

# 2. Backup files are also corrupt
# Solution: Try different backup or check B2 versions

# 3. Insufficient resources
kubectl -n <namespace> describe pod <cluster-name>-recovery-1
# Solution: Increase storage size or node resources

# 4. Configuration mismatch
kubectl -n <namespace> get cluster <cluster-name>-recovery -o yaml
# Solution: Match parameters with original cluster
```

### Recovered Data Still Shows Corruption

```bash
# You may have chosen recovery point after corruption started
# Try earlier recovery point

# Update recovery cluster spec with earlier time
kubectl -n <namespace> edit cluster <cluster-name>-recovery
# Change targetTime to earlier timestamp

# Delete pods to trigger new recovery
kubectl -n <namespace> delete pod -l cnpg.io/cluster=<cluster-name>-recovery
```

## Related Scenarios

- [Scenario 1: Accidental Deletion](01-accidental-deletion.md) - For basic restore procedures
- [Scenario 6: Ransomware Attack](06-ransomware.md) - Similar backup testing approach
- [Scenario 9: Primary Recovery Guide](09-primary-recovery.md) - For accessing B2 backups

## Reference

- [CNPG Point-in-Time Recovery](https://cloudnative-pg.io/documentation/current/recovery/)
- [PostgreSQL Data Checksums](https://www.postgresql.org/docs/current/checksums.html)
- [Velero Backup Verification](https://velero.io/docs/main/backup-verification/)
- [PostgreSQL Corruption Detection](https://wiki.postgresql.org/wiki/Corruption)
