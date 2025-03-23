# Environment Configuration

## Overview

Multi-environment setup supporting development, staging, and production with progressive promotion and
environment-specific configurations.

## Environment Definitions

### Development

```yaml
environment:
  name: development
  namespace_prefix: dev
  sync_wave: 0

  configuration:
    logging:
      level: debug
      retention: 7d
    metrics:
      scrape_interval: 30s
      retention: 7d
    tracing:
      sampling: 100%

  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi

  rollout:
    replicas: 1
    analysis_duration: 30s
    success_rate: '0.95'
```

### Staging

```yaml
environment:
  name: staging
  namespace_prefix: staging
  sync_wave: 1

  configuration:
    logging:
      level: info
      retention: 14d
    metrics:
      scrape_interval: 15s
      retention: 14d
    tracing:
      sampling: 50%

  resources:
    requests:
      cpu: 500m
      memory: 256Mi
    limits:
      cpu: 1000m
      memory: 512Mi

  rollout:
    replicas: 2
    analysis_duration: 60s
    success_rate: '0.98'
```

### Production

```yaml
environment:
  name: production
  namespace_prefix: prod
  sync_wave: 2

  configuration:
    logging:
      level: info
      retention: 30d
    metrics:
      scrape_interval: 15s
      retention: 30d
    tracing:
      sampling: 10%

  resources:
    requests:
      cpu: 1000m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 2Gi

  rollout:
    replicas: 3
    analysis_duration: 300s
    success_rate: '0.999'
```

## Application Configuration

### Base Configuration

```yaml
app_config:
  common:
    service_mesh: true
    metrics_enabled: true
    health_check: true
    network_policy: true

  resources:
    ephemeral_storage: 1Gi
    tmp_memory: 64Mi

  security:
    read_only_root: true
    run_as_non_root: true
    privileged: false
```

### Environment Overrides

```yaml
config_overrides:
  development:
    debug_enabled: true
    trace_all: true
    mock_external_services: true

  staging:
    debug_enabled: false
    trace_all: false
    rate_limiting: true

  production:
    audit_logging: true
    rate_limiting: true
    backup_enabled: true
```

## Network Configuration

### Gateway Settings

```yaml
gateway_config:
  development:
    ingress_class: cilium
    tls: false
    rate_limit: disabled

  staging:
    ingress_class: cilium
    tls: true
    rate_limit: permissive

  production:
    ingress_class: cilium
    tls: true
    rate_limit: strict
```

### Network Policies

```yaml
network_policies:
  development:
    default: allow
    monitoring: required

  staging:
    default: deny
    monitoring: required
    internal: allow

  production:
    default: deny
    monitoring: required
    internal: restricted
```

## Monitoring Configuration

### Metrics Collection

```yaml
metrics_config:
  development:
    prometheus:
      scrape_interval: 30s
      evaluation_interval: 30s
    grafana:
      dashboard_refresh: 1m

  staging:
    prometheus:
      scrape_interval: 15s
      evaluation_interval: 15s
    grafana:
      dashboard_refresh: 30s

  production:
    prometheus:
      scrape_interval: 15s
      evaluation_interval: 15s
    grafana:
      dashboard_refresh: 30s
```

### Alert Configuration

```yaml
alert_config:
  development:
    routes:
      - receiver: slack-dev
        group_wait: 30s

  staging:
    routes:
      - receiver: slack-staging
        group_wait: 30s
        repeat_interval: 4h

  production:
    routes:
      - receiver: pagerduty
        group_wait: 30s
        repeat_interval: 1h
```

## Promotion Workflow

### Development to Staging

```yaml
promotion:
  source: development
  target: staging
  requirements:
    - all_tests_passed
    - security_scan_passed
    - resource_usage_within_limits
  analysis_duration: 60s
```

### Staging to Production

```yaml
promotion:
  source: staging
  target: production
  requirements:
    - all_tests_passed
    - security_scan_passed
    - performance_tests_passed
    - manual_approval
  analysis_duration: 300s
```

## Resource Scaling

### Horizontal Pod Autoscaling

```yaml
hpa_config:
  development:
    min_replicas: 1
    max_replicas: 3
    target_cpu: 80%

  staging:
    min_replicas: 2
    max_replicas: 5
    target_cpu: 70%

  production:
    min_replicas: 3
    max_replicas: 10
    target_cpu: 60%
```

## Security Configuration

### Authentication

```yaml
auth_config:
  development:
    mode: relaxed
    session_timeout: 24h

  staging:
    mode: strict
    session_timeout: 8h

  production:
    mode: strict
    session_timeout: 4h
    mfa_required: true
```

### Audit Logging

```yaml
audit_config:
  development:
    enabled: false

  staging:
    enabled: true
    level: Metadata
    retention: 14d

  production:
    enabled: true
    level: RequestResponse
    retention: 90d
```
