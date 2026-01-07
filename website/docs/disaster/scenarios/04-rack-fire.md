---
sidebar_position: 4
title: 'Scenario 4: Rack Fire'
---

# Scenario 4: Rack Fire

## Symptoms

- Complete physical destruction of server rack and all equipment
- Total loss of Proxmox host (host3.peekoff.com)
- All local storage destroyed (NVMe drives, TrueNAS)
- Network equipment destroyed
- No local infrastructure remains
- Local MinIO backups are gone (TrueNAS destroyed)
- Only offsite Backblaze B2 backups and GitHub repository remain intact

## Impact Assessment

- **Recovery Time Objective (RTO)**: 8-24 hours
- **Recovery Point Objective (RPO)**: Up to 1 week (last weekly B2 backup)
- **Data Loss Risk**: High - limited to last weekly backup
- **Service Availability**: Complete outage until new hardware is provisioned
- **Financial Impact**: Hardware replacement costs, potential insurance claim
- **Rebuilding Requirements**: New server hardware, network equipment, storage

## Prerequisites

### Critical Access Requirements

**You MUST have access to:**

1. **Bitwarden Account**:

   - Master password
   - Contains all credentials needed for recovery

2. **GitHub Repository**:

   - Account: `theepicsaxguy`
   - Repository: `homelab`
   - SSH key or Personal Access Token (stored in Bitwarden)

3. **Backblaze B2 Account**:
   - Account credentials (in Bitwarden)
   - Application keys (in Bitwarden: "backblaze-b2-velero-offsite")
   - Buckets:
     - `homelab-velero-b2` (Velero backups)
     - `homelab-cnpg-b2` (PostgreSQL backups)
     - `homelab-terraform-state` (OpenTofu state)

### Required Hardware

**Minimum Hardware Requirements:**

- **Server**: 1x physical server or new Proxmox-capable host

  - CPU: 8+ cores
  - RAM: 64GB minimum (128GB recommended)
  - Storage: 2x NVMe drives (500GB+ each)
  - Network: Gigabit Ethernet

- **Network Equipment**:
  - Router with VLAN support
  - Managed switch (if needed)
  - Firewall (optional, depending on setup)

### Software Requirements

**On your workstation (laptop/desktop):**

- `tofu` or `terraform` CLI
- `talosctl` CLI
- `kubectl` CLI
- `velero` CLI
- `argocd` CLI (optional)
- `git` CLI
- SSH client
- Web browser

## Recovery Procedure

### Phase 1: Acquire New Hardware

#### Step 1: Procure Replacement Hardware

**Hardware Shopping List:**

```
[ ] Server/Workstation with virtualization support
    - Check: Intel VT-x/VT-d or AMD-V/AMD-Vi enabled
    - Recommended: Dell PowerEdge, HP ProLiant, or custom build

[ ] NVMe SSDs (2x minimum)
    - 500GB+ for VM storage
    - 1TB+ recommended for production use

[ ] RAM (64GB minimum)
    - 4x 16GB or 8x 8GB modules

[ ] Network equipment
    - Managed switch with VLAN support (if needed)
    - Router (if needed)

[ ] Proxmox VE installation media
    - Download from: https://www.proxmox.com/en/downloads
    - Create bootable USB
```

#### Step 2: Verify Network Configuration

Ensure you can recreate the same network:

- **Network**: 10.25.150.0/24
- **Gateway**: 10.25.150.1
- **VLAN**: 150
- **Proxmox Host IP**: 10.25.150.3 (or your original IP)

**If using different network:**

You'll need to update OpenTofu configurations before applying.

### Phase 2: Install Base Infrastructure

#### Step 3: Install Proxmox VE

**Installation:**

1. Boot from Proxmox installation media
2. Follow installation wizard:

   ```
   Hostname: host3.peekoff.com (or new hostname)
   IP Address: 10.25.150.3
   Netmask: 255.255.255.0
   Gateway: 10.25.150.1
   DNS Server: 10.25.150.1 (or 8.8.8.8)
   ```

3. Set root password (store in Bitwarden immediately!)

4. Complete installation and reboot

**Post-Installation:**

```bash
# SSH to Proxmox host
ssh root@10.25.150.3

# Update system
apt update && apt dist-upgrade -y

# Install useful tools
apt install -y smartmontools lm-sensors ethtool
```

**Configure Storage:**

```bash
# Identify NVMe drives
lsblk

# Create ZFS pools (recommended)
zpool create -f Nvme1 /dev/nvme0n1
zpool create -f Nvme2 /dev/nvme1n1

# Verify
pvesm status
zpool list
```

**Configure Network:**

```bash
# Edit network configuration
nano /etc/network/interfaces

# Ensure bridge is configured:
auto vmbr0
iface vmbr0 inet static
    address 10.25.150.3/24
    gateway 10.25.150.1
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0
    # For VLAN 150 support
    bridge-vlan-aware yes

# Apply changes
ifreload -a
```

### Phase 3: Retrieve Infrastructure Code and State

#### Step 4: Clone GitHub Repository

On your workstation:

```bash
# Clone homelab repository
git clone git@github.com:theepicsaxguy/homelab.git
cd homelab

# Verify you have the latest code
git checkout main
git pull origin main
```

#### Step 5: Configure B2 Credentials

Set up Backblaze B2 access for OpenTofu state:

```bash
# Get B2 credentials from Bitwarden
# Item: "backblaze-b2-velero-offsite"
# Fields: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY

export AWS_ACCESS_KEY_ID="<B2_KEY_ID>"
export AWS_SECRET_ACCESS_KEY="<B2_APPLICATION_KEY>"

# Verify credentials work
aws s3 ls s3://homelab-terraform-state \
  --endpoint-url=https://s3.us-west-002.backblazeb2.com
```

#### Step 6: Enable OpenTofu Remote State Backend

Edit `/home/benjaminsanden/Dokument/Projects/homelab/tofu/backend.tf`:

Uncomment the backend configuration:

```hcl
terraform {
  backend "s3" {
    # B2 Bucket configuration
    bucket = "homelab-terraform-state"
    key    = "proxmox/terraform.tfstate"
    region = "us-west-000"

    # Backblaze B2 S3-compatible endpoint
    endpoint = "https://s3.us-west-002.backblazeb2.com"

    # Required for B2 compatibility
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = false
  }
}
```

### Phase 4: Deploy Infrastructure with OpenTofu

#### Step 7: Initialize OpenTofu with B2 State

```bash
cd /path/to/homelab/tofu

# Initialize OpenTofu with remote backend
tofu init

# Verify state was pulled from B2
tofu show

# You should see your previous infrastructure state
```

#### Step 8: Update Proxmox Provider Configuration

Create or update Proxmox credentials:

```bash
# Get Proxmox API token
# Either create new token in Proxmox UI:
# Datacenter → Permissions → API Tokens → Add

# Or create terraform.auto.tfvars with credentials
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

chmod 600 terraform.auto.tfvars
```

**Update Network Configuration (if changed):**

If your new network is different, update `config.auto.tfvars`:

```hcl
network = {
  gateway     = "10.25.150.1"
  vip         = "10.25.150.10"
  api_lb_vip  = "10.25.150.9"
  cidr_prefix = 24
  dns_servers = ["10.25.150.1"]
  bridge      = "vmbr0"
  vlan_id     = 150
}
```

#### Step 9: Apply Infrastructure

Deploy VMs with OpenTofu:

```bash
# Review what will be created
tofu plan

# Apply infrastructure
tofu apply

# Type 'yes' to confirm
```

**This creates:**

- 3 control plane VMs: 10.25.150.11-13
- 3 worker VMs: 10.25.150.21-23
- 2 load balancer VMs: 10.25.150.5-6 (if enabled)
- Talos Linux installed on all VMs

### Phase 5: Bootstrap Kubernetes Cluster

#### Step 10: Bootstrap Talos

```bash
# Navigate to tofu directory
cd /path/to/homelab/tofu

# Export talosconfig
export TALOSCONFIG=$(pwd)/outputs/talosconfig

# Bootstrap first control plane
talosctl bootstrap -n 10.25.150.11

# Wait for bootstrap (5-10 minutes)
talosctl -n 10.25.150.11 health --wait-timeout 10m
```

#### Step 11: Configure kubectl Access

```bash
# Generate kubeconfig
talosctl -n 10.25.150.11 kubeconfig ~/.kube/config --force

# Set context
kubectl config use-context talos

# Verify cluster
kubectl get nodes
```

Wait for all nodes to become Ready:

```bash
kubectl get nodes -w

# Expected output:
# NAME      STATUS   ROLES           AGE   VERSION
# ctrl-00   Ready    control-plane   5m    v1.34.3
# ctrl-01   Ready    control-plane   5m    v1.34.3
# ctrl-02   Ready    control-plane   5m    v1.34.3
# work-00   Ready    <none>          5m    v1.34.3
# work-01   Ready    <none>          5m    v1.34.3
# work-02   Ready    <none>          5m    v1.34.3
```

### Phase 6: Deploy Core Infrastructure

#### Step 12: Deploy Infrastructure Components via OpenTofu

All Kubernetes infrastructure is now deployed automatically by OpenTofu during the cluster bootstrap process. After
Talos bootstrap completes:

```bash
cd /path/to/homelab/tofu

# If Bitwarden token is not in terraform.tfvars, create the secret manually
kubectl create secret generic bitwarden-access-token \
  --namespace external-secrets \
  --from-literal=token="<BITWARDEN_ACCESS_TOKEN>"

# Wait for OpenTofu bootstrap module to complete
# This installs Cert Manager, External Secrets Operator, ArgoCD, and ApplicationSets

# Verify ArgoCD is running
kubectl -n argocd get pods

# Verify ApplicationSets are created
kubectl get applicationsets -n argocd

# Wait for infrastructure ApplicationSet to sync
kubectl wait --for=jsonpath='{.status.sync.status}'=Synced application/infrastructure -n argocd --timeout=600s

# Verify core services are ready
kubectl get pods -n cert-manager
kubectl get pods -n external-secrets
kubectl get pods -n argocd
```

#### Step 13: Configure Longhorn B2 Backup (Optional)

Since TrueNAS/MinIO is gone, update Longhorn to use B2 for backups:

```bash
# Update Longhorn backup target to B2
kubectl -n longhorn-system patch settings.longhorn.io backup-target \
  --type merge \
  --patch '{"value":"s3://longhorn@us-west-000/"}'

# Create Longhorn B2 credentials
kubectl -n longhorn-system create secret generic longhorn-b2-credentials \
  --from-literal=AWS_ACCESS_KEY_ID="<B2_KEY_ID>" \
  --from-literal=AWS_SECRET_ACCESS_KEY="<B2_APPLICATION_KEY>" \
  --from-literal=AWS_ENDPOINTS="https://s3.us-west-002.backblazeb2.com"

# Update backup target credential
kubectl -n longhorn-system patch settings.longhorn.io backup-target-credential-secret \
  --type merge \
  --patch '{"value":"longhorn-b2-credentials"}'
```

### Phase 7: Deploy Applications and Restore Data

#### Step 14: Deploy Velero

```bash
# Velero should be part of infrastructure deployment
kubectl -n velero get pods

# Verify B2 backup storage location
kubectl -n velero get backupstoragelocations

# Should show: backblaze-b2 (ReadWrite)
```

#### Step 15: List Available Backups

```bash
# Install Velero CLI if not already installed
# Download from: https://github.com/vmware-tanzu/velero/releases

# List B2 backups
velero backup get --storage-location backblaze-b2

# Find latest weekly backup
velero backup get --storage-location backblaze-b2 \
  --selector backup-type=weekly-offsite

# Describe latest backup
LATEST_BACKUP=$(velero backup get --storage-location backblaze-b2 \
  --selector backup-type=weekly-offsite \
  -o json | jq -r '.items | sort_by(.metadata.creationTimestamp) | .[-1].metadata.name')

echo "Latest backup: $LATEST_BACKUP"
velero backup describe $LATEST_BACKUP --details
```

#### Step 16: Restore Cluster State from B2

```bash
# Restore everything except infrastructure namespaces
velero restore create rack-fire-restore-$(date +%Y%m%d-%H%M%S) \
  --from-backup $LATEST_BACKUP \
  --storage-location backblaze-b2 \
  --exclude-namespaces velero,cert-manager,external-secrets,longhorn-system,kube-system,argocd

# Monitor restore progress
velero restore get
velero restore logs rack-fire-restore-<timestamp> -f

# Watch pods come up
kubectl get pods -A -w
```

#### Step 17: Deploy ArgoCD and Sync Applications

```bash
# Verify ArgoCD is running
kubectl -n argocd get pods

# Get admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo "ArgoCD admin password: $ARGOCD_PASSWORD"

# Login to ArgoCD
argocd login localhost:8080 \
  --username admin \
  --password $ARGOCD_PASSWORD \
  --port-forward \
  --port-forward-namespace argocd

# Sync all applications
argocd app list
argocd app sync -l argocd.argoproj.io/instance=applications
```

#### Step 18: Restore PostgreSQL Databases from B2

For each CNPG PostgreSQL cluster, restore from B2:

**Example for `auth` namespace (Authentik database):**

```yaml
# Create restore configuration
cat > restore-auth-db.yaml <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: authentik-postgres
  namespace: auth
spec:
  instances: 2

  bootstrap:
    recovery:
      source: b2-backup
      recoveryTarget:
        targetImmediate: true  # Restore to latest backup

  externalClusters:
    - name: b2-backup
      barmanObjectStore:
        destinationPath: s3://homelab-cnpg-b2/auth/authentik-postgres
        endpointURL: https://s3.us-west-002.backblazeb2.com
        s3Credentials:
          accessKeyId:
            name: b2-cnpg-credentials
            key: AWS_ACCESS_KEY_ID
          secretAccessKey:
            name: b2-cnpg-credentials
            key: AWS_SECRET_ACCESS_KEY
        wal:
          compression: gzip
          encryption: AES256

  storage:
    size: 20Gi
    storageClass: longhorn
EOF

# Apply restore
kubectl apply -f restore-auth-db.yaml

# Monitor recovery
kubectl -n auth get cluster authentik-postgres -w
kubectl -n auth logs -l cnpg.io/cluster=authentik-postgres -c postgres --tail=100 -f
```

Repeat for all PostgreSQL clusters in your environment.

## Validation

### Check Infrastructure Health

```bash
# All nodes should be Ready
kubectl get nodes

# All infrastructure pods should be Running
kubectl get pods -n longhorn-system
kubectl get pods -n velero
kubectl get pods -n cert-manager
kubectl get pods -n external-secrets
kubectl get pods -n argocd

# Check Longhorn UI
kubectl -n longhorn-system get svc longhorn-frontend
# Access via LoadBalancer IP
```

### Check Application Status

```bash
# List all namespaces
kubectl get namespaces

# Check application pods
kubectl get pods -A | grep -v Running | grep -v Completed

# Check PVCs are bound
kubectl get pvc -A | grep -v Bound

# Check services
kubectl get svc -A
```

### Verify Data Integrity

**PostgreSQL:**

```bash
# Check all CNPG clusters
kubectl get clusters -A

# Verify database connectivity
kubectl -n auth exec -it authentik-postgres-1 -- psql -U postgres

# Check data
SELECT COUNT(*) FROM <critical_table>;
SELECT MAX(created_at) FROM <timestamped_table>;
```

**Applications:**

- Access application UIs
- Verify user data exists
- Test login/authentication
- Check critical workflows

### Verify Backups Are Running

```bash
# Check Velero schedules
velero schedule get

# Check recent backups
velero backup get | head -10

# Check CNPG backup schedules
kubectl get scheduledbackups -A

# Check Longhorn recurring jobs
kubectl -n longhorn-system get recurringjobs
```

## Post-Recovery Tasks

### 1. Document the Incident

```bash
cat > docs/incidents/rack-fire-$(date +%Y%m%d).md <<EOF
# Rack Fire Disaster Recovery

**Date**: $(date)
**Incident**: Complete destruction of server rack
**Cause**: <fire cause>
**Recovery Time**: <actual hours from incident to full recovery>
**Data Loss (RPO)**: <days since last B2 backup>
**Hardware Replaced**: <full hardware list>
**Total Cost**: <hardware + time>

## What Happened
<detailed description>

## Recovery Timeline
- T+0h: Incident occurred
- T+<X>h: New hardware acquired
- T+<X>h: Proxmox installed
- T+<X>h: Infrastructure deployed via OpenTofu
- T+<X>h: Cluster bootstrapped
- T+<X>h: Data restored from B2
- T+<X>h: All services operational

## Hardware Purchased
<itemized list with costs>

## Data Loss Assessment
- Last B2 backup: <date/time>
- Data lost: <description of data created after last backup>
- User impact: <description>

## Insurance Claim
- Claim filed: <date>
- Claim number: <number>
- Status: <pending/approved/denied>

## Lessons Learned
- What worked well
- What could be improved
- Documentation gaps
- Infrastructure improvements needed

## Follow-up Actions
- [ ] Submit insurance claim
- [ ] Order spare hardware
- [ ] Increase backup frequency
- [ ] Implement off-site hardware caching
- [ ] Review fire suppression systems
EOF
```

### 2. Increase Backup Frequency

Since you just experienced total loss, consider more frequent B2 backups:

```bash
# Update Velero schedule for more frequent B2 backups
kubectl -n velero edit schedule weekly-offsite-schedule

# Change from weekly to daily:
spec:
  schedule: "0 3 * * *"  # Daily at 3 AM UTC instead of Sunday only
```

### 3. Set Up Local Backup Storage (When Possible)

When you acquire new NAS/storage:

```bash
# Deploy TrueNAS or MinIO
# Update Longhorn backup target
# Update Velero default storage location
# Keep B2 as secondary/offsite backup
```

### 4. Test Backup Restoration Monthly

Schedule regular restore tests:

```bash
# Monthly: Test single namespace restore
# Quarterly: Test full cluster restore to test environment
# Annually: Complete DR drill with new hardware
```

### 5. Update Emergency Documentation

```bash
# Create printed emergency runbook
# Include:
# - Bitwarden master password location
# - GitHub access method
# - B2 account details
# - Hardware vendor contact info
# - This disaster recovery documentation
# - Network configuration diagrams

# Store printed copy off-site (safe deposit box, friend's house, etc.)
```

### 6. Consider DR Improvements

**Infrastructure Improvements:**

- **Geographic Redundancy**: Consider cloud-based DR site (AWS, Azure, etc.)
- **Backup Frequency**: Increase to daily or hourly B2 backups
- **Hardware Spares**: Keep spare server/parts at different location
- **Automated Testing**: Implement automated backup validation

**Financial Improvements:**

- **Insurance Review**: Ensure adequate coverage for hardware
- **Budget for Spares**: Allocate budget for emergency hardware purchases

## Troubleshooting

### Cannot Access B2 Backups

```bash
# Verify credentials
aws s3 ls s3://homelab-velero-b2 \
  --endpoint-url=https://s3.us-west-002.backblazeb2.com

# If credentials don't work:
# 1. Login to B2 web console
# 2. Check if keys are still valid
# 3. Generate new application keys if needed
# 4. Update credentials in External Secrets / Bitwarden
```

### Velero Restore Fails

```bash
# Check Velero logs
kubectl -n velero logs deployment/velero -f

# Common issues:
# - Storage class not available: Ensure Longhorn is deployed first
# - Namespace already exists: Use --existing-resource-policy update
# - PVC size conflicts: Delete and recreate PVCs manually

# Retry restore with more options
velero restore create <name> \
  --from-backup $LATEST_BACKUP \
  --existing-resource-policy update \
  --preserve-nodeports
```

### PostgreSQL Recovery Fails

```bash
# Check CNPG cluster status
kubectl -n <namespace> get cluster <cluster-name> -o yaml

# Check pod logs
kubectl -n <namespace> logs <cluster-pod> -c postgres

# Common issues:
# - B2 credentials wrong: Check external secret
# - Backup path wrong: Verify destinationPath in cluster spec
# - Permissions: Check PVC ownership (UID 26 for CNPG)

# Delete and retry with corrected configuration
kubectl -n <namespace> delete cluster <cluster-name>
kubectl apply -f restore-<namespace>-db.yaml
```

### Network Configuration Different

If you can't use same IPs (10.25.150.x):

```bash
# Update tofu/config.auto.tfvars with new network
# Update DNS/ingress configurations
# Regenerate certificates with new domains
# Update external-dns configurations
```

## Related Scenarios

- [Scenario 3: Host Failure](03-host-failure.md) - Similar but hardware survives
- [Scenario 5: Total Site Loss](05-total-site-loss.md) - Same as rack fire (house destroyed)
- [Scenario 6: Ransomware](06-ransomware.md) - If backups are encrypted/compromised

## Reference

- [Backblaze B2 Documentation](https://www.backblaze.com/b2/docs/)
- [Velero Disaster Recovery Guide](https://velero.io/docs/main/disaster-case/)
- [CNPG Backup and Recovery](https://cloudnative-pg.io/documentation/current/backup_recovery/)
- [OpenTofu Backend Documentation](https://opentofu.org/docs/language/settings/backends/s3/)
- Main disaster recovery guide: [Disaster Recovery Overview](../disaster-recovery.md)
- B2 Setup Guide: `/home/benjaminsanden/Dokument/Projects/homelab/BACKBLAZE_B2_SETUP.md`
