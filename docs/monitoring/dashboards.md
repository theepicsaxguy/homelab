# Dashboard Configuration

## Overview

Grafana dashboards provide unified visualization for metrics, logs, and alerts across the infrastructure.

## Standard Dashboards

### Infrastructure Overview

```yaml
dashboard:
  name: Infrastructure Overview
  uid: infrastructure-overview
  panels:
    - name: Cluster Health
      type: stat
      targets:
        - expr: sum(up{job="kubernetes-nodes"})
      fieldConfig:
        thresholds:
          steps:
            - value: 3
              color: red
            - value: 4
              color: yellow
            - value: 5
              color: green

    - name: Resource Usage
      type: timeseries
      targets:
        - expr: sum(container_cpu_usage_seconds_total) by (namespace)
        - expr: sum(container_memory_working_set_bytes) by (namespace)

    - name: Network Traffic
      type: graph
      targets:
        - expr: sum(rate(container_network_receive_bytes_total[5m])) by (namespace)
        - expr: sum(rate(container_network_transmit_bytes_total[5m])) by (namespace)
```

### Progressive Delivery

```yaml
dashboard:
  name: Rollout Analysis
  uid: rollout-analysis
  panels:
    - name: Success Rate
      type: gauge
      targets:
        - expr: |
            sum(rate(
              istio_requests_total{
                reporter="source",
                response_code!~"5.*"
              }[1m]
            )) /
            sum(rate(
              istio_requests_total{
                reporter="source"
              }[1m]
            ))

    - name: Error Rate
      type: timeseries
      targets:
        - expr: |
            sum(rate(
              istio_requests_total{
                reporter="source",
                response_code=~"5.*"
              }[1m]
            ))

    - name: Resource Usage
      type: timeseries
      targets:
        - expr: |
            rate(container_cpu_usage_seconds_total{namespace="$namespace"}[5m])
```

### Application Performance

```yaml
dashboard:
  name: Application Performance
  uid: app-performance
  panels:
    - name: Request Rate
      type: timeseries
      targets:
        - expr: sum(rate(http_requests_total[5m])) by (service)

    - name: Response Time
      type: heatmap
      targets:
        - expr: rate(http_request_duration_seconds_bucket[5m])

    - name: Error Log Rate
      type: timeseries
      datasource: Loki
      targets:
        - expr: |
            sum(rate({namespace="$namespace"} |= "error"[5m])) by (app)
```

## Template Variables

### Common Variables

```yaml
variables:
  - name: namespace
    type: query
    query: label_values(kube_namespace_labels, namespace)

  - name: application
    type: query
    query: label_values(kube_pod_labels{namespace="$namespace"}, app)

  - name: time_range
    type: interval
    values: ['1h', '6h', '12h', '24h', '7d']
```

### Environment Variables

```yaml
variables:
  - name: environment
    type: custom
    values: ['dev', 'staging', 'prod']

  - name: cluster
    type: custom
    query: label_values(kube_cluster_labels, cluster)
```

## Dashboard Organization

### Folder Structure

```yaml
folders:
  infrastructure:
    - Cluster Overview
    - Node Status
    - Network Traffic
    - Storage Usage

  applications:
    - Service Overview
    - API Performance
    - Database Metrics
    - Cache Performance

  security:
    - Auth Metrics
    - Network Policies
    - Audit Logs
    - Compliance
```

### Access Control

```yaml
permissions:
  admin:
    - infrastructure/*
    - applications/*
    - security/*

  operator:
    - infrastructure/Cluster Overview
    - infrastructure/Node Status
    - applications/*

  developer:
    - applications/Service Overview
    - applications/API Performance
```

## Annotation Configuration

### Deployment Markers

```yaml
annotations:
  - name: Deployments
    datasource: Prometheus
    expr: changes(kube_deployment_status_observed_generation{namespace="$namespace"}[5m])

  - name: Config Changes
    datasource: Loki
    expr: {namespace="$namespace"} |= "ConfigMap updated"
```

### Alert Markers

```yaml
annotations:
  - name: Alerts
    datasource: Alertmanager
    expr: ALERTS{severity="critical"}
```

## Performance Optimization

### Query Optimization

- Use appropriate time ranges
- Apply necessary data transformations
- Implement caching where possible
- Optimize template variables

### Dashboard Efficiency

- Limit number of panels
- Use appropriate refresh rates
- Implement data decimation
- Configure alerting thresholds

## Integration Points

### Metrics Integration

- Prometheus data source
- PromQL queries
- Recording rules
- Alert conditions

### Logs Integration

- Loki data source
- LogQL queries
- Log volume metrics
- Error tracking

### Alert Integration

- AlertManager data source
- Alert status panels
- Notification history
- Silence management
