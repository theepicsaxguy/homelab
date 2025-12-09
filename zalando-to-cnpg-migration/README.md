# Zalando to CNPG Migration

## Summary

Migrating **3 databases** from Zalando Postgres Operator to CloudNativePG (CNPG).

## Databases

| Database | Namespace | Instances | Storage | Version | Special Features |
|----------|-----------|-----------|---------|---------|------------------|
| litellm-postgresql | litellm | 1 | 10Gi | PG 17 | - |
| immich-postgresql | immich | 2 | 15Gi | PG 17 | pgvector (vectors) extension |
| authentik-postgresql | auth | 2 | 20Gi | PG 17 | - |

## Configuration

- **S3 Secret**: `longhorn-minio-credentials` (created via ExternalSecret from Bitwarden)
- **S3 Bucket**: `homelab-postgres-backups`
- **S3 Endpoint**: `http://minio.minio.svc.cluster.local:9000`
- **Backup Schedule**: Daily at 2 AM UTC
- **Credentials**: ExternalSecrets using `bitwarden-backend` ClusterSecretStore
- **Storage Class**: `longhorn`

## Prerequisites

Before applying these manifests, ensure the following Bitwarden secrets exist:

### Database Credentials (per database)

- `postgres-litellm-username` and `postgres-litellm-password`
- `postgres-immich-username` and `postgres-immich-password`
- `postgres-authentik-username` and `postgres-authentik-password`

### S3 Credentials (already exist)

- `infra-minio-s3-access-key`
- `infra-minio-s3-secret-key`
- `infra-minio-s3-endpoint-url`

## Apply Instructions

```bash
# Apply all manifests
kubectl apply -R -f zalando-to-cnpg-migration/

# Watch cluster creation (takes 2-5 min per cluster)
kubectl get cluster -A -w

# Verify all clusters are ready
kubectl wait --for=condition=Ready cluster -n litellm litellm-postgresql-cnpg --timeout=600s
kubectl wait --for=condition=Ready cluster -n immich immich-postgresql-cnpg --timeout=600s
kubectl wait --for=condition=Ready cluster -n auth authentik-postgresql-cnpg --timeout=600s
```

## Service Name Changes

Applications must be updated to use the new CNPG service names:

### LiteLLM
| Old (Zalando) | New (CNPG) | Usage |
|---------------|------------|-------|
| `litellm-postgresql` | `litellm-postgresql-cnpg-rw` | Read-Write |
| `litellm-postgresql` | `litellm-postgresql-cnpg-ro` | Read-Only |
| `litellm-postgresql` | `litellm-postgresql-cnpg-r` | Read (any) |

**Secret Change**: Replace `litellm.litellm-postgresql.credentials.postgresql.acid.zalan.do` with `litellm-postgresql-app-secret`

**Update**: `k8s/applications/ai/litellm/deployment.yaml`
- Update `DATABASE_URL` to use: `litellm-postgresql-cnpg-rw.litellm.svc.cluster.local:5432`
- Update secret references from Zalando secret to `litellm-postgresql-app-secret`

### Immich
| Old (Zalando) | New (CNPG) | Usage |
|---------------|------------|-------|
| `immich-postgresql` | `immich-postgresql-cnpg-rw` | Read-Write |
| `immich-postgresql` | `immich-postgresql-cnpg-ro` | Read-Only |
| `immich-postgresql` | `immich-postgresql-cnpg-r` | Read (any) |

**Secret Change**: Update `k8s/applications/media/immich/immich-server/externalsecret.yaml`
- Replace Zalando secret reference with: `immich-postgresql-app-secret`
- Remove `zalando-k8s-store.yaml` SecretStore (no longer needed)

**Update**: Connection string to use `immich-postgresql-cnpg-rw.immich.svc.cluster.local:5432`

### Authentik
| Old (Zalando) | New (CNPG) | Usage |
|---------------|------------|-------|
| `authentik-postgresql` | `authentik-postgresql-cnpg-rw` | Read-Write |
| `authentik-postgresql` | `authentik-postgresql-cnpg-ro` | Read-Only |
| `authentik-postgresql` | `authentik-postgresql-cnpg-r` | Read (any) |

**Secret Change**: Update `k8s/infrastructure/auth/authentik/values.yaml`
- Replace `authentik-user.authentik-postgresql.credentials.postgresql.acid.zalan.do` with `authentik-postgresql-app-secret`
- Update host to: `authentik-postgresql-cnpg-rw`

## Migration Steps

### Phase 1: Create CNPG Clusters (No Downtime)

1. Apply all CNPG manifests (creates new clusters alongside Zalando)
2. Wait for clusters to be ready
3. Verify backups are configured

```bash
kubectl apply -R -f zalando-to-cnpg-migration/
kubectl get cluster -A
kubectl get backup -A
```

### Phase 2: Data Migration (Requires Downtime)

For each database, perform the following steps:

#### Option A: pg_dump/pg_restore (Recommended for small databases < 10GB)

```bash
# Example for litellm
NAMESPACE=litellm
OLD_DB=litellm-postgresql
NEW_DB=litellm-postgresql-cnpg-rw
DATABASE=litellm

# Scale down application
kubectl scale deployment -n $NAMESPACE litellm-deployment --replicas=0

# Dump from Zalando
kubectl exec -n $NAMESPACE $OLD_DB-0 -- pg_dump -U litellm -d $DATABASE -Fc > /tmp/${DATABASE}.dump

# Restore to CNPG
kubectl exec -n $NAMESPACE ${NEW_DB}-1 -c postgres -- psql -U litellm -d $DATABASE -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
kubectl cp /tmp/${DATABASE}.dump $NAMESPACE/${NEW_DB}-1:/tmp/${DATABASE}.dump -c postgres
kubectl exec -n $NAMESPACE ${NEW_DB}-1 -c postgres -- pg_restore -U litellm -d $DATABASE /tmp/${DATABASE}.dump
```

#### Option B: Backup and Restore (For large databases)

1. Create a backup of the Zalando database
2. Use CNPG's barman-cloud-restore to restore from backup
3. This requires configuring CNPG to restore from the Zalando backup location

### Phase 3: Update Applications

Update each application's manifests to use the new CNPG service names and secrets:

```bash
# Update litellm
kubectl edit deployment -n litellm litellm-deployment

# Update immich
kubectl edit externalsecret -n immich immich-db-url

# Update authentik
kubectl edit helmrelease -n auth authentik
```

### Phase 4: Verify and Cleanup

1. Scale applications back up
2. Verify connectivity to new databases
3. Monitor for errors
4. Once stable, delete Zalando postgresql resources

```bash
# Delete Zalando resources (ONLY after verifying CNPG works)
kubectl delete postgresql -n litellm litellm-postgresql
kubectl delete postgresql -n immich immich-postgresql
kubectl delete postgresql -n auth authentik-postgresql
```

## Verification

```bash
# Check cluster status
kubectl get cluster -A

# Check pods
kubectl get pods -A -l cnpg.io/cluster

# Check backups
kubectl get backup -A
kubectl get scheduledbackup -A

# Test connectivity
kubectl run -it --rm debug --image=postgres:16 --restart=Never -- psql -h litellm-postgresql-cnpg-rw.litellm.svc.cluster.local -U litellm -d litellm
```

## Rollback Plan

If issues occur, rollback is simple since Zalando clusters remain in place during Phase 1-2:

1. Scale down applications
2. Update application configs to use old Zalando services
3. Scale up applications
4. Delete CNPG clusters

```bash
# Rollback example
kubectl scale deployment -n litellm litellm-deployment --replicas=0
# Revert manifest changes
kubectl apply -f k8s/applications/ai/litellm/deployment.yaml
kubectl scale deployment -n litellm litellm-deployment --replicas=1
kubectl delete cluster -n litellm litellm-postgresql-cnpg
```

## Features Gained with CNPG

- **Declarative Backups**: ScheduledBackup CRD for automated backups
- **Point-in-Time Recovery**: Continuous WAL archiving to S3
- **Monitoring**: Built-in Prometheus metrics via PodMonitor
- **High Availability**: Synchronous replication with configurable sync replicas
- **Connection Pooling**: Built-in PgBouncer support (not enabled in this migration)
- **Rolling Updates**: Automated PostgreSQL minor version updates
- **Better Resource Management**: Fine-grained control over storage and compute

## Support

For issues during migration:
- Check CNPG operator logs: `kubectl logs -n cnpg-system deployment/cnpg-controller-manager`
- Check cluster events: `kubectl describe cluster -n <namespace> <cluster-name>`
- Review pod logs: `kubectl logs -n <namespace> <pod-name> -c postgres`
