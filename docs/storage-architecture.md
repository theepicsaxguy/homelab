# Storage Architecture

## Overview

The cluster storage architecture is built around Proxmox CSI (Container Storage Interface) driver, providing dynamic
persistent storage provisioning for containerized applications.

## Storage Components

### Proxmox CSI Driver

```yaml
component:
  name: Proxmox CSI
  purpose: Dynamic volume provisioning
  features:
    - Volume lifecycle management
    - Snapshot support
    - Clone capabilities
    - Online volume expansion
```

```mermaid
graph TB
    subgraph Storage Layer
        TrueNAS[TrueNAS Core]
        CSI[Proxmox CSI Driver]
        CNPG[CloudNative PG]
    end

    subgraph Volume Types
        Block[Block Storage]
        File[File Storage]
        Object[Object Storage]
    end

    subgraph Applications
        Databases[Database Workloads]
        Media[Media Applications]
        Config[Configuration Storage]
    end

    Storage Layer --> Volume Types
    Volume Types --> Applications
```

### Storage Classes

```yaml
classes:
  standard:
    type: 'Proxmox Block Storage'
    provisioner: 'proxmox.csi.k8s.io'
    parameters:
      format: 'raw'
      size: 'dynamic'
  fast:
    type: 'SSD-backed storage'
    provisioner: 'proxmox.csi.k8s.io'
    parameters:
      format: 'raw'
      pool: 'fast-pool'
```

## Volume Management

### PVC Lifecycle

1. Provisioning

   - Dynamic allocation
   - Size-based provisioning
   - Storage class selection

2. Attachment
   - Node-level attachment
   - Multi-attach policies
   - Mount propagation

### Snapshots and Backups

```yaml
backup_strategy:
  snapshots:
    frequency: 'Daily'
    retention: '7 days'
  backups:
    type: 'Application-specific'
    location: 'Secondary storage'
```

## Performance Characteristics

### I/O Profiles

```yaml
performance_profiles:
  standard:
    iops: 'Medium'
    throughput: 'Up to 100MB/s'
    latency: '<10ms'
  fast:
    iops: 'High'
    throughput: 'Up to 500MB/s'
    latency: '<5ms'
```

### Resource Quotas

```yaml
quotas:
  default:
    storage: '10Gi per PVC'
    snapshots: '5 per PVC'
  expanded:
    storage: '100Gi per PVC'
    snapshots: '10 per PVC'
```

## High Availability

### Storage Redundancy

1. Volume Replication

   - Node-level redundancy
   - Data consistency
   - Failover capabilities

2. Backup Strategy
   - Regular snapshots
   - Off-site backups
   - Recovery testing

## Monitoring and Operations

### Storage Metrics

```yaml
metrics:
  capacity:
    warning: '80% used'
    critical: '90% used'
  performance:
    latency_threshold: '20ms'
    iops_minimum: '1000'
```

### Health Checks

1. Volume Health

   - Mount point checks
   - Filesystem integrity
   - Performance monitoring

2. CSI Driver Health
   - Controller status
   - Node plugin status
   - Provisioner health

## Security

### Access Control

1. Storage RBAC

   - Volume access policies
   - Namespace quotas
   - SecurityContext enforcement

2. Encryption
   - Volume encryption support
   - Key management
   - Secure deletion

## Troubleshooting

### Common Issues

```yaml
issues:
  volume_mount:
    checks:
      - PVC status
      - Node mount points
      - CSI node logs
  performance:
    checks:
      - IO stats
      - Latency metrics
      - Resource contention
```

### Debug Procedures

1. Volume Issues

   - Check PVC/PV status
   - Verify node mounts
   - Review CSI logs

2. Performance Issues
   - Monitor IO metrics
   - Check resource limits
   - Verify storage class

## Resource Requirements

### Storage Resources

```yaml
minimum_requirements:
  capacity: '100GB per node'
  iops: '1000 IOPS'
  throughput: '100MB/s'
```

### Node Requirements

```yaml
node_storage:
  system: '20GB'
  containers: '40GB'
  volumes: 'Varies by workload'
```

## Future Improvements

1. Storage Features

   - Enhanced snapshot management
   - Automated backup solutions
   - Advanced quota management

2. Performance Optimization

   - IO scheduling improvements
   - Cache optimization
   - Monitoring enhancements

3. Management Features
   - Storage analytics
   - Capacity planning
   - Automated scaling
