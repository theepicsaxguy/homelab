# Metrics Configuration

## Core Infrastructure Metrics

### Node Metrics

```yaml
node_metrics:
  collection:
    interval: 15s
    targets:
      - node-exporter
      - kube-state-metrics
  metrics:
    - node_cpu_usage_seconds_total
    - node_memory_MemTotal_bytes
    - node_filesystem_avail_bytes
    - node_network_transmit_bytes_total
    - node_network_receive_bytes_total
```

### Kubernetes Core Metrics

```yaml
kubernetes_metrics:
  collection:
    interval: 30s
    targets:
      - kubelet
      - apiserver
      - controller-manager
      - scheduler
  metrics:
    - container_cpu_usage_seconds_total
    - container_memory_working_set_bytes
    - apiserver_request_duration_seconds
    - workqueue_adds_total
```

### Gateway API Metrics

```yaml
gateway_metrics:
  collection:
    interval: 15s
    targets:
      - cilium-operator
      - gateway-api
  metrics:
    - gateway_tcp_connections
    - gateway_http_requests_total
    - gateway_request_duration_seconds
```

## Application Metrics

### Standard Service Monitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: app-metrics
spec:
  selector:
    matchLabels:
      monitoring: prometheus
  endpoints:
    - port: metrics
      interval: 15s
      path: /metrics
  namespaceSelector:
    matchNames:
      - prod-apps
      - staging-apps
      - dev-apps
```

### Analysis Templates

#### Success Rate Analysis

```yaml
metrics:
  - name: success-rate
    interval: 30s
    successCondition: result[0] >= 0.95
    failureLimit: 2
    provider:
      prometheus:
        query: |
          sum(rate(
            istio_requests_total{
              reporter="source",
              destination_service=~"${service_name}",
              response_code!~"5.*"
            }[1m]
          )) /
          sum(rate(
            istio_requests_total{
              reporter="source",
              destination_service=~"${service_name}"
            }[1m]
          ))
```

#### Resource Usage Analysis

```yaml
metrics:
  - name: resource-health
    interval: 300s
    successCondition: result[0] >= 0.999
    provider:
      prometheus:
        query: |
          min(
            avg_over_time(
              rate(container_cpu_usage_seconds_total{namespace="{{args.namespace}}"}[15m])[30m:]
              /
              on(pod) kube_pod_container_resource_requests{resource="cpu",namespace="{{args.namespace}}"}[30m:]
            )
          )
```

## Environment-Specific Configuration

### Development

```yaml
scrape_configs:
  interval: 30s
  evaluation_interval: 30s
retention:
  time: 7d
```

### Staging

```yaml
scrape_configs:
  interval: 15s
  evaluation_interval: 15s
retention:
  time: 14d
```

### Production

```yaml
scrape_configs:
  interval: 15s
  evaluation_interval: 15s
retention:
  time: 30d
```

## Recording Rules

### Resource Usage Rules

```yaml
groups:
  - name: resource-usage
    rules:
      - record: instance:container_cpu_usage:rate5m
        expr: |
          rate(container_cpu_usage_seconds_total[5m])
      - record: instance:container_memory_usage:avg
        expr: |
          avg_over_time(container_memory_working_set_bytes[5m])
```

### Error Rate Rules

```yaml
groups:
  - name: errors
    rules:
      - record: instance:request_errors:rate5m
        expr: |
          rate(http_requests_total{status=~"5.*"}[5m])
```

## Storage Configuration

### Retention Settings

- Time-based retention: 15 days default
- Size-based retention: 100GB per instance
- Block duration: 2 hours
- Compaction policy: 2h blocks for 48h

### High Availability

- Replica factor: 2
- Consistency level: quorum
- Deduplication enabled
- Cross-zone distribution

## Integration Points

### Grafana

- Default data source
- Dashboard provisioning
- Alert rule integration
- Variable templates

### AlertManager

- Alert routing rules
- Notification templates
- Silencing configuration
- Maintenance windows

### ArgoCD Rollouts

- Analysis templates
- Success metrics
- Resource validation
- Error thresholds
