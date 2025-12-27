---
title: 'Portkey Gateway Deployment'
---

Portkey Gateway runs in the `portkey` namespace with locked down Pod Security Standard labels. The namespace manifest
applies a restricted policy set before any other resource syncs.

## Configuration

The ConfigMap sets `NODE_ENV`, health check path, port, and log level so the container starts in production mode. The
Deployment pulls `portkeyai/gateway:1.12.1`, runs it as UID and GID `1000`, and keeps the file system read-only except
for writable volumes. npm and Node.js operations are redirected to writable locations via environment variables
(`NPM_CONFIG_CACHE`, `XDG_CONFIG_HOME`, etc.) and additional volume mounts for `/home/node/.npm`, `/home/node/.config`,
`/app/cache`, `/var/log`, and `/var/run`.

## Probes and Resources

All three probes call `/v1/health` on port `8787`. Startup waits up to fifty seconds, readiness checks every ten
seconds, and liveness runs on a thirty second cadence. Requests stay small (100m CPU, 256Mi memory), while limits allow
brief spikes to 500m CPU and 512Mi memory.

## Traffic Policy

Gateway API traffic arrives through the shared `external` listener. The HTTPRoute forwards `portkey.peekoff.com` traffic
to the Service and adds strict security headers on responses. A NetworkPolicy only allows ingress from the `gateway` and
`monitoring` namespaces and restricts egress to DNS plus HTTP and HTTPS.

## Monitoring

Prometheus discovers the pods through a ServiceMonitor that scrapes `/metrics` over HTTP every thirty seconds. The
Deployment labels and annotations enable the scrape and keep version tracking in sync with the `1.12.1` release.

## Model Comparison

Portkey mounts JSON strategy files at `/app/configs` so you can call the gateway with an `x-portkey-config` header. Each
name maps to a prebuilt routing policy:

- `azure-models` spreads traffic across eight Azure OpenAI variants.
- `claude-models` rotates through the three Claude tiers.
- `openai-models` balances across three direct OpenAI models.
- `all-models` mixes Azure, Anthropic, OpenAI, and Cerebras targets with semantic caching.
- `cost-optimized` inspects token counts to choose between budget and premium Azure plans.

API credentials live in Bitwarden and sync into the cluster with External Secrets so keys stay out of Git.
