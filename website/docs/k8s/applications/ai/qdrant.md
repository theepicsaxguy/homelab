---
title: 'Qdrant Vector Store'
---

Qdrant runs as a single replica Deployment with a 50Gi PersistentVolumeClaim mounted at `/qdrant/storage`. The Pod exposes HTTP on port 6333 and gRPC on port 6334, matching the defaults from the upstream image.

## Networking

Traffic stays inside the cluster through the `qdrant` Service and can be published through both the internal and external Gateways on `qdrant.pc-tips.se`.

```yaml
# k8s/applications/ai/qdrant/httproute.yaml
parentRefs:
  - name: external
    namespace: gateway
  - name: internal
    namespace: gateway
hostnames:
  - 'qdrant.pc-tips.se'
backendRefs:
  - name: qdrant
    port: 6333
```
