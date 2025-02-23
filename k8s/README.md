# Kubernetes Configuration

This directory contains the GitOps configuration for our entire cluster, managed through ArgoCD.

## Architecture Overview

Our infrastructure follows a strict GitOps approach with:

- Base configurations with common settings
- Environment-specific overlays with customizations
- Progressive deployment through sync waves
- Resource graduation across environments

## Directory Structure

```
.
├── apps/                   # Application workloads
│   ├── base/              # Base application configurations
│   │   ├── external/      # External service integrations
│   │   ├── media/        # Media applications
│   │   └── tools/        # Development tools
│   └── overlays/         # Environment-specific configs
│       ├── dev/
│       ├── staging/
│       └── prod/
├── infra/                 # Core infrastructure
│   ├── base/             # Base infrastructure components
│   │   ├── network/      # Cilium, DNS, Gateway
│   │   ├── storage/      # CSI drivers
│   │   ├── auth/         # Authentication
│   │   ├── controllers/  # Core controllers
│   │   ├── monitoring/   # Observability stack
│   │   └── vpn/         # VPN services
│   └── overlays/         # Environment configurations
│       ├── dev/
│       ├── staging/
│       └── prod/
└── sets/                  # ApplicationSet configurations

```

## Environment Strategy

- **Development**: Fast iteration, relaxed limits
- **Staging**: Production-like with HA
- **Production**: Full HA, strict limits

## Infrastructure Components

| Component   | Purpose        | Configuration Path        | Health Check    |
| ----------- | -------------- | ------------------------- | --------------- |
| Cilium      | CNI & Security | infra/base/network/cilium | Pods & Services |
| Authelia    | Authentication | infra/base/auth/authelia  | Deployment & DB |
| Prometheus  | Monitoring     | infra/base/monitoring     | StatefulSet     |
| CSI Drivers | Storage        | infra/base/storage        | DaemonSet       |

## Getting Started

1. **Initial Setup**:

   - Follow manual-bootstrap.md for first-time setup
   - Ensure ArgoCD is configured

2. **Making Changes**:

   - Modify base configurations or overlays
   - Validate using provided scripts
   - Let ArgoCD handle deployment

3. **Validation**:
   ```bash
   # From repository root
   ./scripts/validate_manifests.sh -d k8s/infra
   ```

## Best Practices

1. **GitOps Workflow**

   - All changes through Git
   - ArgoCD as deployment mechanism
   - No manual kubectl applies

2. **Resource Management**

   - Use appropriate limits per environment
   - Enable HPA for scalable workloads
   - Follow pod anti-affinity in prod/staging

3. **Security**

   - Network policies required
   - Secrets via Bitwarden SM Operator
   - RBAC with least privilege

4. **Monitoring**
   - Health checks configured
   - Resource metrics enabled
   - Proper logging setup

## Troubleshooting

1. Check ArgoCD UI for sync status
2. Verify kustomize builds locally
3. Review resource limits
4. Check application logs
5. Validate network policies
