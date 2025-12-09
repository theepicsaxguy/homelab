# Zalando to CNPG Migration - Complete Replacement

## Overview

This PR provides complete production-ready manifests to migrate **all 3 Zalando Postgres databases** to CloudNativePG (CNPG). All resources are configured with S3 backups, ExternalSecrets for credentials, and high availability where appropriate.

## Changes

### Databases Migrated

| Database | Namespace | Instances | Storage | Version | Special Notes |
|----------|-----------|-----------|---------|---------|---------------|
| **litellm-postgresql** | litellm | 1 | 10Gi | PostgreSQL 17 | - |
| **immich-postgresql** | immich | 2 (HA) | 15Gi | PostgreSQL 17 | Requires pgvector (vectors) extension |
| **authentik-postgresql** | auth | 2 (HA) | 20Gi | PostgreSQL 17 | - |

### Infrastructure Configuration

- **S3 Backups**: Configured via `homelab-postgres-backups` bucket on MinIO
- **Credentials**: ExternalSecrets using `bitwarden-backend` ClusterSecretStore
- **Storage Class**: `longhorn` (consistent with existing cluster)
- **Backup Schedule**: Daily at 2 AM UTC (cron: `0 0 2 * * *`)
- **Retention**: 30 days for all backups

### Files Created

```
zalando-to-cnpg-migration/
├── README.md                           # Complete migration guide
├── PR_DESCRIPTION.md                   # This file
├── litellm/
│   ├── 00-s3-credentials.yaml         # MinIO credentials (ExternalSecret)
│   ├── 00-credentials.yaml            # App credentials (ExternalSecret)
│   ├── 01-cluster.yaml                # CNPG Cluster
│   ├── 02-scheduled-backup.yaml       # ScheduledBackup
│   └── kustomization.yaml             # Kustomize manifest
├── immich/
│   ├── 00-credentials.yaml            # App credentials (ExternalSecret)
│   ├── 01-cluster.yaml                # CNPG Cluster with vector extensions
│   ├── 02-scheduled-backup.yaml       # ScheduledBackup
│   └── kustomization.yaml             # Kustomize manifest
└── auth/
    ├── 00-credentials.yaml            # App credentials (ExternalSecret)
    ├── 01-cluster.yaml                # CNPG Cluster
    ├── 02-scheduled-backup.yaml       # ScheduledBackup
    └── kustomization.yaml             # Kustomize manifest
```

## Prerequisites

### Bitwarden Secrets Required

The following secrets must exist in Bitwarden before applying these manifests:

**Database Credentials** (new, must be created):
- `postgres-litellm-username` and `postgres-litellm-password`
- `postgres-immich-username` and `postgres-immich-password`  
- `postgres-authentik-username` and `postgres-authentik-password`

**S3 Credentials** (already exist):
- `infra-minio-s3-access-key`
- `infra-minio-s3-secret-key`
- `infra-minio-s3-endpoint-url`

## Apply Instructions

### Step 1: Create CNPG Clusters (No Downtime)

```bash
# Apply all manifests to create new CNPG clusters
kubectl apply -R -f zalando-to-cnpg-migration/

# Watch cluster creation (takes 2-5 min per cluster)
kubectl get cluster -A -w

# Verify all clusters are ready
kubectl wait --for=condition=Ready cluster -n litellm litellm-postgresql-cnpg --timeout=600s
kubectl wait --for=condition=Ready cluster -n immich immich-postgresql-cnpg --timeout=600s
kubectl wait --for=condition=Ready cluster -n auth authentik-postgresql-cnpg --timeout=600s
```

### Step 2: Verify Clusters & Backups

```bash
# Check cluster status
kubectl get cluster -A

# Check pods
kubectl get pods -A -l cnpg.io/cluster

# Check backups are configured
kubectl get scheduledbackup -A

# Verify S3 credentials are mounted
kubectl get secret -n litellm longhorn-minio-credentials
kubectl get secret -n immich longhorn-minio-credentials  
kubectl get secret -n auth longhorn-minio-credentials
```

## Service Name Changes

Applications must be updated to use the new CNPG service endpoints:

### LiteLLM

**Old Service**: `litellm-postgresql.litellm.svc.cluster.local`  
**New Service**: `litellm-postgresql-cnpg-rw.litellm.svc.cluster.local` (read-write)

**Files to Update**:
- `k8s/applications/ai/litellm/deployment.yaml`
  - Update `DATABASE_URL` environment variable
  - Replace secret reference from `litellm.litellm-postgresql.credentials.postgresql.acid.zalan.do` to `litellm-postgresql-app-secret`

### Immich

**Old Service**: `immich-postgresql.immich.svc.cluster.local`  
**New Service**: `immich-postgresql-cnpg-rw.immich.svc.cluster.local` (read-write)

**Files to Update**:
- `k8s/applications/media/immich/immich-server/externalsecret.yaml`
  - Update to use `immich-postgresql-app-secret` instead of Zalando secret
  - Update host in connection string
- Remove `zalando-k8s-store.yaml` (no longer needed)

### Authentik

**Old Service**: `authentik-postgresql.auth.svc.cluster.local`  
**New Service**: `authentik-postgresql-cnpg-rw.auth.svc.cluster.local` (read-write)

**Files to Update**:
- `k8s/infrastructure/auth/authentik/values.yaml`
  - Update `authentik.postgresql.host` to `authentik-postgresql-cnpg-rw`
  - Replace `volumes.secret.secretName` from `authentik-user.authentik-postgresql.credentials.postgresql.acid.zalan.do` to `authentik-postgresql-app-secret`

## Data Migration Strategy

### Recommended Approach: pg_dump/pg_restore

For databases under 50GB, use pg_dump/pg_restore:

```bash
# Example for litellm (adapt for other databases)
NAMESPACE=litellm
OLD_POD=$(kubectl get pod -n $NAMESPACE -l cluster-name=litellm-postgresql -o jsonpath='{.items[0].metadata.name}')
NEW_POD=$(kubectl get pod -n $NAMESPACE -l cnpg.io/cluster=litellm-postgresql-cnpg -o jsonpath='{.items[0].metadata.name}')

# 1. Scale down application
kubectl scale deployment -n $NAMESPACE litellm-deployment --replicas=0

# 2. Dump from Zalando
kubectl exec -n $NAMESPACE $OLD_POD -- pg_dump -U litellm -d litellm -Fc > /tmp/litellm.dump

# 3. Restore to CNPG
kubectl cp /tmp/litellm.dump $NAMESPACE/$NEW_POD:/tmp/litellm.dump -c postgres
kubectl exec -n $NAMESPACE $NEW_POD -c postgres -- pg_restore -U litellm -d litellm --clean --if-exists /tmp/litellm.dump

# 4. Verify data
kubectl exec -n $NAMESPACE $NEW_POD -c postgres -- psql -U litellm -d litellm -c '\dt'

# 5. Update application manifests (see section above)

# 6. Scale up application
kubectl scale deployment -n $NAMESPACE litellm-deployment --replicas=1
```

### Alternative: Logical Replication (Zero Downtime)

For production environments requiring zero downtime, consider using PostgreSQL logical replication:
1. Configure publication on Zalando database
2. Configure subscription on CNPG database
3. Wait for initial sync
4. Cutover applications during maintenance window
5. Verify and cleanup

(See README.md for detailed instructions)

## Verification

After migration, verify each database:

```bash
# Test connectivity
kubectl run -it --rm psql --image=postgres:17 --restart=Never -- \
  psql -h litellm-postgresql-cnpg-rw.litellm.svc.cluster.local -U litellm -d litellm -c '\dt'

# Check backups are running
kubectl get backup -A

# Monitor cluster health
kubectl get cluster -A
kubectl describe cluster -n litellm litellm-postgresql-cnpg
```

## Rollback Plan

If issues occur, rollback is straightforward:

1. Scale down applications
2. Revert manifest changes (use old Zalando service names)
3. Scale up applications
4. Optionally delete CNPG clusters

```bash
# Example rollback
kubectl scale deployment -n litellm litellm-deployment --replicas=0
# Revert k8s/applications/ai/litellm/deployment.yaml
kubectl apply -f k8s/applications/ai/litellm/deployment.yaml
kubectl scale deployment -n litellm litellm-deployment --replicas=1
```

## Benefits of CNPG

- ✅ **Declarative Backups**: ScheduledBackup CRD instead of cron jobs
- ✅ **Point-in-Time Recovery**: Continuous WAL archiving
- ✅ **Built-in Monitoring**: Prometheus metrics via PodMonitor
- ✅ **High Availability**: Synchronous replication with automatic failover
- ✅ **Connection Pooling**: Built-in PgBouncer support (not enabled yet)
- ✅ **Automated Updates**: Rolling updates for minor versions
- ✅ **Better Observability**: Rich status conditions and events
- ✅ **Active Development**: CNCF project with regular releases

## Testing Checklist

- [ ] Create Bitwarden secrets for database credentials
- [ ] Apply CNPG manifests
- [ ] Verify clusters reach Ready state
- [ ] Verify S3 backups are configured
- [ ] Perform test migration with pg_dump/restore
- [ ] Update application manifests
- [ ] Test application connectivity
- [ ] Verify data integrity
- [ ] Test backup and restore procedures
- [ ] Monitor for 24 hours
- [ ] Delete Zalando resources

## Post-Migration Cleanup

Once migration is verified successful, remove Zalando resources:

```bash
# Delete Zalando postgresql resources
kubectl delete postgresql -n litellm litellm-postgresql
kubectl delete postgresql -n immich immich-postgresql
kubectl delete postgresql -n auth authentik-postgresql

# Delete Zalando operator (optional, if no other databases remain)
kubectl delete deployment -n postgres-operator postgres-operator
```

## Support

For issues or questions:
- Check CNPG documentation: https://cloudnative-pg.io
- Review cluster events: `kubectl describe cluster -n <namespace> <cluster-name>`
- Check operator logs: `kubectl logs -n cnpg-system deployment/cnpg-controller-manager`

---

**Ready for immediate production use after applying and migrating data.**
