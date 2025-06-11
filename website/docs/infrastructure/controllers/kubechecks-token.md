---
sidebar_position: 3
title: Kubechecks ArgoCD Token
description: Manual creation of the Kubechecks ArgoCD API key
---

# Kubechecks ArgoCD API Token

Kubechecks requires an ArgoCD API token for authentication. The account is defined in `argocd-cm`, but the token itself is
created manually through the ArgoCD UI or CLI.

## Declare the account

In `k8s/infrastructure/controllers/argocd/values.yaml` the account is configured:

```yaml
configs:
  cm:
    accounts.kubechecks: apiKey
```

## Provide a static token

Generate a token in ArgoCD for the `kubechecks` account and save it to Bitwarden. The Kubechecks deployment pulls this token directly from Bitwarden via `kubechecks-secret-external.yaml`.

## Consuming the token

`kubechecks-secret-external.yaml` pulls the Bitwarden item into a Kubernetes secret:

```yaml
- secretKey: argocd_api_token
  remoteRef:
    key: 0d2a2732-db70-49b7-b64a-b29400a92230
```

The secret is referenced by the Kubechecks Helm chart so the token never lives in the repository.
