# Progressive Deployment with Argo Rollouts

Our infrastructure uses Argo Rollouts for advanced deployment strategies. The configuration follows our standard
environment pattern:

## Configuration Structure

```
infra/
├── base/
│   └── controllers/
│       └── argo-rollouts/
│           ├── kustomization.yaml    # Base configuration
│           └── patches/
│               └── resource-limits.yaml
└── overlays/
    ├── dev/
    │   └── patches/
    │       └── argo-rollouts.yaml    # Single replica, basic resources
    ├── staging/
    │   └── patches/
    │       └── argo-rollouts.yaml    # 2 replicas, increased resources
    └── prod/
        └── patches/
            └── argo-rollouts.yaml    # 3 replicas, HA with pod anti-affinity
```

## Environment-Specific Configurations

- **Development**: Single replica with basic resource allocation

  - CPU: 200m request, 1000m limit
  - Memory: 256Mi request, 512Mi limit

- **Staging**: Two replicas with increased resources

  - CPU: 500m request, 2 CPU limit
  - Memory: 512Mi request, 1Gi limit

- **Production**: Three replicas with HA configuration
  - CPU: 500m request, 2 CPU limit
  - Memory: 512Mi request, 1Gi limit
  - Pod anti-affinity for high availability

## Usage

The Rollouts controller is deployed automatically through our infrastructure ApplicationSet with appropriate sync waves.
For using Rollouts in your applications, refer to the [external documentation](../external-docs/getting-started.md).
