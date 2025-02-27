# Application Architecture

## Overview

This document describes the application deployment architecture in our homelab infrastructure, following GitOps
principles and using ArgoCD as the deployment mechanism.

## Structure

```
k8s/applications/
├── base/                 # Base configurations
│   ├── external/        # External service integrations
│   ├── media/          # Media applications
│   └── tools/          # Development tools
└── overlays/            # Environment-specific configurations
    ├── dev/            # Development environment
    ├── staging/        # Staging environment
    └── prod/           # Production environment
```

## Deployment Strategy

### Environment Progression

1. **Development (Wave 3)**

   - Allows empty applications
   - Single replica deployments
   - Minimal resource requests

2. **Staging (Wave 4)**

   - No empty applications
   - 3 replicas with pod anti-affinity
   - Production-like resource limits

3. **Production (Wave 5)**
   - Strict validation
   - 3 replicas with pod anti-affinity
   - Full production resource limits

### High Availability Requirements

- Staging and Production environments require:
  - 3 replicas minimum
  - Pod anti-affinity rules
  - Proper resource limits
  - Zero-downtime deployments

### Resource Management

Resource limits are defined per environment:

| Environment | CPU Request | CPU Limit | Memory Request | Memory Limit |
| ----------- | ----------- | --------- | -------------- | ------------ |
| Dev         | 100m        | 500m      | 256Mi          | 512Mi        |
| Staging     | 500m        | 2         | 1Gi            | 2Gi          |
| Prod        | 1           | 4         | 2Gi            | 4Gi          |

## Application Categories

### External Services

- Proxmox integration
- TrueNAS integration
- Home Assistant integration

### Media Applications

- \*arr stack (Sonarr, Radarr, etc.)
- Media server (Jellyfin)

### Development Tools

- Debug tools
- Utility containers

## Security Considerations

- All applications must use Bitwarden Secrets Manager
- No direct volume mounting of secrets
- Environment-specific security policies
- Regular security scanning with Trivy

## Validation Requirements

- Must pass kustomize build tests
- Must validate against Kubernetes 1.32.0
- Must pass security scanning
- Must conform to resource limit requirements

## Resource Management

### Media Applications

- CPU: 1-4 cores
- Memory: 4-8 GiB
- Storage: 10-20 GiB ephemeral
- Suitable for: Jellyfin, \*arr stack

### External Integrations

- CPU: 250m-1 core
- Memory: 512Mi-2GiB
- Storage: 1-5 GiB ephemeral
- Suitable for: Proxmox, TrueNAS, HAOS integrations

### Development Tools

- CPU: 500m-2 cores
- Memory: 1-4 GiB
- Storage: 5-10 GiB ephemeral
- Suitable for: Debug tools, utility containers

## Security Policies

### Network Security

- Default deny-all with explicit allows
- Namespace isolation
- Monitoring access (port 9090)
- DNS resolution for external access
- ArgoCD connectivity for GitOps

### Pod Security

- Non-root execution
- Read-only root filesystem
- Drop all capabilities
- Resource quotas enforcement
- Proper security contexts

### High Availability

- Production/Staging: 3 replicas minimum
- Pod anti-affinity rules
- Topology spread constraints
- Pod disruption budgets
- Zero-downtime deployments
