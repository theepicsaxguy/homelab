---
title: 'Pinepods Deployment Notes'
---

Pinepods runs as a web application in the `pinepods` namespace. The manifests live in `k8s/applications/web/pinepods`
and mirror the upstream container defaults while fitting into the cluster guardrails.

## Configuration and Secrets

- Non-sensitive settings (`SEARCH_API_URL`, `DB_TYPE`, `DEBUG_MODE`) stay in the `pinepods-config` ConfigMap.
- `USERNAME`, `PASSWORD`, `FULLNAME`, and `EMAIL` come from `es-pinepods-admin`. Bitwarden keys
  (`app-pinepods-admin-username`, `-password`, `-fullname`, `-email`) feed that secret through External Secrets.

## Database

- CloudNativePG runs PostgreSQL 18 in a single-node `pinepods-db` cluster with a 20Gi Longhorn-backed volume.
- Bootstrap creates the `pinepods` database and grants ownership to the managed `app` role, which CloudNativePG stores
  in the `pinepods-db-app` secret.
- The Deployment reads `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, and `DB_PASSWORD` from that CNPG secret.

## Monitoring

- `pinepods-db` exposes PostgreSQL metrics through a dedicated PodMonitor instead of the deprecated CNPG toggle.

## Storage Layout

- `pinepods-downloads`: 100Gi Longhorn PVC mounted at `/opt/pinepods/downloads`.
- `pinepods-backups`: 20Gi Longhorn PVC mounted at `/opt/pinepods/backups`.

## Deployment Highlights

- Runs `madeofpendletonwool/pinepods:0.8.2` as a single replica with non-root security settings.
- Requests 250m CPU / 512Mi memory and caps usage at 500m CPU / 1Gi memory.
- Readiness probe hits `GET /api/pinepods_check` every 15 seconds after a 30-second delay; the liveness probe follows
  the same path with a 60-second delay.

### Horust Service Definitions & CrashLoopBackOff Remediation

The upstream image includes Horust service definition files (`.toml` configs) under `/etc/horust/services/`. During
startup, `startup.sh` copies service configurations from `/pinepods/startup/services/` into that directory, then
launches Horust with `--services-path /etc/horust/services/` to supervise the Rust API (`pinepods-api`), Nginx proxy,
and gPodder API gateway.

A prior manifest revision mounted an `emptyDir` volume at `/etc/horust/services/`, which shadowed the image's baked-in
service definitions. When Horust initialized, it found no `.toml` files and could not start or supervise any services.
The process then exited cleanly with exit code 0 (not a crash, just nothing to do). As a result, the HTTP listener never
bound to port 8040. Kubernetes readiness probes attempting `GET /api/pinepods_check` failed with connection refused,
triggering liveness probe failures and repeated restarts (`CrashLoopBackOff`).

Remediation involved removing the `emptyDir` volume and its corresponding `volumeMount` targeting
`/etc/horust/services/`. With the mount gone, startup scripts can properly copy service definitions into that directory,
Horust loads them, and supervised processes (including the web server) start normally. The readiness and liveness probes
then succeed once the HTTP endpoint `/api/pinepods_check` becomes available on port 8040.

Checklist after change:

1. Confirm new ReplicaSet does NOT include a `horust-services` volume or volumeMount.
2. Observe container state: should transition from `Running` → `Ready` after readiness initialDelaySeconds.
3. `kubectl exec` into the pod and run `ls /etc/horust/services/` to verify multiple `.toml` service files are present
   (not empty).
4. HTTP `GET /api/pinepods_check` returns 200 (and `{"pinepods_instance": true}` in JSON) within the readiness probe
   window.
5. Logs should show "Starting services with Horust..." followed by service startup messages; no exit with code 0 before
   readiness delay.

## Networking

- Service `pinepods` exposes port 8040 inside the namespace.
- `HTTPRoute` binds `pinepods.peekoff.com` to both the internal and external Gateways.

## Verification Checklist

1. Confirm the `pinepods-db` CNPG cluster reaches a ready state and emits the `pinepods-db-app` secret.
2. Wait for the Deployment to become `Available`, then curl `http://localhost:8040/api/pinepods_check` inside the pod.
3. Resolve `pinepods.peekoff.com` through the Gateway and ensure it returns HTTP 200.
4. Inspect the download and backup PVCs to verify files land in the correct paths.
5. Ensure `/etc/horust/services` contains service TOML files (not empty).
