---
title: 'DEX Configuration for ArgoCD'
---

This document provides instructions for enabling DEX in ArgoCD and updating the `values.yaml` file accordingly. It also includes steps for adding the secret entry for `dex.authentik.clientId`.

:::info
This guide assumes you have a working ArgoCD setup and access to the necessary configuration files.
:::

## Common use cases

- **Use Case 1:** Enabling DEX for single sign-on (SSO) in ArgoCD to streamline authentication and authorization processes.
- **Use Case 2:** Integrating ArgoCD with an external identity provider (IdP) for enhanced security and user management.

## Overview of DEX Configuration

DEX is an OpenID Connect (OIDC) provider that can be used to authenticate users in ArgoCD. By enabling DEX, you can integrate ArgoCD with various identity providers, such as Authentik, to manage user authentication and authorization.

- **Core Principles:** DEX acts as a middleman between ArgoCD and the identity provider, handling the authentication flow and providing tokens to ArgoCD.
- **Benefits:** Simplifies user management, enhances security, and supports multiple identity providers.
- **Drawbacks:** Adds complexity to the setup and requires additional configuration.

**Example:** The GitOps workflow in this project relies on ArgoCD to reconcile the declared state in Git with the live state in the Kubernetes cluster. Enabling DEX ensures that only authenticated users can access and manage the ArgoCD instance.

## Important considerations

- **Dependency:** This component requires Authentik to be configured as the identity provider.
- **Limitation:** This approach does not support legacy authentication methods.
- **Security Note:** Ensure that the DEX configuration is properly secured and that sensitive information, such as client secrets, is stored securely.

## Enabling DEX in ArgoCD

To enable DEX in ArgoCD, follow these steps:

1. Open the `values.yaml` file located in `k8s/infrastructure/controllers/argocd/`.
2. Set `dex.enabled` to `true`:

```yaml
dex:
  enabled: true
```

3. Replace the existing `oidc.config` with the new configuration under `configs.cm`:

```yaml
configs:
  cm:
    dex.config: |
      connectors:
      - config:
          issuer: https://sso.pc-tips.se/application/o/argocd/
          clientID: $dex.authentik.clientId
          clientSecret: $dex.authentik.clientSecret
          insecureEnableGroups: true
          scopes:
            - openid
            - profile
            - email
        name: authentik
        type: oidc
        id: authentik
```

4. Correct the variable reference for `clientID` to `$dex.authentik.clientId`.

## Legacy `values-oidc.yaml`

Earlier revisions included a separate `values-oidc.yaml` file. That file has since been removed from the repository, so no cleanup is required.

## Adding Secret Entry for `dex.authentik.clientId`

To ensure both credentials are provided, add a secret entry for `dex.authentik.clientId` in the `externalsecret.yaml` file:

1. Open the `externalsecret.yaml` file located in `k8s/infrastructure/controllers/argocd/`.
2. Add the following entry under `data`:

```yaml
data:
  - secretKey: dex.authentik.clientId
    remoteRef:
      key: <appropriate-remote-key>
```

Replace `<appropriate-remote-key>` with the actual remote key for `dex.authentik.clientId`.

## Summary

By following these steps, you will enable DEX in ArgoCD, update the `values.yaml` file, and add the secret entry for `dex.authentik.clientId`.
