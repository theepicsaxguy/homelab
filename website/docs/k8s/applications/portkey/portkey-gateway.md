---
title: 'Portkey Gateway Deployment'
---

Portkey Gateway runs in the `portkey` namespace with locked down Pod Security Standard labels. The namespace manifest applies a
restricted policy set before any other resource syncs.

## Configuration

The ConfigMap sets `NODE_ENV`, health check path, port, and log level so the container starts in production mode. The Deployment
pulls `portkeyai/gateway:1.12.1`, runs it as UID and GID `1000`, and keeps the file system read-only except for temporary
storage mounted at `/tmp` and `/var/tmp`.

## Probes and Resources

All three probes call `/v1/health` on port `8787`. Startup waits up to fifty seconds, readiness checks every ten seconds, and
liveness runs on a thirty second cadence. Requests stay small (100m CPU, 256Mi memory), while limits allow brief spikes to 500m
CPU and 512Mi memory.

## Traffic Policy

Gateway API traffic arrives through the shared `external` listener. The HTTPRoute forwards `portkey.pc-tips.se` traffic to the
Service and adds strict security headers on responses. A NetworkPolicy only allows ingress from the `gateway` and `monitoring`
namespaces and restricts egress to DNS plus HTTP and HTTPS.

## Monitoring

Prometheus discovers the pods through a ServiceMonitor that scrapes `/metrics` over HTTP every thirty seconds. The Deployment
labels and annotations enable the scrape and keep version tracking in sync with the `1.12.1` release.
