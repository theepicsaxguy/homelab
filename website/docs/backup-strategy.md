# Longhorn Backup Strategy

## Overview

This document outlines the comprehensive backup strategy for the homelab Kubernetes cluster using Longhorn distributed storage. The strategy implements a tiered backup approach with different frequencies and retention policies based on data criticality and recovery requirements.

## Context

The homelab is a GitOps-managed Kubernetes cluster running on Talos Linux with Argo CD for continuous deployment. Storage is provided by Longhorn, a distributed block storage system that supports automated backups to S3-compatible storage. The backup system uses label-based recurring jobs to automatically back up PersistentVolumeClaims (PVCs) based on their assigned tier.

### Key Components

- **Longhorn**: Distributed storage with built-in backup capabilities
- **Recurring Jobs**: Automated backup schedules triggered by PVC labels
- **Backup Tiers**: Three tiers (GFS, Daily, Weekly) with different frequencies and retention
- **Storage Target**: S3-compatible storage (MinIO) for backup retention

## Backup Tiers

### GFS (Grandfather-Father-Son)
- **Frequency**: Hourly + Daily + Weekly
- **Retention**: 48 hours (hourly), 14 days (daily), 8 weeks (weekly)
- **Total Backups**: ~70 per volume
- **Storage Impact**: High (frequent snapshots)
- **Use Case**: Critical databases requiring point-in-time recovery

### Daily
- **Frequency**: Daily
- **Retention**: 14 days
- **Total Backups**: ~14 per volume
- **Storage Impact**: Medium
- **Use Case**: Important application data and configurations

### Weekly
- **Frequency**: Weekly
- **Retention**: 4 weeks
- **Total Backups**: ~4 per volume
- **Storage Impact**: Low
- **Use Case**: Non-critical application data

## Implementation

### Labeling Strategy

PVCs and StatefulSet volumeClaimTemplates are labeled with two key-value pairs:

```yaml
metadata:
  labels:
    recurring-job.longhorn.io/source: enabled
    recurring-job-group.longhorn.io/<tier>: enabled
```

Where `<tier>` is one of: `gfs`, `daily`, or `weekly`.

### Labeled Resources

#### GFS Tier
**Critical Databases:**
- Authentik PostgreSQL - SSO system, critical for authentication
- Immich PostgreSQL - Photo management database, contains all metadata
- OpenCode data volume - SQLite database with user code and configurations

**Justification**: These contain irreplaceable data where any loss would be catastrophic. Point-in-time recovery is essential for databases.

#### Daily Tier
**PostgreSQL Databases:**
- LiteLLM PostgreSQL - AI model routing, important but can tolerate some data loss

**Application Data:**
- Audiobookshelf library - User-uploaded media library data
- Immich library - Photo storage (metadata handled separately)
- Audiobookshelf metadata/podcasts - Media indexes and metadata
- Pipeline data - OpenWebUI pipelines, Pinepods downloads/backups, Audiobookrequest config

**Justification**: Important operational data that should be backed up regularly but doesn't require hourly granularity. Recovery within 24 hours is acceptable.

#### Weekly Tier
**Application Configurations:**
- Jellyfin cache - Media server cache (can be rebuilt)
- SABnzbd - Usenet downloader config and incomplete downloads
- Jellyseerr - Media request manager
- Sonarr/Radarr - Media management automation
- Baby Buddy - Baby tracking application
- MQTT - Message broker data
- Zigbee2MQTT - IoT device configuration
- UniFi Controller - Network management
- Home Assistant - Smart home configuration
- KaraKeep - Document management (MeiliSearch + web data)
- OpenWebUI web data - Chat interface data

**Justification**: Configuration and cache data that has value but can tolerate weekly backups. These applications can be reconfigured if lost, though it would be inconvenient.

## Exclusions

Certain PVCs and applications are intentionally excluded from automated backups:

### User-Excluded Applications
- **PedroBot**: Not critical for backup
- **Qdrant**: Vector database with replaceable embeddings
- **OpenHands**: Development/testing tool
- **VLLM**: AI model embeddings (can be regenerated)
- **HeadlessX**: Remote desktop (ephemeral sessions)
- **Unrar**: Temporary processing tool
- **Media-share**: Handled by separate snapshot strategy

### Infrastructure Components
- Redis instances (minimal state, replaceable)
- ArgoCD, Cilium, and other infrastructure PVCs (can be redeployed)

**Justification**: These contain ephemeral, cache, or easily regeneratable data. Backing them up would consume storage without significant benefit.

## Why This Strategy?

### Risk-Based Approach
The tiered strategy balances backup frequency with storage costs and recovery requirements. Critical data gets maximum protection, while less important data gets appropriate coverage without over-protection.

### Cost Optimization
- GFS: ~70 backups per volume (high cost, high value)
- Daily: ~14 backups per volume (medium cost, medium value)
- Weekly: ~4 backups per volume (low cost, low value)

### Recovery Considerations
- **RTO (Recovery Time Objective)**: GFS allows recovery to any point in the last 8 weeks
- **RPO (Recovery Point Objective)**: Ranges from 1 hour (GFS) to 1 week (Weekly)
- **Data Criticality**: Matches backup frequency to business impact of data loss

### Operational Benefits
- **Automated**: Label-based triggers require no manual intervention
- **Scalable**: New PVCs automatically inherit backup behavior
- **GitOps**: Backup configuration is declarative and version-controlled
- **Cost-Effective**: Avoids backing up ephemeral or replaceable data

## Implementation Status

- ✅ Identified and labeled all critical PVCs and StatefulSets
- ✅ Created appropriate backup tiers with justified retention policies
- ✅ Excluded non-critical and ephemeral data
- ✅ Documented the strategy for future maintenance

## Future Considerations

- Monitor backup storage usage and adjust retention if needed
- Consider adding a "monthly" tier for archival data if required
- Evaluate backup restore procedures periodically
- Review excluded applications annually for changes in criticality