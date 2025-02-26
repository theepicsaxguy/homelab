# Longhorn Distributed Storage

## Overview

Longhorn provides distributed block storage with replication, backup, and guaranteed IOPS features.

## Configuration

Default configuration optimized for our homelab:

```yaml
component:
  replication:
    count: 3
  resources:
    manager:
      cpu: 250m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
  storage:
    overprovisioning: 200%
    minimalAvailable: 10%
```

## Storage Features

### Volume Management

- Dynamic provisioning
- Volume snapshots
- Backup and restore
- Live volume expansion

### High Availability

- Volume replication
- Node failure handling
- Automatic failover
- Data locality options

## Performance Settings

### Resource Allocation

- Guaranteed Engine CPU: 0.2 cores
- Guaranteed Replica CPU: 0.2 cores
- Priority class: system-cluster-critical

### IOPS Management

- Auto-balancing enabled
- Concurrent rebuild limit: 2
- Storage network optimization
- Disk pressure handling

## Backup Configuration

### Default Settings

- Backup store poll interval: 300s
- Auto salvage: enabled
- Auto deletion on detach: enabled
- Default filesystem: ext4

### Monitoring Integration

- Volume metrics
- Node metrics
- Backup status
- Performance data

## Best Practices

1. Volume Management

   - Use appropriate replica count
   - Enable auto-salvage
   - Configure backups
   - Monitor space usage

2. Performance

   - Balance workload distribution
   - Monitor resource usage
   - Use appropriate storage classes
   - Configure IOPS limits

3. Maintenance
   - Regular backup verification
   - Monitor replica health
   - Update component versions
   - Resource optimization
