# Logging Configuration

## Overview

The logging infrastructure is built on Loki with multi-tenant support and environment-specific retention policies.

## Log Collection

### Source Configuration

```yaml
promtail:
  scrape_configs:
    - job_name: kubernetes-pods
      kubernetes_sd_configs:
        - role: pod
      pipeline_stages:
        - docker: {}
        - labels:
            namespace:
            app:
            component:
        - output:
            source: message

    - job_name: system-logs
      static_configs:
        - targets:
            - localhost
          labels:
            job: systemd
            __path__: /var/log/journal

    - job_name: audit-logs
      kubernetes_sd_configs:
        - role: pod
      relabel_configs:
        - source_labels: [__meta_kubernetes_pod_annotation_kubernetes_io_control_plane]
          action: keep
          regex: true
```

### Label Strategy

```yaml
static_labels:
  cluster: homelab
  environment: ${ENV}

dynamic_labels:
  - namespace
  - app
  - pod
  - container
  - node
  - severity

extracted_labels:
  - level
  - status_code
  - method
  - path
```

## Storage Configuration

### Retention Rules

```yaml
retention_config:
  production:
    logs: 30d
    audit: 90d
    metrics: 15d
  staging:
    logs: 14d
    audit: 30d
    metrics: 7d
  development:
    logs: 7d
    audit: 14d
    metrics: 3d
```

### Storage Backend

```yaml
storage:
  type: filesystem
  filesystem:
    directory: /data/loki/chunks
  index:
    prefix: index_
    period: 24h
```

## Query Configuration

### LogQL Examples

```logql
# Error tracking across services
{namespace=~".*-apps"} |= "error"
  | json
  | status_code >= 500

# Resource consumption patterns
{component="resource-monitor"}
  | json
  | unwrap cpu_usage
  | avg_over_time(1h)

# Security events
{job="audit-log"}
  |~ "forbidden|denied|failed"
  | json
  | by_src_ip
```

### Performance Optimization

- Label cardinality limits
- Stream selector optimization
- Query time range limits
- Cache configuration

## Integration Points

### Grafana Integration

```yaml
datasources:
  loki:
    url: http://loki:3100
    search:
      maxLookback: 30d
    alerting:
      maxLookback: 1h

dashboard_config:
  logs:
    refresh: 30s
    time_range: 6h
    variables:
      - namespace
      - app
      - severity
```

### Alert Rules

```yaml
groups:
  - name: log-based-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate({namespace=~".*-apps"}
            |~ "error|ERROR" [5m])) by (namespace) > 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High error rate detected

      - alert: AuditFailure
        expr: |
          sum(rate({job="audit-log"}
            |~ "forbidden|denied" [5m])) > 5
        for: 2m
        labels:
          severity: critical
```

## Environment-Specific Settings

### Development

```yaml
loki:
  log_level: debug
  query_timeout: 1m
  max_look_back: 7d
  cache:
    enabled: false
```

### Staging

```yaml
loki:
  log_level: info
  query_timeout: 2m
  max_look_back: 14d
  cache:
    enabled: true
    size: 256MB
```

### Production

```yaml
loki:
  log_level: info
  query_timeout: 5m
  max_look_back: 30d
  cache:
    enabled: true
    size: 1GB
  replication_factor: 2
```

## Maintenance Procedures

### Log Rotation

- Size-based rotation
- Time-based rotation
- Compression settings
- Retention enforcement

### Performance Monitoring

- Query performance
- Storage utilization
- Cache hit rates
- Ingestion rates

### Troubleshooting Guide

1. Check log ingestion status
2. Verify label configuration
3. Monitor query performance
4. Validate retention rules
5. Review error patterns
