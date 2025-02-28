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
│       ├── dev/          # Development (Wave 3)
│       ├── staging/      # Staging (Wave 4)
│       └── prod/         # Production (Wave 5)
├── infrastructure/        # Core infrastructure
│   ├── base/             # Base infrastructure components
│   │   ├── network/      # Cilium, Gateway API, DNS
│   │   │   ├── cilium/   # CNI and Service Mesh
│   │   │   └── gateway/  # Gateway API configurations
│   │   ├── storage/      # CSI drivers, Longhorn
│   │   ├── auth/         # Authelia, LLDAP
│   │   ├── controllers/  # Core controllers
│   │   ├── monitoring/   # Prometheus, Grafana
│   │   └── vpn/          # VPN services
│   └── overlays/         # Environment configurations
│       ├── dev/          # Development (Wave 0)
│       ├── staging/      # Staging (Wave 1)
│       └── prod/
└── sets/                  # ApplicationSet configurations

```

## Environment Strategy

- **Development**: Fast iteration, relaxed limits
- **Staging**: Production-like with HA
- **Production**: Full HA, strict limits

## Network Architecture

Our networking stack is built on:

- **Cilium** (v1.17+) for CNI and service mesh capabilities
- **Gateway API** for modern ingress management
- Structured gateway classes:
  - External (Internet-facing services)
  - Internal (Cluster-local services)
  - TLS Passthrough (Direct TLS termination)

## Gateway Structure

```yaml
Gateways:
  - gw-external: # Internet-facing services
      - HTTP/HTTPS routes
      - Load balancing
  - gw-internal: # Cluster-local services
      - Internal DNS
      - Service mesh integration
  - gw-tls-passthrough: # Direct TLS termination
      - Secure services
      - Certificate management
```

## Infrastructure Components

| Component   | Purpose            | Configuration Path                  | Health Check    |
| ----------- | ------------------ | ----------------------------------- | --------------- |
| Cilium      | CNI & Service Mesh | infrastructure/base/network/cilium  | Pods & Services |
| Gateway API | Ingress Management | infrastructure/base/network/gateway | Routes & Certs  |
| Authelia    | Authentication     | infrastructure/base/auth/authelia   | Deployment & DB |
| Prometheus  | Monitoring         | infrastructure/base/monitoring      | StatefulSet     |
| CSI Drivers | Storage            | infrastructure/base/storage         | DaemonSet       |

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
