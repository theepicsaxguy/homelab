---
title: 'HeadlessX Deployment Notes'
---

This service runs the modular HeadlessX browserless API behind the internal gateway. The manifests live in `k8s/applications/web/headlessx` and stay aligned with the original docker-compose configuration.

## Build and Image

* The Dockerfile at `images/headlessx/Dockerfile` builds HeadlessX from source using the upstream repository at `https://github.com/saifyxpro/HeadlessX`.
* The CI workflow in `.github/workflows/image-build.yaml` automatically builds and pushes the image to `ghcr.io/theepicsaxguy/headlessx:1.2.0` when changes are made to the Dockerfile.
* The build uses a multi-stage Dockerfile pattern: the first stage clones and builds from source, and the second stage creates a minimal runtime image.

## Namespace

* Namespace: `headlessx`. No extra quota or limit range is defined here—reuse the cluster defaults.

## Configuration and Secrets

* Runtime knobs (`PORT`, `NODE_ENV`, `UV_THREADPOOL_SIZE`, `NODE_OPTIONS`) are set directly on the Deployment.
* `AUTH_TOKEN` comes from `es-headlessx-auth-token`, which pulls `app-headlessx-auth-token` out of Bitwarden through External Secrets.

## Storage Layout

* Logs persist to `headlessx-logs`, a 10Gi Longhorn-backed PVC mounted at `/app/logs`.
* `/tmp` uses an `emptyDir` to mimic the compose bind mount.

## Deployment Highlights

* Single replica Deployment with requests set to 1 CPU / 1Gi and limits to 4 CPU / 4Gi.
* Probes hit `GET /api/health` on port 3000 with a 15s initial delay, 30s period, and 10s timeout.
* Pod security: `runAsNonRoot`, `runAsUser`/`runAsGroup` 1000, default seccomp, no privilege escalation, and all capabilities dropped.
## Networking

* Service `headlessx` exposes port 3000 internally.
* `HTTPRoute` binds `headlessx.pc-tips.se` to the `internal` Gateway and forwards all paths to the Service.
* `NetworkPolicy` only permits ingress from namespaces labeled `name=gateway`, and limits egress to DNS plus outbound HTTP/HTTPS.
* Publish `headlessx.pc-tips.se` inside the private DNS zone so the Gateway’s internal address resolves for callers.

## Verification Checklist

1. Wait for the Deployment to become `Available` and confirm probes stay green.
2. `kubectl port-forward` or exec into the pod and curl `http://localhost:3000/api/health` → HTTP 200.
3. Resolve `headlessx.pc-tips.se` from an internal network and curl through the Gateway → HTTP 200.
4. Inspect `/app/logs` to verify log files reach the PVC. Tune retention or ship to centralized logging before the volume fills.
