---
sidebar_position: 1
title: ArgoCD GitOps
description: ArgoCD configuration and GitOps workflow management
---

# ArgoCD Configuration Guide

This guide explains my GitOps deployment strategy using ArgoCD ApplicationSets for managing the complete cluster lifecycle.

## Deployment Structure

### ApplicationSet Organization

```yaml
ApplicationSets:
  infrastructure:
    wave: 1  # Bootstrap components
    components:
      - crds/               # Custom Resource Definitions
      - network/            # Cilium, CoreDNS
      - storage/           # Longhorn
      - auth/              # Authentik
      - monitoring/        # Prometheus Stack

  applications:
    wave: 2  # Application deployments
    components:
      - media/            # Media services
      - automation/       # Home automation
      - tools/            # Utility applications
      - external/         # External services
```

## Deployment Waves

### Sync Wave Ordering

| Wave | Component Type  | Description                        | Timeout |
|------|----------------|-----------------------------------|---------|
| -1   | CRDs          | Custom Resource Definitions        | 5m      |
| 0    | Core          | Cilium, CoreDNS, cert-manager     | 10m     |
| 1    | Storage       | Longhorn                          | 10m     |
| 2    | Auth          | Authentik                         | 10m     |
| 3    | Monitoring    | Prometheus Stack                   | 10m     |
| 4    | Applications  | Media, Tools, External Services    | 15m     |

### Wave Configuration

```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true
    - PruneLast=true
    - RespectIgnoreDifferences=true
  retry:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

## Application Management

### Infrastructure Set

Example application definition:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cilium
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  project: infrastructure
  source:
    path: k8s/infrastructure/network/cilium
    repoURL: https://github.com/pc-cdn/homelab.git
    targetRevision: main
  destination:
    namespace: network
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Application Set

Example for media services:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: media-apps
  namespace: argocd
spec:
  generators:
    - git:
        repoURL: https://github.com/pc-cdn/homelab.git
        revision: HEAD
        directories:
          - path: k8s/applications/media/*
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      project: applications
      source:
        path: '{{path}}'
        repoURL: https://github.com/pc-cdn/homelab.git
      destination:
        namespace: media
        server: https://kubernetes.default.svc
```

## Health Checks

### Resource Health

Configuration example:

```yaml
health:
  healthChecks:
    - group: apps
      kind: Deployment
      jsonPath: .status.conditions[?(@.type=="Available")].status
    - group: apps
      kind: StatefulSet
      jsonPath: .status.readyReplicas
```

### Automated Recovery

```yaml
automated:
  prune: true
  selfHeal: true
  allowEmpty: false
retry:
  limit: 5
  backoff:
    duration: 5s
    factor: 2
    maxDuration: 3m
```

## Operational Tasks

### Manual Synchronization

If needed, sync applications manually:

```bash
# Sync all applications
argocd app sync -l argocd.argoproj.io/instance=infrastructure

# Sync specific application
argocd app sync cilium
```

### Status Verification

Check deployment status:

```bash
# List all applications
argocd app list

# Get detailed status
argocd app get cilium
```

## Troubleshooting Guide

### Common Issues

1. **Sync Failures**
   - Verify Git repository access
   - Check resource dependencies
   - Review application logs

2. **Health Check Failures**
   - Check resource state
   - Verify network policies
   - Inspect pod logs

3. **Timeout Issues**
   - Review sync wave timeouts
   - Check resource limits
   - Verify dependencies

### Debug Commands

```bash
# Get application events
kubectl -n argocd get events --field-selector involvedObject.kind=Application

# Check application controller logs
kubectl -n argocd logs -l app.kubernetes.io/name=argocd-application-controller

# Verify resource states
argocd app resources cilium
```

## Resource Tracking

Argo CD identifies resources by the labels and annotations it adds during
deployment. Two modes exist:

- **label** — Only the `app.kubernetes.io/instance` label is required. This is
  the simpler option and works well for most clusters.
- **annotation+label** — Adds the label and the
  `argocd.argoproj.io/tracking-id` annotation. Both must be present for Argo CD
  to manage the object.

If you switch from `label` to `annotation+label`, existing resources that only
have the label will be ignored because the annotation is missing. Server-side
apply cannot fix this, as it happens after resource discovery. Changing back to
`label` brings those resources under management again.

## Best Practices

1. **Wave Management**
   - Use appropriate sync waves
   - Define clear dependencies
   - Set realistic timeouts

2. **Resource Organization**
   - Group related resources
   - Use consistent naming
   - Label resources properly

3. **Health Checks**
   - Define appropriate probes
   - Set meaningful thresholds
   - Monitor critical paths

4. **Security**
   - Use RBAC properly
   - Secure sensitive configs
   - Monitor access logs
