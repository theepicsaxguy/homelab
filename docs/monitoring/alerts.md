# Alert Management

## Overview

Alert configuration using Prometheus AlertManager with standardized severity levels and routing.

## Alert Configuration

### Severity Levels

```yaml
severity_levels:
  critical:
    response_time: immediate
    notification:
      - pagerduty
      - slack_critical
    repeat_interval: 1h
    resolve_timeout: 5m

  warning:
    response_time: <4h
    notification:
      - slack_alerts
    repeat_interval: 4h
    resolve_timeout: 15m

  info:
    response_time: next_business_day
    notification:
      - slack_info
    repeat_interval: 24h
    resolve_timeout: 30m
```

### Progressive Delivery Alerts

#### Resource Analysis

```yaml
groups:
  - name: rollout-analysis
    rules:
      - alert: RolloutResourceUtilization
        expr: |
          min(
            avg_over_time(
              rate(container_cpu_usage_seconds_total{namespace="{{args.namespace}}"}[5m])[10m:]
              /
              on(pod) kube_pod_container_resource_requests{resource="cpu",namespace="{{args.namespace}}"}[10m:]
            )
          ) > 0.95
        for: 5m
        labels:
          severity: warning
          type: rollout
        annotations:
          summary: High resource utilization during rollout

      - alert: RolloutErrorSpike
        expr: |
          sum(rate(
            istio_requests_total{
              reporter="source",
              response_code=~"5.*"
            }[1m]
          )) > 0.05
        for: 2m
        labels:
          severity: critical
          type: rollout
```

### Infrastructure Alerts

#### Node Health

```yaml
groups:
  - name: node-health
    rules:
      - alert: NodeHighCPU
        expr: instance:node_cpu_utilisation:rate5m > 0.8
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: High CPU usage on {{ $labels.instance }}

      - alert: NodeHighMemory
        expr: instance:node_memory_utilisation:rate5m > 0.85
        for: 10m
        labels:
          severity: warning
```

#### Storage Alerts

```yaml
groups:
  - name: storage
    rules:
      - alert: VolumeFilling
        expr: kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes < 0.15
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: Storage volume {{ $labels.persistentvolumeclaim }} is filling up

      - alert: VolumeFullCritical
        expr: kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes < 0.05
        for: 10m
        labels:
          severity: critical
```

## Notification Configuration

### Slack Integration

```yaml
receivers:
  - name: slack_critical
    slack_configs:
      - channel: '#alerts-critical'
        title: '{{ template "slack.title" . }}'
        text: '{{ template "slack.text" . }}'
        send_resolved: true

  - name: slack_alerts
    slack_configs:
      - channel: '#alerts-general'
        title: '{{ template "slack.title" . }}'
        text: '{{ template "slack.text" . }}'
        send_resolved: true
```

### PagerDuty Integration

```yaml
receivers:
  - name: pagerduty
    pagerduty_configs:
      - routing_key: <secret>
        description: '{{ template "pagerduty.description" . }}'
        severity: '{{ if eq .GroupLabels.severity "critical" }}critical{{ else }}warning{{ end }}'
        class: '{{ .GroupLabels.type }}'
        group: '{{ .GroupLabels.namespace }}'
        send_resolved: true
```

## Routing Configuration

### Route Tree

```yaml
route:
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: slack_alerts
  routes:
    - match:
        severity: critical
      receiver: pagerduty
      group_wait: 30s
      repeat_interval: 1h
      continue: true

    - match:
        type: rollout
      receiver: slack_critical
      group_wait: 0s
      repeat_interval: 5m

    - match_re:
        namespace: .*-prod
      receiver: slack_critical
      continue: true
```

## Maintenance and Silencing

### Maintenance Windows

```yaml
time_intervals:
  - name: maintenance-window
    time_intervals:
      - weekdays: ['saturday']
        times:
          - start_time: 22:00
            end_time: 06:00
    routes:
      - receiver: slack_info
        group_wait: 5m
        repeat_interval: 1h
```

### Inhibition Rules

```yaml
inhibit_rules:
  - source_match:
      severity: critical
    target_match:
      severity: warning
    equal:
      - namespace
      - instance

  - source_match:
      alertname: NodeUnreachable
    target_match_re:
      alertname: .*
    equal:
      - instance
```

## Alert Templates

### Slack Templates

```yaml
templates:
  - name: slack.title
    template: |
      [{{ .Status | toUpper }}] {{ .GroupLabels.alertname }}

  - name: slack.text
    template: |
      *Alert:* {{ .GroupLabels.alertname }}
      *Severity:* {{ .GroupLabels.severity }}
      *Status:* {{ .Status }}
      {{ if ne .Status "resolved" }}
      *Summary:* {{ .CommonAnnotations.summary }}
      {{ end }}
```

### PagerDuty Templates

```yaml
templates:
  - name: pagerduty.description
    template: |
      {{ .GroupLabels.alertname }} - {{ .CommonAnnotations.summary }}
      Severity: {{ .GroupLabels.severity }}
      Environment: {{ .GroupLabels.namespace }}
```
