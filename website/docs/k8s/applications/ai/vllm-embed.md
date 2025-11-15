---
title: 'vLLM Embedding Server'
---

The embedding server runs the OpenAI-compatible entrypoint from the CPU image tagged `vllm-openai-cpu:0.11.0`. It loads `intfloat/e5-base-v2` in embed mode and stores the Hugging Face cache on a 100Gi PersistentVolumeClaim.

## Secrets

An ExternalSecret pulls the `HUGGING_FACE_HUB_TOKEN` field from Bitwarden into the `vllm-embed` namespace.

```yaml
# k8s/applications/ai/vllm-embed/externalsecret.yaml
metadata:
  name: app-vllm-embed-hf-token
```

## Access

Requests reach the Deployment through the `vllm-embed` Service on port 8000 or via the `embeddings.local` host on the Gateway.
