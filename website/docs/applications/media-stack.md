---
sidebar_position: 1
title: Media Stack
description: Overview and configuration of the self-managed media services
---

# Media services stack

This document details the self-managed media services stack, including configuration, resource allocation, and best
practices.

## Core apps

### Jellyfin

- **Purpose**: Primary media streaming server
- **Features**:
  - Hardware-accelerated transcoding (Intel QuickSync)
  - Direct play optimization
  - Multi-user support
  - High Dynamic Range (HDR) tone mapping

### Management suite (*arr stack)

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
  - Integration with *arr apps
  - Stats and history tracking

## Infrastructure configuration

### Deployment configuration

The *arr apps share a common Kustomize base located in `k8s/apps/media/arr/base`. This base injects
node selectors, security settings, environment variables, and shared volume mounts via a JSON patch. Each individual
app kustomization references this base and only defines its unique image and resource requirements. The base
also mounts ephemeral volumes at `/tmp` and `/run` so the apps can write temporary data despite the
read-only root file system. Bazarr requires a small exception here: the container's `allowPrivilegeEscalation`
flag must enable its s6-init scripts to drop privileges.

### Storage layout

```yaml
Storage Classes:
  media-storage: # For media files
    type: Longhorn
    replication: 1
    size: 2Ti
  longhorn: # For app data
    type: Longhorn
    replication: 2
    size: 100Gi
```

### Resource allocation

| App         | CPU Request | CPU Limit | Memory Request | Memory Limit | Storage     |
| ----------- | ----------- | --------- | -------------- | ------------ | ----------- |
| Jellyfin    | 2           | 4         | 2Gi            | 5Gi          | 2Ti (media) |
| Sonarr      | 500m        | 1         | 512Mi          | 1Gi          | 10Gi        |
| Radarr      | 500m        | 1         | 512Mi          | 1Gi          | 10Gi        |
| Prowlarr    | 250m        | 500m      | 256Mi          | 512Mi        | 5Gi         |

### Network configuration

- **Internal Access**: Via Cilium ClusterIP services
- **External Access**: Through Cilium Gateway API
- **Authentication**: Integrated with Authentik single sign-on
- **Security**: Zero-trust model with explicit policy

## Performance optimizations

### Jellyfin optimizations

1. **Hardware Acceleration**

   ```yaml
   devices:
     - /dev/dri/renderD128 # Intel QuickSync device
   ```

2. **Storage Performance**
   - Direct volume mounts for media
   - Solid State Drive (SSD) storage class for metadata
   - Optimized read patterns
   - Metadata cache stored on a persistent volume

### *arr stack optimizations

1. **Database Performance**

   - SQLite on SSD storage
   - Regular VACUUM scheduling
   - Proper journal modes

2. **Network Performance**
   - Keep-alive connections
   - Efficient API polling
   - Scheduled tasks distribution

## Monitoring & maintenance

### Key metrics

- Transcode queue length
- Storage use
- Network throughput
- API response times

### Alerts configuration

```yaml
alerts:
  storage:
    threshold: 85%
    warning: 75%
  transcoding:
    queue_length: >10
    duration: >30
```

## Known issues & solutions

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
- [x] Enhanced metadata caching layer
- [ ] Backup strategy improvements

## Troubleshooting guide

1. **Transcoding Issues**

   - Ensure GPU access permissions are correct
   - Check transcode temporary directory
   - Check GPU usage

2. **Download Issues**

   - Validate indexer connectivity
   - Check download client settings
   - Verify storage permissions

3. **Performance Issues**
   - Review resource use
   - Check network connectivity
   - Validate storage performance

## Migration guide: Deployment to StatefulSet

### Prerequisites

   - Backup all PersistentVolumeClaims before starting
- Have access to `kubectl` for manual intervention if needed
- Schedule a maintenance window

### Step-by-step migration process

#### 1. Preparation

```shell
# Disable auto-sync for media apps in ArgoCD
argocd app set media-stack --sync-policy none

# Replace <app-name> with the specific app (e.g., bazarr, sonarr)
# First, find the name of the PersistentVolume (PV) bound to your app's config claim.
export PersistentVolumeClaim_NAME=<app-name>-config
export PV_NAME=$(kubectl get persistentvolumeclaim $PVC_NAME -n media -o jsonpath='{.spec.volumeName}')
echo "Found PV Name: $PV_NAME for PersistentVolumeClaim: $PVC_NAME"

# If the above command returned a PV_NAME, proceed.
# Protect the PV from deletion by setting its reclaim policy to Retain
kubectl patch pv $PV_NAME -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'

# Scale down the existing deployment
kubectl scale deployment <app-name> --replicas=0 -n media

# Delete the old PersistentVolumeClaim. The PV will enter a "Released" state.
kubectl delete persistentvolumeclaim $PVC_NAME -n media

# Clear the claimRef from the PV to make it "Available"
# This allows a new PVC to bind to it.
kubectl patch pv $PV_NAME --type json -p='[{"op": "remove", "path": "/spec/claimRef"}]'
```

#### 2. Migration

```shell
# Apply the StatefulSet changes through ArgoCD
# This will create a new PersistentVolumeClaim (e.g., config-<app-name>-0)
# Replace <app-name> with the specific app (e.g., bazarr, sonarr)
argocd app sync media-stack --resource-by-key StatefulSet:<app-name> -n media

# Verify the StatefulSet is running and the new PVC (e.g., config-<app-name>-0)
# has bound to the original (now "Available") PersistentVolume.
kubectl get statefulset,persistentvolumeclaim -n media -l app=<app-name>
kubectl logs statefulset/<app-name> -n media
```

#### 3. Verification

   - Check app logs for successful startup
- Verify all data is present and accessible
- Test basic features
- Confirm the app can write to its configuration volume

#### 4. Cleanup

```shell
# Once verified, delete the old deployment
kubectl delete deployment <app-name> -n media

# Re-enable auto-sync
argocd app set media-stack --sync-policy automated
```

### Troubleshooting

If issues occur during migration:

1. **Data Access Issues**
   - Verify PersistentVolumeClaim mounting and permissions
   - Check StatefulSet events: `kubectl describe statefulset <app-name> -n media`

2. **App Startup Problems**
   - Review container logs
   - Verify environment variables and configurations

3. **Recovery Plan**
   If needed, revert to deployment:

   ```shell
      kubectl scale statefulset <app-name> --replicas=0 -n media
   kubectl scale deployment <app-name> --replicas=1 -n media
   ```
