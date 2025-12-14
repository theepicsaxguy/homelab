# Authentik PostgreSQL Recovery - Quick Start

## What This Does

Recovers Authentik PostgreSQL from restored PVC `pvc-d90367da-3a78-4f7f-b112-4fbcb13cb7f4` (restored from Zalando Spilo
backup) and migrates from Zalando PostgreSQL to CloudNativePG.

## One-Command Recovery (Sequential)

```bash
cd /home/develop/homelab/k8s/infrastructure/auth/authentik/recover

# Set kubeconfig
export KUBECONFIG=/home/develop/homelab/config

# Step 0: Verify restored PVC
kubectl apply -f 00-restore-longhorn-backup.yaml
kubectl wait --for=condition=complete --timeout=120s job/verify-restored-pvc -n auth
kubectl logs -n auth job/verify-restored-pvc

# Step 1-2: Setup snapshots
kubectl apply -f 01-volumesnapshotclass.yaml
kubectl apply -f 02-volumesnapshot.yaml
kubectl wait --for=jsonpath='{.status.readyToUse}'=true volumesnapshot/auth-postgres-recovery -n auth --timeout=300s

# Step 3: Verify data
kubectl apply -f 03-verify-backup-data-job.yaml
kubectl wait --for=condition=complete --timeout=120s job/verify-backup-data -n auth
kubectl logs -n auth job/verify-backup-data

# Step 4: SKIPPED - Longhorn doesn't support creating PVCs from Kubernetes VolumeSnapshots
# We work directly on the restored PVC since we already have a snapshot (auth-postgres-recovery)
# The temp-postgres-fix PVC creation is skipped - jobs use pvc-d90367da-3a78-4f7f-b112-4fbcb13cb7f4 directly

# Step 5-7: Transform data (restructure, fix permissions, clean Zalando)
kubectl apply -f 05-restructure-pgdata-job.yaml
kubectl wait --for=condition=complete --timeout=300s job/restructure-pgdata -n auth

kubectl apply -f 06-fix-permissions-job.yaml
kubectl wait --for=condition=complete --timeout=300s job/fix-pgdata-permissions -n auth

kubectl apply -f 07-cleanup-zalando-artifacts-job.yaml
kubectl wait --for=condition=complete --timeout=300s job/fix-postgresql-conf -n auth

# Step 8: Inspect (optional but recommended)
kubectl apply -f 08-inspect-database-job.yaml
kubectl wait --for=condition=complete --timeout=300s job/inspect-postgres-database -n auth
kubectl logs -n auth job/inspect-postgres-database

# Step 9: Create clean snapshot
kubectl apply -f 09-volumesnapshot-fixed.yaml
kubectl wait --for=jsonpath='{.status.readyToUse}'=true volumesnapshot/auth-postgres-recovery-fixed -n auth --timeout=300s

# Step 10-11: Deploy CNPG
kubectl apply -f 10-objectstore.yaml
kubectl apply -f 11-cluster-recovery.yaml
kubectl wait --for=condition=ready --timeout=600s pod/authentik-postgresql-1 -n auth

# Step 12: Post-cluster configuration
kubectl apply -f 12-post-cluster-configuration-job.yaml
kubectl wait --for=condition=complete --timeout=300s job/authentik-post-recovery-config -n auth
kubectl logs -n auth job/authentik-post-recovery-config

echo "✅ Recovery complete!"
```

## Verification

```bash
# Check cluster
kubectl get cluster -n auth authentik-postgresql

# Check database
kubectl exec -n auth authentik-postgresql-1 -- psql -U postgres -d authentik -c "\dt"

# Check secret
echo "DB: $(kubectl get secret -n auth authentik-postgresql-app -o jsonpath='{.data.dbname}' | base64 -d)"
```

## Cleanup

```bash
# Note: temp-postgres-fix PVC is not created (Step 4 skipped due to Longhorn limitation)
kubectl delete job -n auth verify-restored-pvc verify-backup-data restructure-pgdata fix-pgdata-permissions fix-postgresql-conf inspect-postgres-database authentik-post-recovery-config
kubectl delete serviceaccount,role,rolebinding -n auth authentik-post-recovery
```

## Estimated Time

- Step 0 (Verify PVC): < 1 minute
- Steps 1-9 (Prepare): 10-15 minutes
- Steps 10-12 (Deploy): 5-10 minutes
- **Total: 17-26 minutes**

## Troubleshooting

If any step fails, check logs:

```bash
kubectl logs -n auth job/<job-name>
```

Then delete and retry:

```bash
kubectl delete job -n auth <job-name>
kubectl apply -f <step-file>.yaml
```

See [README.md](README.md) for detailed documentation.
