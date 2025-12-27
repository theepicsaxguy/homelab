---
title: 'Deploy and Manage Infrastructure Services'
---

This guide explains how I deploy and manage core Kubernetes infrastructure using GitOps with ArgoCD.

## Quick Start

Infrastructure components live in `/k8s/infrastructure/` organized by function:

- `auth/` - Identity management (Authentik)
- `controllers/` - Core controllers (ArgoCD, Cert-Manager)
- `crds/` - Custom Resource Definitions
- `database/` - Database operators
- `monitoring/` - Observability stack
- `network/` - CNI and DNS configuration
- `storage/` - Storage providers

## Deployment Process

I use ArgoCD ApplicationSet to manage infrastructure:

1. Components are defined in category folders
2. ApplicationSet watches these folders
3. ArgoCD automatically deploys changes

### Key Files

```yaml
# /k8s/infrastructure/application-set.yaml
metadata:
  name: 'infra-{{ path.basename }}'
spec:
  project: infrastructure
  destination:
    namespace: infrastructure-system
```

## Core Components

### 1. Networking (Cilium)

- **Purpose:** CNI, network security, load balancing
- **Features:**
  - eBPF-based networking
  <!-- vale off -->
  - LoadBalancer IP pool: 10.25.150.220-255
  <!-- vale on -->
  - L2 announcements for LAN services
  - Kubernetes Gateway API support

### 2. DNS (CoreDNS)

- Internal domain: `cluster.local` (set in `tofu/locals.tf`)
- External forwarding to 10.25.150.1, 1.1.1.1, 8.8.8.8
- Caching enabled
- Runs as a non-root user (UID/GID 1000) with NET_BIND_SERVICE capability

### 3. Gateway API

Three gateway types:

- External (10.25.150.222) - Internet-facing
- Internal (10.25.150.220) - LAN only
- TLS Passthrough (10.25.150.221) - Direct TLS

### 4. Security

- **Cert-Manager:**

  - Cloudflare DNS validation
  - Internal CA for cluster services
  - Automatic certificate renewal
  - Separate certificates for peekoff.com and goingdark.social

- **External Secrets:**
  - Bitwarden integration
  - Secure secret management
  - Certificate-based auth

### 5. Storage (Longhorn)

- Distributed block storage
- Default storage class
- Path: /var/lib/longhorn/
- Web UI available

### 6. Monitoring

Kube Prometheus Stack provides:

- Metrics collection
- Alerting
- Grafana dashboards

### 7. Authentication (Authentik)

- Single Sign-On
<!-- vale off -->
- PostgreSQL backend
<!-- vale on -->
- Proxy outpost for app protection
- Configuration via Git
- Worker liveness probe timeout set to 5 seconds to avoid restarts

## Best Practices

1. Use GitOps for all changes
2. Keep secrets in Bitwarden
3. Use internal CA for service mesh
4. Monitor with Prometheus
5. Implement proper backup strategies
6. Run databases with at least two instances to avoid single points of failure

Need help? Check component examples in `/k8s/infrastructure/` for reference implementations.
