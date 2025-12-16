# Authentik PostgreSQL Recovery - Quick Start

## What This Does

Recovers Authentik PostgreSQL from Longhorn backup `backup-14c8704f5cbd43d0` (from Dec 2, 2025) and migrates from Zalando PostgreSQL to CloudNativePG.

## One-Command Recovery (Sequential)

```bash
cd /home/develop/homelab/k8s/infrastructure/auth/authentik/recover

# Set kubeconfig
export KUBECONFIG=/home/develop/homelab/config

# Step 0: Restore from Longhorn backup
kubectl apply -f 00-restore-longhorn-backup.yaml
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/backup-14c8704f5cbd43d0 -n auth --timeout=900s

# Step 1-2: Setup snapshots
kubectl apply -f 01-volumesnapshotclass.yaml
kubectl apply -f 02-volumesnapshot.yaml
kubectl wait --for=jsonpath='{.status.readyToUse}'=true volumesnapshot/auth-postgres-recovery -n auth --timeout=300s

# Step 3: Verify data
kubectl apply -f 03-verify-backup-data-job.yaml
kubectl wait --for=condition=complete --timeout=120s job/verify-backup-data -n auth
kubectl logs -n auth job/verify-backup-data

# Step 4: Create temp workspace
kubectl apply -f 04-temp-restore-pvc.yaml
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/temp-postgres-fix -n auth --timeout=600s

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
kubectl delete pvc temp-postgres-fix -n auth
kubectl delete job -n auth verify-backup-data restructure-pgdata fix-pgdata-permissions fix-postgresql-conf inspect-postgres-database authentik-post-recovery-config
kubectl delete serviceaccount,role,rolebinding -n auth authentik-post-recovery
```

## Estimated Time

- Step 0 (Restore): 5-15 minutes
- Steps 1-9 (Prepare): 10-15 minutes
- Steps 10-12 (Deploy): 5-10 minutes
- **Total: 20-40 minutes**

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
