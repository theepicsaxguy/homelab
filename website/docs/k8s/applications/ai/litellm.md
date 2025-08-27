---
title: 'LiteLLM Prompt Storage'
---

LiteLLM can persist request and response data to PostgreSQL for later review. The deployment mounts a proxy configuration file that enables prompt logging.

## Configuration

```yaml
# k8s/applications/ai/litellm/configmap.yaml
data:
  proxy_server_config.yaml: |
    general_settings:
      store_model_in_db: true
      store_prompts_in_spend_logs: true
```

The Deployment mounts this file at `/app/proxy_server_config.yaml` to activate the settings.
