# Proxmox CSI Configuration

## Overview

The Proxmox CSI Driver provides storage integration between Kubernetes and Proxmox storage pools.

## Storage Classes

```yaml
storage_classes:
  proxmox-standard:
    type: 'general purpose'
    provisioner: 'proxmox.csi.pc-tips.se'
    volumeBindingMode: WaitForFirstConsumer

  proxmox-fast:
    type: 'high performance'
    provisioner: 'proxmox.csi.pc-tips.se'
    volumeBindingMode: WaitForFirstConsumer
    parameters:
      type: 'ssd'
```

## Volume Management

### Dynamic Provisioning

- Automatic volume creation
- Storage pool selection
- Size management
- Node affinity

### Volume Features

- Online volume expansion
- Snapshot support
- Clone capabilities
- Backup integration

## Performance Configuration

```yaml
csi_config:
  controller:
    replicas: 1
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
  node:
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
      limits:
        cpu: 100m
        memory: 128Mi
```

## Security Considerations

1. **Access Control**

   - Token-based authentication
   - Minimal permissions
   - Secure communication
   - Volume encryption

2. **Network Security**
   - Internal network only
   - No external access
   - Encryption in transit
   - Network policies

## Monitoring Integration

1. **Metrics**

   - Volume creation/deletion
   - Storage capacity
   - Operation latency
   - Error rates

2. **Alerts**
   - Storage capacity
   - Operation failures
   - Performance degradation
   - Controller health
