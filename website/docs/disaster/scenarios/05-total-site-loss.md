---
sidebar_position: 5
title: 'Scenario 5: Total Site Loss'
---

# Scenario 5: Total Site Loss

## Symptoms

- Entire home/building destroyed (fire, flood, natural disaster)
- All local infrastructure completely lost
- All physical equipment destroyed
- No access to original location
- Local network infrastructure gone
- All local backups destroyed (TrueNAS, MinIO)
- **Only survivors**: GitHub repository and Backblaze B2 backups

## Impact Assessment

- **Recovery Time Objective (RTO)**: 8-24 hours (hardware dependent)
- **Recovery Point Objective (RPO)**: Up to 1 week (last weekly B2 backup)
- **Data Loss Risk**: High - limited to weekly backup schedule
- **Service Availability**: Complete outage until infrastructure is rebuilt
- **Personal Impact**: High - home disaster, potential displacement
- **Financial Impact**: Significant - hardware replacement, potential insurance claim
- **Emotional Impact**: High - prioritize personal safety and well-being first

## Prerequisites

### CRITICAL: What You Need Access To

This scenario assumes you have:

1. **Personal Safety**:

   - You and your family are safe
   - You have access to temporary housing/workspace
   - You have a computer/laptop to work from

2. **Account Access** (stored separately from your homelab):

   - **Bitwarden master password** (memorized or stored separately)
   - **GitHub account access** (2FA codes, recovery codes)
   - **Backblaze B2 account access** (2FA codes if enabled)
   - **Email access** (for password resets if needed)

3. **Documentation Access**:

   - This disaster recovery documentation (ideally saved offline or printed)
   - Network diagrams (if stored separately)
   - Hardware configurations (if documented elsewhere)

4. **Financial Resources**:
   - Budget for new hardware
   - Credit card or funds for purchases
   - Insurance policy information (if applicable)

### Required Software (Install on your workstation)

```bash
# Install required CLIs
# macOS (using Homebrew)
brew install opentofu kubectl talosctl velero argocd git

# Linux
# Download binaries from official releases:
# - OpenTofu: https://github.com/opentofu/opentofu/releases
# - kubectl: https://kubernetes.io/docs/tasks/tools/
# - talosctl: https://github.com/siderolabs/talos/releases
# - velero: https://github.com/vmware-tanzu/velero/releases
# - argocd: https://github.com/argoproj/argo-cd/releases

# Windows
# Use WSL2 with Linux instructions, or install individual binaries
```

### Decision: New Hardware Location

**Option A: Rebuild at Original Location**

If your home is being rebuilt:

- Same network configuration possible
- Insurance may cover hardware replacement
- Can use same IP addressing scheme
- Longer timeline (waiting for home reconstruction)

**Option B: Temporary/New Location**

If rebuilding elsewhere:

- May need different network configuration
- Faster deployment possible
- Consider cloud hosting as interim solution
- Need to update DNS and firewall rules

**Option C: Cloud Migration**

Consider cloud-based recovery:

- AWS EKS, Azure AKS, or Google GKE
- Faster initial recovery
- Higher ongoing costs
- May convert to permanent solution

## Recovery Procedure

### Phase 1: Emergency Preparation

#### Step 1: Ensure Personal Safety and Stability

**Before attempting technical recovery:**

```
[ ] You and family are safe and in stable housing
[ ] Insurance claim filed (if applicable)
[ ] Essential documentation retrieved/replaced
[ ] Stable internet connection available
[ ] Working computer/laptop available
[ ] Financial resources for hardware purchases confirmed
```

**Technical recovery can wait. Your safety comes first.**

#### Step 2: Verify Access to Critical Accounts

```bash
# Verify Bitwarden access
# Login to: https://vault.bitwarden.com
# Retrieve all necessary credentials

# Verify GitHub access
git clone git@github.com:theepicsaxguy/homelab.git
# If SSH key lost, use HTTPS with PAT or create new SSH key

# Verify B2 access
# Login to: https://www.backblaze.com/b2/sign-in.html
# Verify buckets exist:
# - homelab-velero-b2
# - homelab-cnpg-b2
# - homelab-terraform-state
```

#### Step 3: Inventory What Survived

Document what you have access to:

```bash
# Create recovery checklist
cat > ~/recovery-checklist.md <<EOF
# Total Site Loss Recovery Checklist

## Access Verified
- [ ] Bitwarden account
- [ ] GitHub repository
- [ ] Backblaze B2 buckets
- [ ] Email accounts
- [ ] Domain registrar

## Last Known Good State
- Last B2 backup date: <check Velero backups>
- Last code commit: <check GitHub>
- Last OpenTofu state: <check B2 state bucket>

## Hardware Decisions
- Location: <original/temporary/cloud>
- Timeline: <immediate/weeks/months>
- Budget: <amount available>

## Network Planning
- Keep original IPs (10.25.150.x): YES / NO
- VLANs: <same/different>
- Internet provider: <same/different>
- Domain names: <keep/change>
EOF
```

### Phase 2: Acquire Infrastructure

#### Step 4: Procure New Hardware

**Minimum Hardware Requirements:**

```
Shopping List:
[ ] Server/Workstation
    CPU: 8+ cores (16+ recommended)
    RAM: 64GB minimum (128GB+ recommended)
    Storage: 2x 500GB+ NVMe SSDs
    Network: Gigabit Ethernet

[ ] Network Equipment
    Router with VLAN support
    Managed switch (optional)
    Network cables, power strips

[ ] Proxmox VE Installation Media
    USB drive (8GB+)
    Download: https://www.proxmox.com/en/downloads
```

**Hardware Options:**

```bash
# Option 1: Home Server Hardware
# - Dell PowerEdge (R720, R730)
# - HP ProLiant (DL380, DL360)
# - Custom build (ASUS, Supermicro boards)

# Option 2: Workstation Conversion
# - High-end workstation repurposed
# - Must support virtualization (VT-x/AMD-V)

# Option 3: Cloud Provider (Temporary)
# - Hetzner dedicated servers
# - OVH dedicated servers
# - DigitalOcean (for testing recovery procedure)
```

#### Step 5: Set Up Network Infrastructure

Configure your network:

**If using same IP scheme (10.25.150.0/24):**

```bash
# Configure router/switch for VLAN 150
# Assign gateway: 10.25.150.1
# Reserve IPs:
#   10.25.150.3  - Proxmox host
#   10.25.150.5-6 - Load balancers
#   10.25.150.9  - API LB VIP
#   10.25.150.10 - Cluster VIP
#   10.25.150.11-13 - Control planes
#   10.25.150.21-23 - Workers
```

**If using different network:**

You'll need to update OpenTofu configurations (see Troubleshooting section).

### Phase 3: Install Base Infrastructure

#### Step 6: Install Proxmox VE

Follow Proxmox installation:

```
1. Boot from installation USB
2. Select "Install Proxmox VE"
3. Accept license
4. Select target disk (NVMe)
5. Configure:
   Country: <your country>
   Timezone: <your timezone>
   Keyboard: <your layout>
6. Set root password (SAVE IN BITWARDEN!)
7. Network configuration:
   Hostname: host3.peekoff.com
   IP: 10.25.150.3
   Netmask: 255.255.255.0
   Gateway: 10.25.150.1
   DNS: 10.25.150.1
8. Confirm and install
9. Reboot
```

**Post-installation setup:**

```bash
# SSH to Proxmox
ssh root@10.25.150.3

# Update system
apt update && apt dist-upgrade -y

# Configure storage
# For ZFS (recommended):
zpool create -f Nvme1 /dev/nvme0n1
zpool create -f Nvme2 /dev/nvme1n1

# Or use LVM/Directory storage
pvesm add dir local --path /var/lib/vz --content vztmpl,iso,backup
```

**Configure network for VLAN 150:**

```bash
# Edit network interfaces
nano /etc/network/interfaces

# Add VLAN-aware bridge:
auto vmbr0
iface vmbr0 inet static
    address 10.25.150.3/24
    gateway 10.25.150.1
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes

# Apply
ifreload -a
```

### Phase 4: Restore Infrastructure as Code

#### Step 7: Clone GitHub Repository

```bash
# On your workstation
git clone git@github.com:theepicsaxguy/homelab.git
cd homelab

# Verify repository integrity
git log --oneline -10
git status
```

#### Step 8: Configure B2 Backend Access

```bash
# Get B2 credentials from Bitwarden
# Item: "backblaze-b2-velero-offsite" or "terraform-state-b2"

export AWS_ACCESS_KEY_ID="<B2_KEY_ID>"
export AWS_SECRET_ACCESS_KEY="<B2_APPLICATION_KEY>"

# Test B2 access
aws s3 ls s3://homelab-terraform-state \
  --endpoint-url=https://s3.us-west-002.backblazeb2.com

# Should show: proxmox/terraform.tfstate
```

#### Step 9: Enable OpenTofu Remote Backend

Edit `tofu/backend.tf` and uncomment:

```hcl
terraform {
  backend "s3" {
    bucket = "homelab-terraform-state"
    key    = "proxmox/terraform.tfstate"
    region = "us-west-000"
    endpoint = "https://s3.us-west-002.backblazeb2.com"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = false
  }
}
```

#### Step 10: Initialize OpenTofu with Remote State

```bash
cd homelab/tofu

# Initialize and pull state from B2
tofu init

# Verify state
tofu show | head -50

# You should see your previous infrastructure configuration
```

### Phase 5: Deploy Infrastructure

#### Step 11: Configure Proxmox Credentials

```bash
# Create API token in Proxmox UI:
# Datacenter → Permissions → API Tokens → Add
# Token ID: root@pam!tofu
# Copy the secret (shown only once!)

# Create terraform.auto.tfvars
cat > terraform.auto.tfvars <<EOF
proxmox = {
  name         = "host3"
  cluster_name = "host3"
  endpoint     = "https://10.25.150.3:8006"
  insecure     = true
  username     = "root@pam"
  api_token    = "<PROXMOX_API_TOKEN>"
}
EOF

chmod 600 terraform.auto.tfvars
```

#### Step 12: Review and Apply Infrastructure

```bash
# Review what will be created
tofu plan

# Apply infrastructure
tofu apply

# Type 'yes' when prompted
```

**This recreates:**

- All Talos Linux VMs
- Control plane nodes (10.25.150.11-13)
- Worker nodes (10.25.150.21-23)
- Load balancers (10.25.150.5-6)

### Phase 6: Bootstrap Kubernetes

#### Step 13: Bootstrap Talos Cluster

```bash
cd homelab/tofu

# Export talosconfig
export TALOSCONFIG=$(pwd)/outputs/talosconfig

# Bootstrap first control plane
talosctl bootstrap -n 10.25.150.11

# Wait for bootstrap (5-10 minutes)
talosctl -n 10.25.150.11 health --wait-timeout 10m

# Generate kubeconfig
talosctl -n 10.25.150.11 kubeconfig ~/.kube/config --force

# Verify cluster
kubectl config use-context talos
kubectl get nodes -w
```

#### Step 14: Deploy Core Infrastructure via OpenTofu

All Kubernetes infrastructure is now deployed automatically by OpenTofu during the cluster bootstrap process. After
Talos bootstrap completes:

```bash
cd homelab/tofu

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

### Phase 7: Restore Data from B2

#### Step 15: Deploy Velero and Verify Backups

```bash
# Verify Velero is running
kubectl -n velero get pods

# Check B2 backup location
kubectl -n velero get backupstoragelocations backblaze-b2

# List available backups
velero backup get --storage-location backblaze-b2

# Find latest backup
LATEST_BACKUP=$(velero backup get --storage-location backblaze-b2 \
  --selector backup-type=weekly-offsite \
  -o json | jq -r '.items | sort_by(.metadata.creationTimestamp) | .[-1].metadata.name')

echo "Latest backup: $LATEST_BACKUP"

# Check backup age
velero backup describe $LATEST_BACKUP | grep "Created:"
```

#### Step 16: Restore Applications and Data

```bash
# Restore from latest B2 backup
velero restore create site-loss-restore-$(date +%Y%m%d-%H%M%S) \
  --from-backup $LATEST_BACKUP \
  --storage-location backblaze-b2 \
  --exclude-namespaces velero,cert-manager,external-secrets,longhorn-system,kube-system,argocd

# Monitor restore
velero restore get
velero restore logs site-loss-restore-<timestamp> -f

# Watch pods
kubectl get pods -A -w
```

#### Step 17: Restore PostgreSQL Databases

For each CNPG cluster, create restore configuration:

**Example template:**

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: <cluster-name>
  namespace: <namespace>
spec:
  instances: 2

  bootstrap:
    recovery:
      source: b2-backup
      recoveryTarget:
        targetImmediate: true

  externalClusters:
    - name: b2-backup
      barmanObjectStore:
        destinationPath: s3://homelab-cnpg-b2/<namespace>/<cluster-name>
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
```

Apply for each database:

```bash
kubectl apply -f restore-auth-db.yaml
kubectl apply -f restore-media-db.yaml
# ... etc
```

## Validation

### Infrastructure Health Check

```bash
# All nodes Ready
kubectl get nodes

# All infrastructure pods Running
kubectl get pods -A | grep -v Running | grep -v Completed

# Longhorn healthy
kubectl -n longhorn-system get volumes
# Access Longhorn UI and verify all volumes healthy

# All PVCs Bound
kubectl get pvc -A | grep -v Bound
```

### Application Validation

```bash
# List all applications
kubectl get pods -A

# Check critical services
kubectl -n auth get pods
kubectl -n media get pods

# Verify databases
kubectl get clusters -A

# Test database connectivity
kubectl -n auth exec -it <postgres-pod> -- psql -U postgres -c "SELECT version();"
```

### Data Integrity Check

**Check recovery point:**

```bash
# For each database, check latest data timestamp
kubectl -n <namespace> exec -it <postgres-pod> -- psql -U postgres <<EOF
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
EOF

# Check for any timestamped data
# SELECT MAX(created_at), MAX(updated_at) FROM <critical_table>;
# Compare to incident timestamp to understand data loss
```

### External Access Validation

```bash
# Check ingress
kubectl get ingress -A

# Verify external DNS (if configured)
# Update DNS records if IP changed

# Test application access
curl -k https://<your-domain>

# Verify SSL certificates
kubectl get certificates -A
```

## Post-Recovery Tasks

### 1. Comprehensive Incident Documentation

```bash
cat > ~/total-site-loss-incident.md <<EOF
# Total Site Loss Disaster Recovery Report

**Incident Date**: <date of disaster>
**Recovery Start**: <date recovery started>
**Recovery Complete**: <date services restored>
**Total RTO**: <hours from incident to full recovery>
**RPO (Data Loss)**: <days since last B2 backup>

## Incident Details
- Type: <fire/flood/natural disaster>
- Location: <address>
- Personal impact: <family status, housing>
- Equipment lost: <full inventory>

## What Survived
✓ GitHub repository (theepicsaxguy/homelab)
✓ Backblaze B2 backups
  - Last Velero backup: <date>
  - Last CNPG backup: <date>
  - OpenTofu state: <date>
✓ Bitwarden vault access
✓ Domain names and DNS

## What Was Lost
✗ All physical hardware
✗ Local MinIO backups
✗ TrueNAS and local storage
✗ Data created after: <last backup date>

## Recovery Timeline
<detailed hour-by-hour timeline>

## Financial Impact
- Hardware replacement: $<amount>
- Insurance coverage: $<amount>
- Out-of-pocket: $<amount>
- Cloud costs (temporary): $<amount>

## Data Loss Assessment
<detailed analysis of what data was lost>

## What Worked Well
- B2 backups were intact and restorable
- GitHub repository had all infrastructure code
- Bitwarden had all credentials
- Documentation was accessible
- OpenTofu state in B2 was critical

## What Could Be Improved
- More frequent B2 backups (weekly → daily)
- Printed emergency documentation off-site
- Spare hardware at alternate location
- Cloud-based DR environment ready to go
- Better documentation of manual steps

## Lessons Learned
<key takeaways>

## Follow-up Actions
- [ ] File insurance claim
- [ ] Update backup frequency
- [ ] Create printed DR runbook (store off-site)
- [ ] Set up cloud-based DR environment
- [ ] Document new hardware configuration
- [ ] Update monitoring and alerting
- [ ] Schedule quarterly DR drills
EOF
```

### 2. Implement Immediate Improvements

**Increase backup frequency:**

```bash
# Change Velero B2 backups from weekly to daily
kubectl -n velero edit schedule weekly-offsite-schedule

# Update schedule:
spec:
  schedule: "0 3 * * *"  # Daily at 3 AM instead of weekly

# Rename schedule
# Or create new daily schedule
```

**Add backup monitoring:**

```bash
# Create alerts for:
# - Backup failures
# - Backup age > 48 hours
# - B2 bucket access issues
```

### 3. Create Off-Site Emergency Kit

**Physical emergency kit (store at safe location):**

```
[ ] Printed copy of this disaster recovery documentation
[ ] Network diagrams and IP addressing
[ ] Hardware configuration notes
[ ] Bitwarden emergency access instructions
[ ] GitHub account recovery codes
[ ] B2 account information
[ ] Domain registrar contact info
[ ] Insurance policy numbers
[ ] Emergency contact list
[ ] USB drive with:
    - Proxmox ISO
    - Talos Image
    - CLI tools (kubectl, tofu, etc.)
```

### 4. Consider Permanent DR Infrastructure

**Options to prevent future total loss:**

1. **Cloud-based standby environment:**

   ```bash
   # Maintain dormant cluster in cloud
   # Use cheap instances (can upscale when needed)
   # Regular restore tests to cloud environment
   ```

2. **Co-location or friend's house:**

   ```bash
   # Store spare server at alternate location
   # Can be brought online quickly
   # Shared homelab with trusted friend
   ```

3. **Geographic replication:**
   ```bash
   # Run two clusters in different locations
   # Primary + DR site with replication
   # More complex but near-zero RTO
   ```

### 5. Update Financial Planning

```bash
# Budget for:
# - Spare hardware fund
# - Increased cloud costs (B2 storage, compute)
# - Insurance coverage review
# - Emergency hardware purchase capacity
```

### 6. Schedule Regular DR Drills

```bash
# Quarterly: Test restore from B2 to cloud environment
# Semi-annually: Full recovery drill with actual hardware
# Annually: Complete site loss scenario with new hardware

# Document each drill
# Update procedures based on findings
# Rotate responsibilities (if family member might need to recover)
```

## Troubleshooting

### Different Network Configuration Required

If you can't use 10.25.150.0/24:

```bash
# Update tofu/config.auto.tfvars
network = {
  gateway     = "192.168.1.1"      # New gateway
  vip         = "192.168.1.10"     # New VIP
  api_lb_vip  = "192.168.1.9"      # New API VIP
  cidr_prefix = 24
  dns_servers = ["192.168.1.1"]
  bridge      = "vmbr0"
  vlan_id     = 0                  # Disable VLAN if not supported
}

# Update nodes_config with new IPs
# Then apply with tofu
```

### B2 Credentials Lost

If you can't access B2:

```bash
# Login to B2 web console
https://www.backblaze.com/b2/sign-in.html

# If credentials lost:
# 1. Use email recovery
# 2. Answer security questions
# 3. Contact B2 support with account verification

# Generate new application keys
# Update all secrets that use B2
```

### GitHub Repository Inaccessible

If you can't clone GitHub repo:

```bash
# Option 1: Use HTTPS instead of SSH
git clone https://github.com/theepicsaxguy/homelab.git

# Option 2: Generate new SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub
# Add to GitHub: Settings → SSH Keys

# Option 3: Use GitHub web interface
# Download repository as ZIP from GitHub.com
```

### Bitwarden Access Lost

**This is critical - Bitwarden contains all credentials:**

```bash
# Try recovery:
# 1. Email recovery (if configured)
# 2. Emergency access (if configured)
# 3. Recovery codes (if printed/stored)

# If all else fails:
# - Contact B2 support for account recovery
# - Reset GitHub password via email
# - Create new Proxmox passwords
# - Manually recreate all secrets in cluster
```

### Hardware Insufficient for Full Cluster

If you can only afford partial hardware:

```bash
# Option 1: Deploy smaller cluster
# Update tofu config to 1 control plane, 1 worker
# Reduce resource allocations

# Option 2: Cloud migration (temporary)
# Deploy to Hetzner/OVH/DigitalOcean
# Restore services
# Migrate back to hardware when available

# Option 3: Selective restore
# Restore only critical applications
# Leave non-essential services offline
```

## Related Scenarios

- [Scenario 4: Rack Fire](04-rack-fire.md) - Similar scenario, rack destroyed but house intact
- [Scenario 3: Host Failure](03-host-failure.md) - Similar recovery procedure but data survives
- [Scenario 6: Ransomware](06-ransomware.md) - If backups are compromised

## Reference

- [Backblaze B2 Documentation](https://www.backblaze.com/b2/docs/)
- [Velero Disaster Recovery](https://velero.io/docs/main/disaster-case/)
- [CNPG Backup and Recovery](https://cloudnative-pg.io/documentation/current/backup_recovery/)
- [Talos Disaster Recovery](https://www.talos.dev/latest/advanced/disaster-recovery/)
- [OpenTofu Backend Configuration](https://opentofu.org/docs/language/settings/backends/s3/)
- Main disaster recovery guide: [Disaster Recovery Overview](../disaster-recovery.md)

## Emergency Contacts

**Critical Services:**

- **Backblaze Support**: support@backblaze.com
- **GitHub Support**: https://support.github.com
- **Bitwarden Support**: https://bitwarden.com/contact/
- **Proxmox Community**: https://forum.proxmox.com/

**Personal Contacts:**

- Update with your emergency contacts
- Technical friends who can help
- Family members with Bitwarden emergency access
- Insurance adjuster contact

---

## Final Notes

**Remember:**

1. **Your safety and well-being come first.** Technical recovery can wait.
2. **This is a documented, tested procedure.** You have everything you need in GitHub + B2.
3. **Data loss is limited to your RPO** (up to 1 week). This is acceptable for a total loss scenario.
4. **Insurance may cover hardware.** Document everything for your claim.
5. **The homelab will come back.** It's just infrastructure and data - you're safe, and that's what matters.

**You can do this. One step at a time.**
