---
title: 'Bytebot Deployment'
---

Bytebot runs three Pods: the desktop VNC session, the API agent, and the Next.js UI. A Postgres StatefulSet stores agent data and a LiteLLM proxy fans out to Anthropic, OpenAI, and Gemini.

## Secrets

ExternalSecrets pull API keys, database URL, and the Postgres password from Bitwarden via the shared ClusterSecretStore. Each workload references the rendered Secret directly using `envFrom` or `secretKeyRef`.

```yaml
# k8s/applications/ai/bytebot/externalsecrets
- agent-credentials.yaml
- db-url.yaml
- litellm-credentials.yaml
- postgres-credentials.yaml
```

## Networking

The Services expose port 80 and route traffic to the container ports. The HTTPRoute named `bytebot` fans `/api` to the agent, `/vnc` to the desktop, and `/` to the UI. A second Route, `bytebot-llm-proxy`, can publish LiteLLM externally if you keep the hostname.

## Images

Update image revisions in one place through the `images` block inside `kustomization.yaml`. The Deployments and StatefulSet reference tags via Kustomize so you do not need to touch the workload manifests when bumping versions.
