---
title: 'Disaster Recovery: Talos + Longhorn
'
---

This guide walks you through the complete disaster recovery process for a Talos Kubernetes cluster with Longhorn persistent storage, restoring both infrastructure and data from S3 backups.

## Prerequisites

Before starting the recovery process, ensure you have:

- **S3 Access**: Full access to the S3 bucket containing your Longhorn backups
- **Administrative Access**: Cluster admin privileges and `kubectl` configured
- **GitOps Tools**: Working knowledge of your GitOps setup (ArgoCD, etc.)
- **Longhorn Access**: Access to Longhorn UI or CLI/API tools
- **Infrastructure Code**: Your OpenTofu/Terraform configurations ready

## Recovery Workflow Overview

The disaster recovery process follows these sequential phases:

1. **Infrastructure Rebuild** - Recreate the Talos cluster and core components
2. **Storage Preparation** - Deploy and configure Longhorn with S3 connectivity
3. **Application Deployment** - Restore applications and create PVCs
4. **Data Restoration** - Restore volumes from S3 backups
5. **Verification** - Validate the complete recovery

---

## Phase 1: Infrastructure Rebuild

### 1.1 Recreate the Talos Cluster

Rebuild your cluster infrastructure using OpenTofu:

```bash
# Clean up existing resources
tofu destroy

# Apply image factory configurations first
tofu apply -target=module.talos.talos_image_factory_schematic.this -target=module.talos.talos_image_factory_schematic.updated

# Deploy the complete infrastructure
tofu apply
```

### 1.2 Deploy Core Infrastructure Components

Deploy the essential infrastructure components in the correct order:

```bash
# Deploy networking (Cilium)
kustomize build --enable-helm infrastructure/network/ | kubectl apply -f -

# Deploy CRDs
kubectl apply -k infrastructure/crds

# Deploy External Secrets Operator
kustomize build --enable-helm infrastructure/controllers/external-secrets/ | kubectl apply -f -

# Deploy Cert Manager
kustomize build --enable-helm infrastructure/controllers/cert-manager | kubectl apply -f -

# Configure Bitwarden access token for External Secrets
kubectl create secret generic bitwarden-access-token \
  --namespace external-secrets \
  --from-literal=token=<your-token>

# Reapply networking to ensure complete configuration
kustomize build --enable-helm infrastructure/network/ | kubectl apply -f -

# Deploy Longhorn storage
kustomize build --enable-helm infrastructure/storage/longhorn/ | kubectl apply -f -

# Deploy remaining infrastructure components
kustomize build --enable-helm infrastructure/ | kubectl apply -f -
```

**⚠️ Important**: Do not deploy applications with persistent volumes yet. This phase only sets up the core infrastructure.

---

## Phase 2: Storage Preparation

### 2.1 Verify Longhorn Health and S3 Connectivity

1. **Access Longhorn UI**
   - Use the LoadBalancer IP or configured domain (if ACME cert is approved)
   - Navigate to the Longhorn dashboard

2. **Prepare Nodes for Restore**
   - Go to **Node** section
   - **Disable scheduling** on all nodes to prevent automatic PVC creation during restore

3. **Verify S3 Backup Connection**
   - Navigate to **Settings → Backup Target**
   - Confirm S3 connection is active and backups are visible

### 2.2 Prepare for Volume Restoration

1. **Review Available Backups**
   - Go to **Backup** section
   - Set page results to 100 to see all backups
   - Identify the backups you need to restore

**Note**: Keep scheduling disabled until after volume restoration is complete.

---

## Phase 3: Application Deployment

### 3.1 Deploy Applications and Create PVCs

Redeploy your applications using your GitOps workflow. This creates the PVCs that will be bound to the restored volumes:

```bash
# Using ArgoCD
argocd app sync <your-app>

# Or direct kubectl application
kubectl apply -f k8s/applications/
```

**Expected State**: Applications will be in pending state, waiting for persistent volumes. This is normal at this stage.

---

## Phase 4: Data Restoration

### 4.1 Restore Volumes from S3 Backups

**Via Longhorn UI (Recommended for small numbers of volumes):**

1. Navigate to **Backup** section
2. For batch restoration:
   - Select all required backups
   - Click **Restore Latest Backup**
3. For individual volumes:
   - Go to **Volumes → Create Volume from Backup**
   - Select the appropriate backup from S3
   - **Critical**: Use the exact PVC name as the volume name
   - Complete the restore process

### 4.2 Re-enable Node Scheduling

After all volumes are restored:

1. Navigate to **Node** section
2. **Enable scheduling** on all nodes
3. Verify nodes show as schedulable

### 4.3 Alternative: Automated Restoration

For large-scale deployments with many volumes, consider using automation scripts or the Longhorn API. Reference implementation details can be found in [Longhorn Issue #1867](https://github.com/longhorn/longhorn/issues/1867).

---

## Phase 5: Verification and Validation

### 5.1 Check Resource Status

Monitor the recovery progress:

```bash
# Check PVC and Pod status across all namespaces
kubectl get pvc,pods -A

# Watch for status changes
kubectl get pvc,pods -A -w
```

**Expected Results**:

- All PVCs should show `Bound` status
- Pods should transition from `Pending` to `Running`

### 5.2 Verify Longhorn Volume Health

In the Longhorn UI:

1. Navigate to **Volume** section
2. Confirm all volumes show `Healthy` status
3. Verify volumes are attached to appropriate nodes
4. Check replica status and distribution

### 5.3 Application-Level Verification

Test your applications to ensure data integrity:

```bash
# Check application logs
kubectl logs -n <namespace> <pod-name>

# Verify application functionality
kubectl exec -n <namespace> <pod-name> -- <verification-command>
```

### 5.4 Data Integrity Checks

Perform application-specific data validation:

- Database connectivity and data consistency
- File system integrity for file-based applications
- Application-specific health checks

---

## Troubleshooting Common Issues

### Volume Restore Failures

- Verify S3 connectivity and credentials
- Check backup integrity in S3
- Ensure sufficient storage space on nodes

### PVC Binding Issues

- Confirm volume names exactly match PVC names
- Check StorageClass compatibility
- Verify node scheduling is enabled

### Application Startup Problems

- Review pod events: `kubectl describe pod <pod-name>`
- Check persistent volume mount points
- Verify application configuration and secrets

---

## Post-Recovery Tasks

After successful recovery:

1. **Update Monitoring**: Ensure all monitoring and alerting is functional
2. **Test Backups**: Verify new backup jobs are running correctly
   - Automated CronJobs handle MongoDB and Meilisearch snapshots. The MongoDB job writes backups to a separate `mongo-backup` volume. Confirm recent successful runs with `kubectl get jobs -n <namespace>`.
3. **Document Changes**: Record any configuration changes made during recovery
4. **Schedule DR Test**: Plan the next disaster recovery test

---

## Additional Resources

- [Longhorn Backup and Restore Documentation](https://longhorn.io/docs/snapshots-and-backups/backup-and-restore/volume-restore/)
- [CNCF GitOps Disaster Recovery Patterns](https://github.com/cncf/tag-app-delivery/blob/main/gitops/disaster-recovery.md)
- [Longhorn Community Automation Discussion](https://github.com/longhorn/longhorn/issues/1867)

---

## Quick Reference Commands

```bash
# Cluster rebuild
tofu destroy && tofu apply

# Infrastructure deployment
kustomize build --enable-helm infrastructure/network/ | kubectl apply -f -

# Status monitoring
kubectl get pvc,pods -A

# Application logs
kubectl logs -n <namespace> <pod-name>
```
