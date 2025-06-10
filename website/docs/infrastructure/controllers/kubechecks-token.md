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

## Provide a static token

A fixed token is stored in Bitwarden. An `ExternalSecret` merges it into `argocd-secret` so the ArgoCD API can authenticate Kubechecks requests. The same secret UID is referenced by the Kubechecks deployment.

## Consuming the token

The `ExternalSecret` for Kubechecks references the same secret:

```yaml
- secretKey: argocd_api_token
  remoteRef:
    key: 0d2a2732-db70-49b7-b64a-b29400a92230
```

This approach keeps the API token out of the cluster while still being fully declarative.
