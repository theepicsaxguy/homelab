---
title: 'HeadlessX Deployment Notes'
---

This service runs the modular HeadlessX API behind the internal gateway. The manifests live in `k8s/applications/web/headlessx` and stay aligned with the original Docker Compose configuration.

## Build and image

* The Dockerfile at `images/headlessx/Dockerfile` builds HeadlessX from source using the upstream repository at `https://github.com/saifyxpro/HeadlessX`.
* The build uses a three stage Dockerfile pattern matching the official HeadlessX Dockerfile:
  1. **Source stage**: Clones the HeadlessX repository at the specified version
  2. **Website builder stage**: Builds the HeadlessX web interface for production
  3. **Runtime stage**: Uses the official Playwright base image `mcr.microsoft.com/playwright:v1.56.1-noble`. That image already includes the browser dependencies.
* The CI workflow in `.github/workflows/image-build.yaml` builds the image and publishes the `latest`, base image (`3.22`), app version (`1.2.0`), and Git commit suffix tags to `ghcr.io/theepicsaxguy/headlessx` whenever the Dockerfile changes.
* The runtime image includes a `HEALTHCHECK` that probes `/api/health` every 30 seconds.

## Namespace

* Namespace: `headlessx`. No extra quota or limit range lives here. Use the cluster defaults.

## Configuration and secrets

* Runtime knobs (`PORT`, `NODE_ENV`, `UV_THREADPOOL_SIZE`, `NODE_OPTIONS`) are set directly on the Deployment.
* `AUTH_TOKEN` comes from `es-headlessx-auth-token`, which pulls `app-headlessx-auth-token` out of Bitwarden through External Secrets.

## Storage layout

* A persistent volume claim (PVC) named `headlessx-logs` provides 10 Gi of storage backed by Longhorn at `/app/logs`.
* `/tmp` uses an `emptyDir` to mimic the compose bind mount.

## Deployment highlights

* Single replica Deployment with requests set to 1 CPU / 1Gi and limits to 4 CPU / 4Gi.
* Probes hit `GET /api/health` on port 3000 with a 15 second initial delay, a 30 second period, and a 10 second timeout.
* Pod security: `runAsNonRoot`, `runAsUser` and `runAsGroup` 1000, the runtime default seccomp profile, no privilege escalation, and all capabilities dropped.
## Networking

* Service `headlessx` exposes port 3000 internally.
* `HTTPRoute` binds `headlessx.pc-tips.se` to the `internal` Gateway and forwards all paths to the Service.
* `NetworkPolicy` only permits ingress from namespaces labeled `name=gateway`, and limits egress to Domain Name System (DNS) plus outbound HTTP and HTTPS.
* Publish `headlessx.pc-tips.se` inside the private DNS zone so the Gateway’s internal address resolves for callers.

## Verification checklist

1. Wait for the Deployment to become `Available` and confirm probes stay green.
2. `kubectl port-forward` or exec into the pod and run `curl "http://localhost:3000/api/health"` → HTTP 200.
3. Resolve `headlessx.pc-tips.se` from an internal network and call it through the Gateway with `curl "https://headlessx.pc-tips.se/api/health"` → HTTP 200.
4. Inspect `/app/logs` to verify log files reach the persistent volume claim. Tune retention or ship to centralized logging before the volume fills.
