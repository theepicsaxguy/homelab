# Storage Monitoring

## Overview

Comprehensive monitoring of storage resources across all providers and volumes in the cluster, with integration into the
central monitoring stack.

## Storage Providers

### Longhorn Storage

```yaml
metrics:
  controller:
    - replica_count
    - volume_capacity
    - actual_size
    - provisioned_iops
    - actual_iops
  volume:
    - readiops
    - writeiops
    - readlatency
    - writelatency
    - readthroughput
    - writethroughput
```

### NFS Storage

```yaml
metrics:
  nfs:
    - available_bytes
    - used_bytes
    - operations
    - rpc_stats
  mount:
    - read_bytes
    - write_bytes
    - read_operations
    - write_operations
```

## Alert Configuration

### Capacity Alerts

```yaml
groups:
  - name: storage-capacity
    rules:
      - alert: StorageNearlyFull
        expr: |
          kubelet_volume_stats_available_bytes /
          kubelet_volume_stats_capacity_bytes < 0.15
        for: 1h
        labels:
          severity: warning
          component: storage
        annotations:
          summary: Storage volume {{ $labels.persistentvolumeclaim }} is nearly full

      - alert: StorageCriticallyFull
        expr: |
          kubelet_volume_stats_available_bytes /
          kubelet_volume_stats_capacity_bytes < 0.05
        for: 10m
        labels:
          severity: critical
          component: storage
```

### Performance Alerts

```yaml
groups:
  - name: storage-performance
    rules:
      - alert: HighLatency
        expr: |
          rate(longhorn_volume_read_latency_microseconds[5m]) > 10000
          or
          rate(longhorn_volume_write_latency_microseconds[5m]) > 10000
        for: 5m
        labels:
          severity: warning
          component: storage

      - alert: LowIOPS
        expr: |
          rate(longhorn_volume_read_iops[5m]) < 100
          and
          rate(longhorn_volume_write_iops[5m]) < 100
        for: 15m
        labels:
          severity: warning
          component: storage
```

## Dashboard Configuration

### Volume Overview

```yaml
panels:
  - name: Volume Capacity
    type: gauge
    targets:
      - expr: |
          kubelet_volume_stats_available_bytes /
          kubelet_volume_stats_capacity_bytes * 100

  - name: IOPS by Volume
    type: graph
    targets:
      - expr: rate(longhorn_volume_read_iops[5m])
      - expr: rate(longhorn_volume_write_iops[5m])

  - name: Latency by Volume
    type: graph
    targets:
      - expr: rate(longhorn_volume_read_latency_microseconds[5m])
      - expr: rate(longhorn_volume_write_latency_microseconds[5m])
```

### Storage Class Performance

```yaml
panels:
  - name: Throughput by StorageClass
    type: graph
    targets:
      - expr: |
          sum(
            rate(longhorn_volume_read_bytes[5m])
          ) by (storageclass)
      - expr: |
          sum(
            rate(longhorn_volume_write_bytes[5m])
          ) by (storageclass)

  - name: Average Latency by StorageClass
    type: graph
    targets:
      - expr: |
          avg(
            rate(longhorn_volume_read_latency_microseconds[5m])
          ) by (storageclass)
```

## Integration with Central Monitoring

### ServiceMonitor Configuration

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: longhorn-monitoring
spec:
  selector:
    matchLabels:
      app: longhorn-manager
  endpoints:
    - port: manager
      interval: 15s
```

### Recording Rules

```yaml
groups:
  - name: storage-aggregation
    rules:
      - record: storage:volume_usage:ratio
        expr: |
          kubelet_volume_stats_available_bytes /
          kubelet_volume_stats_capacity_bytes

      - record: storage:throughput:rate5m
        expr: |
          sum(
            rate(longhorn_volume_read_bytes[5m]) +
            rate(longhorn_volume_write_bytes[5m])
          ) by (volume)
```

## Performance Optimization

### Caching Strategy

- Read-ahead caching enabled
- Write-back caching configured
- Cache size optimization
- IO pattern analysis

### Resource Allocation

```yaml
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

## Troubleshooting

### Common Issues

1. High Latency

   - Check network connectivity
   - Verify IO patterns
   - Analyze system resources
   - Review cache hit rates

2. Low IOPS
   - Check storage provisioning
   - Verify resource limits
   - Analyze concurrent operations
   - Review QoS settings

### Debugging Tools

```yaml
diagnostic_tools:
  - longhorn-manager logs
  - kubectl describe pv/pvc
  - storage class events
  - node capacity analysis
```
