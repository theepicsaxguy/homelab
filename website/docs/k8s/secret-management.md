---
sidebar_position: 4
title: Secret Management
description: How to manage secrets using External Secrets and Bitwarden.
---

# Secret Management Strategy

This project uses the [External Secrets Operator](https://external-secrets.io/) to securely pull secrets from [Bitwarden](https://bitwarden.com/) into the cluster. This means sensitive data never lives in Git.

## Core Concepts

1. **Bitwarden as the Source of Truth**—every token, password, and key lives in Bitwarden.
2. **External Secrets Operator**—syncs those secrets into Kubernetes at runtime.
3. **—Name-Based Lookups—we use a naming convention for secrets in Bitwarden:

## Naming Convention

All Bitwarden secrets follow the `{scope}-{service-or-app}-{description}` pattern.

- **`{scope}`** – high-level category like `infra`, `app`, or `global`.
- **`{service-or-app}`** – the specific component name (e.g., `argocd`, `cloudflare`).
- **`{description}`** – short purpose description such as `api-token`, `oauth-client-id`, or `db-password`.

Example: the client ID for ArgoCD's OIDC setup is stored as `app-argocd-oauth-client-id`.

## Workflow for Adding a Secret

1. **Create the secret in Bitwarden**—use the naming convention, store the value.
2. **Reference it in an `ExternalSecret` manifest**—point the `remoteRef.key` to the Bitwarden name.
3. **Commit the manifest**—once merged, ArgoCD applies it and the operator syncs the secret into the cluster.

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: newapp-secrets
  namespace: newapp
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: bitwarden-backend
  target:
    name: newapp-k8s-secret
  data:
    - secretKey: API_KEY
      remoteRef:
        key: app-newapp-api-key
```

This setup keeps credentials out of the repository while making manifest files self-explanatory.
