# Alert Management

## Overview

Alert configuration using Prometheus AlertManager with standardized severity levels and routing.

## Alert Rules

### Infrastructure Alerts

```yaml
groups:
  - name: infrastructure
    rules:
      - alert: NodeHighCPU
        expr: node_cpu_usage > 80
        for: 5m
        labels:
          severity: warning
      - alert: NodeHighMemory
        expr: node_memory_usage > 85
        for: 5m
        labels:
          severity: warning
```

### Application Alerts

```yaml
groups:
  - name: applications
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
        for: 2m
        labels:
          severity: critical
      - alert: SlowResponses
        expr: http_request_duration_seconds > 2
        for: 5m
        labels:
          severity: warning
```

## Routing Configuration

### Severity Levels

- critical: Immediate action required
- warning: Investigation needed
- info: Awareness only

### Time Windows

```yaml
routes:
  critical:
    group_wait: 30s
    group_interval: 2m
    repeat_interval: 1h
  warning:
    group_wait: 1m
    group_interval: 5m
    repeat_interval: 4h
```

## Notification Channels

### Channel Configuration

```yaml
receivers:
  - name: slack-critical
    slack_configs:
      - channel: '#alerts-critical'
        title: '{{ .GroupLabels.alertname }}'
  - name: slack-general
    slack_configs:
      - channel: '#alerts-general'
        title: '{{ .GroupLabels.alertname }}'
```

## Silencing and Inhibition

### Silencing Rules

- Maintenance windows
- Known issues
- Test environments
- Duplicate alerts

### Inhibition Rules

- Parent/child relationships
- Dependent services
- Cascading failures
- Environmental factors
