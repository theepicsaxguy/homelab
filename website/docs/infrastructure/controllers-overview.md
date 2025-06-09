---
sidebar_position: 2
title: Controllers Overview
description: Core infrastructure controllers and their configuration
---

# Infrastructure Controllers

This document outlines the core infrastructure controllers deployed in our Kubernetes cluster.

## Core Controllers

### ArgoCD

- **Purpose**: GitOps deployment controller
- **Version**: Latest stable (automated by Renovate)
- **Features**:
  - Application state synchronization
  - Progressive delivery
  - Resource health monitoring
  - Multi-cluster management

### cert-manager

- **Purpose**: Certificate management
- **Version**: Latest v1.x (automated by Renovate)
- **Features**:
  - Let's Encrypt integration
  - Internal PKI support
  - Automated renewal
  - CSI driver integration

### External Secrets

- **Purpose**: Secrets management
- **Version**: Latest stable (automated by Renovate)
- **Features**:
  - Bitwarden integration
  - Secrets rotation
  - Secure key distribution
  - Cross-namespace secrets

### Longhorn

**Features**:

- Distributed block storage
- Volume replication
- Backup capabilities
- Storage overprovisioning

### Kubechecks

- **Purpose**: Validate ArgoCD applications via policy checks
- **Version**: Latest stable (automated by Renovate)
- **Features**:
  - Schema validation
  - GitHub integration
  - Custom webhook support

## Resource Management

### Base Resource Configuration

```yaml
Standard Resource Profile:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 512Mi

High-Availability Profile:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 1Gi
```

### Controller-Specific Resources

| Controller       | CPU Request | Memory Request | CPU Limit | Memory Limit |
| ---------------- | ----------- | -------------- | --------- | ------------ |
| ArgoCD Server    | 500m        | 512Mi          | 2000m     | 1Gi          |
| cert-manager     | 75m         | 96Mi           | 75m       | 96Mi         |
| External Secrets | 80m         | 100Mi          | 80m       | 100Mi        |
| Longhorn Manager | 250m        | 256Mi          | 250m      | 256Mi        |
| Kubechecks       | 200m        | 256Mi          | 500m      | 512Mi        |

## High Availability

### Deployment Strategy

```yaml
Replication:
  argocd-server: 2
  argocd-repo-server: 2
  argocd-applicationset: 2
  cert-manager-controller: 2
  cert-manager-webhook: 2
  cert-manager-cainjector: 2
  external-secrets-operator: 2
  external-secrets-webhook: 2
  longhorn-manager: 3 # One per node

Pod Disruption Budget:
  minAvailable: 1
```

### Node Placement

```yaml
Topology Spread:
  maxSkew: 1
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: DoNotSchedule
```

## Monitoring Integration

### Metrics Collection

All controllers expose Prometheus metrics:

- ArgoCD: Application sync status, performance metrics
- cert-manager: Certificate status, renewal metrics
- External Secrets: Sync status, error rates
- Longhorn: Volume health, performance metrics

### Alert Rules

```yaml
Critical Alerts:
  - ArgoCD application out of sync > 1h
  - Certificate renewal failure
  - Secrets sync failure
  - Volume degradation

Warning Alerts:
  - High resource usage
  - Slow sync operations
  - Certificate expiring soon
```

## Version Management

### Update Strategy

- Automated updates via Renovate
- Version constraints in Helm values
- Progressive rollout through environments
- Regular review of change logs

### Current Versions

```yaml
Controllers:
  argocd: <see https://github.com/argoproj/argo-cd/releases>
  cert-manager: <see https://github.com/cert-manager/cert-manager/releases>
  external-secrets: <see https://github.com/external-secrets/external-secrets/releases>
  longhorn: <see https://github.com/longhorn/longhorn/releases>
```

## Security Configuration

### RBAC Settings

- Minimal permissions model
- Namespace isolation
- Service account restrictions
- Security context constraints

### Network Policies

```yaml
Ingress Rules:
  - Allow metrics collection
  - Allow API access from authorized sources
  - Allow cross-controller communication
  - Deny all other traffic
```

## Troubleshooting Guide

### Common Issues

1. **Controller Pod Crashes**

   - Check resource limits
   - Review recent changes
   - Monitor system resources

2. **Sync Failures**

   - Verify Git repository access
   - Check network connectivity
   - Review controller logs

3. **Performance Issues**
   - Monitor resource usage
   - Check node capacity
   - Review scaling configuration

### Debug Commands

```bash
# Check controller status
kubectl -n argocd get pods
kubectl -n cert-manager get pods
kubectl -n external-secrets get pods

# View controller logs
kubectl -n <namespace> logs -l app=<controller-name>

# Verify RBAC
kubectl auth can-i --as system:serviceaccount:<ns>:<sa> <verb> <resource>
```
