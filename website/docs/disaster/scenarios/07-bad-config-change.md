---
sidebar_position: 7
title: "Scenario 7: Bad Configuration Change"
---

# Scenario 7: Bad Configuration Change

## Symptoms

- ArgoCD deployed broken configuration causing service outages
- OpenTofu/Terraform apply destroyed or misconfigured infrastructure
- Git commit introduced breaking changes to Kubernetes manifests
- Cluster resources deleted or modified by automation
- Applications failing to start after configuration update
- Services unreachable after infrastructure change
- Resource quotas exceeded due to misconfiguration

## Impact Assessment

- **Recovery Time Objective (RTO)**: 30 minutes - 2 hours
- **Recovery Point Objective (RPO)**: Minimal (revert to previous git commit)
- **Data Loss Risk**: Low (application data usually preserved, only configuration affected)
- **Service Availability**: Partial or complete outage until reverted
- **Blast Radius**: Can range from single application to entire cluster

## Prerequisites

- Git repository access with push permissions
- `kubectl` access to the cluster
- ArgoCD CLI or web UI access
- OpenTofu/Terraform CLI installed
- Knowledge of what changed (git history)
- Backup access if data was affected

## Recovery Procedure

### Step 1: Identify the Bad Change

Determine what changed and when:

```bash
# Check recent git commits
cd /home/benjaminsanden/Dokument/Projects/homelab
git log --oneline --decorate --graph -20

# See what files were changed
git show HEAD
git diff HEAD~1

# Check ArgoCD application status
argocd app list
argocd app get <app-name>

# Check which apps are unhealthy
argocd app list --output json | jq '.[] | select(.status.health.status != "Healthy") | {name: .metadata.name, health: .status.health.status}'

# Check recent Kubernetes events
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -30

# Check which resources were recently modified
kubectl get all -A -o json | jq -r '.items[] | select(.metadata.creationTimestamp > "'$(date -u -d '1 hour ago' --rfc-3339=seconds)'") | "\(.kind)/\(.metadata.name) in \(.metadata.namespace)"'
```

### Step 2: Quick Assessment of Impact

Determine the severity and scope:

```bash
# Check cluster overall health
kubectl get nodes
kubectl get pods -A | grep -v Running
kubectl top nodes

# Check critical services
kubectl -n kube-system get pods
kubectl -n argocd get pods
kubectl -n monitoring get pods

# Check if databases are affected
kubectl get clusters.postgresql.cnpg.io -A
kubectl -n database get pods

# Check persistent volumes
kubectl get pv,pvc -A | grep -v Bound
```

### Step 3: Immediate Mitigation

Choose the fastest recovery path:

#### Option A: Git Revert (Recommended for most cases)

If the bad change was deployed via GitOps:

```bash
cd /home/benjaminsanden/Dokument/Projects/homelab

# View the problematic commit
git log --oneline -5
git show <commit-hash>

# Option 1: Revert the last commit (creates new revert commit)
git revert HEAD
git push origin main

# Option 2: Revert specific commit (if not the latest)
git revert <commit-hash>
git push origin main

# Option 3: Hard reset to previous commit (DESTRUCTIVE - use with caution)
# Only if you're sure no one else pushed commits
git log --oneline -5
git reset --hard <good-commit-hash>
git push --force origin main  # CAUTION: This rewrites history

# After git revert/reset, sync ArgoCD
argocd app sync --all
# Or sync specific app
argocd app sync <app-name>
```

#### Option B: Manual Kubernetes Rollback

If the change was applied directly to Kubernetes:

```bash
# Rollback a deployment to previous revision
kubectl -n <namespace> rollout undo deployment/<deployment-name>

# Rollback to specific revision
kubectl -n <namespace> rollout history deployment/<deployment-name>
kubectl -n <namespace> rollout undo deployment/<deployment-name> --to-revision=<number>

# Check rollback status
kubectl -n <namespace> rollout status deployment/<deployment-name>

# Rollback statefulset
kubectl -n <namespace> rollout undo statefulset/<statefulset-name>

# View current and previous configurations
kubectl -n <namespace> get deployment <deployment-name> -o yaml > current.yaml
kubectl -n <namespace> rollout history deployment/<deployment-name> --revision=<prev-num> > previous.yaml
diff previous.yaml current.yaml
```

#### Option C: ArgoCD Manual Sync to Previous Version

If the app is out of sync:

```bash
# Sync to specific git revision
argocd app sync <app-name> --revision <good-commit-hash>

# Or via ArgoCD UI:
# 1. Navigate to application
# 2. Click "History and Rollback"
# 3. Select previous successful deployment
# 4. Click "Rollback"

# Verify sync status
argocd app wait <app-name> --health
```

### Step 4: OpenTofu/Terraform Recovery

If infrastructure was misconfigured or destroyed:

```bash
cd /home/benjaminsanden/Dokument/Projects/homelab/tofu

# Check what Terraform thinks changed
tofu plan

# View Terraform state to see what exists
tofu state list
tofu show

# If resources were deleted, restore from state
# Option 1: Revert git changes first
cd ..
git revert HEAD
cd tofu

# Option 2: Import existing resources back into state
# If resources still exist but were removed from state:
tofu import <resource-type>.<name> <resource-id>

# Example: Import Kubernetes namespace
tofu import kubernetes_namespace.auth auth

# If resources were destroyed, recreate them
tofu apply

# Verify no unexpected changes
tofu plan  # Should show "No changes"
```

**If Terraform destroyed critical resources:**

```bash
# Check Terraform state backup
ls -lah /home/benjaminsanden/Dokument/Projects/homelab/tofu/terraform.tfstate.backup
cp terraform.tfstate.backup terraform.tfstate

# Or restore from git history
git checkout HEAD~1 -- terraform.tfstate
tofu refresh
tofu plan

# Reapply infrastructure
tofu apply
```

### Step 5: Verify Service Recovery

```bash
# Check all pods are running
kubectl get pods -A | grep -v "Running\|Completed"

# Check services are accessible
kubectl get svc -A

# Test critical applications
kubectl -n <namespace> port-forward svc/<service> 8080:80
curl http://localhost:8080/health

# Check ingress/loadbalancer status
kubectl get ingress -A
kubectl get svc -l type=LoadBalancer -A

# Verify databases are healthy
kubectl get clusters.postgresql.cnpg.io -A
kubectl -n database exec -it <postgres-pod> -- psql -U postgres -c "SELECT 1;"

# Check persistent volumes are bound
kubectl get pvc -A | grep -v Bound
```

### Step 6: ArgoCD Re-sync All Applications

Ensure all applications are in sync with git:

```bash
# Get list of out-of-sync applications
argocd app list --output json | jq -r '.[] | select(.status.sync.status != "Synced") | .metadata.name'

# Sync all applications
argocd app sync --all

# Watch sync progress
watch -n 2 'argocd app list'

# Check for any errors
argocd app list --output json | jq -r '.[] | select(.status.sync.status == "OutOfSync" or .status.health.status != "Healthy") | {name: .metadata.name, sync: .status.sync.status, health: .status.health.status}'

# View application details if issues persist
argocd app get <app-name> --show-operation

# Force sync if needed (will delete resources not in git)
argocd app sync <app-name> --force
```

### Step 7: Data Integrity Check

Verify no data was lost:

```bash
# Check PVC status
kubectl get pvc -A

# For PostgreSQL databases, verify data
kubectl -n database exec -it <postgres-pod> -- bash
psql -U postgres

# Inside PostgreSQL:
\l  # List databases
\c <database>  # Connect to database
SELECT COUNT(*) FROM <critical-table>;
SELECT MAX(created_at) FROM <critical-table>;  # Check latest record

# Check application data via API
curl -H "Authorization: Bearer $TOKEN" https://app.example.com/api/health
```

**If data was affected, restore from backup:**

```bash
# List recent backups
velero backup get | head -10

# Restore only affected namespace's PVCs
velero restore create restore-config-fix-$(date +%Y%m%d-%H%M%S) \
  --from-backup <backup-name> \
  --include-namespaces <namespace> \
  --include-resources persistentvolumeclaims,persistentvolumes

# For database, use CNPG point-in-time recovery
# See: 01-accidental-deletion.md for detailed CNPG recovery
```

## Common Scenarios and Solutions

### Scenario 1: ArgoCD Deployed Broken Manifest

```bash
# Symptoms: App shows "OutOfSync" or "Degraded"
argocd app get <app-name>

# Solution:
cd /home/benjaminsanden/Dokument/Projects/homelab
git revert HEAD
git push origin main
argocd app sync <app-name>

# Alternative: Edit in place, then update git
kubectl -n <namespace> edit deployment <name>
# Fix the issue
# Then update git to match
```

### Scenario 2: Resource Quotas Exceeded

```bash
# Symptoms: Pods show "FailedCreate" with quota errors
kubectl describe pod <pod-name>

# Check quotas
kubectl get resourcequota -A
kubectl describe resourcequota -n <namespace>

# Solution: Revert resource changes or increase quota
git revert HEAD  # If resource requests were increased
# Or increase quota
kubectl -n <namespace> edit resourcequota <quota-name>
```

### Scenario 3: NetworkPolicy Broke Connectivity

```bash
# Symptoms: Pods can't communicate, "no route to host"
kubectl -n <namespace> get networkpolicy

# Temporary fix: Delete blocking policy
kubectl -n <namespace> delete networkpolicy <policy-name>

# Permanent fix: Revert git change
git revert HEAD
git push origin main
argocd app sync <app-name>
```

### Scenario 4: ConfigMap/Secret Update Broke App

```bash
# Symptoms: App crashes after ConfigMap/Secret change
kubectl -n <namespace> get configmap,secret

# View current vs previous
kubectl -n <namespace> get configmap <name> -o yaml

# Rollback by editing in place
kubectl -n <namespace> edit configmap <name>
# Or restore from git
git show HEAD~1:k8s/apps/<app>/configmap.yaml | kubectl apply -f -

# Restart pods to pick up change
kubectl -n <namespace> rollout restart deployment/<name>
```

### Scenario 5: Helm Chart Upgrade Failed

```bash
# Symptoms: Helm release in failed state
helm list -A | grep -i failed

# Check release history
helm history <release-name> -n <namespace>

# Rollback to previous release
helm rollback <release-name> <revision> -n <namespace>

# Or uninstall and reinstall from git
helm uninstall <release-name> -n <namespace>
argocd app sync <app-name>
```

## Post-Recovery Tasks

### 1. Root Cause Analysis

```bash
# Document what went wrong
cat > /home/benjaminsanden/Dokument/Projects/homelab/docs/incidents/bad-config-$(date +%Y%m%d).md <<EOF
# Configuration Change Incident

**Date**: $(date)
**Affected Services**: <list>
**Downtime**: <duration>
**Git Commit**: $(git rev-parse HEAD)

## What Happened
<description of the bad change>

## Impact
- Services affected: <list>
- Users impacted: <number/description>
- Data lost: <none/description>

## Recovery Steps
1. Reverted git commit <hash>
2. Synced ArgoCD applications
3. Verified service restoration

## Root Cause
<why the bad change was introduced>

## Prevention
- [ ] Add pre-commit validation
- [ ] Implement staging environment testing
- [ ] Review change approval process
- [ ] Add monitoring alerts for this failure mode
EOF
```

### 2. Implement Change Controls

```bash
# Add pre-commit hooks for validation
cd /home/benjaminsanden/Dokument/Projects/homelab
cat > .pre-commit-config.yaml <<EOF
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace

  - repo: https://github.com/norwoodj/helm-docs
    rev: v1.11.0
    hooks:
      - id: helm-docs

  - repo: local
    hooks:
      - id: kubectl-validate
        name: Validate Kubernetes manifests
        entry: bash -c 'kubectl apply --dry-run=client -f'
        language: system
        files: \\.yaml$
        pass_filenames: true
EOF

pre-commit install
```

### 3. Add ArgoCD Sync Waves

Prevent cascading failures by controlling deployment order:

```yaml
# In your Kubernetes manifests, add annotations:
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Deploy first
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  annotations:
    argocd.argoproj.io/sync-wave: "2"  # Deploy after database
```

### 4. Enable ArgoCD Auto-Rollback

```yaml
# In ArgoCD Application spec:
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      # Rollback on failed deployment
    retry:
      limit: 2
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### 5. Set up Staging Environment

```bash
# Create staging namespace/cluster
kubectl create namespace staging

# Deploy to staging first, then production
# Update ArgoCD ApplicationSet to deploy to staging first
```

## Troubleshooting

### Git Revert Doesn't Fix Issue

```bash
# Check if there are multiple bad commits
git log --oneline -10

# Revert multiple commits
git revert HEAD~3..HEAD
git push origin main

# Or reset to known-good commit
git log --oneline -20
# Find last known-good commit
git reset --hard <good-commit-hash>
git push --force origin main
```

### ArgoCD Won't Sync

```bash
# Check ArgoCD application status
argocd app get <app-name>

# View sync errors
argocd app logs <app-name> --follow

# Check ArgoCD repo connection
argocd repo list
argocd repo get https://github.com/theepicsaxguy/homelab.git

# Force refresh repository
argocd app sync <app-name> --force --prune

# Check ArgoCD controller logs
kubectl -n argocd logs -l app.kubernetes.io/name=argocd-application-controller --tail=100
```

### Terraform State is Corrupted

```bash
# Restore from backup
cd /home/benjaminsanden/Dokument/Projects/homelab/tofu
cp terraform.tfstate.backup terraform.tfstate

# Or restore from git
git log --all --full-history -- terraform.tfstate
git show <commit-hash>:tofu/terraform.tfstate > terraform.tfstate

# Refresh state from actual infrastructure
tofu refresh

# If completely broken, recreate state
# Import all resources one by one
tofu import <resource>.<name> <id>
```

### Changes Reverted but Pods Still Failing

```bash
# Old pods may be running with old config
# Force restart all deployments
kubectl -n <namespace> rollout restart deployment --all

# Or delete pods to force recreation
kubectl -n <namespace> delete pods --all

# Check if ConfigMaps/Secrets need updating
kubectl -n <namespace> get configmap,secret -o yaml

# Check image pull errors
kubectl -n <namespace> describe pods | grep -A 5 "Failed"
```

## Prevention Strategies

### Immediate Actions

1. **Enable pre-commit hooks**: Validate YAML before commit
2. **Require PR reviews**: No direct commits to main branch
3. **Add ArgoCD sync windows**: Prevent syncs during critical times
4. **Enable ArgoCD notifications**: Alert on failed syncs
5. **Document change procedures**: Checklist for config changes

### Long-term Improvements

```bash
# 1. Set up GitHub branch protection
# In GitHub repo settings:
# - Require pull request reviews
# - Require status checks (CI tests)
# - Require signed commits

# 2. Add CI validation pipeline
# .github/workflows/validate.yaml
cat > .github/workflows/validate.yaml <<EOF
name: Validate
on: [pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate Kubernetes manifests
        run: |
          kubectl apply --dry-run=client -f k8s/ -R
      - name: Validate Terraform
        run: |
          cd tofu
          terraform init -backend=false
          terraform validate
EOF

# 3. Implement staging environment
# Deploy changes to staging first, verify, then promote to production

# 4. Add monitoring alerts
# Alert when ArgoCD apps become unhealthy
# Alert when pods crash loop

# 5. Regular backup testing
# Monthly: Test restoring from backup
# Verify rollback procedures work
```

## Related Scenarios

- [Scenario 1: Accidental Deletion](01-accidental-deletion.md) - If config change deleted resources
- [Scenario 2: Disk Failure](02-disk-failure.md) - If bad change broke storage
- [Scenario 8: Data Corruption](08-data-corruption.md) - If config change corrupted data

## Reference

- [ArgoCD Sync Options](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/)
- [Kubernetes Rollback](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)
- [OpenTofu State Management](https://opentofu.org/docs/language/state/)
- [Git Revert vs Reset](https://git-scm.com/docs/git-revert)
