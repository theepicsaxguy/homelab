# Storage Architecture Overview

## Storage Infrastructure

The cluster uses a flexible storage architecture built on Proxmox's storage capabilities and the Proxmox CSI driver.

## Components

### 1. Storage Providers

- **Proxmox CSI Driver**

  - Dynamic volume provisioning
  - Storage class support
  - Direct Proxmox storage integration

- **Local Path Provisioner**
  - Node-local storage
  - High-performance options
  - Development workloads

### 2. Storage Classes

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

### 3. Backup and Recovery

- Volume snapshots
- Persistent volume backups
- Disaster recovery procedures

## Detailed Documentation

- [Proxmox CSI Configuration](proxmox-csi.md)
- [Storage Performance](performance.md)
- [Monitoring Storage](monitoring.md)

## Best Practices

1. **Volume Management**

   - Use appropriate storage classes
   - Implement resource quotas
   - Regular monitoring

2. **Performance Optimization**

   - Storage class selection
   - Volume placement strategy
   - I/O considerations

3. **Data Protection**
   - Regular backups
   - Snapshot policies
   - Recovery testing
