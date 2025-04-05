# Longhorn Distributed Storage

## Overview

Longhorn provides distributed block storage with replication, backup, and guaranteed IOPS features.

## Talos Linux Requirements

### System Extensions

The following system extensions are required for Longhorn to function properly on Talos Linux:

- `siderolabs/iscsi-tools`: For iSCSI connectivity between nodes
- `siderolabs/util-linux-tools`: For various filesystem operations

These extensions are already included in our Talos configuration (see `tofu/talos/image/schematic.yaml`).

### Data Path Configuration

Longhorn requires a special mount configuration on all nodes:

```yaml
machine:
  kubelet:
    extraMounts:
      - destination: /var/lib/longhorn
        type: bind
        source: /var/lib/longhorn
        options:
          - bind
          - rshared
          - rw
```

### Pod Security Configuration

Longhorn requires privileged pod security context. Our namespace configuration already includes:

```yaml
metadata:
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/audit: baseline
    pod-security.kubernetes.io/warn: baseline
```

### Upgrade Considerations

**IMPORTANT**: When upgrading Talos Linux, always use the `--preserve` flag to prevent data loss:

```bash
talosctl upgrade-k8s --to <version> --preserve
```

This flag ensures that `/var/lib/longhorn` directory contents are preserved during upgrades. Without it, all local
replicas would be destroyed.

### Limitations

- Only v1 data volumes are supported
- Talos immutability means certain operations must be handled carefully

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

## Recovery Procedures

### Recovering From Upgrade Without Preservation

If an upgrade occurred without the `--preserve` flag and data was lost:

1. In Longhorn UI, disable scheduling for all affected nodes
2. Remove the affected disks from the node
3. Add the disks back (they should be empty now)
4. Re-enable scheduling
5. The volumes will be rebuilt from replicas on other nodes (if replica count >1)

### Recovering From Node Failure

1. If a node becomes unresponsive:

   - Longhorn automatically reschedules volumes to other nodes
   - Replicas will be rebuilt if capacity allows

2. When restoring the node:
   - Verify that `/var/lib/longhorn` mount is correctly configured
   - Check that all system extensions are present
   - Allow Longhorn to rebalance volumes automatically

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
