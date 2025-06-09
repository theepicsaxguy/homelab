---
sidebar_position: 3
title: Monitoring Stack
description: Deploying kube-prometheus-stack with CRDs managed via server-side apply
---

# Monitoring Stack

The observability stack relies on the kube-prometheus-stack Helm chart. This chart ships large CRD definitions which can
exceed Kubernetes' 256 KB annotation limit when applied with the default client-side method.

To avoid sync errors in Argo CD:

1. The CRDs are installed through a dedicated `crds` kustomization that references the upstream YAML files.
2. The Helm release is configured with `includeCRDs: false` and the Argo CD Application sets `skipCrds: true`.
3. The Application uses `ServerSideApply`, so Argo CD doesn't add the `last-applied-configuration` annotation.

This approach keeps the deployment idempotent and avoids manual patching of CRDs.

## Grafana OAuth Credentials

Grafana relies on OIDC with Authentik for authentication. The OAuth client ID and
secret are managed through an ExternalSecret in `k8s/infrastructure/monitoring/prometheus-stack`.
Ensure the secret keys reference the correct Bitwarden entries before deploying:

```yaml
data:
  - secretKey: clientId
    remoteRef:
      key: e0653cbf-e89e-4c7f-bf15-b2f4014daf64
      property: value
  - secretKey: clientSecret
    remoteRef:
      key: 56041409-832c-4d56-8688-b2f4014dc3cc
      property: value
```

If these values are missing, the Grafana pod will fail to authenticate.
