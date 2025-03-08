# Infrastructure Common Components

This directory contains reusable components and configurations that are shared across all infrastructure deployments.

## 📦 Component Structure

```
components/
├── env-vars/           # Environment-specific configurations
│   ├── base-config.yaml         # Base environment settings
│   ├── resource-patch.yaml      # Resource configuration patches
│   ├── kustomization.yaml       # Component configuration
│   └── varreference.yaml        # Variable substitution rules
├── rollouts/          # Standardized rollout configurations
│   ├── analysis-template.yaml   # Standard metrics analysis
│   ├── rollout-pattern.yaml     # Base rollout pattern
│   └── kustomization.yaml       # Rollout component config
```

## 🔧 Usage

### Environment Variables

The `env-vars` component provides a standardized way to manage environment-specific configurations:

1. Base configuration is defined in `env-vars/base-config.yaml`
2. Environment-specific overrides are in `overlays/<env>/env-overrides.yaml`
3. Resource patches automatically apply the configuration

### Available Variables

Core infrastructure variables available across all environments:

| Variable | Description | Default |
|----------|-------------|---------|
| DEFAULT_REPLICA_COUNT | Pod replica count | Varies by env |
| DEFAULT_MEMORY_REQUEST | Memory request | Varies by env |
| DEFAULT_CPU_REQUEST | CPU request | Varies by env |
| DEFAULT_MEMORY_LIMIT | Memory limit | Varies by env |
| DEFAULT_CPU_LIMIT | CPU limit | Varies by env |
| ENVIRONMENT_TYPE | Environment name | base/dev/staging/prod |
| LOG_LEVEL | Logging verbosity | Varies by env |
| DEBUG_ENABLED | Enable debug mode | Varies by env |
| METRICS_PORT | Metrics endpoint port | 9090 |

### Rollout Patterns

The `rollouts` component provides standardized deployment patterns:

1. Progressive canary deployments
2. Automated metric analysis
3. Traffic management via Istio

## 🔄 Implementation

To use these components in your overlay:

```yaml
# In your overlay's kustomization.yaml
components:
- ../../common/components/env-vars
- ../../common/components/rollouts

patchesStrategicMerge:
- env-overrides.yaml  # Your environment-specific overrides
```

## 🚨 Important Notes

1. Always use these components to ensure consistency across environments
2. Environment-specific overrides should only modify approved variables
3. Follow GitOps principles - all changes must be committed to Git
4. Use the standard rollout patterns for predictable deployments
5. Metric analysis templates are pre-configured for Prometheus