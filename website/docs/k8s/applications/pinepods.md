---
title: 'Pinepods Deployment Notes'
---

Pinepods runs as a web application in the `pinepods` namespace. The manifests live in `k8s/applications/web/pinepods` and mirror the upstream container defaults while fitting into the cluster guardrails.

## Configuration and Secrets

* Non-sensitive settings (`SEARCH_API_URL`, `DB_TYPE`, `DEBUG_MODE`) stay in the `pinepods-config` ConfigMap.
* `USERNAME`, `PASSWORD`, `FULLNAME`, and `EMAIL` come from `es-pinepods-admin`. Bitwarden keys (`app-pinepods-admin-username`, `-password`, `-fullname`, `-email`) feed that secret through External Secrets.

## Database

* CloudNativePG runs PostgreSQL 18 in a single-node `pinepods-db` cluster with a 20Gi Longhorn-backed volume.
* Bootstrap creates the `pinepods` database and role, then writes connection details to the generated secret `pinepods-db-app`.
* The Deployment reads `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, and `DB_PASSWORD` from that CNPG secret.

## Monitoring

* `pinepods-db` exposes PostgreSQL metrics through a dedicated PodMonitor instead of the deprecated CNPG toggle.

## Storage Layout

* `pinepods-downloads`: 100Gi Longhorn PVC mounted at `/opt/pinepods/downloads`.
* `pinepods-backups`: 20Gi Longhorn PVC mounted at `/opt/pinepods/backups`.

## Deployment Highlights

* Runs `madeofpendletonwool/pinepods:latest` as a single replica with non-root security settings.
* Requests 250m CPU / 512Mi memory and caps usage at 500m CPU / 1Gi memory.
* Readiness probe hits `GET /api/pinepods_check` every 15 seconds after a 30-second delay; the liveness probe follows the same path with a 60-second delay.

## Networking

* Service `pinepods` exposes port 8040 inside the namespace.
* `HTTPRoute` binds `pinepods.pc-tips.se` to both the internal and external Gateways.

## Verification Checklist

1. Confirm the `pinepods-db` CNPG cluster reaches a ready state and emits the `pinepods-db-app` secret.
2. Wait for the Deployment to become `Available`, then curl `http://localhost:8040/api/pinepods_check` inside the pod.
3. Resolve `pinepods.pc-tips.se` through the Gateway and ensure it returns HTTP 200.
4. Inspect the download and backup PVCs to verify files land in the correct paths.
