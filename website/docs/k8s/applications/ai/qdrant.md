---
title: 'Qdrant Vector Store'
---

Qdrant runs as a single replica Deployment with a 50Gi PersistentVolumeClaim mounted at `/qdrant/storage`. The Pod
exposes HTTP on port 6333 and gRPC on port 6334, matching the defaults from the upstream image.

## Networking

Traffic stays inside the cluster through the `qdrant` Service and can be published through both the internal and
external Gateways on `qdrant.peekoff.com`.

```yaml
# k8s/applications/ai/qdrant/httproute.yaml
parentRefs:
  - name: external
    namespace: gateway
  - name: internal
    namespace: gateway
hostnames:
  - 'qdrant.peekoff.com'
backendRefs:
  - name: qdrant
    port: 6333
```

## Authentication

Qdrant supports static API key auth using `service.api_key` or the env var `QDRANT__SERVICE__API_KEY`. The cluster
stores this in Bitwarden and surfaces it via an ExternalSecret.

```yaml
# k8s/applications/ai/qdrant/externalsecret.yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: app-qdrant-api-key
  namespace: qdrant
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: bitwarden-backend
    kind: ClusterSecretStore
  target:
    name: app-qdrant-api-key
    creationPolicy: Owner
  data:
    - secretKey: QDRANT__SERVICE__API_KEY
      remoteRef:
        key: app-qdrant-api-key
```

Injected into the Deployment:

```yaml
env:
  - name: QDRANT__SERVICE__API_KEY
    valueFrom:
      secretKeyRef:
        name: app-qdrant-api-key
        key: QDRANT__SERVICE__API_KEY
```

Clients send the header:

```
api-key: <API_KEY>
```

Optional:

- Read-only key: `QDRANT__SERVICE__READ_ONLY_API_KEY`
- JWT RBAC (fine-grained access): set `QDRANT__SERVICE__JWT_RBAC=true` and use Bearer tokens
  (`Authorization: Bearer <JWT>`)

Security notes:

- Enforce TLS termination at the Gateway before exposing API keys.
- Future hardening: switch to unprivileged image variant and restrict egress with NetworkPolicies.
- Only ports 6333 (HTTP) and 6334 (gRPC) are required for single-node access.

```

```
