---
title: 'vLLM Embedding Server'
---

The embedding server runs the OpenAI-compatible entrypoint from the official CPU image `public.ecr.aws/q9t5s3a7/vllm-cpu-release-repo:v0.10.2`. It loads `intfloat/e5-base-v2` in embed mode and stores the Hugging Face cache on a 100Gi PersistentVolumeClaim.

## Secrets

An ExternalSecret pulls the `HUGGING_FACE_HUB_TOKEN` field from Bitwarden into the `vllm-embed` namespace.

```yaml
# k8s/applications/ai/vllm-embed/externalsecret.yaml
metadata:
  name: app-vllm-embed-hf-token
```

## Access

Requests reach the Deployment through the `vllm-embed` Service on port 8000 or via `embeddings.pc-tips.se` on the internal and external Gateways.
