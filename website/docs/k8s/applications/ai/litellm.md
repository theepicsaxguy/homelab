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

## Tracking Usage and Spend

### Basic Tracking

After making requests, navigate to the Logs section in the LiteLLM UI to view Model, Usage and Cost information.

### Per-User Tracking

To track spend and usage for each Open WebUI user, configure both Open WebUI and LiteLLM:

#### Enable User Info Headers in Open WebUI

Set the following environment variable for Open WebUI to enable user information in request headers:

```yaml
# k8s/applications/ai/openwebui/webui-statefulset.yaml
env:
  - name: ENABLE_FORWARD_USER_INFO_HEADERS
    value: 'true'
```

#### Configure LiteLLM to Parse User Headers

Add the following to your LiteLLM config to specify the request header mapping for user tracking:

```yaml
# k8s/applications/ai/litellm/configmap.yaml
general_settings:
  user_header_mappings:
    - header_name: X-OpenWebUI-User-Id
      litellm_user_role: internal_user
    - header_name: X-OpenWebUI-User-Email
      litellm_user_role: customer
```

#### Custom Spend Tag Headers

You can add custom headers to the request to track spend and usage:

```yaml
# k8s/applications/ai/litellm/configmap.yaml
litellm_settings:
  extra_spend_tag_headers:
    - "X-OpenWebUI-User-Id"
    - "X-OpenWebUI-User-Email"
    - "X-OpenWebUI-User-Name"
```

#### Available Tracking Options

You can use any of the following headers in `header_name` in `user_header_mappings`:

- `X-OpenWebUI-User-Id`
- `X-OpenWebUI-User-Email`
- `X-OpenWebUI-User-Name`

These may offer better readability and easier mental attribution when hosting for a small group of users that you know well.

Choose based on your needs, but note that in Open WebUI:

- Users can modify their own usernames
- Administrators can modify both usernames and emails of any account

## Responses API (OpenAI `/responses`)

LiteLLM supports the OpenAI-style Responses API which provides session continuity, stored responses, and advanced streaming features. To enable Requests/Responses API features, update the ConfigMap and Deployment values below.

- **Session continuity**: add `optional_pre_call_checks: ["responses_api_deployment_check"]` under `router_settings` in `proxy_server_config.yaml` (already present in the default ConfigMap). This ensures follow-up requests using `previous_response_id` route to the same upstream deployment.

- **Cold storage for prompts**: Optional for basic responses API functionality. Set `store_prompts_in_cold_storage: true` and configure `cold_storage_custom_logger` and `s3_callback_params` in the ConfigMap to store request/response text into S3 for auditing, session continuity, and long-term storage. The ConfigMap uses environment variables for S3 credentials — create a `litellm-s3-secret` Secret with keys `bucket_name`, `region_name`, `access_key_id`, `secret_access_key`.

- **Response ID security**: by default LiteLLM encrypts response IDs so clients cannot fetch others' responses. To allow cross-access (not recommended for multi-tenant deployments), set `disable_responses_id_security: true` in the ConfigMap's `general_settings` or set the `DISABLE_RESPONSES_ID_SECURITY` env var on the Deployment. The Deployment includes `DISABLE_RESPONSES_ID_SECURITY` which defaults to `false`.

- **Performance optimizations**: The config enables Redis caching, Qdrant semantic caching, usage-based routing, and connection pooling for fast responses. For high-throughput deployments, consider increasing `database_connection_pool_limit` and enabling `background_health_checks`.
