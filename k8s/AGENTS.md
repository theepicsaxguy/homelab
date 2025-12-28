# Kubernetes Infrastructure - Agent Guidelines

This document provides guidance for agents working with Kubernetes infrastructure in this repository. It is a scoped
`AGENTS.md` meant to be authoritative source for anything under `k8s/`.

## Purpose & Scope

- Scope: `k8s/` (all files and subdirectories). Use this file as primary reference for Kubernetes manifests,
   kustomize, Argo CD ApplicationSets, and operational patterns.
- Goal: enable an agent to validate, extend, and reason about Kubernetes manifests and operational policies without
   external tools or secrets.


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

- `k8s/applications/` — user-facing apps organized by category (e.g., `ai/`, `media/`, `web/`). Each app should have its
  own `kustomization.yaml`.
  - Active categories: `ai/`, `automation/`, `external/`, `media/`, `network/`, `tools/`, `web/`
  - Category-level AGENTS.md template available: `k8s/applications/AGENTS-TEMPLATE.md`
  - Create category-level AGENTS.md when categories develop unique patterns (5+ apps, shared resources, or special
    workflows)
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

## Storage

### StorageClasses

The cluster has multiple storage classes available:

- **`proxmox-csi`** (Primary, `csi.proxmox.sinextra.dev`) — **Use this for all new workloads**. Provides dynamic
  provisioning directly from Proxmox Nvme1 ZFS datastore.

  - Reclaim Policy: `Retain`
  - Volume Binding Mode: `WaitForFirstConsumer` (binds when pod is scheduled)
  - Supports volume expansion: Yes
  - Backend: Proxmox datastore with direct ZFS volumes
  - Configuration: `k8s/infrastructure/storage/proxmox-csi/`

- **`longhorn`** (Legacy, `driver.longhorn.io`) — Default storage class for existing workloads. Being phased out for new
  applications.

  - Reclaim Policy: `Retain`
  - Supports replicated storage across nodes
  - Use only for legacy apps that require Longhorn-specific features

- **`longhorn-static`** (Legacy) — Static provisioning for manually-created Longhorn volumes

### When to Use Each StorageClass

**Use `proxmox-csi` for:**

- All new applications and databases
- Single-node stateful workloads (most common case)
- Direct high-performance storage access

**Use `longhorn` only for:**

- Existing workloads already using it (migration pending)
- Workloads requiring replicated storage across multiple nodes
- Applications with existing backup jobs configured in Longhorn

### Creating PersistentVolumeClaims

For new applications, always specify `storageClassName: proxmox-csi`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
  namespace: my-namespace
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-csi # Always use proxmox-csi for new workloads
  resources:
    requests:
      storage: 10Gi
```

## Backups

### Longhorn Backup Strategy (for `longhorn` StorageClass only)

**Note:** Longhorn backup rules **only apply to volumes using the `longhorn` StorageClass**. PVCs using `proxmox-csi`
StorageClass are automatically backed up via Velero (see Velero Backup Strategy section below).

See the repository-level `k8s/AGENTS.md` Longhorn section for label-based backup rules. Key rule: PVCs without backup
labels are not backed up. Use labels `recurring-job.longhorn.io/source: enabled` plus group label
`recurring-job-group.longhorn.io/gfs=enabled` or `.../daily=enabled`.

### Velero Backup Strategy (for `proxmox-csi` StorageClass)

**Overview:** Velero automatically backs up all resources in all namespaces via namespace-based schedules. PVCs using
`proxmox-csi` StorageClass are automatically included via CSI snapshots - **no annotations or labels needed**.

**Velero Schedules:**

- `velero-daily`: Daily backups at 02:00, 14-day TTL
- `velero-gfs`: Hourly backups for GFS tier, 14-day TTL
- `velero-weekly`: Weekly backups on Sundays at 03:00, 28-day TTL

All schedules are configured in `k8s/infrastructure/controllers/velero/schedules/` and include all namespaces by default
(except the `velero` namespace itself).

**Opt-Out Approach:**

- By default, all PVCs in all namespaces are backed up automatically
- To exclude specific volumes from backup, annotate the pod with `backup.velero.io/exclude-from-backup: "true"` or use
  `backup.velero.io/backup-volumes-excludes` to exclude specific volume names
- No annotations needed on PVCs themselves unless you want to specify a custom `VolumeSnapshotClass` via
  `velero.io/csi-volumesnapshot-class`

**Best Practices:**

- PVCs using `proxmox-csi` are automatically backed up - no configuration needed
- Use pod-level annotations only if you need to exclude specific volumes (e.g., cache, temp data)
- For critical workloads, ensure they're included in the appropriate Velero schedule (daily, gfs, or weekly)

## How to Add an Application

1. Create `k8s/applications/<category>/<app>/` and add `kustomization.yaml` and manifests.
2. Ensure `k8s/applications/<category>/kustomization.yaml` references the new app.
3. Test locally with `kustomize build --enable-helm k8s/applications/<category>/<app>` and inspect output.
4. Create a PR. Do not apply changes directly to cluster.

## Testing Manifests

- Unit: Validate that each `kustomization.yaml` builds without error.
- Integration: `kustomize build` for parent directories (`k8s/applications` and `k8s/infrastructure`) and run `kubeval`
  or CI validators.
- CI: PRs should include `kustomize build --enable-helm` in their CI step (see repo workflows for examples).

## Boundaries & Safety

- Do not hardcode secrets in manifests. Use ExternalSecrets/SecretProvider references.
- Do not change `k8s/infrastructure/application-set.yaml` without review — it affects discovery and sync ordering.
- Do not modify CRD definitions unless you understand operator compatibility.

## Kubernetes-Specific Operational Rules

### Secret Management & References

**Auto-Generated Secret Names**

- **When using operators that auto-generate secrets** (like CloudNativePG/CNPG), verify the generated secret name before
  referencing it in applications. Operators often append suffixes like `-app`, `-superuser`, or `-owner`.
- **Always query the cluster** to confirm the exact secret name:
  ```bash
  kubectl get secrets -n <namespace> | grep <cluster-name>
  ```
- **Before updating `kustomization.yaml` or Deployment manifests** with a secret reference, decode the secret to verify
  its structure and keys:
  ```bash
  kubectl get secret <secret-name> -n <namespace> -o jsonpath='{.data}' | jq 'keys'
  ```

### Operator & CRD Logic

**Connection Secrets & Endpoints**

- **Check for existing connection secrets or endpoints** before creating new ones. For backup/objectStore configuration
  (e.g., MinIO/S3 for CNPG or Longhorn), search for existing secrets:
  ```bash
  kubectl get secrets -n <namespace> | grep -E 'minio|s3|backup'
  ```
- **Decode existing secrets** to verify endpoint URLs and credentials rather than assuming `localhost` or default
  values:
  ```bash
  kubectl get secret <secret-name> -n <namespace> -o jsonpath='{.data.MINIO_ENDPOINT}' | base64 -d
  ```

**Bitwarden Secrets Manager Pattern (Critical)**

- **Bitwarden Secrets Manager (NOT the vault)** only supports `name` and `value` fields - no `property` or custom fields
- **Always create separate Bitwarden Secrets Manager entries** for each secret value needed:
  - Pattern: `<app-name>-<purpose>` (e.g., `backblaze-b2-velero-access-key-id`)
  - Never use `property` field in `remoteRef` - only `key`
  - Example: See `k8s/applications/ai/litellm/litellm-secrets.yaml` for correct pattern
- **Bitwarden Vault custom fields work differently** - if using vault with custom fields, reference via `property` but this requires
  Bitwarden Vault, not Secrets Manager

**ExternalSecret Template Configuration (Bitwarden Secrets Manager)**

When configuring ExternalSecrets with Bitwarden Secrets Manager backend:

- **Must use `engineVersion: v2`** under `spec.target.template`:
  ```yaml
  apiVersion: external-secrets.io/v1
  kind: ExternalSecret
  spec:
    target:
      template:
        engineVersion: v2  # REQUIRED for Bitwarden Secrets Manager
        data:
          cloud: |
            [default]
              aws_access_key_id={{ .B2_ACCESS_KEY_ID }}
  data:
    - secretKey: AWS_ACCESS_KEY_ID
      remoteRef:
        key: backblaze-b2-velero-access-key-id  # NO 'property' field
  ```
- **Critical: Template indentation must be under `target:`**, not under `spec:`
- **Multiple secret keys**: Create separate Bitwarden Secrets Manager entries for each (access-key-id, secret-access-key, password, etc.)

**Velero Configuration (Kopia Data Mover)**

- **Kopia is now the primary data mover** - Restic is deprecated (Velero 1.15+)
- **Configuration**: `uploaderType: kopia` in Velero Helm values
- **Node Agent hostPath access is required and expected**:
  - PodSecurity warning `would violate PodSecurity "baseline:latest": hostPath volumes` is expected behavior
  - Velero node-agent needs access to `/var/lib/kubelet/pods` for file system backups
- **Repository password**: Required for Kopia client-side encryption (defense in depth with B2 SSE-B2 server-side encryption)

**Velero CRDs (Restic vs Kopia)**

When working with Velero manifests, be aware of the CRD migration:

- **Legacy (deprecated)**: `resticrepositories.velero.io`
- **Modern (Kopia)**:
  - `backuprepositories.velero.io` - Manages Kopia backup repositories (per namespace)
  - `podvolumebackups.velero.io` - File system backup operations
  - `podvolumerestores.velero.io` - File system restore operations
- **Exclude from backups**: Use modern CRD names in Schedule manifests:
  ```yaml
  excludedResources:
    - backuprepositories.velero.io
    - podvolumebackups.velero.io
    - podvolumerestores.velero.io
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

**Alternative: ExternalSecrets (Non-Circular Pattern)**

- If you MUST use Bitwarden Secrets Manager for CNPG credentials (not recommended):
  - Create **separate Bitwarden entries** for each secret key (no `property` field)
  - Pattern: `<cluster-name>-<purpose>-<key-name>` (e.g., `immich-db-password`, `immich-db-user`)
  - Example ExternalSecret:
    ```yaml
    data:
      - secretKey: password
        remoteRef:
          key: immich-db-password  # Separate entry for each key
      - secretKey: username
        remoteRef:
          key: immich-db-user
    ```

**Common Anti-Pattern (Avoid):**

- Using ExternalSecrets to create CNPG app secrets creates circular dependencies
- CNPG clusters fail to initialize because they expect the secret to exist before they can create it
- Always remove `bootstrap.initdb.secret` references and let CNPG auto-generate credentials

**Correct Pattern:**

- Omit `bootstrap.initdb.secret` from Cluster manifests
- CNPG will automatically create `<cluster-name>-app` secret with random credentials
- Applications reference the auto-generated secret directly

**Barman Cloud Backup Setup**

CNPG uses the official plugin-based backup architecture with dual backup destinations for redundancy:

**Dual Backup Architecture:**

1. **Local MinIO (Fast Recovery)**
   - Destination: `s3://homelab-postgres-backups/<namespace>/<cluster-name>`
   - Endpoint: `https://truenas.peekoff.com:9000`
   - Purpose: Quick restores from local NAS
   - Retention: Managed by backup job schedules

2. **Backblaze B2 (Disaster Recovery)**
   - Destination: `s3://homelab-cnpg-b2/<namespace>/<cluster-name>`
   - Endpoint: `https://s3.us-west-000.backblazeb2.com`
   - Purpose: Offsite disaster recovery
   - Retention: 30 days (configurable per cluster)

**Required Components:**

- **ObjectStore resources** (2 per cluster):
   - One for local MinIO (e.g., `<cluster-name>-minio-store`)
   - One for Backblaze B2 (e.g., `<cluster-name>-b2-store`)
- **ExternalSecret for B2 credentials** (Bitwarden Secrets Manager):
   - Create **separate Bitwarden Secrets Manager entries** for each secret (one per key):
     - `backblaze-b2-cnpg-access-key-id` → AWS_ACCESS_KEY_ID
     - `backblaze-b2-cnpg-secret-access-key` → AWS_SECRET_ACCESS_KEY
   - Pattern: `<purpose>-<app-name>-<key-name>` (no `property` field with Secrets Manager)
- **Cluster plugins section**:
   - Uses `barman-cloud.cloudnative-pg.io` plugin with `isWALArchiver: true`
   - References B2 ObjectStore for continuous WAL archiving to offsite

- **Cluster backup.barmanObjectStore section**:
  - Configured for Backblaze B2 (primary offsite backup)
  - Includes WAL and data compression (gzip) and encryption (AES256)
  - Retention policy: 30 days (adjustable per cluster)

- **ScheduledBackup resource**:
  - Method: `plugin` with `barman-cloud.cloudnative-pg.io`
  - Schedule: Weekly on Sundays at 02:00 (`0 0 2 * * 0`)
  - Triggers base backup to B2 via plugin architecture
  - WAL archiving runs continuously via plugin configuration

- **Cluster externalClusters section** (for recovery):
  - Defines both B2 and MinIO backup locations as external clusters
  - Enables point-in-time recovery from either destination

**Complete Backup Setup Pattern:**

```yaml
# 1. ExternalSecret for B2 credentials
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: b2-cnpg-credentials
  namespace: <namespace>
spec:
  secretStoreRef:
    name: bitwarden-backend
    kind: ClusterSecretStore
  target:
    name: b2-cnpg-credentials
  data:
    - secretKey: AWS_ACCESS_KEY_ID
      remoteRef:
        key: backblaze-b2-cnpg-offsite
        property: AWS_ACCESS_KEY_ID
    - secretKey: AWS_SECRET_ACCESS_KEY
      remoteRef:
        key: backblaze-b2-cnpg-offsite
        property: AWS_SECRET_ACCESS_KEY

---
# 2. Local MinIO ObjectStore
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: <cluster-name>-minio-store
  namespace: <namespace>
spec:
  configuration:
    destinationPath: s3://homelab-postgres-backups/<namespace>/<cluster-name>
    endpointURL: https://truenas.peekoff.com:9000
    s3Credentials:
      accessKeyId:
        name: longhorn-minio-credentials
        key: AWS_ACCESS_KEY_ID
      secretAccessKey:
        name: longhorn-minio-credentials
        key: AWS_SECRET_ACCESS_KEY

---
# 3. Backblaze B2 ObjectStore
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: <cluster-name>-b2-store
  namespace: <namespace>
spec:
  configuration:
    destinationPath: s3://homelab-cnpg-b2/<namespace>/<cluster-name>
    endpointURL: https://s3.us-west-000.backblazeb2.com
    s3Credentials:
      accessKeyId:
        name: b2-cnpg-credentials
        key: AWS_ACCESS_KEY_ID
      secretAccessKey:
        name: b2-cnpg-credentials
        key: AWS_SECRET_ACCESS_KEY

---
# 4. Cluster with plugin configuration
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: <cluster-name>
  namespace: <namespace>
spec:
  plugins:
  - name: barman-cloud.cloudnative-pg.io
    isWALArchiver: true
    parameters:
      barmanObjectName: <cluster-name>-b2-store

  backup:
    barmanObjectStore:
      destinationPath: s3://homelab-cnpg-b2/<namespace>/<cluster-name>
      endpointURL: https://s3.us-west-000.backblazeb2.com
      s3Credentials:
        accessKeyId:
          name: b2-cnpg-credentials
          key: AWS_ACCESS_KEY_ID
        secretAccessKey:
          name: b2-cnpg-credentials
          key: AWS_SECRET_ACCESS_KEY
      wal:
        compression: gzip
        encryption: AES256
      data:
        compression: gzip
        encryption: AES256
        jobs: 2
    retentionPolicy: "30d"

  externalClusters:
    - name: <cluster-name>-b2-backup
      barmanObjectStore:
        destinationPath: s3://homelab-cnpg-b2/<namespace>/<cluster-name>
        endpointURL: https://s3.us-west-000.backblazeb2.com
        s3Credentials:
          accessKeyId:
            name: b2-cnpg-credentials
            key: AWS_ACCESS_KEY_ID
          secretAccessKey:
            name: b2-cnpg-credentials
            key: AWS_SECRET_ACCESS_KEY
        wal:
          compression: gzip
          encryption: AES256
    - name: <cluster-name>-minio-backup
      barmanObjectStore:
        destinationPath: s3://homelab-postgres-backups/<namespace>/<cluster-name>
        endpointURL: https://truenas.peekoff.com:9000
        s3Credentials:
          accessKeyId:
            name: longhorn-minio-credentials
            key: AWS_ACCESS_KEY_ID
          secretAccessKey:
            name: longhorn-minio-credentials
            key: AWS_SECRET_ACCESS_KEY
        wal:
          compression: gzip
          encryption: AES256

---
# 5. ScheduledBackup (weekly to B2)
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:
  name: <cluster-name>-backup
  namespace: <namespace>
spec:
  schedule: "0 0 2 * * 0"
  backupOwnerReference: self
  cluster:
    name: <cluster-name>
  method: plugin
  pluginConfiguration:
    name: barman-cloud.cloudnative-pg.io
```

**Key Configuration Details:**

- **Plugin handles WAL archiving**: Continuous WAL shipping to B2 via `plugins` section
- **ScheduledBackup triggers base backups**: Weekly full backups to B2 via plugin
- **Compression & encryption**: Both WAL and data backups use gzip compression and AES256 encryption
- **Retention policy**: 30 days of backups retained in B2 (adjust per cluster requirements)
- **Recovery options**: Can restore from either B2 or MinIO via `externalClusters` definitions

**Backup Tier Guidelines:**

- **All CNPG clusters** should have both MinIO and B2 backup destinations configured
- **Weekly base backups** to B2 provide disaster recovery coverage
- **Continuous WAL archiving** to B2 enables point-in-time recovery
- **MinIO backups** provide fast local restore option for non-disaster scenarios

### Destructive Action Protocol

**Never Delete Without Evidence**

- **Never delete a Job, Pod, or PVC to "fix" a config error** unless you have proof via logs that the resource is in an
  unrecoverable state or holding stale configuration.
- **Required evidence before deletion:**

  ```bash
  # Check Pod logs
  kubectl logs <pod-name> -n <namespace>

  # Check Pod events and configuration
  kubectl describe pod <pod-name> -n <namespace>

  # Check Job status (if applicable)
  kubectl describe job <job-name> -n <namespace>
  ```

- **Blindly deleting resources masks the root cause.** If a resource is failing, identify why it's failing first. Common
  non-destructive fixes:
  - Update the manifest and re-apply (for Deployments, StatefulSets).
  - Delete and recreate only ConfigMaps or Secrets that have changed.
  - Use `kubectl rollout restart` for Deployments/StatefulSets when only env vars or mounts changed.

### Resource Identification & Migration

**Distinguishing Old vs. New Resources**

- **When migrating infrastructure** (e.g., between database operators), use labels and metadata to distinguish
  resources:

  ```bash
  # Check resource ownership
  kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.metadata.ownerReferences}'

  # Check resource age
  kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.metadata.creationTimestamp}'

  # Check resource labels
  kubectl get pod <pod-name> -n <namespace> --show-labels
  ```

- **Do not assume a "Running" pod belongs to the new system** without verifying its controller reference and creation
  timestamp.

---

# Kubernetes Infrastructure - Agent Guidelines

This document provides guidance for agents working with the Kubernetes infrastructure in this repository.

## Longhorn Backup Strategy

**Note:** This section applies **only to PVCs using the `longhorn` StorageClass**. PVCs using `proxmox-csi` StorageClass
are automatically backed up via Velero (see Velero Backup Strategy section below).

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
    recurring-job.longhorn.io/source: enabled # Required for PVC sync
    recurring-job-group.longhorn.io/gfs: enabled # OR "daily" OR omit entirely
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
```

### Decision Guide

| Workload                    | Tier            | Rationale                                  |
| --------------------------- | --------------- | ------------------------------------------ |
| Postgres, MySQL, MongoDB    | `gfs`           | Critical data, need point-in-time recovery |
| GitLab, Vault, Keycloak     | `gfs`           | Configuration/state is critical            |
| Harbor, Nexus               | `daily`         | Important but not time-critical            |
| RabbitMQ, Kafka             | `daily`         | Can replay messages                        |
| Prometheus, Loki            | `daily` or none | Metrics are replaceable                    |
| Redis (cache), temp storage | none            | Ephemeral data                             |

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

The backup jobs are defined in
[k8s/infrastructure/storage/longhorn/recurringjob.yaml](../infrastructure/storage/longhorn/recurringjob.yaml). Each job
targets a specific group (`gfs` or `daily`), and retention policies scale appropriately:

- More frequent backups = shorter retention (e.g., hourly keeps 48, daily keeps 14)
- Less frequent backups = longer retention (e.g., weekly keeps 8)
- Snapshot cleanup runs across all groups to prevent temporary snapshot accumulation

### Troubleshooting Disk Expansion Issues

If Longhorn fails to recognize expanded disk space after increasing node disk capacity, check the `node.longhorn.io`
objects for missing `spec.name` field. This field is required for the node controller to sync disk status.

**Symptoms:**

- Disk expansion at OS level successful
- Longhorn UI shows old disk capacity
- Manager logs show:
  `"failed to sync node for longhorn-system/<node>: no node name provided to check node down or deleted"`

**Resolution:**

1. Identify affected nodes: `kubectl get node.longhorn.io -n longhorn-system`
2. Check if `spec.name` is missing: `kubectl get node.longhorn.io <node> -n longhorn-system -o yaml`
3. If missing, edit the resource: `kubectl edit node.longhorn.io <node> -n longhorn-system`
4. Add under `spec:`: `name: <node>` (matching `metadata.name`)
5. Save and verify disk status updates automatically

**Prevention:** Ensure `spec.name` is always present in `node.longhorn.io` objects. This is a known issue with
enhancement request for validation (longhorn/longhorn#6793).

## Velero Backup Strategy

### Overview

Velero automatically backs up all resources in all namespaces via namespace-based schedules. **PVCs using `proxmox-csi`
StorageClass are automatically included via CSI snapshots - no annotations or labels needed.**

### Velero Schedules

The cluster has three Velero schedules configured in `k8s/infrastructure/controllers/velero/schedules/`:

- **`velero-daily`**: Daily backups at 02:00, 14-day TTL
- **`velero-gfs`**: Hourly backups for GFS tier, 14-day TTL
- **`velero-weekly`**: Weekly backups on Sundays at 03:00, 28-day TTL

All schedules include all namespaces by default (except `velero` namespace itself) and back up all resources
including PVCs.

**Velero Data Mover: Kopia (2025 Best Practices)**

- Velero uses **Kopia** as primary data mover for file system backups
- Restic is deprecated (Velero 1.15+)
- Repository password encrypts backup data client-side (defense in depth with B2 SSE-B2 server-side encryption)
- See: `k8s/infrastructure/controllers/velero/values.yaml` (uploaderType: kopia)

### Automatic Backup for proxmox-csi Volumes

- **No configuration needed**: PVCs using `proxmox-csi` StorageClass are automatically backed up via Velero CSI
  snapshots
- **No annotations or labels required** on PVCs - Velero schedules include all resources in all namespaces
- Volume snapshots are created automatically during backup operations

### Opt-Out Approach

If you need to exclude specific volumes from backup:

- **Exclude entire pod volumes**: Add annotation `backup.velero.io/exclude-from-backup: "true"` to the pod
- **Exclude specific volumes**: Add annotation `backup.velero.io/backup-volumes-excludes: "volume-name"` to the pod
  (comma-separated for multiple volumes)
- **Custom VolumeSnapshotClass**: Add annotation `velero.io/csi-volumesnapshot-class: "class-name"` to the PVC if you
  need a specific snapshot class

### Best Practices

- **Default behavior**: All `proxmox-csi` PVCs are automatically backed up - no action needed
- **Exclude only when necessary**: Use pod-level annotations only for volumes that shouldn't be backed up (e.g., cache,
  temp data, ephemeral storage)
- **Storage class selection**: Use `proxmox-csi` for new workloads to get automatic Velero backups; use `longhorn` only
  for legacy workloads or when Longhorn-specific features are needed

## Pre-Merge Checklist

Before merging Kubernetes manifest changes, verify:

- [ ] All kustomizations build successfully: `kustomize build --enable-helm k8s/applications` and
       `kustomize build --enable-helm k8s/infrastructure`
- [ ] No hardcoded secrets in manifests (use ExternalSecrets/SecretProvider)
- [ ] PVCs have appropriate backup configuration:
   - For `longhorn` StorageClass: backup labels (`recurring-job.longhorn.io/source` + tier label)
   - For `proxmox-csi` StorageClass: automatically backed up by Velero (no labels needed)
- [ ] Resources have appropriate requests/limits for → workload
- [ ] Network policies allow required traffic patterns
- [ ] HTTPRoutes/Ingress configs follow security best practices (auth, CORS)
- [ ] Deployment/StatefulSet follows non-root container patterns
- [ ] Changes to ApplicationSet or CRDs have been reviewed by infra team
- [ ] Database credentials use auto-generated secrets (for CNPG) or verified ExternalSecrets
- [ ] Backup tier matches criticality: GFS for critical data, Daily for standard apps, None for ephemeral
- [ ] **Velero uses Kopia data mover**: `uploaderType: kopia` configured (not deprecated Restic)
- [ ] **ExternalSecrets use correct backend pattern**:
   - Bitwarden Secrets Manager: No `property` field, separate secrets for each key
   - Bitwarden Vault: Custom fields allowed, use `property` in `remoteRef`
- [ ] **ExternalSecret templates use `engineVersion: v2`** (required for Bitwarden Secrets Manager)
- [ ] **Template indented under `spec.target.template:`** (not under `spec:`)
- [ ] Changes tested locally and validated against cluster (if access available)
