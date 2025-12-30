# Kubernetes Infrastructure - Domain Guidelines

SCOPE: Kubernetes manifests, operators, and GitOps patterns
INHERITS FROM: /AGENTS.md
TECHNOLOGIES: Kubernetes, Kustomize, Helm, Argo CD, CNPG, Velero, Proxmox CSI

## DOMAIN CONTEXT

Purpose:
Define and manage all Kubernetes resources for the homelab cluster, including applications, infrastructure components, storage, networking, and authentication.

Boundaries:
- Handles: All Kubernetes manifests, Argo CD ApplicationSets, operator CRDs, storage classes, and network policies
- Does NOT handle: VM provisioning (see tofu/), container image building (see images/)
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
New workloads use `proxmox-csi` StorageClass for dynamic provisioning from Proxmox Nvme1 ZFS datastore. Always specify `storageClassName` in PVCs.

### Secret Management Pattern
External Secrets Operator syncs secrets from Bitwarden Secrets Manager into Kubernetes. Create separate Bitwarden entries for each secret value (no `property` field). Use `engineVersion: v2` under `spec.target.template` and indent templates correctly under `spec.target.template:`, not `spec:`.

### GitOps Pattern
All changes go through Git. Argo CD auto-syncs manifests from `k8s/` to cluster. Never apply changes directly via `kubectl apply`. Validate manifests with `kustomize build` before committing.

### Operator Pattern
Operators manage complex stateful workloads (CNPG for databases, Velero for backups). Define operator CRDs in manifests. Let operators reconcile state automatically. Query operator status before making changes.

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
- `controllers/`: Cluster operators (Argo CD, Velero, Cert Manager, External Secrets, CNPG, NVIDIA GPU, Node Feature Discovery)
- `crd/`: Custom Resource Definitions for operators
- `database/`: Database operators (CloudNativePG)
- `deployment/`: Deployment utilities (Kubechecks)
- `monitoring/`: Monitoring stack (Hubble)
- `network/`: Network policies and CNI (Cilium), CoreDNS, Gateway API, Cloudflared
- `storage/`: Storage providers (Proxmox CSI)

### Application Categories
- `ai/`: AI/ML applications (see k8s/applications/ai/AGENTS.md for details)
- `automation/`: Home automation (Home Assistant, Frigate, MQTT, Zigbee2MQTT)
- `external/`: External service proxies (Proxmox, TrueNAS)
- `media/`: Media management (Jellyfin, Immich, arr-stack, Audiobookshelf)
- `network/`: Network services (Unifi)
- `tools/`: Utility applications (IT-Tools, Unrar)
- `web/`: Web applications (BabyBuddy, HeadlessX, Pinepods, Kiwix, Pedrobot)

## ANTI-PATTERNS

Never hardcode secrets or credentials in manifests. Use ExternalSecrets Operator to sync from Bitwarden.

Never apply changes directly to cluster with `kubectl apply` for permanent changes. All changes must go through GitOps.

Never delete resources (Pods, PVCs, Jobs) without evidence from logs and events. Diagnose root cause before taking destructive action.

Never guess resource names or secret keys. Query the cluster to verify: `kubectl get secret <name> -n <namespace>`, `kubectl get service <name> -n <namespace>`.

Always use `kubectl describe` to inspect resource status, events, and conditions—it's safe and non-destructive.

Always use `kubectl explain` to understand resource schemas and field meanings—never guess YAML structure.

Never use dangerous kubectl flags:
- `--force` bypasses safety checks and can cause data loss
- `--grace-period=0` terminates pods immediately without graceful shutdown, risking data corruption
- `--ignore-not-found` masks errors by silently ignoring missing resources

These flags hide problems instead of fixing them. Find and fix the root cause instead.

Never modify CRD definitions without understanding operator compatibility. Fetch official CRD documentation before making changes.

Never use `latest` tags for container images. Pin to specific versions for reproducibility.

Never skip backup configuration for stateful workloads. Proxmox CSI PVCs are automatically backed up by Velero.

Never create circular dependencies with ExternalSecrets for CNPG databases. Let CNPG auto-generate credentials (`<cluster-name>-app` secret).

Never use `property` field with Bitwarden Secrets Manager. Create separate Bitwarden entries for each secret value.

Never use legacy barman approach for CNPG backups. Always use the barman plugin (`type: barmanObjectStore`) integrated with CNPG.

After making changes, verify relevant documentation doesn't contain outdated information. Update or flag stale docs.

## STORAGE CLASSES

### Proxmox CSI (Primary)
Use `storageClassName: proxmox-csi` for all workloads. Provides dynamic provisioning from Proxmox Nvme1 ZFS datastore. Supports volume expansion. Automatically backed up by Velero.

## BACKUP STRATEGY

### Velero Backups (Kopia filesystem backups)
Velero backs up all PVCs using Kopia filesystem backups (not CSI snapshots). Proxmox CSI driver does not support CSI snapshots due to experimental status and permission requirements.

**Velero Schedules**:
- `velero-daily`: Daily backups at 02:00, 14-day TTL
- `velero-gfs`: Hourly backups for GFS tier, 14-day TTL
- `velero-weekly`: Weekly backups on Sundays at 03:00, 28-day TTL

**Excluded Namespaces**: `velero`, `kube-system`, `default`, `kiwix`

**Key Configuration**: `defaultVolumesToFsBackup: true` for filesystem backup via Kopia

**Exclude volumes from backup** with pod annotations:
- `backup.velero.io/exclude-from-backup: "true"` (exclude entire pod)
- `backup.velero.io/backup-volumes-excludes: "volume-name"` (exclude specific volumes)

### Longhorn Backups (Removed)

Longhorn storage has been deprecated and removed. All workloads now use Proxmox CSI with Velero backups. See breaking changes documentation for migration details.

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
- Use the barman plugin for backups (not the legacy barman object storage approach)
- Two ObjectStore resources: One for local MinIO, one for Backblaze B2
- ExternalSecret for B2 credentials (separate Bitwarden entries for access-key-id and secret-access-key)
- Cluster plugin configuration for WAL archiving to B2 using the barman plugin
- ScheduledBackup resource (weekly to B2 via plugin architecture)
- ExternalClusters definitions for both MinIO and B2 recovery paths

### CNPG Barman Plugin Pattern
Always use the barman plugin architecture (`type: barmanObjectStore`) for CNPG backups. Never use the legacy barman standalone deployment approach. The plugin is integrated into CNPG and managed entirely through Cluster and Backup CRDs.

## CRITICAL BOUNDARIES

Never commit secrets or credential material to Git.

Never modify CRD definitions without consulting official documentation.

Never apply changes directly to cluster—use GitOps.

Never delete resources without evidence from logs and events.

Never guess resource names or secret keys—query cluster first.

Never skip backup configuration for stateful workloads.

Never create circular dependencies with ExternalSecrets for CNPG databases.

## REFERENCES

For commit message format, see /AGENTS.md

For infrastructure provisioning (VMs, networking), see /tofu/AGENTS.md

For container image building, see /images/AGENTS.md

### Application-Specific References
- AI applications: k8s/applications/ai/AGENTS.md
- Automation applications: k8s/applications/automation/AGENTS.md
- Media applications: k8s/applications/media/AGENTS.md
- Web applications: k8s/applications/web/AGENTS.md

### Infrastructure-Specific References
- Authentik identity provider: k8s/infrastructure/auth/authentik/AGENTS.md
- Cluster controllers: k8s/infrastructure/controllers/AGENTS.md
- Database management: k8s/infrastructure/database/AGENTS.md
- Network configuration: k8s/infrastructure/network/AGENTS.md
- Storage providers: k8s/infrastructure/storage/AGENTS.md
