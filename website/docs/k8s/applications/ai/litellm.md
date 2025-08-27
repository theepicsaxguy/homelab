---
title: 'LiteLLM Proxy Configuration'
---

LiteLLM reads its settings from a ConfigMap. The file enables database logging, Redis caching, and Prometheus metrics. A lightweight Redis Service runs in cluster for caching and router state. It has no persistence or auth.

## Configuration

```yaml
# k8s/applications/ai/litellm/configmap.yaml
data:
  proxy_server_config.yaml: |
    litellm_settings:
      callbacks: ["prometheus"]
      cache: true
      cache_params:
        type: redis
        host: redis.litellm.svc.kube.pc-tips.se
        port: 6379
    router_settings:
      redis_host: redis.litellm.svc.kube.pc-tips.se
      redis_port: "6379"
    general_settings:
      store_model_in_db: true
      store_prompts_in_spend_logs: true
```

The Deployment mounts this file at `/app/proxy_server_config.yaml`. Probes call `/health/readiness` and `/health/liveliness` on port `4001`. Prometheus scrapes metrics from `/metrics`.
