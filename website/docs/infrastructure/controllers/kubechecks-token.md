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

ServiceAccount and RBAC rules, along with a post-install Job and weekly CronJob, are now templated via the Argo CD Helm
chart using the `extraObjects` field. Each upgrade triggers the one-shot job to create or refresh the token, which is
then stored in a Secret. The CronJob rotates the token weekly.

## Consuming the token

The `ExternalSecret` for Kubechecks references the pushed secret:

```yaml
- secretKey: argocd_api_token
  remoteRef:
    key: argocd-kubechecks-api-token
```

This approach keeps the API token out of the cluster while still being fully declarative.
