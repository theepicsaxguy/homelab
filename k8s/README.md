# Kubernetes Configuration

This directory contains the GitOps configuration for the entire cluster, managed through ArgoCD.

## Directory Structure

```
.
├── apps/                  # Application workloads
│   ├── dev/              # Development tools
│   ├── external/         # External service integrations
│   └── media/           # Media stack
├── infra/                # Core infrastructure
│   ├── auth/            # Authentication (Authelia)
│   ├── controllers/     # Core controllers
│   ├── crossplane-crds/ # Crossplane resources
│   ├── monitoring/      # Prometheus stack
│   ├── network/         # Cilium, DNS, Gateway
│   └── storage/         # CSI drivers
└── sets/                # ApplicationSet configurations
```

## Application Structure

Each application follows the structure:

```yaml
app_directory:
  - application-set.yaml # ArgoCD ApplicationSet
  - kustomization.yaml # Resource composition
  - project.yaml # ArgoCD project definition
```

## Infrastructure Components

| Component  | Purpose        | Performance Impact     |
| ---------- | -------------- | ---------------------- |
| Cilium     | CNI & Security | Minimal (eBPF)         |
| Authelia   | Authentication | Low (caching)          |
| Prometheus | Monitoring     | Medium (storage heavy) |
| CSI        | Storage        | Varies by backend      |

## Performance Notes

- ApplicationSets use progressive syncs
- Resource requests/limits are mandatory
- HPA configured for scalable workloads
- Network policies enforce zero-trust

## Resource Requirements

| Component  | CPU  | Memory | Storage |
| ---------- | ---- | ------ | ------- |
| ArgoCD     | 1C   | 1Gi    | 10Gi    |
| Monitoring | 2C   | 4Gi    | 50Gi    |
| Auth       | 500m | 512Mi  | 1Gi     |

## Getting Started

1. Bootstrap ArgoCD:

   ```bash
   tofu init && tofu apply
   ```

2. Applications sync automatically via ApplicationSets

## Adding New Applications

1. Create directory under `/apps`
2. Define ApplicationSet
3. Create ArgoCD project
4. Add Kustomization

## Security Considerations

- All manifests must be signed
- Secrets handled via SealedSecrets
- RBAC strictly enforced
- Network policies required
