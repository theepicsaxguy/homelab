---
sidebar_position: 2
title: Restore PostgreSQL From Backup
description: Restore a CloudNativePG cluster from Barman backups or VolumeSnapshots
---

# Restore PostgreSQL (CloudNativePG)

This document describes how to restore a CloudNativePG cluster from backups or VolumeSnapshots.

## Recovery Options

CloudNativePG supports multiple recovery methods:

1. **Barman Cloud Backup** - Restore from S3-stored backups
2. **VolumeSnapshot** - Restore from Longhorn snapshots
3. **pg_basebackup** - Clone from an existing cluster

## Recovery from Barman Cloud Backup

### Prerequisites

- ObjectStore resource configured with S3 credentials
- Existing backups in the S3 bucket
- CNPG operator running

### Recovery Cluster Manifest

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: <app>-db-recovered
  namespace: <namespace>
spec:
  instances: 1
  imageName: ghcr.io/cloudnative-pg/postgresql:18

  storage:
    size: 20Gi
    storageClass: proxmox-csi

  bootstrap:
    recovery:
      source: <app>-backup

  externalClusters:
    - name: <app>-backup
      plugin:
        name: barman-cloud.cloudnative-pg.io
        parameters:
          barmanObjectName: <app>-minio-store
```

### Point-in-Time Recovery (PITR)

To recover to a specific point in time:

```yaml
bootstrap:
  recovery:
    source: <app>-backup
    recoveryTarget:
      targetTime: "2024-01-15 10:30:00"
```

## Recovery from VolumeSnapshot

### Prerequisites

- Longhorn VolumeSnapshot exists
- Snapshot contains valid PGDATA

### Create Snapshot (if needed)

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: <app>-pgdata-backup
  namespace: <namespace>
spec:
  volumeSnapshotClassName: longhorn-snapshot
  source:
    persistentVolumeClaimName: <app>-db-1
```

### Recovery from Snapshot

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: <app>-db-recovered
  namespace: <namespace>
spec:
  instances: 1
  imageName: ghcr.io/cloudnative-pg/postgresql:18

  storage:
    size: 20Gi
    storageClass: proxmox-csi

  bootstrap:
    recovery:
      volumeSnapshots:
        storage:
          name: <app>-pgdata-backup
          kind: VolumeSnapshot
          apiGroup: snapshot.storage.k8s.io
```

## Verification Steps

### Check Cluster Status

```bash
# Watch cluster initialization
kubectl get cluster <cluster-name> -n <namespace> -w

# Check pod logs during recovery
kubectl logs -n <namespace> <cluster-name>-1 -f
```

### Verify Data Integrity

```bash
# Port forward to the cluster
kubectl port-forward -n <namespace> svc/<cluster-name>-rw 5432:5432 &

# Connect and verify
psql -h localhost -U <user> -d <database> -c '\dt'
psql -h localhost -U <user> -d <database> -c 'SELECT COUNT(*) FROM <table>;'
```

## Troubleshooting

### Cluster Stuck in Recovery

Check operator logs:

```bash
kubectl logs -n cnpg-system deployment/cnpg-controller-manager --tail=100
```

### VolumeSnapshot Issues

Verify snapshot is ready:

```bash
kubectl get volumesnapshot -n <namespace>
kubectl describe volumesnapshot <snapshot-name> -n <namespace>
```

### Permission Issues

CNPG expects PGDATA owned by UID/GID 26:26. If restoring from a foreign snapshot:

```bash
# Check permissions inside the pod
kubectl exec -n <namespace> <pod-name> -- ls -la /var/lib/postgresql/data/
```

## Post-Recovery Tasks

1. **Update application configs** - Point applications to the new cluster service
2. **Verify credentials** - Check the auto-generated `<cluster-name>-app` secret
3. **Enable backups** - Add ObjectStore and ScheduledBackup resources
4. **Scale replicas** - Increase instances after primary is healthy

## Reference

For detailed disaster recovery scenarios, see [Zalando to CNPG Migration](/docs/disaster/zalando-to-cnpg) which documents a real-world recovery case.
