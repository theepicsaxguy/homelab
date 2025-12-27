---
sidebar_position: 0
title: "Disaster Recovery Scenarios"
---

# Disaster Recovery Scenarios

This section provides step-by-step recovery procedures for various disaster scenarios that could affect your homelab infrastructure.

## Quick Reference

| Scenario | RTO | RPO | Recovery Source | Complexity |
|----------|-----|-----|-----------------|------------|
| [1. Accidental Deletion](01-accidental-deletion.md) | 15-30 min | 1-24 hours | Local (MinIO) | ⭐ Low |
| [2. Disk Failure](02-disk-failure.md) | 2-4 hours | 1-24 hours | Local (MinIO) | ⭐⭐ Medium |
| [3. Host Failure](03-host-failure.md) | 4-8 hours | 1 week | B2 + Git | ⭐⭐⭐ High |
| [4. Rack Fire](04-rack-fire.md) | 8-24 hours | 1 week | B2 + Git | ⭐⭐⭐⭐ Critical |
| [5. Total Site Loss](05-total-site-loss.md) | 8-24 hours | 1 week | B2 + Git | ⭐⭐⭐⭐ Critical |
| [6. Ransomware](06-ransomware.md) | 8-24 hours | 1 week | B2 (clean) | ⭐⭐⭐ High |
| [7. Bad Config Change](07-bad-config-change.md) | 30 min - 2 hours | Minutes | Git + Local | ⭐ Low |
| [8. Data Corruption](08-data-corruption.md) | 4-8 hours | Weeks | B2 (old backup) | ⭐⭐⭐ High |
| [9. Primary Recovery](09-primary-recovery.md) | 1-4 hours | N/A | B2 + TrueNAS | ⭐ Low |

**Legend:**
- **RTO** (Recovery Time Objective): Expected time to restore service
- **RPO** (Recovery Point Objective): Maximum acceptable data loss
- **Recovery Source**: Primary data source for recovery

## Backup Architecture Overview

Your homelab uses a multi-tier backup strategy:

### Local Backups (TrueNAS MinIO)

**Purpose**: Fast recovery for common scenarios

- **Velero Cluster Backups**:
  - Hourly GFS: 48 backups (2 days)
  - Daily: 14 backups (2 weeks)
  - Weekly: 4 backups (1 month)
  - Location: `s3://velero@truenas.peekoff.com:9000`

- **CNPG PostgreSQL Backups**:
  - Continuous WAL archiving
  - Daily base backups at 2 AM
  - Location: `s3://homelab-postgres-backups@truenas.peekoff.com:9000`

- **Longhorn Volume Backups**:
  - GFS Tier (critical): Hourly (48), Daily (14), Weekly (8)
  - Daily Tier: 14 backups
  - Weekly Tier: 4 backups

### Offsite Backups (Backblaze B2)

**Purpose**: Disaster recovery for site loss scenarios

- **Velero Weekly Backups**:
  - Every Sunday at 3 AM UTC
  - 90-day retention (~13 backups)
  - Location: `s3://homelab-velero-b2`

- **CNPG PostgreSQL Backups**:
  - Continuous WAL archiving to B2
  - Daily base backups
  - 30-day retention
  - Location: `s3://homelab-cnpg-b2`

- **OpenTofu State**:
  - Real-time synchronization
  - Full version history
  - Location: `s3://homelab-terraform-state`

### Infrastructure as Code (GitHub)

**Purpose**: Cluster configuration and application definitions

- **Repository**: `theepicsaxguy/homelab`
- **Contents**:
  - OpenTofu/Terraform configurations (`tofu/`)
  - Kubernetes manifests (`k8s/`)
  - ArgoCD ApplicationSets
  - Talos machine configurations
  - Documentation

## Recovery Decision Tree

```
Incident Occurs
│
├─ Was it human error / recent change?
│  └─ YES → Scenario 1 (Accidental Deletion) or 7 (Bad Config)
│
├─ Is it hardware-related?
│  ├─ Single disk failure → Scenario 2 (Disk Failure)
│  ├─ Proxmox host down → Scenario 3 (Host Failure)
│  └─ Entire rack destroyed → Scenario 4 (Rack Fire)
│
├─ Is data corrupt or encrypted?
│  ├─ Ransomware suspected → Scenario 6 (Ransomware)
│  └─ Gradual corruption → Scenario 8 (Data Corruption)
│
├─ Is your house affected?
│  └─ YES → Scenario 5 (Total Site Loss)
│
└─ Are you unable to recover?
   └─ Family member needs help → Scenario 9 (Primary Recovery)
```

## Critical Infrastructure Details

### Cluster Information

- **Kubernetes Distribution**: Talos Linux v1.11.5
- **Kubernetes Version**: 1.34.3
- **Control Plane Nodes**: 3
  - `ctrl-00`: 10.25.150.11
  - `ctrl-01`: 10.25.150.12
  - `ctrl-02`: 10.25.150.13
- **Worker Nodes**: 3
  - `work-00`: 10.25.150.21
  - `work-01`: 10.25.150.22
  - `work-02`: 10.25.150.23
- **Virtual IP**: 10.25.150.10
- **Network**: VLAN 150, 10.25.150.0/24

### Infrastructure Components

- **Proxmox**: host3.peekoff.com
- **Storage**: Longhorn (distributed block storage)
- **Networking**: Cilium CNI
- **GitOps**: ArgoCD v9.2.2
- **Backup**: Velero v11.2.0
- **Database**: CloudNativePG (CNPG)
- **IaC**: OpenTofu (Terraform fork)

### Backup Locations

- **Local**: TrueNAS at `truenas.peekoff.com:9000`
- **Offsite**: Backblaze B2 (`s3.us-west-000.backblazeb2.com`)
- **State**: OpenTofu state in B2
- **Code**: GitHub `theepicsaxguy/homelab`

## Prerequisites for All Scenarios

Before disaster strikes, ensure you have:

1. **Access Credentials**:
   - Bitwarden master password
   - GitHub access (SSH key or PAT)
   - Backblaze B2 credentials (in Bitwarden)
   - Proxmox root password (in Bitwarden)

2. **Required Tools**:
   - `kubectl` (Kubernetes CLI)
   - `velero` (Velero CLI)
   - `talosctl` (Talos CLI)
   - `tofu` or `terraform` (OpenTofu CLI)
   - `git` (Git CLI)
   - `argocd` (ArgoCD CLI)

3. **Documentation Access**:
   - This documentation (ideally printed or on separate device)
   - Infrastructure repository cloned locally
   - Network diagrams (if available)

4. **Communication**:
   - Contact information for technical support
   - Incident tracking system (for documenting recovery)

## Testing Schedule

Regular disaster recovery testing ensures procedures work when needed:

### Monthly

- [ ] Run cluster health checks
- [ ] Verify backup schedules are running
- [ ] Check backup storage capacity (MinIO and B2)
- [ ] Review and update credentials

### Quarterly

- [ ] Test namespace restore from local backup (Scenario 1)
- [ ] Test PostgreSQL point-in-time recovery (Scenario 1)
- [ ] Verify B2 backups are accessible
- [ ] Update disaster recovery documentation

### Annually

- [ ] Full disaster recovery test (Scenario 3 or 4)
  - Provision test hardware or cloud VPS
  - Complete rebuild from B2 backups
  - Validate all data restored
  - Document actual recovery time
  - Update procedures based on findings

- [ ] Review and update contact information
- [ ] Review and update Bitwarden credentials
- [ ] Update recovery tool versions

## Emergency Contacts

- **Primary**: [Your name] - [Phone]
- **Technical Backup**: [Friend's name] - [Phone]
- **Infrastructure Provider**: Proxmox community forums
- **Backup Provider**: Backblaze support - support@backblaze.com

## Additional Resources

- [Main Disaster Recovery Guide](../disaster-recovery.md) - Talos + Longhorn recovery walkthrough
- [Velero Backup Documentation](../../infrastructure/controllers/velero-backup.md)
- [PostgreSQL Backup Strategy](../../infrastructure/database/postgres-backup.md)
- [Storage Backup Strategy](../../storage/backup-strategy.md)
- [BACKBLAZE_B2_SETUP.md](/BACKBLAZE_B2_SETUP.md) - B2 account setup guide
- [CNPG_B2_IMPLEMENTATION_NOTE.md](/CNPG_B2_IMPLEMENTATION_NOTE.md) - PostgreSQL B2 backup implementation

## Scenario-Specific Guidance

Click on any scenario above to view the complete step-by-step recovery procedure. Each scenario includes:

- **Symptoms**: How to identify this scenario
- **Impact Assessment**: RTO/RPO and data loss risk
- **Prerequisites**: What you need before starting
- **Recovery Procedure**: Detailed step-by-step instructions
- **Validation**: How to verify recovery succeeded
- **Post-Recovery Tasks**: Cleanup and documentation
- **Troubleshooting**: Common issues and solutions

Start with the scenario that best matches your current situation using the decision tree above.
