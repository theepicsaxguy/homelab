# CNPG B2 Backup Implementation Note

## Current Status

I've updated the authentik PostgreSQL cluster as an example of how to add B2 offsite backups to CNPG clusters.

## Approach

The configuration uses a dual-backup strategy:

1. **Primary WAL Archive**: Backblaze B2 (offsite, disaster recovery)
   - Real-time WAL shipping to B2
   - Compressed and encrypted
   - 30-day retention

2. **External Clusters**: Both B2 and MinIO configured for recovery
   - Can restore from either location
   - B2 for disaster recovery (site loss)
   - MinIO retained for fast local recovery (if available)

3. **Velero**: Still backs up entire PVCs to both MinIO (daily/weekly) and B2 (weekly)

## Remaining Work

The same pattern needs to be applied to the other 5 PostgreSQL clusters:

1. `/home/benjaminsanden/Dokument/Projects/homelab/k8s/applications/media/immich/immich-server/database.yaml`
2. `/home/benjaminsanden/Dokument/Projects/homelab/k8s/applications/ai/litellm/database.yaml`
3. `/home/benjaminsanden/Dokument/Projects/homelab/k8s/applications/automation/n8n/database.yaml`
4. `/home/benjaminsanden/Dokument/Projects/homelab/k8s/applications/ai/bytebot/postgres/database.yaml`
5. `/home/benjaminsanden/Dokument/Projects/homelab/k8s/applications/web/pinepods/database.yaml`

For each file:
1. Add ExternalSecret for `b2-cnpg-credentials` (same as authentik)
2. Add `authentik-b2-store` ObjectStore resource
3. Update `plugins` section to point to B2 store
4. Add `backup` section with barmanObjectStore to B2
5. Add `externalClusters` for both B2 and MinIO

## Prerequisites

Before applying these changes:
1. Complete [BACKBLAZE_B2_SETUP.md](BACKBLAZE_B2_SETUP.md)
2. Verify B2 credentials are in Bitwarden
3. Test B2 connectivity
4. Apply changes during a maintenance window (WAL archive switch can cause brief disruption)

## Testing

After applying:
```bash
# Verify ObjectStores are created
kubectl get objectstore -A

# Check cluster backup configuration
kubectl -n auth describe cluster authentik-postgresql

# Verify WAL archiving to B2
kubectl -n auth logs -l cnpg.io/cluster=authentik-postgresql -c postgres | grep "wal.*uploaded"

# Force a base backup to B2
kubectl cnpg backup authentik-postgresql -n auth
```

## Recovery Examples

Documented in disaster recovery scenarios (to be created).
