---
sidebar_position: 1
title: Infrastructure Overview
description: Overview of the cluster's infrastructure components and organization
---

# Infrastructure Overview

This document provides a comprehensive overview of my cluster's core infrastructure components, which are managed using GitOps principles through ArgoCD.

## Directory Structure

My infrastructure follows a structured organization:

```
infrastructure/
├── application-set.yaml        # ArgoCD ApplicationSet for automated deployment
├── project.yaml               # ArgoCD Project definition
├── kustomization.yaml        # Main kustomization file
├── auth/                     # Authentication (Authentik)
├── controllers/              # Core controllers
│   ├── argocd/              # GitOps controller
│   ├── cert-manager/        # Certificate management
│   ├── external-secrets/    # Secrets management
│   └── longhorn/           # Storage controller
├── crds/                    # Custom Resource Definitions
├── database/               # Database services
├── deployment/            # Deployment controllers
├── monitoring/           # Monitoring stack
└── network/              # Networking (Cilium, CoreDNS)
```

## Core Components

### Authentication (auth/)

- **Authentik**: Primary authentication provider
  - SSO for cluster services
  - OAuth 2.0 proxy integration
  - User management

### Controllers (controllers/)

1. **ArgoCD**
   - GitOps workflow management
   - Progressive delivery
   - Application synchronization

2. **cert-manager**
   - Certificate lifecycle management
   - Let's Encrypt integration
   - Internal PKI

3. **external-secrets**
   - Secrets management with Bitwarden
   - Secure key distribution
   - Secret rotation

4. **Longhorn**
   - Distributed storage
   - Volume replication
   - Backup management

### Networking (network/)

1. **Cilium**
   - CNI provider
   - Network policies
   - Load balancing
   - Gateway API implementation

2. **CoreDNS**
   - Cluster DNS
   - Service discovery
   - Custom DNS entries

## GitOps Workflow

### Application Deployment

```yaml
Deployment Flow:
1. CRDs (Wave -1)
2. Core Infrastructure (Wave 0)
3. Controllers (Wave 1)
4. Storage (Wave 2)
5. Networking (Wave 3)
6. Authentication (Wave 4)
7. Applications (Wave 5+)
```

### Version Control

- All changes through Git
- Pull request workflow
- Automated validation
- Deployment tracking

## Security Model

### RBAC Configuration

```yaml
Permissions:
  infrastructure:
    - cluster-admin scope
    - restricted to infrastructure namespace
  applications:
    - namespace-scoped
    - limited to specific resources
```

### Network Security

- Zero-trust network model
- Explicit network policies
- TLS everywhere
- Gateway API for ingress

## Maintenance Procedures

### Component Updates

1. Update in Git repository
2. ArgoCD auto sync
3. Progressive rollout
4. Validation checks

### Troubleshooting Guide

When issues arise:

1. Check ArgoCD sync status:
```shell
kubectl get applications -n argocd
```

2. Verify resources:
```shell
kubectl get events -n <namespace>
kubectl describe <resource> -n <namespace>
```

3. Review logs:
```shell
kubectl logs -n <namespace> <pod> -f
```

## Best Practices

1. **GitOps Principles**
   - Everything in Git
   - Declarative configurations
   - Automated reconciliation

2. **Security**
   - Least privilege access
   - Regular certificate rotation
   - Secure secret management

3. **High Availability**
   - Component redundancy
   - Data replication
   - Failure domain isolation

## Monitoring & Alerting

### Key Metrics

- Controller health
- Resource utilization
- Certificate expiration
- Storage capacity

### Alert Rules

```yaml
Priorities:
  critical:
    - Controller failures
    - Certificate expiration < 7 days
    - Storage capacity > 85%
  warning:
    - High resource usage
    - Sync delays
    - Storage capacity > 75%
```

## Future Enhancements

- [ ] Enhanced metric collection
- [ ] Automated disaster recovery
- [ ] cross cluster failover
- [ ] Advanced policy enforcement
