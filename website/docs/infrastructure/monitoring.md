---
sidebar_position: 3
title: Monitoring Stack
description: Deploying kube-prometheus-stack with CRDs installed via Helm
---

# Monitoring Stack

The observability stack relies on the kube-prometheus-stack Helm chart. CRDs are
installed directly from the chart using `includeCRDs: true`. Argo CD applies the
chart with server-side apply to avoid annotation bloat.

If you see a `ComparisonError` mentioning
`alertmanagers.monitoring.coreos.com`, verify that the CRDs exist in the cluster
before troubleshooting further.

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
