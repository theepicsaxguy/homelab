---
title: 'vLLM Embedding Server'
---

The embedding server uses the OpenAI-compatible entrypoint in the custom image `ghcr.io/theepicsaxguy/vllm-cpu`.
The `Dockerfile` in `images/vllm-cpu/` pins the current Ubuntu long term support releases so Python, `gcc`, and `gperftools` match between builds.
It loads `intfloat/e5-base-v2` using the `--convert embed` argument and stores the Hugging Face cache on a 100Gi PersistentVolumeClaim.
The server runs on CPU, with device selection handled at the container image build level.

## Configuration

The deployment includes CPU-specific optimizations based on official vLLM documentation:

- `VLLM_CPU_KVCACHE_SPACE`: set to 2GB to reduce memory overhead (default is 4GB)
- `SYS_NICE` capability: enables better CPU scheduling for improved performance
- Memory allocation: 5Gi request and 6Gi limit to accommodate model weights, overhead, and KV cache

## Secrets

An ExternalSecret pulls the `HUGGING_FACE_HUB_TOKEN` field from Bitwarden into the `vllm-embed` namespace.

```yaml
# k8s/applications/ai/vllm-embed/externalsecret.yaml
metadata:
  name: app-vllm-embed-hf-token
```

## Access

Requests reach the Deployment through the `vllm-embed` Service on port 8000 or via `embeddings.pc-tips.se` on the internal and external Gateways.
