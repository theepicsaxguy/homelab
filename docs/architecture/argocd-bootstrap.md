# ArgoCD Bootstrap Process

## Overview

ArgoCD serves as the primary GitOps operator in our infrastructure. This document outlines the bootstrap process and considerations for managing ArgoCD itself.

## Bootstrap Strategy

### Initial Installation

ArgoCD is installed via OpenTofu with the following characteristics:
- Helm chart version: 7.8.4
- Namespace: argocd
- Replace strategy enabled for reinstallation scenarios
- Cleanup enabled for failed installations

### Handling Existing Installations

The bootstrap process is idempotent and handles existing installations by:
1. Using `replace = true` to allow reinstallation if needed
2. Cleaning up failed installations automatically
3. Creating the namespace if it doesn't exist

### Post-Installation Flow

1. ArgoCD installation completes
2. App-of-Apps pattern deploys remaining infrastructure
3. Bitwarden Secrets Manager operator is deployed via ArgoCD
4. Other infrastructure components follow in defined sync waves

## Recovery Procedures

If ArgoCD needs to be reinstalled:

1. Verify existing state:
```bash
kubectl get applications -n argocd
```

2. Run OpenTofu:
```bash
cd k8s
tofu apply
```

3. Verify installation:
```bash
kubectl get pods -n argocd
```

The bootstrap process will handle the reinstallation automatically while preserving GitOps principles.