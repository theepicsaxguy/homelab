# Kubernetes Infrastructure - Agent Guidelines

This document provides guidance for agents working with the Kubernetes infrastructure in this repository.

## Longhorn Backup Strategy

### Overview
Our cluster uses Longhorn with a label-based backup approach. **PVCs without backup labels are NOT backed up.**

### Backup Tiers

- **GFS (Grandfather-Father-Son)**: For critical databases and stateful apps
  - Hourly backups: retained 48 (2 days)
  - Daily backups: retained 14 (2 weeks)
  - Weekly backups: retained 8 (2 months)
  - Label: `recurring-job-group.longhorn.io/gfs=enabled`

- **Daily**: For standard applications
  - Daily backups at 2 AM: retained 14 (2 weeks)
  - Label: `recurring-job-group.longhorn.io/daily=enabled`

- **None**: For caches, temp data, ephemeral storage
  - No labels = no backups

### Applying Backups to PVCs

All PVCs require the source label plus the tier label:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-data
  labels:
    recurring-job.longhorn.io/source: enabled  # Required for PVC sync
    recurring-job-group.longhorn.io/gfs: enabled  # OR "daily" OR omit entirely
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
```

### Decision Guide

| Workload | Tier | Rationale |
|----------|------|-----------|
| Postgres, MySQL, MongoDB | `gfs` | Critical data, need point-in-time recovery |
| GitLab, Vault, Keycloak | `gfs` | Configuration/state is critical |
| Harbor, Nexus | `daily` | Important but not time-critical |
| RabbitMQ, Kafka | `daily` | Can replay messages |
| Prometheus, Loki | `daily` or none | Metrics are replaceable |
| Redis (cache), temp storage | none | Ephemeral data |

### Important Notes

- Backups are stored in S3 (`s3://longhorn@us-west-1/`)
- GFS volumes will have ~70 backups in S3 (hourly + daily + weekly)
- Daily volumes will have ~14 backups in S3
- Unlabeled volumes consume **zero S3 storage**
- Snapshot cleanup runs every 6 hours to prevent snapshot buildup

### Verifying PVC Backup Status

Before applying changes, check what would change:

```bash
# List all PVCs and their current backup status
kubectl get pvc --all-namespaces -o json | \
  jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name): \(.metadata.labels["recurring-job-group.longhorn.io/gfs"] // .metadata.labels["recurring-job-group.longhorn.io/daily"] // "NO BACKUP")"'
```

This shows which PVCs would lose backups after applying changes (if they relied on the old "default" group).

### RecurringJob Configuration

The backup jobs are defined in [k8s/infrastructure/storage/longhorn/recurringjob.yaml](../infrastructure/storage/longhorn/recurringjob.yaml). Each job targets a specific group (`gfs` or `daily`), and retention policies scale appropriately:

- More frequent backups = shorter retention (e.g., hourly keeps 48, daily keeps 14)
- Less frequent backups = longer retention (e.g., weekly keeps 8)
- Snapshot cleanup runs across all groups to prevent temporary snapshot accumulation

