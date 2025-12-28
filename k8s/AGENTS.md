# Kubernetes Infrastructure - Domain Guidelines

SCOPE: Kubernetes manifests, operators, and GitOps patterns
INHERITS FROM: ../AGENTS.md
TECHNOLOGIES: Kubernetes, Kustomize, Helm, Argo CD, CNPG, Velero, Longhorn, Proxmox CSI

## DOMAIN CONTEXT

Purpose:
Define and manage all Kubernetes resources for the homelab cluster, including applications, infrastructure components, storage, networking, and authentication.

Boundaries:
- Handles: All Kubernetes manifests, Argo CD ApplicationSets, operator CRDs, storage classes, and network policies
- Does NOT handle: VM provisioning, network infrastructure (see tofu/), container image building (see images/)
- Integrates with: tofu/ (cluster bootstrapping), images/ (container images), website/ (documentation)

Architecture:
- `k8s/applications/` - User-facing applications organized by category (ai, media, web, automation, etc.)
- `k8s/infrastructure/` - Core infrastructure components (controllers, network, storage, auth, database)
- `k8s/application-set.yaml` - Argo CD ApplicationSet for automatic resource discovery
- GitOps workflow: Argo CD syncs manifests from this directory to the cluster

## QUICK-START COMMANDS

```bash
# Build and validate any kustomization
kustomize build --enable-helm k8s/applications/<category>/<app>
kustomize build --enable-helm k8s/infrastructure/<component>

# Build top-level applications or infrastructure
kustomize build --enable-helm k8s/applications
kustomize build --enable-helm k8s/infrastructure

# Validate generated YAML
kustomize build k8s/applications | yq eval -P -
kustomize build k8s/applications | kubeval --strict --ignore-missing-schemas
```

## TECHNOLOGY CONVENTIONS

### Kustomize
- Use `--enable-helm` flag when kustomizations pull in Helm charts
- Set `generatorOptions.disableNameSuffixHash: true` for stable resource names
- Organize overlays by environment or configuration variant

### Argo CD ApplicationSets
- Auto-discover directories via git generator pattern
- Infrastructure applications sync before applications (use sync waves if needed)
- Reference: `k8s/application-set.yaml`

### Resource Naming
- Follow Kubernetes conventions: lowercase DNS-compliant names
- Use descriptive prefixes for related resources: `<app>-<component>` (e.g., `immich-postgresql`)
- Namespace names match application directories where possible

## PATTERNS

### Storage Pattern
New workloads use `proxmox-csi` StorageClass for dynamic provisioning from Proxmox Nvme1 ZFS datastore. Legacy workloads use `longhorn` StorageClass with replicated volumes. Always specify `storageClassName` in PVCs.

### Secret Management Pattern
External Secrets Operator syncs secrets from Bitwarden Secrets Manager into Kubernetes. Create separate Bitwarden entries for each secret value (no `property` field). Use `engineVersion: v2` under `spec.target.template` and indent templates correctly under `spec.target.template:`, not `spec:`.

### GitOps Pattern
All changes go through Git. Argo CD auto-syncs manifests from `k8s/` to cluster. Never apply changes directly via `kubectl apply`. Validate manifests with `kustomize build` before committing.

### Operator Pattern
Operators manage complex stateful workloads (CNPG for databases, Longhorn for storage, Velero for backups). Define operator CRDs in manifests. Let operators reconcile state automatically. Query operator status before making changes.

## TESTING

Strategy:
- Local validation: `kustomize build --enable-helm` to compile manifests
- Schema validation: `kubeval --strict` if available, or manual inspection
- Operator validation: Check CRD schemas with `kubectl explain <resource>.<field>`

Requirements:
- All kustomizations must build without errors
- No hardcoded secrets in manifests
- PVCs must specify storage classes and have appropriate backup labels

Tools:
- kustomize: Build and validate manifests
- yq: Inspect and manipulate YAML
- kubeval: Validate against Kubernetes schemas (optional)
- kubectl: Query cluster state and CRD schemas

## WORKFLOWS

Development:
- Create or modify manifests in `k8s/applications/<category>/<app>/` or `k8s/infrastructure/<component>/`
- Test locally: `kustomize build --enable-helm k8s/applications/<category>/<app>`
- Add new apps: Create directory, add `kustomization.yaml`, update parent kustomization
- Commit changes: Use conventional commits with `k8s` or `infra` scope

Build:
- `kustomize build --enable-helm` for kustomizations with Helm charts
- `kustomize build` for pure Kustomize configurations
- Inspect output: Pipe to `yq` or save to file for review

Deployment:
- All deployments happen via GitOps through Argo CD
- Create PR with changes
- Argo CD auto-syncs when changes merge to main branch
- Monitor sync status in Argo CD UI or via `kubectl get application`

## COMPONENTS

### Infrastructure Components
- `auth/`: Authentication services (Authentik SSO)
- `controllers/`: Cluster operators (Argo CD, Velero, Kubechecks)
- `crd/`: Custom Resource Definitions for operators
- `database/`: Database operators (CloudNativePG)
- `deployment/`: Deployment utilities (Kubechecks)
- `monitoring/`: Monitoring stack (Hubble)
- `network/`: Network policies and CNI (Cilium)
- `storage/`: Storage providers (Longhorn, Proxmox CSI)

### Application Categories
- `ai/`: AI/ML applications (see k8s/applications/ai/AGENTS.md for details)
- `automation/`: Home automation (Home Assistant, Frigate, MQTT, Zigbee2MQTT)
- `external/`: External service proxies (Proxmox, TrueNAS)
- `media/`: Media management (Jellyfin, Immich, arr-stack, Audiobookshelf)
- `network/`: Network services (Unifi)
- `tools/`: Utility applications (IT-Tools, Unrar)
- `web/`: Web applications (BabyBuddy, HeadlessX, Pinepods)

## ANTI-PATTERNS

Never hardcode secrets or credentials in manifests. Use ExternalSecrets Operator to sync from Bitwarden.

Never apply changes directly to cluster with `kubectl apply` for permanent changes. All changes must go through GitOps.

Never delete resources (Pods, PVCs, Jobs) without evidence from logs and events. Diagnose root cause before taking destructive action.

Never guess resource names or secret keys. Query the cluster to verify: `kubectl get secret <name> -n <namespace>`, `kubectl get service <name> -n <namespace>`.

Never modify CRD definitions without understanding operator compatibility. Fetch official CRD documentation before making changes.

Never use `latest` tags for container images. Pin to specific versions for reproducibility.

Never skip backup configuration. PVCs using `longhorn` require backup labels. PVCs using `proxmox-csi` are automatically backed up by Velero.

Never create circular dependencies with ExternalSecrets for CNPG databases. Let CNPG auto-generate credentials (`<cluster-name>-app` secret).

Never use `property` field with Bitwarden Secrets Manager. Create separate Bitwarden entries for each secret value.

## STORAGE CLASSES

### Proxmox CSI (Primary)
Use `storageClassName: proxmox-csi` for all new workloads. Provides dynamic provisioning from Proxmox Nvme1 ZFS datastore. Supports volume expansion. PVCs are automatically backed up by Velero CSI snapshots (no annotations needed).

### Longhorn (Legacy)
Use `storageClassName: longhorn` only for existing workloads requiring replicated storage across nodes. PVCs require backup labels: `recurring-job.longhorn.io/source: enabled` plus tier label (`recurring-job-group.longhorn.io/gfs=enabled` for critical data, `.../daily=enabled` for standard apps).

## BACKUP STRATEGY

### Longhorn Backups (legacy storage only)
Apply backup tier labels to PVCs:
- GFS (Grandfather-Father-Son): Critical databases and stateful apps with hourly/daily/weekly backups
- Daily: Standard applications with daily backups retained 14 days
- None: Caches, temp data, ephemeral storage (no labels)

### Velero Backups (proxmox-csi storage)
All PVCs using `proxmox-csi` are automatically backed up via Velero CSI snapshots. Velero schedules:
- `velero-daily`: Daily backups at 02:00, 14-day TTL
- `velero-gfs`: Hourly backups for GFS tier, 14-day TTL
- `velero-weekly`: Weekly backups on Sundays at 03:00, 28-day TTL

Exclude volumes from backup with pod annotations:
- `backup.velero.io/exclude-from-backup: "true"` (exclude entire pod)
- `backup.velero.io/backup-volumes-excludes: "volume-name"` (exclude specific volumes)

### CNPG Database Backups
CloudNativePG databases use dual backup destinations:
- Local MinIO (fast recovery from NAS)
- Backblaze B2 (offsite disaster recovery, 30-day retention)
- Scheduled backups weekly on Sundays at 02:00
- Continuous WAL archiving to B2 for point-in-time recovery

## DATABASE PATTERNS

### CNPG Auto-Generated Credentials (Preferred)
Omit `bootstrap.initdb.secret` from Cluster manifests. CNPG automatically creates `<cluster-name>-app` secret containing username, password, dbname, host, port, uri. Applications reference this secret directly.

### CNPG Backup Configuration
All CNPG clusters require:
- Two ObjectStore resources: One for local MinIO, one for Backblaze B2
- ExternalSecret for B2 credentials (separate Bitwarden entries for access-key-id and secret-access-key)
- Cluster plugin configuration for WAL archiving to B2
- ScheduledBackup resource (weekly to B2 via plugin architecture)
- ExternalClusters definitions for both MinIO and B2 recovery paths

## CRITICAL BOUNDARIES

Never commit secrets or credential material to Git.

Never modify CRD definitions without consulting official documentation.

Never apply changes directly to cluster—use GitOps.

Never delete resources without evidence from logs and events.

Never guess resource names or secret keys—query cluster first.

Never skip backup configuration for stateful workloads.

Never create circular dependencies with ExternalSecrets for CNPG databases.

## REFERENCES

For commit message format, see root AGENTS.md

For infrastructure provisioning (VMs, networking), see tofu/AGENTS.md

For container image building, see images/AGENTS.md

For AI application-specific patterns, see k8s/applications/ai/AGENTS.md

For Authentik identity provider specifics, see k8s/infrastructure/auth/authentik/AGENTS.md
