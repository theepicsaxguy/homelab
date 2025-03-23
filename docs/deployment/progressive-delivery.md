# Progressive Delivery

## Overview

Progressive delivery implementation using Argo Rollouts with environment-specific configurations and integrated
monitoring.

## Core Components

### Argo Rollouts Configuration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
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
                response_code!~"5.*"
              }[1m]
            )) /
            sum(rate(
              istio_requests_total{
                reporter="source"
              }[1m]
            ))
```

## Environment Configuration

### Development

```yaml
rollout_config:
  replicas: 1
  steps:
    - setWeight: 50
    - pause: { duration: 30s }
    - analysis:
        templates:
          - success-rate
    - setWeight: 100

  analysis:
    interval: 30s
    successCondition: '>= 0.95'
    failureLimit: 2
```

### Staging

```yaml
rollout_config:
  replicas: 2
  steps:
    - setWeight: 20
    - pause: { duration: 60s }
    - analysis:
        templates:
          - success-rate
    - setWeight: 50
    - pause: { duration: 60s }
    - analysis:
        templates:
          - resource-health
    - setWeight: 100

  analysis:
    interval: 60s
    successCondition: '>= 0.98'
    failureLimit: 1
```

### Production

```yaml
rollout_config:
  replicas: 3
  steps:
    - setWeight: 10
    - pause: { duration: 300s }
    - analysis:
        templates:
          - success-rate
          - resource-health
    - setWeight: 30
    - pause: { duration: 300s }
    - analysis:
        templates:
          - success-rate
          - resource-health
          - error-rate
    - setWeight: 100

  analysis:
    interval: 300s
    successCondition: '>= 0.999'
    failureLimit: 1
```

## Analysis Templates

### Resource Health

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: resource-health
spec:
  metrics:
    - name: cpu-usage
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

### Error Rate

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: error-rate
spec:
  metrics:
    - name: error-rate
      interval: 300s
      successCondition: result[0] <= 0.001
      provider:
        prometheus:
          query: |
            sum(rate(
              istio_requests_total{
                reporter="source",
                response_code=~"5.*"
              }[5m]
            ))
```

## Monitoring Integration

### Metrics Collection

```yaml
serviceMonitor:
  enabled: true
  selector:
    matchLabels:
      app.kubernetes.io/name: argo-rollouts
  endpoints:
    - port: metrics
      interval: 15s
```

### Dashboard Configuration

```yaml
grafana:
  dashboards:
    rollout_analysis:
      panels:
        - Success Rate
        - Error Rate
        - Resource Usage
        - Network Traffic
      variables:
        - namespace
        - rollout
        - revision
```

## Network Configuration

### Traffic Management

```yaml
trafficRouting:
  managedBy: cilium
  cilium:
    enabled: true
    routeTimeout: 30s
    retries:
      attempts: 3
      perTryTimeout: 2s
      retryOn: '5xx'
```

### Gateway Integration

```yaml
gateway:
  className: cilium
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  listeners:
    - protocol: HTTPS
      port: 443
      routes:
        kind: HTTPRoute
        labels:
          app.kubernetes.io/name: myapp
```

## Security Configuration

### RBAC

```yaml
rbac:
  create: true
  rules:
    - apiGroups: ['argoproj.io']
      resources: ['rollouts', 'analysisruns', 'experiments']
      verbs: ['*']
    - apiGroups: ['']
      resources: ['services']
      verbs: ['get', 'list', 'watch', 'patch']
```

### Network Policies

```yaml
networkPolicies:
  create: true
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              name: monitoring
```

## Rollback Strategy

### Automatic Rollback

- Triggered by failed analysis
- Resource threshold breaches
- Error rate spikes
- Health check failures

### Manual Rollback

```yaml
rollback:
  enabled: true
  strategy: linear
  steps:
    - setWeight: 0
    - pause: { duration: 30s }
    - promote:
        targetRevision: prev-stable
```

## Troubleshooting

### Common Issues

1. Failed Analysis

   - Check Prometheus queries
   - Verify metric collection
   - Review thresholds
   - Check service health

2. Stuck Rollouts
   - Verify analysis templates
   - Check pod status
   - Review network policies
   - Check resource constraints

### Debug Tools

```yaml
debugging:
  commands:
    - kubectl argo rollouts get rollout
    - kubectl argo rollouts status
    - kubectl argo rollouts promote
    - kubectl argo rollouts abort
```
