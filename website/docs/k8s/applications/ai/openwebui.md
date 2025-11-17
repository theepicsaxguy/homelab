---
title: 'OpenWebUI Pipelines'
---

Pipelines run alongside OpenWebUI to handle OpenAI-compatible traffic on port `9099`. The Deployment mounts a persistent volume at `/app/pipelines` so installed pipeline modules and dependencies survive pod restarts.

## Configuration

- **Storage**: `openwebui-pipelines-storage` is a `10Gi` Longhorn `PersistentVolumeClaim` mounted at `/app/pipelines` in the `openwebui-pipelines` Deployment.
- **Secrets**: The ExternalSecret `app-openwebui-pipelines-api-key` sources `PIPELINES_API_KEY` from Bitwarden and injects it into the container.
- **Service**: The `pipelines` `ClusterIP` Service exposes port `9099` inside the `open-webui` namespace.
- **Access**: Add an OpenAI connection in the OpenWebUI admin panel with base URL `http://pipelines.open-webui.svc.cluster.local:9099` and the same API key stored in Bitwarden. Use that connection for models that should run through pipelines.
- **Upstream provider**: Configure pipeline valves in the OpenWebUI UI to call LiteLLM at `http://litellm.litellm.svc.cluster.local:4000/v1` with the existing LiteLLM API key.
