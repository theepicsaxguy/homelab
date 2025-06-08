---
sidebar_position: 3
title: Kubechecks ArgoCD Token
description: Declarative generation of the Kubechecks ArgoCD API key
---

# Kubechecks ArgoCD API Token

Kubechecks requires an ArgoCD API token for authentication. The account is defined in `argocd-cm` so ArgoCD does not
store a token automatically.

## Declare the account

In `k8s/infrastructure/controllers/argocd/values.yaml` the account is configured:

```yaml
configs:
  cm:
    accounts.kubechecks: apiKey
```

## Automatic token generation

The Helm chart includes a small Job under `extraObjects` that creates the token using the Kubernetes API. It first checks for the `argocd-kubechecks-token` Secret. If it is missing, the Job generates a new value with `openssl rand -hex 32` and stores it in the Secret. The token is also pushed to Bitwarden through a `PushSecret` resource. The Job runs on every upgrade so the token is recreated if needed.

## Consuming the token

The `ExternalSecret` for Kubechecks references the pushed secret:

```yaml
- secretKey: argocd_api_token
  remoteRef:
    key: argocd-kubechecks-api-token
```

This approach keeps the API token out of the cluster while still being fully declarative.
