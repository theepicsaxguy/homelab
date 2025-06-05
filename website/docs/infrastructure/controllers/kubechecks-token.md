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

A `Job` and `CronJob` within the `argocd` namespace create and rotate the token. The job stores the token in a temporary
secret which is then pushed to Bitwarden using a `PushSecret`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: argocd-token-generator
  namespace: argocd
```

The `PushSecret` uploads the token to Bitwarden under the key `argocd-kubechecks-api-token`.

## Consuming the token

The `ExternalSecret` for Kubechecks references the pushed secret:

```yaml
- secretKey: argocd_api_token
  remoteRef:
    key: argocd-kubechecks-api-token
```

This approach keeps the API token out of the cluster while still being fully declarative.
