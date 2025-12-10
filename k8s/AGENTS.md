# Kubernetes Infrastructure - Agent Guidelines

This document provides guidance for agents working with the Kubernetes infrastructure in this repository. It is a scoped `AGENTS.md` meant to be the authoritative source for anything under `k8s/`.

## Purpose & Scope

- Scope: `k8s/` (all files and subdirectories). Use this file as the primary reference for Kubernetes manifests, kustomize, Argo CD ApplicationSets, and operational patterns.
- Goal: enable an agent to validate, extend, and reason about Kubernetes manifests and operational policies without external tools or secrets.

## Quick-start Commands (verify locally)

Run these commands from the repository root.

```bash
# Build a kustomize overlay (Helm enabled)
kustomize build --enable-helm k8s/applications/<category>/<app>

# Build infra overlays
kustomize build --enable-helm k8s/infrastructure/<component>

# Validate generated YAML (example: check for syntax)
kustomize build k8s/applications | yq eval -P -

# Lint manifests (kubectl kustomize + kubeval if installed)
kustomize build k8s/applications | kubeval --strict --ignore-missing-schemas
```

Notes:
- Use `--enable-helm` when a kustomization pulls in Helm charts.
- `yq` and `kubeval` are recommended but optional; fall back to manual inspection if not available.

## Structure & Examples

- `k8s/applications/` — user-facing apps organized by category (e.g., `ai/`, `media/`, `web/`). Each app should have its own `kustomization.yaml`.
  - Active categories: `ai/`, `automation/`, `external/`, `media/`, `network/`, `tools/`, `web/`
  - Category-level AGENTS.md template available: `k8s/applications/AGENTS-TEMPLATE.md`
  - Create category-level AGENTS.md when categories develop unique patterns (5+ apps, shared resources, or special workflows)
- `k8s/infrastructure/` — cluster-level components (controllers, network, storage, auth, database).
- Example app layout:

```
k8s/applications/ai/litellm/
├── kustomization.yaml
├── deployment.yaml
├── service.yaml
└── httproute.yaml
```

## Operational Patterns

- GitOps: Argo CD ApplicationSets defined at `k8s/application-set.yaml` auto-discover new directories.
- Sync waves: infrastructure is applied before applications (use ApplicationSet ordering when adding infra components).
- Use `generatorOptions.disableNameSuffixHash: true` in kustomizations when you need stable resource names.

## Backups (Longhorn)

See the repository-level `k8s/AGENTS.md` Longhorn section for label-based backup rules. Key rule: PVCs without backup labels are not backed up. Use labels `recurring-job.longhorn.io/source: enabled` plus group label `recurring-job-group.longhorn.io/gfs=enabled` or `.../daily=enabled`.

## How to Add an Application

1. Create `k8s/applications/<category>/<app>/` and add `kustomization.yaml` and manifests.
2. Ensure `k8s/applications/<category>/kustomization.yaml` references the new app.
3. Test locally with `kustomize build --enable-helm k8s/applications/<category>/<app>` and inspect output.
4. Create a PR. Do not apply changes directly to cluster.

## Testing Manifests

- Unit: Validate that each `kustomization.yaml` builds without error.
- Integration: `kustomize build` for parent directories (`k8s/applications` and `k8s/infrastructure`) and run `kubeval` or CI validators.
- CI: PRs should include `kustomize build --enable-helm` in their CI step (see repo workflows for examples).

## Boundaries & Safety

- Do not hardcode secrets in manifests. Use ExternalSecrets/SecretProvider references.
- Do not change `k8s/infrastructure/application-set.yaml` without review — it affects discovery and sync ordering.
- Do not modify CRD definitions unless you understand operator compatibility.

## Kubernetes-Specific Operational Rules

### Secret Management & References

**Auto-Generated Secret Names**

- **When using operators that auto-generate secrets** (like CloudNativePG/CNPG, Zalando Postgres Operator), verify the generated secret name before referencing it in applications. Operators often append suffixes like `-app`, `-superuser`, or `-owner`.
- **Always query the cluster** to confirm the exact secret name:
  ```bash
  kubectl get secrets -n <namespace> | grep <cluster-name>
  ```
- **Before updating `kustomization.yaml` or Deployment manifests** with a secret reference, decode the secret to verify its structure and keys:
  ```bash
  kubectl get secret <secret-name> -n <namespace> -o jsonpath='{.data}' | jq 'keys'
  ```

### Operator & CRD Logic

**Connection Secrets & Endpoints**

- **Check for existing connection secrets or endpoints** before creating new ones. For backup/objectStore configuration (e.g., MinIO/S3 for CNPG or Longhorn), search for existing secrets:
  ```bash
  kubectl get secrets -n <namespace> | grep -E 'minio|s3|backup'
  ```
- **Decode existing secrets** to verify endpoint URLs and credentials rather than assuming `localhost` or default values:
  ```bash
  kubectl get secret <secret-name> -n <namespace> -o jsonpath='{.data.MINIO_ENDPOINT}' | base64 -d
  ```

**CloudNativePG (CNPG) Specific Rules**

- **Verify the installed CNPG operator version** before writing manifests:
  ```bash
  kubectl get deployment -n cnpg-system cnpg-controller-manager -o jsonpath='{.spec.template.spec.containers[0].image}'
  ```
- **Version-specific behavior:**
  - Version < 1.29: May require the deprecated `Barman Cloud Plugin` via `Cluster.spec.backup.barmanObjectStore`.
  - Version ≥ 1.29: Use `Cluster.spec.backup.barmanObjectStore` with the plugin architecture.
  - Always consult the official CNPG documentation for the installed version.
- **Always validate the `Cluster` status immediately after creation:**
  ```bash
  kubectl get cluster <cluster-name> -n <namespace>
  kubectl describe cluster <cluster-name> -n <namespace>
  ```
- **If a Cluster is stuck in "Setting up primary,"** check the operator logs first, not just the Pod logs:
  ```bash
  kubectl logs -n cnpg-system deployment/cnpg-controller-manager --tail=100
  ```

### CNPG Database Management Patterns

**Auto-Generated Credentials (Preferred)**

- **CNPG automatically generates database credentials** when no `bootstrap.initdb.secret` is specified
- **Never use ExternalSecrets for CNPG app credentials** - this creates circular dependencies
- **Auto-generated secret naming:** `<cluster-name>-app` (e.g., `immich-postgresql-app`)
- **Secret contains:** `username`, `password`, `dbname`, `host`, `port`, `uri`, `jdbc-uri`, etc.

**Common Anti-Pattern (Avoid):**
- Using ExternalSecrets to create CNPG app secrets creates circular dependencies
- CNPG clusters fail to initialize because they expect the secret to exist before they can create it
- Always remove `bootstrap.initdb.secret` references and let CNPG auto-generate credentials

**Correct Pattern:**
- Omit `bootstrap.initdb.secret` from Cluster manifests
- CNPG will automatically create `<cluster-name>-app` secret with random credentials
- Applications reference the auto-generated secret directly

**Barman Cloud Backup Setup**

- **Use ObjectStore + plugins architecture** (modern approach)
- **ObjectStore resource** defines S3 backup destination
- **Cluster plugins section** references the ObjectStore
- **ScheduledBackup** uses `method: plugin` with `barman-cloud.cloudnative-pg.io`

**Complete Backup Setup:**
- Create ObjectStore resource with S3 destination path and credentials
- Add plugins section to Cluster spec referencing the ObjectStore
- Create ScheduledBackup with plugin method and barman-cloud configuration
- Add backup labels: `recurring-job.longhorn.io/source: enabled` and tier label (`gfs` or `daily`)

**Backup Tier Guidelines:**
- **GFS (Grandfather-Father-Son):** Critical databases needing point-in-time recovery
- **Daily:** Standard applications with daily retention
- **None:** Caches, ephemeral data

### Destructive Action Protocol

**Never Delete Without Evidence**

- **Never delete a Job, Pod, or PVC to "fix" a config error** unless you have proof via logs that the resource is in an unrecoverable state or holding stale configuration.
- **Required evidence before deletion:**
  ```bash
  # Check Pod logs
  kubectl logs <pod-name> -n <namespace>

  # Check Pod events and configuration
  kubectl describe pod <pod-name> -n <namespace>

  # Check Job status (if applicable)
  kubectl describe job <job-name> -n <namespace>
  ```
- **Blindly deleting resources masks the root cause.** If a resource is failing, identify why it's failing first. Common non-destructive fixes:
  - Update the manifest and re-apply (for Deployments, StatefulSets).
  - Delete and recreate only ConfigMaps or Secrets that have changed.
  - Use `kubectl rollout restart` for Deployments/StatefulSets when only env vars or mounts changed.

### Resource Identification & Migration

**Distinguishing Old vs. New Resources**

- **When migrating infrastructure** (e.g., Zalando Postgres → CNPG), use labels and metadata to distinguish resources:
  ```bash
  # Check resource ownership
  kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.metadata.ownerReferences}'

  # Check resource age
  kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.metadata.creationTimestamp}'

  # Check resource labels
  kubectl get pod <pod-name> -n <namespace> --show-labels
  ```
- **Do not assume a "Running" pod belongs to the new system** without verifying its controller reference and creation timestamp.

---
# Kubernetes Infrastructure - Agent Guidelines

This document provides guidance for agents working with the Kubernetes infrastructure in this repository.

## Longhorn Backup Strategy

### Overview
Our cluster uses Longhorn with a label-based backup approach. **PVCs without backup labels are NOT backed up.**

### Backup Tiers

- **GFS (Grandfather-Father-Son)**: For critical databases and stateful apps
  - Hourly backups: retained 48 (2 days)
  - Daily backups: retained 14 (2 weeks)
  - Weekly backups: retained 8 (2 months)
  - Label: `recurring-job-group.longhorn.io/gfs=enabled`

- **Daily**: For standard applications
  - Daily backups at 2 AM: retained 14 (2 weeks)
  - Label: `recurring-job-group.longhorn.io/daily=enabled`

- **None**: For caches, temp data, ephemeral storage
  - No labels = no backups

### Applying Backups to PVCs

All PVCs require the source label plus the tier label:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-data
  labels:
    recurring-job.longhorn.io/source: enabled  # Required for PVC sync
    recurring-job-group.longhorn.io/gfs: enabled  # OR "daily" OR omit entirely
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
```

### Decision Guide

| Workload | Tier | Rationale |
|----------|------|-----------|
| Postgres, MySQL, MongoDB | `gfs` | Critical data, need point-in-time recovery |
| GitLab, Vault, Keycloak | `gfs` | Configuration/state is critical |
| Harbor, Nexus | `daily` | Important but not time-critical |
| RabbitMQ, Kafka | `daily` | Can replay messages |
| Prometheus, Loki | `daily` or none | Metrics are replaceable |
| Redis (cache), temp storage | none | Ephemeral data |

### Important Notes

- Backups are stored in S3 (`s3://longhorn@us-west-1/`)
- GFS volumes will have ~70 backups in S3 (hourly + daily + weekly)
- Daily volumes will have ~14 backups in S3
- Unlabeled volumes consume **zero S3 storage**
- Snapshot cleanup runs every 6 hours to prevent snapshot buildup

### Verifying PVC Backup Status

Before applying changes, check what would change:

```bash
# List all PVCs and their current backup status
kubectl get pvc --all-namespaces -o json | \
  jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name): \(.metadata.labels["recurring-job-group.longhorn.io/gfs"] // .metadata.labels["recurring-job-group.longhorn.io/daily"] // "NO BACKUP")"'
```

This shows which PVCs would lose backups after applying changes (if they relied on the old "default" group).

### RecurringJob Configuration

The backup jobs are defined in [k8s/infrastructure/storage/longhorn/recurringjob.yaml](../infrastructure/storage/longhorn/recurringjob.yaml). Each job targets a specific group (`gfs` or `daily`), and retention policies scale appropriately:

- More frequent backups = shorter retention (e.g., hourly keeps 48, daily keeps 14)
- Less frequent backups = longer retention (e.g., weekly keeps 8)
- Snapshot cleanup runs across all groups to prevent temporary snapshot accumulation

