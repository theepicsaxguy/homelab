---
sidebar_position: 1
title: Media Stack
description: Overview and configuration of the self-hosted media services
---

# Media Services Stack

This document details our self-hosted media services stack, including configuration, resource allocation, and best
practices.

## Core Applications

### Jellyfin

- **Purpose**: Primary media streaming server
- **Features**:
  - Hardware-accelerated transcoding (Intel QuickSync)
  - Direct play optimization
  - Multi-user support
  - HDR tone mapping

### Management Suite (\*arr Stack)

#### Sonarr

- **Purpose**: TV series management and automation
- **Key Features**:
  - Series monitoring
  - Release quality profiles
  - Automated download management

#### Radarr

- **Purpose**: Movie collection management
- **Key Features**:
  - Movie monitoring
  - Quality profiles
  - Custom formats support

#### Prowlarr

- **Purpose**: Unified indexer management
- **Features**:
  - Centralized indexer configuration
  - Integration with \*arr applications
  - Stats and history tracking

## Infrastructure Configuration

### Deployment Configuration

The \*arr applications share a common Kustomize base located in `k8s/applications/media/arr/base`. This base injects
node selectors, security settings, environment variables, and shared volume mounts via a JSON patch. Each individual
application kustomization references this base and only defines its unique image and resource requirements.

### Storage Layout

```yaml
Storage Classes:
  media-storage: # For media files
    type: Longhorn
    replication: 1
    size: 2Ti
  metadata-storage: # For application data
    type: Longhorn
    replication: 2
    size: 100Gi
```

### Resource Allocation

| Application | CPU Request | CPU Limit | Memory Request | Memory Limit | Storage     |
| ----------- | ----------- | --------- | -------------- | ------------ | ----------- |
| Jellyfin    | 2           | 4         | 2Gi            | 5Gi          | 2Ti (media) |
| Sonarr      | 50m         | 1         | 384Mi          | 1Gi          | 10Gi        |
| Radarr      | 50m         | 1         | 128Mi          | 1Gi          | 10Gi        |
| Prowlarr    | 50m         | 500m      | 192Mi          | 512Mi        | 5Gi         |

### Network Configuration

- **Internal Access**: Via Cilium ClusterIP services
- **External Access**: Through Cilium Gateway API
- **Authentication**: Integrated with Authentik SSO
- **Security**: Zero-trust model with explicit policy

## Performance Optimizations

### Jellyfin Optimizations

1. **Hardware Acceleration**

   ```yaml
   devices:
     - /dev/dri/renderD128 # Intel QuickSync device
   ```

2. **Storage Performance**
   - Direct volume mounts for media
   - SSD storage class for metadata
   - Optimized read patterns

### \*arr Stack Optimizations

1. **Database Performance**

   - SQLite on SSD storage
   - Regular VACUUM scheduling
   - Proper journal modes

2. **Network Performance**
   - Keep-alive connections
   - Efficient API polling
   - Scheduled tasks distribution

## Monitoring & Maintenance

### Key Metrics

- Transcode queue length
- Storage utilization
- Network throughput
- API response times

### Alerts Configuration

```yaml
alerts:
  storage:
    threshold: 85%
    warning: 75%
  transcoding:
    queue_length: >10
    duration: >30
```

## Known Issues & Solutions

1. **Library Scan Impact**

   - **Issue**: High CPU usage during scans
   - **Solution**: Implemented scheduled scans during off-peak hours
   - **Status**: Managed via CronJob

2. **Database Performance**
   - **Issue**: SQLite contention under load
   - **Solution**: Moved to SSD storage, optimized vacuum schedule
   - **Status**: Monitoring via Prometheus

## Roadmap

- [ ] Integration with Home Assistant for automation
- [ ] Implementation of cross-node GPU sharing
- [ ] Enhanced metadata caching layer
- [ ] Backup strategy improvements

## Troubleshooting Guide

1. **Transcoding Issues**

   - Verify GPU access permissions
   - Check transcode temporary directory
   - Monitor GPU utilization

2. **Download Issues**

   - Validate indexer connectivity
   - Check download client settings
   - Verify storage permissions

3. **Performance Issues**
   - Review resource utilization
   - Check network connectivity
   - Validate storage performance
