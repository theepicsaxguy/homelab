# Metrics Configuration

## Overview

The metrics infrastructure is built around Prometheus, providing comprehensive monitoring of all cluster components.

## Prometheus Configuration

### Service Discovery

```yaml
prometheus:
  serviceMonitorSelector:
    matchLabels:
      monitoring: prometheus

  podMonitorSelector:
    matchLabels:
      monitoring: prometheus

  resources:
    requests:
      memory: 2Gi
      cpu: 500m
    limits:
      memory: 4Gi
      cpu: 1000m
```

## Standard Metrics

### Node Metrics

- CPU utilization
- Memory usage
- Disk I/O
- Network traffic
- System load

### Kubernetes Metrics

- Pod status
- Container resources
- API server latency
- etcd metrics
- Scheduler metrics

### Application Metrics

```yaml
# Standard service monitor configuration
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: app-metrics
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
    - port: metrics
      interval: 15s
      path: /metrics
```

## Retention and Storage

- 15-day retention period
- Compaction settings
- Storage requirements
- Backup configuration

## Integration Points

- Grafana dashboards
- Alert rules
- Recording rules
- External exporters
