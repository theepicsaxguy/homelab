---
title: 'Loops Deployment Notes'
---

Loops runs the ActivityPub-enabled short-form video platform at `loops.pc-tips.se`. The manifests live in `k8s/applications/web/loops` and mirror the upstream docker-compose layout with dedicated PHP-FPM, Nginx, Horizon, PostgreSQL, and Redis components.

## Build and Image

* `images/loops/Dockerfile` produces the PHP-FPM runtime. It pulls `joinloops/loops-server` `v1.0.0-beta.1`, installs Composer dependencies, enables Redis, PDO MySQL/PostgreSQL, and bundles FFmpeg for media processing.
* The runtime ships a simple entrypoint that seeds `storage` on first boot and exposes the php-fpm status endpoint for health checks.
* CI publishes the built image to `ghcr.io/theepicsaxguy/loops:v1.0.0-beta.1` whenever the Dockerfile changes.

## Namespace

* Namespace: `loops` with the standard GitOps label. The Argo CD project in `k8s/applications/web/project.yaml` now whitelists it for sync.

## Configuration and Secrets

* Application secrets land in `es-loops-app-env`, drawing Bitwarden keys for the Laravel app key, S3 credentials, mailer settings, and Turnstile tokens.
* Database credentials come from the Zalando Postgres Operator secret `loops.loops-postgresql.credentials.postgresql.acid.zalan.do` and are injected into both the web and Horizon Deployments.
* Runtime environment variables set Redis-backed cache/session/queue drivers, S3 storage, and FFmpeg binaries. Update `APP_URL` or other knobs in `app-deployment.yaml` if the hostname changes.

## Storage Layout

* `loops-storage` is a 20Gi Longhorn PVC mounted at `/var/www/storage` so Passport keys, caches, and generated assets survive restarts.
* Source code syncs into an `emptyDir` via an init container so the php-fpm and Nginx containers share the same document root without rebuilding images for config tweaks.

## Deployments and Services

* `loops-app` runs two replicas with separate php-fpm and unprivileged Nginx containers. Probes hit the FastCGI port and HTTP root, and traffic flows through the `loops` Service on port 80.
* `loops-horizon` keeps Laravel Horizon online for queue processing. Probes call `php artisan horizon:status` to make sure workers stay registered.
* `loops-postgresql` defines a two-instance Postgres cluster via the Zalando operator. Adjust size or resources there before scaling replicas.
* `redis` Deployment provides the cache/queue backend with AOF disabled to keep the workload in-memory.

## Networking

* `HTTPRoute` binds `loops.pc-tips.se` to the `internal` Gateway and forwards requests to the Service on port 80.
* `NetworkPolicy` only permits ingress from namespaces labeled `name=gateway` and limits egress to DNS, HTTPS, Postgres, and Redis.

## Verification Checklist

1. Confirm both `loops-app` replicas become `Ready` and that php-fpm status reports `ready=1` via `kubectl exec` with `php-fpm-healthcheck`.
2. Run `kubectl exec -n loops deployment/loops-app -c nginx -- curl -I http://127.0.0.1/` to validate the Nginx sidecar.
3. Check `php artisan horizon:status` inside the Horizon pod until it returns `Horizon is running.`
4. Upload a short test clip; confirm it lands in the configured S3 bucket and playback works through the Gateway endpoint.
