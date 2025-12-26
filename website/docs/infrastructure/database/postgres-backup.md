---
sidebar_position: 1
title: PostgreSQL Backups
description: WAL archiving and scheduled backups using CloudNativePG and Barman Cloud
---

# CloudNativePG Backup Configuration

CloudNativePG provides native backup support through Barman Cloud. Backups are stored in the MinIO S3-compatible
storage.

## Backup Architecture

Each CNPG cluster uses two components for backups:

1. **ObjectStore** - Defines the S3 destination and credentials
2. **ScheduledBackup** - Configures the backup schedule

## ObjectStore Configuration

```yaml
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: <app>-minio-store
  namespace: <namespace>
spec:
  configuration:
    destinationPath: s3://homelab-postgres-backups/<app>/<cluster-name>
    endpointURL: https://truenas.peekoff.com:9000
    s3Credentials:
      accessKeyId:
        name: longhorn-minio-credentials
        key: AWS_ACCESS_KEY_ID
      secretAccessKey:
        name: longhorn-minio-credentials
        key: AWS_SECRET_ACCESS_KEY
```

The `longhorn-minio-credentials` ExternalSecret supplies credentials. This same secret is reused across applications for
S3 backup access.

## Cluster Backup Plugin

Add the Barman Cloud plugin to the Cluster spec:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
spec:
  # ... other config ...
  plugins:
    - name: barman-cloud.cloudnative-pg.io
      isWALArchiver: true
      parameters:
        barmanObjectName: <app>-minio-store
```

## Scheduled Backups

Configure a ScheduledBackup to run periodic full backups:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:
  name: <cluster-name>-backup
  namespace: <namespace>
spec:
  schedule: '0 3 * * *' # 03:00 UTC daily
  backupOwnerReference: self
  cluster:
    name: <cluster-name>
  method: plugin
  pluginConfiguration:
    name: barman-cloud.cloudnative-pg.io
```

## Credential Secret Structure

The `longhorn-minio-credentials` secret must contain:

- `AWS_ACCESS_KEY_ID` - MinIO access key
- `AWS_SECRET_ACCESS_KEY` - MinIO secret key
- `AWS_REGION` - Region identifier (e.g., `us-west-1`)
- `AWS_S3_FORCE_PATH_STYLE` - Set to `true` for MinIO

## Backup Verification

Check backup status:

```bash
# List backups for a cluster
kubectl get backup -n <namespace>

# Check ScheduledBackup status
kubectl get scheduledbackup -n <namespace>

# View cluster backup status
kubectl describe cluster <cluster-name> -n <namespace> | grep -A 20 "Status:"
```
