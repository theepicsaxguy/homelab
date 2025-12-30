---
sidebar_position: 3
title: "Scenario 3: Host Failure"
---

# Scenario 3: Host Failure

## Symptoms

- Proxmox host (host3.peekoff.com) won't boot or is completely unresponsive
- Hardware failure (motherboard, multiple disk failures, power supply)
- BIOS/UEFI errors preventing boot
- Complete loss of Proxmox hypervisor
- All VMs (control planes and workers) are down
- Cluster is completely inaccessible (no API, no nodes)
- Cannot SSH to Proxmox host

## Impact Assessment

- **Recovery Time Objective (RTO)**: 4-8 hours
- **Recovery Point Objective (RPO)**: Up to 1 week (weekly B2 backup)
- **Data Loss Risk**: Moderate - depends on age of last B2 backup
- **Service Availability**: Complete outage of all services
- **Prerequisites**: May require hardware replacement or repair

## Prerequisites

- Physical access to the Proxmox host or replacement hardware
- Working Proxmox installation media (USB/ISO)
- `tofu` (OpenTofu) CLI installed on your workstation
- `talosctl` CLI installed on your workstation
- `kubectl` CLI installed on your workstation
- `argocd` CLI installed (optional but recommended)
- Access to GitHub repository: `theepicsaxguy/homelab`
- Backblaze B2 credentials (stored in Bitwarden)
- Bitwarden access token for External Secrets
- Proxmox API token and credentials
- Network access to the 10.25.150.0/24 VLAN

## Recovery Procedure

### Step 1: Assess Hardware Failure

Determine if hardware needs replacement or repair:

**Check Hardware:**

```bash
# If host is accessible at all, check system logs
ssh root@host3.peekoff.com
dmesg | grep -i "error\|fail"
journalctl -xe

# Check hardware status
lscpu
lsmem
lspci
smartctl -a /dev/sda  # Check all disks
```

**Decision Point:**

- **Repairable**: Proceed with reinstallation on existing hardware
- **Hardware replacement needed**: Provision new hardware, then proceed

### Step 2: Install Fresh Proxmox

Install Proxmox VE on the host:

**Installation Steps:**

1. Boot from Proxmox VE installation media
2. Follow installation wizard:
   - Hostname: `host3.peekoff.com`
   - IP Address: `10.25.150.3` (or whatever your Proxmox host IP was)
   - Gateway: `10.25.150.1`
   - DNS: `10.25.150.1`
   - Set root password (store in Bitwarden)

3. After installation, access Proxmox web UI:
   ```
   https://10.25.150.3:8006
   ```

4. Update Proxmox:
   ```bash
   ssh root@host3.peekoff.com
   apt update && apt upgrade -y
   ```

**Configure Storage:**

```bash
# Create or configure storage pools
# If using ZFS (recommended):
zpool create -f Nvme1 /dev/nvme0n1
zpool create -f Nvme2 /dev/nvme1n1

# Or for existing pools, import them:
zpool import
zpool import Nvme1
zpool import Nvme2

# Verify storage
pvesm status
```

**Configure Networking:**

```bash
# Edit network config
nano /etc/network/interfaces

# Ensure vmbr0 is configured for VLAN 150:
# auto vmbr0
# iface vmbr0 inet static
#     address 10.25.150.3/24
#     gateway 10.25.150.1
#     bridge-ports eno1
#     bridge-stp off
#     bridge-fd 0

# Apply network changes
ifreload -a
```

### Step 3: Clone Infrastructure Repository

On your workstation, clone the homelab repository:

```bash
# Clone repository
git clone git@github.com:theepicsaxguy/homelab.git
cd homelab

# Verify you're on the main branch
git checkout main
git pull origin main
```

### Step 4: Configure OpenTofu Backend for B2

Set up credentials for B2 remote state:

```bash
# Set B2 credentials as environment variables
# (Get these from Bitwarden: "backblaze-b2-velero-offsite")
export AWS_ACCESS_KEY_ID="<B2_keyID>"
export AWS_SECRET_ACCESS_KEY="<B2_applicationKey>"

# Verify backend configuration
cd tofu
cat backend.tf
```

Uncomment the backend configuration in `/home/benjaminsanden/Dokument/Projects/homelab/tofu/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket = "homelab-terraform-state"
    key    = "proxmox/terraform.tfstate"
    region = "us-west-000"

    endpoint = "https://s3.us-west-000.backblazeb2.com"

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = false
  }
}
```

### Step 5: Initialize OpenTofu with Remote State

Initialize OpenTofu and pull state from B2:

```bash
cd /path/to/homelab/tofu

# Initialize with B2 backend
tofu init

# Verify state is pulled from B2
tofu show

# Review what will be created
tofu plan
```

### Step 6: Configure Proxmox Provider Credentials

Set up Proxmox API credentials:

```bash
# Create .auto.tfvars file with Proxmox credentials
# (Get API token from Proxmox or Bitwarden)

cat > terraform.auto.tfvars <<EOF
proxmox = {
  name         = "host3"
  cluster_name = "host3"
  endpoint     = "https://host3.peekoff.com:8006"
  insecure     = true
  username     = "root@pam"
  api_token    = "<PROXMOX_API_TOKEN>"
}
EOF

# Protect the credentials file
chmod 600 terraform.auto.tfvars
```

**Or use environment variables:**

```bash
export TF_VAR_proxmox='{"name":"host3","cluster_name":"host3","endpoint":"https://host3.peekoff.com:8006","insecure":true,"username":"root@pam","api_token":"<TOKEN>"}'
```

### Step 7: Deploy Infrastructure with OpenTofu

Deploy the Talos cluster VMs:

```bash
# Apply infrastructure (creates VMs)
tofu apply

# Review changes and type 'yes' to confirm
# This will create:
# - 3 control plane VMs (ctrl-00, ctrl-01, ctrl-02)
# - 3 worker VMs (work-00, work-01, work-02)
# - 2 load balancer VMs (lb-00, lb-01) if enabled
```

**Expected VM Configuration:**

- **Control Planes:**
  - ctrl-00: 10.25.150.11
  - ctrl-01: 10.25.150.12
  - ctrl-02: 10.25.150.13

- **Workers:**
  - work-00: 10.25.150.21
  - work-01: 10.25.150.22
  - work-02: 10.25.150.23

- **VIP:** 10.25.150.10

### Step 8: Bootstrap Talos Cluster

Bootstrap the Talos cluster using generated configs:

```bash
# Talos configs are generated in tofu/outputs/
cd tofu

# Export talosconfig
export TALOSCONFIG=$(pwd)/outputs/talosconfig

# Verify connectivity to nodes
talosctl -n 10.25.150.11 version
talosctl -n 10.25.150.12 version
talosctl -n 10.25.150.13 version

# Bootstrap the first control plane
talosctl bootstrap -n 10.25.150.11

# Wait for bootstrap (5-10 minutes)
# Monitor bootstrap progress
talosctl -n 10.25.150.11 dmesg -f
talosctl -n 10.25.150.11 health --wait-timeout 10m
```

### Step 9: Configure kubectl Access

Generate and configure kubeconfig:

```bash
# Generate kubeconfig
talosctl -n 10.25.150.11 kubeconfig outputs/kubeconfig

# Or merge with existing kubeconfig
talosctl -n 10.25.150.11 kubeconfig ~/.kube/config --force

# Set context
kubectl config use-context talos

# Verify cluster access
kubectl get nodes
kubectl get pods -A
```

**Wait for all nodes to become Ready:**

```bash
# Watch node status
kubectl get nodes -w

# All nodes should be Ready:
# NAME      STATUS   ROLES           AGE   VERSION
# ctrl-00   Ready    control-plane   5m    v1.34.3
# ctrl-01   Ready    control-plane   5m    v1.34.3
# ctrl-02   Ready    control-plane   5m    v1.34.3
# work-00   Ready    <none>          5m    v1.34.3
# work-01   Ready    <none>          5m    v1.34.3
# work-02   Ready    <none>          5m    v1.34.3
```

### Step 10: Deploy Core Infrastructure

Deploy essential infrastructure components in order:

**1. Deploy CRDs:**

```bash
cd /path/to/homelab/k8s

# Apply CRDs
kubectl apply -k infrastructure/crds/
```

**2. Deploy External Secrets Operator:**

```bash
# Deploy External Secrets
kustomize build --enable-helm infrastructure/controllers/external-secrets/ | kubectl apply -f -

# Wait for External Secrets to be ready
kubectl -n external-secrets wait --for=condition=available deployment/external-secrets --timeout=300s
kubectl -n external-secrets wait --for=condition=available deployment/external-secrets-cert-controller --timeout=300s
kubectl -n external-secrets wait --for=condition=available deployment/external-secrets-webhook --timeout=300s
```

**3. Configure Bitwarden Secret Store:**

```bash
# Create Bitwarden access token secret
# (Get token from Bitwarden)
kubectl create secret generic bitwarden-access-token \
  --namespace external-secrets \
  --from-literal=token="<BITWARDEN_ACCESS_TOKEN>"

# Verify External Secrets can access Bitwarden
kubectl -n external-secrets get clustersecretstore bitwarden-backend
kubectl -n external-secrets get clustersecretstore bitwarden-backend -o yaml | grep status -A 5
```

**4. Deploy Cert Manager:**

```bash
# Deploy Cert Manager
kustomize build --enable-helm infrastructure/controllers/cert-manager/ | kubectl apply -f -

# Wait for Cert Manager
kubectl -n cert-manager wait --for=condition=available deployment/cert-manager --timeout=300s
```

**5. Deploy Longhorn Storage:**

```bash
# Deploy Longhorn
kustomize build --enable-helm infrastructure/storage/longhorn/ | kubectl apply -f -

# Wait for Longhorn (may take 5-10 minutes)
kubectl -n longhorn-system wait --for=condition=available deployment/longhorn-driver-deployer --timeout=600s

# Verify Longhorn nodes
kubectl -n longhorn-system get nodes
```

**6. Deploy Remaining Infrastructure:**

```bash
# Deploy all infrastructure
kustomize build --enable-helm infrastructure/ | kubectl apply -f -

# Monitor deployment
kubectl get pods -A -w
```

### Step 11: Deploy ArgoCD

Deploy ArgoCD for GitOps:

```bash
# ArgoCD should be part of infrastructure deployment
# Verify ArgoCD is running
kubectl -n argocd get pods

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access ArgoCD UI
kubectl -n argocd port-forward svc/argocd-server 8080:443
# Navigate to https://localhost:8080

# Or use ArgoCD CLI
argocd login localhost:8080 --username admin --password <password>
```

### Step 12: Sync Applications with ArgoCD

Sync all applications:

```bash
# List all applications
argocd app list

# Sync all applications
argocd app sync -l argocd.argoproj.io/instance=applications

# Or sync individually
argocd app sync <app-name>

# Monitor sync status
argocd app list
kubectl get applications -n argocd -w
```

**Or via kubectl:**

```bash
# Sync all apps by deleting and reapplying
kubectl delete applications -n argocd --all
kubectl apply -k infrastructure/deployment/argocd/applications/
```

### Step 13: Restore Data from Velero/B2

Restore application data from B2 backups:

**Deploy Velero:**

```bash
# Velero should be deployed as part of infrastructure
kubectl -n velero get pods

# Verify B2 backup location
kubectl -n velero get backupstoragelocations
```

**List Available Backups:**

```bash
# List B2 backups
velero backup get --storage-location backblaze-b2

# Check specific backup details
velero backup describe <backup-name> --details
```

**Restore from Latest Backup:**

```bash
# Find the latest weekly offsite backup
LATEST_BACKUP=$(velero backup get --storage-location backblaze-b2 \
  --selector backup-type=weekly-offsite \
  -o json | jq -r '.items | sort_by(.metadata.creationTimestamp) | .[-1].metadata.name')

echo "Latest backup: $LATEST_BACKUP"

# Create restore (exclude namespaces that shouldn't be restored)
velero restore create host-failure-restore-$(date +%Y%m%d-%H%M%S) \
  --from-backup $LATEST_BACKUP \
  --exclude-namespaces velero,cert-manager,external-secrets,argocd,longhorn-system

# Monitor restore
velero restore get
velero restore logs host-failure-restore-<timestamp>
```

**Restore Individual Namespaces (if preferred):**

```bash
# Restore specific critical namespaces
for ns in auth media applications; do
  velero restore create restore-${ns}-$(date +%Y%m%d-%H%M%S) \
    --from-backup $LATEST_BACKUP \
    --include-namespaces $ns
done
```

## Validation

### Check Infrastructure Components

```bash
# Check all pods are running
kubectl get pods -A | grep -v Running | grep -v Completed

# Check nodes
kubectl get nodes

# Check Longhorn
kubectl -n longhorn-system get pods
kubectl -n longhorn-system get volumes

# Check Velero
kubectl -n velero get pods

# Check ArgoCD
kubectl -n argocd get applications
```

### Check Application Status

```bash
# List all namespaces
kubectl get namespaces

# Check application pods
kubectl get pods -A

# Check PVCs are bound
kubectl get pvc -A

# Check services
kubectl get svc -A
```

### Verify Data Integrity

**For PostgreSQL databases:**

```bash
# List CNPG clusters
kubectl get clusters -A

# Check cluster health
kubectl -n <namespace> get cluster <cluster-name>

# Verify database connectivity
kubectl -n <namespace> exec -it <postgres-pod> -- psql -U postgres -c "SELECT version();"

# Check data exists
kubectl -n <namespace> exec -it <postgres-pod> -- psql -U postgres -c "SELECT COUNT(*) FROM <table>;"
```

**For applications:**

- Access application UIs and verify functionality
- Check user data exists
- Test login and authentication
- Verify recent data is present (within RPO window)

### Check External Connectivity

```bash
# Verify DNS resolution
kubectl run -it --rm debug --image=alpine --restart=Never -- nslookup google.com

# Check ingress
kubectl get ingress -A

# Test external access to applications
curl -k https://<your-domain>
```

## Post-Recovery Tasks

### 1. Document the Incident

```bash
cat > docs/incidents/host-failure-$(date +%Y%m%d).md <<EOF
# Host Failure Incident

**Date**: $(date)
**Failed Host**: host3.peekoff.com
**Cause**: <hardware failure description>
**Recovery Time**: <duration>
**Data Loss**: <RPO - age of last backup>
**Backup Used**: $LATEST_BACKUP

## What Happened
<description of the failure>

## Hardware Actions Taken
- <hardware replacement/repair details>

## Recovery Steps
1. Fresh Proxmox installation
2. OpenTofu apply from B2 state (includes Talos cluster bootstrap and ArgoCD deployment)
3. Verify ArgoCD ApplicationSets synced
4. Velero restore from B2

## Lessons Learned
<what went well, what could be improved>

## Follow-up Actions
- [ ] Monitor hardware health
- [ ] Review backup frequency
- [ ] Test backup restoration more frequently
EOF
```

### 2. Verify Backup Schedules

```bash
# Check Velero schedules
velero schedule get

# Verify backups are running
velero backup get | head -20

# Check Longhorn backup schedules
kubectl -n longhorn-system get recurringjobs

# Verify CNPG backups
kubectl get scheduledbackups -A
```

### 3. Update Documentation

Update infrastructure documentation with:
- New hardware details (if replaced)
- Recovery timeline and actual RTO
- Any configuration changes made
- Updated network diagrams

### 4. Review and Test

Schedule follow-up tasks:
- Test restore procedure again in 90 days
- Review backup retention policies
- Consider increasing backup frequency
- Implement hardware monitoring/alerting

### 5. Commit State Changes

If any infrastructure changes were made:

```bash
cd /path/to/homelab

# Review changes
git status
git diff

# Commit changes
git add .
git commit -m "Update infrastructure after host failure recovery

- Document host3 hardware replacement
- Update Proxmox configuration
- Verify all services restored from B2 backup
- RTO: <actual time>
- RPO: <actual data loss>"

git push origin main
```

## Troubleshooting

### Talos Bootstrap Fails

```bash
# Check Talos node logs
talosctl -n 10.25.150.11 logs

# Reset and retry bootstrap
talosctl -n 10.25.150.11 reset --graceful=false --reboot

# Wait for reboot, then bootstrap again
talosctl bootstrap -n 10.25.150.11
```

### Nodes Not Joining Cluster

```bash
# Check node status
talosctl -n 10.25.150.12 version
talosctl -n 10.25.150.12 health

# Check etcd health
talosctl -n 10.25.150.11 etcd members

# If needed, reset and regenerate configs
cd /path/to/homelab/tofu
tofu destroy -target=module.talos
tofu apply
```

### External Secrets Not Working

```bash
# Check ClusterSecretStore status
kubectl -n external-secrets get clustersecretstore bitwarden-backend -o yaml

# Verify Bitwarden token
kubectl -n external-secrets get secret bitwarden-access-token -o yaml

# Check External Secrets logs
kubectl -n external-secrets logs deployment/external-secrets -f

# Recreate Bitwarden token if needed
kubectl -n external-secrets delete secret bitwarden-access-token
kubectl create secret generic bitwarden-access-token \
  --namespace external-secrets \
  --from-literal=token="<NEW_TOKEN>"
```

### Velero Restore Stuck

```bash
# Check restore status
velero restore describe <restore-name>

# Check logs
velero restore logs <restore-name>

# Check Velero pod logs
kubectl -n velero logs deployment/velero

# Common issues:
# - Storage class not available: Deploy Longhorn first
# - B2 credentials wrong: Check external secret
# - Network issues: Check connectivity to B2
```

### PVCs Not Binding After Restore

```bash
# Check Longhorn status
kubectl -n longhorn-system get pods
kubectl -n longhorn-system get nodes

# Check available volumes
kubectl -n longhorn-system get volumes

# Restore volumes from Longhorn backup if needed
# Via Longhorn UI: Backup → Restore Latest Backup
```

### ArgoCD Applications Not Syncing

```bash
# Check ArgoCD status
kubectl -n argocd get applications

# Describe application for errors
kubectl -n argocd describe application <app-name>

# Force sync
argocd app sync <app-name> --force

# Check ArgoCD logs
kubectl -n argocd logs deployment/argocd-application-controller
```

## Related Scenarios

- [Scenario 2: Disk Failure](02-disk-failure.md) - If only storage is affected
- [Scenario 4: Rack Fire](04-rack-fire.md) - Similar recovery but with all hardware destroyed
- [Scenario 5: Total Site Loss](05-total-site-loss.md) - Recovery with completely new infrastructure

## Reference

- [Talos Linux Documentation](https://www.talos.dev/latest/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Velero Disaster Recovery](https://velero.io/docs/main/disaster-case/)
- [ArgoCD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- Main disaster recovery guide: [Disaster Recovery Overview](../disaster-recovery.md)
