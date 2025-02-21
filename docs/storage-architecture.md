# Storage Architecture

## Overview

The cluster storage architecture leverages multiple storage solutions including Proxmox CSI and Longhorn for different use cases, providing dynamic persistent storage provisioning and distributed block storage for containerized applications.

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

### Longhorn Distributed Storage

```yaml
component:
  name: Longhorn
  version: 1.8.0
  purpose: Distributed block storage
  features:
    - Volume replication
    - Backup to S3
    - Storage overprovisioning
    - Guaranteed IOPS
  configuration:
    replication: 2 replicas
    engine:
      cpu: 0.2 cores
      memory: 256Mi
    backup:
      target: S3 compatible
      automation: Yes
    deployment:
      method: Helm chart
      repository: https://charts.longhorn.io
```

```mermaid
graph TB
    subgraph Storage Layer
        TrueNAS[TrueNAS Core]
        CSI[Proxmox CSI Driver]
        Longhorn[Longhorn Storage]
        CNPG[CloudNative PG]
    end

    subgraph Volume Types
        Block[Block Storage]
        File[File Storage]
        Object[Object Storage]
        Replicated[Replicated Volumes]
    end

    subgraph Applications
        Databases[Database Workloads]
        Media[Media Applications]
        Config[Configuration Storage]
        StatefulApps[Stateful Applications]
    end

    Storage Layer --> Volume Types
    Volume Types --> Applications
    Longhorn --> Replicated
    Replicated --> StatefulApps
```

### Storage Classes

```yaml
classes:
  proxmox-csi:
    type: 'Proxmox Block Storage'
    provisioner: 'proxmox.csi.k8s.io'
    parameters:
      format: 'raw'
      size: 'dynamic'
  longhorn:
    type: 'Replicated Block Storage'
    provisioner: 'driver.longhorn.io'
    parameters:
      numberOfReplicas: '2'
      staleReplicaTimeout: '30'
```

## Volume Management

### PVC Lifecycle

1. Provisioning

   - Dynamic allocation
   - Size-based provisioning
   - Storage class selection
   - Replica count (Longhorn)

2. Attachment
   - Node-level attachment
   - Multi-attach policies
   - Mount propagation
   - Replica distribution

### Snapshots and Backups

```yaml
backup_strategy:
  snapshots:
    frequency: 'Daily'
    retention: '7 days'
  backups:
    type: 'S3 compatible'
    location: 'us-east-1'
    automation: 'Longhorn backup controller'
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
  longhorn:
    iops: 'Guaranteed per volume'
    throughput: 'Based on replica count'
    latency: 'Network dependent'
```

### Resource Allocation

```yaml
resources:
  longhorn:
    engine:
      cpu: '0.2 cores'
      memory: '256Mi'
    replicas: 2
    storage_efficiency: '50%'  # Due to replication
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

## Current Features

1. Storage Features
   - ✓ Enhanced snapshot management (via Longhorn)
   - ✓ Automated S3 backups (via Longhorn)
   - ✓ Advanced quota management (via StorageClass)

2. Performance Features
   - ✓ Guaranteed IOPS (via Longhorn)
   - ✓ Replica distribution
   - ✓ Storage overprovisioning

3. Management Features
   - ✓ Storage analytics (via Prometheus integration)
   - ✓ Multi-node resilience
   - ✓ Automated replica healing

## Future Improvements

1. Storage Enhancements
   - Cross-cluster replication
   - Data locality awareness
   - Tiered storage classes

2. Performance Optimization
   - IO priority classes
   - Network optimization
   - Cache tuning

3. Management Features
   - ML-based capacity planning
   - Predictive failure analysis
   - Cost optimization
