# Storage Architecture

## Storage Components

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

## Storage Classes

### Performance Tiers

1. **high-performance**

   - SSD-backed storage
   - Low latency requirements
   - Database workloads

2. **standard**

   - General purpose storage
   - Mixed workload support
   - Application data

3. **capacity**
   - HDD-backed storage
   - High capacity needs
   - Media storage

## Backup Architecture

### Components

- Scheduled snapshots
- Volume replication
- Off-site backups
- Retention policies

### Backup Procedures

1. Database backups (CloudNative PG)
2. PV snapshots (CSI)
3. Configuration backups
4. System state backups

## Recovery Procedures

### Volume Recovery

1. Identify failed volume
2. Create recovery snapshot
3. Restore volume data
4. Validate application state

### Database Recovery

1. Stop affected workload
2. Restore from backup
3. Validate data integrity
4. Resume operations

## Maintenance Operations

### Regular Tasks

- Storage health monitoring
- Capacity planning
- Performance optimization
- Backup verification

### Emergency Procedures

1. Volume failure response
2. Emergency snapshots
3. Quick recovery steps
4. Data salvage process

## Scaling Guidelines

### Vertical Scaling

- Volume expansion
- Storage pool growth
- Performance tuning
- IOPS management

### Horizontal Scaling

- Additional storage nodes
- Replication targets
- Backup destinations
- Cache layers

## Performance Monitoring

### Metrics

- IOPS monitoring
- Latency tracking
- Throughput measurement
- Capacity trending

### Alerts

- Capacity thresholds
- Performance degradation
- Hardware failures
- Backup failures
