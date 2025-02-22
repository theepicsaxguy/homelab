# Logging Configuration

## Overview

The logging infrastructure uses Loki for log aggregation with standardized labels and retention policies.

## Log Collection

### Sources

```yaml
log_sources:
  kubernetes:
    - Container logs
    - System logs
    - Control plane logs
    - Audit logs
  applications:
    - Application logs
    - Access logs
    - Error logs
    - Debug logs
```

### Label Strategy

```yaml
log_labels:
  common:
    - namespace
    - app
    - component
    - instance
  custom:
    - severity
    - environment
    - team
    - service
```

## Retention and Storage

### Retention Rules

- High-value logs: 30 days
- System logs: 14 days
- Debug logs: 7 days
- Audit logs: 90 days

### Storage Configuration

```yaml
storage:
  chunks:
    retention: 30d
    storage_type: filesystem
  index:
    prefix: loki_index
    retention: 90d
```

## Query Best Practices

### Label Queries

- Use label selectors
- Avoid full text search
- Optimize time ranges
- Limit result sets

### Common Patterns

```logql
{namespace="app"} |= "error"
{app="service"} | json | status >= 500
{component="ingress"} | logfmt
```

## Integration

### Grafana Integration

- Log exploration
- Dashboard panels
- Alert rules
- Annotations

### Alert Configuration

- Error patterns
- Rate thresholds
- Missing logs
- Pattern matching
