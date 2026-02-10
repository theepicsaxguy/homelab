---
sidebar_position: 5
title: CNPG Database Restoration Guide
description: Step-by-step guide for restoring CloudNativePG clusters from backup
---

# CloudNativePG Database Restoration from Backup

This guide documents the complete process for restoring a CloudNativePG database cluster from a backup stored in MinIO or Backblaze B2.

## When to Use This Guide

Use this restoration process when:
- Your database cluster has been deleted or corrupted
- You need to recover data from a specific point in time
- You're migrating to a new cluster with old data
- Disk space issues have caused data loss or corruption

## Prerequisites

- Access to backup storage (MinIO or B2)
- CNPG operator running in the cluster
- ObjectStore resources configured
- Backup exists in the storage backend

---

## Real-World Case Study: Authentik PostgreSQL Recovery

### The Problem

On February 10, 2026, the Authentik PostgreSQL cluster (`authentik-postgresql`) experienced a critical issue:

1. **WAL Volume Full**: Pod `authentik-postgresql-1` filled its 4GB WAL volume to 99.6% capacity with 246 unarchived WAL files
2. **Incorrect Barman Configuration**: MinIO destinationPath was hardcoded to `authentik-postgresql-2` instead of the cluster name
3. **Cluster Rebuilt**: After troubleshooting, the cluster was rebuilt from `initdb`, losing all user data
4. **User Credentials Lost**: After rebuild, user login credentials didn't work

### Investigation Steps

#### 1. Check Backup Availability

First, we verified backups existed in MinIO:

```bash
# List backup directories
aws --endpoint-url https://truenas.peekoff.com:9000 \
  s3 ls s3://homelab-postgres-backups/auth/authentik-postgresql/ \
  --no-verify-ssl

# Output showed nested structure:
# authentik-postgresql/
# └── authentik-postgresql/
#     ├── base/
#     └── wals/
```

#### 2. Find Available Base Backups

```bash
# List base backups
aws --endpoint-url https://truenas.peekoff.com:9000 \
  s3 ls s3://homelab-postgres-backups/auth/authentik-postgresql/authentik-postgresql/base/ \
  --no-verify-ssl

# Found daily backups:
# 20260205T020001/ - Feb 5, 02:00 (last backup before incident)
# 20260210T090949/ - Feb 10, 09:09 (after rebuild - wrong data)
```

#### 3. Verify Backup Integrity

```bash
# Check backup metadata
aws --endpoint-url https://truenas.peekoff.com:9000 \
  s3 cp s3://homelab-postgres-backups/auth/authentik-postgresql/authentik-postgresql/base/20260205T020001/backup.info - \
  --no-verify-ssl

# Key information from backup:
# - backup_name: backup-20260205020000
# - cluster_size: 178582784 (170MB)
# - status: DONE
# - systemid: 7589448288821846035
# - timeline: 4
```

---

## Restoration Process

### Step 1: Create Restoration Cluster Configuration

Create a new cluster that will bootstrap from the backup. The key is using `bootstrap.recovery`:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: authentik-postgresql-restored  # Different name to avoid conflicts
  namespace: auth
spec:
  instances: 2
  imageName: ghcr.io/cloudnative-pg/postgresql:17

  # Bootstrap from backup
  bootstrap:
    recovery:
      source: authentik-postgresql-minio-backup
      recoveryTarget:
        backupID: 20260205T020001  # Specific backup to restore

  storage:
    size: 20Gi
    storageClass: proxmox-csi

  walStorage:
    size: 4Gi
    storageClass: proxmox-csi

  # Enable Barman plugin for WAL archiving
  plugins:
  - name: barman-cloud.cloudnative-pg.io
    enabled: true
    isWALArchiver: true
    parameters:
      barmanObjectName: authentik-minio-store

  # Define external backup source
  externalClusters:
    - name: authentik-postgresql-minio-backup
      plugin:
        name: barman-cloud.cloudnative-pg.io
        parameters:
          barmanObjectName: authentik-minio-store
          serverName: authentik-postgresql  # Original cluster name

  # ... rest of cluster config
```

**Important Configuration Points:**

- `bootstrap.recovery.source`: References the external cluster definition
- `recoveryTarget.backupID`: Specific backup timestamp to restore
- `externalClusters[].plugin.parameters.serverName`: Must match the original cluster name used in backup path
- `externalClusters[].plugin.parameters.barmanObjectName`: References the ObjectStore resource

### Step 2: Apply the Restoration Configuration

```bash
kubectl apply -f restoration-cluster.yaml
```

**What Happens:**

1. CNPG creates a recovery job pod (`<cluster>-1-full-recovery-xxx`)
2. The job downloads the base backup from MinIO/B2
3. PostgreSQL starts in recovery mode
4. WAL files are streamed and replayed from the archive
5. Once recovery completes, the cluster is promoted to primary

**Monitor Progress:**

```bash
# Watch recovery job
kubectl logs -n auth authentik-postgresql-restored-1-full-recovery-xxx -c full-recovery --tail=50 -f

# Key log messages to watch for:
# - "Restore through plugin detected, proceeding..."
# - "restored log file \"XXXX\" from archive" (replaying WALs)
# - "redo in progress, elapsed time: X s, current LSN: Y"
```

**Recovery Time:**
- Base backup restore: ~30 seconds
- WAL replay: Depends on number of WAL files (in our case, 300+ WAL files took ~5-7 minutes)
- Total time: ~10 minutes for a 170MB database

### Step 3: Verify Restored Data

Once the recovery job completes and the primary pod starts:

```bash
# Check database size
kubectl exec -n auth authentik-postgresql-restored-1 -c postgres -- \
  psql -U postgres -d app -c "SELECT pg_size_pretty(pg_database_size('app'));"

# Output: 152 MB (vs 32 MB in empty cluster)

# Check user count
kubectl exec -n auth authentik-postgresql-restored-1 -c postgres -- \
  psql -U postgres -d app -c "SELECT COUNT(*) FROM authentik_core_user;"

# Output: 7 (vs 4 in fresh cluster)

# Verify last activity timestamp
kubectl exec -n auth authentik-postgresql-restored-1 -c postgres -- \
  psql -U postgres -d app -c \
  "SELECT username, last_login FROM authentik_core_user ORDER BY last_login DESC LIMIT 3;"

# Output showed last login: 2026-02-05 08:05:58 (matches backup timestamp!)
```

### Step 4: Update Application Configuration

#### Update Database Connection

The restored cluster has a different name and credentials. Update your application:

```yaml
# Original: authentik-postgresql-rw
# New: authentik-postgresql-restored-rw

# In k8s/infrastructure/auth/authentik/values.yaml
authentik:
  postgresql:
    host: authentik-postgresql-restored-rw  # Updated service name
```

#### Update Database Credentials Secret

The restored cluster generates new credentials:

```bash
# Get new credentials from restored cluster
NEW_PASSWORD=$(kubectl get secret -n auth authentik-postgresql-restored-app \
  -o jsonpath='{.data.password}' | base64 -d)

# Update application secret
kubectl patch secret -n auth authentik-postgresql-app \
  --type='json' \
  -p="[{\"op\": \"replace\", \"path\": \"/data/password\", \"value\": \"$(echo -n $NEW_PASSWORD | base64)\"}]"

# Restart application
kubectl rollout restart deployment -n auth authentik-server authentik-worker
```

### Step 5: Clean Up Old Cluster

Once the restored cluster is verified and the application is healthy:

```bash
# Delete old cluster (if any remnants exist)
kubectl delete cluster -n auth authentik-postgresql

# Wait for pods to terminate
kubectl get pods -n auth -w
```

---

## Common Issues and Solutions

### Issue: "password authentication failed for user"

**Cause:** Application is using old database credentials

**Solution:**
```bash
# Get new password from restored cluster
kubectl get secret -n auth <cluster-name>-restored-app -o jsonpath='{.data.password}' | base64 -d

# Update application secret
kubectl patch secret -n auth <app-secret-name> \
  --type='json' \
  -p="[{\"op\": \"replace\", \"path\": \"/data/password\", \"value\": \"<base64-encoded-password>\"}]"
```

### Issue: Recovery job stuck at "restored log file"

**Cause:** Many WAL files to replay (normal for backups with long time between backup and recovery)

**Solution:** Be patient. Monitor the LSN progress:
```bash
kubectl logs -n auth <cluster>-1-full-recovery-xxx -c full-recovery | grep "current LSN"
```

Compare against the last WAL file in backup:
```bash
aws s3 ls s3://bucket/path/wals/TIMELINE/ --endpoint-url <url> | tail -1
```

### Issue: "Name or service not known" for database host

**Cause:** Application config still references old cluster service name

**Solution:** Update application configuration to use new service name (`<cluster-name>-restored-rw`)

### Issue: Two clusters trying to start simultaneously

**Cause:** Old cluster definition not deleted before restoring

**Solution:**
```bash
# List all clusters
kubectl get cluster -n <namespace>

# Delete old cluster
kubectl delete cluster -n <namespace> <old-cluster-name>
```

---

## Post-Restoration Checklist

- [ ] Verify database size matches expected backup size
- [ ] Check key application data is present and correct
- [ ] Confirm application can connect and authenticate
- [ ] Test critical application functionality
- [ ] Verify timestamps on data match backup time
- [ ] Update monitoring/alerting if cluster name changed
- [ ] Update documentation with new cluster name
- [ ] Consider renaming restored cluster to original name (requires downtime)
- [ ] Configure new scheduled backups
- [ ] Fix any Barman configuration issues that caused the problem

---

## Lessons Learned from Authentik Case

### Root Causes Identified

1. **Incorrect Barman Configuration**
   - `destinationPath` was hardcoded to pod name (`authentik-postgresql-2`) instead of cluster name
   - Should be: `s3://bucket/namespace/<cluster-name>`

2. **No Base Backup Monitoring**
   - Scheduled backups existed but `barmanObjectName` parameter was missing
   - Backups only ran on specific day/time
   - No alerting for failed backups

3. **WAL Archiving Issues**
   - Old WAL files from previous timeline not cleaned up after failover
   - No monitoring for WAL disk usage

### Preventive Measures

1. **Fix ObjectStore Configuration**
   ```yaml
   spec:
     configuration:
       destinationPath: s3://bucket/namespace/<cluster-name>  # Use cluster name, not pod name!
   ```

2. **Add Backup Monitoring**
   ```yaml
   # In ScheduledBackup
   spec:
     method: plugin
     pluginConfiguration:
       name: barman-cloud.cloudnative-pg.io
       parameters:
         barmanObjectName: <objectstore-name>  # Don't forget this!
   ```

3. **Monitor Continuous Archiving Status**
   ```bash
   kubectl get cluster -n <namespace> <cluster-name> \
     -o jsonpath='{.status.conditions[?(@.type=="ContinuousArchiving")]}'
   ```

4. **Set Up WAL Disk Usage Alerts**
   - Alert when WAL volume > 80% full
   - Monitor for `.ready` files accumulating

---

## Additional Resources

- [CNPG Troubleshooting Guide](./cnpg-troubleshooting.md)
- [CloudNativePG Recovery Documentation](https://cloudnative-pg.io/documentation/current/recovery/)
- [Barman Cloud Documentation](https://pgbarman.org/)
- [Point-in-Time Recovery Guide](https://cloudnative-pg.io/documentation/current/recovery/#point-in-time-recovery-pitr)
