Homelab GitOps monorepo built on Talos Kubernetes with Argo CD, OpenTofu, custom images, and Docusaurus documentation.

<Global_rules>
- Always use parallel subagents to save context, time and stay on track.
- Use available skills for any task when possible. Skills encode established workflows.
- Never log secrets, credentials, API keys, tokens, or connection strings.
- All warnings must be resolved. Lint, type, complexity, and compiler warnings fail CI.
- A PR must read like one author: match the naming, structure, DI style, and error handling shape of the surrounding code.
- A file exceeding 300 lines likely has more than one responsibility and must be split.
- Apply all cluster changes through GitOps and Argo CD unless the user approves manual kustomize and kubectl.
- Always explicitly set pod spec hostNetwork false, hostPID false, hostIPC false; pod securityContext runAsNonRoot true, runAsUser, runAsGroup, fsGroup, fsGroupChangePolicy OnRootMismatch; container securityContext allowPrivilegeEscalation false, readOnlyRootFilesystem true, capabilities.drop ["ALL"]; and container resources cpu/memory requests and limits, even with custom values.
  - Note: hostNetwork, hostPID, and hostIPC are pod spec fields, not PodSecurityContext fields.
- Workloads must specify limits for emptyDir and all resource volumes.
- Run kustomize build --enable-helm on the changed path before commit.
- Use Conventional Commits with type and scope.
- Keep user-facing documentation in website/docs only.
- Avoid new markdown files inside k8s, tofu, and images.
- Avoid git commands unless the user requests them.
- NEVER use --force, --grace-period=0, and --ignore-not-found.
- Avoid secrets and generated artifacts in Git.
- Pin container images to specific tags. Never vague tags like latest or main.
- never create any markdown docuemnts, summary or analyzis etc if the user havent told you to do so.
</Global_rules>

<repo_paths>
- /k8s
- /tofu
- /images
- /website
</repo_paths>

<k8s>
<k8s_rules>
- Use ExternalSecret external-secrets.io/v1 with ClusterSecretStore bitwarden-backend; name each Bitwarden item app-<application>-<secret-name>; set refreshInterval 1h.
- Avoid ExternalSecret for CNPG application credentials; use CNPG auto-generated <cluster-name>-app secrets instead.
- Use Kubernetes Secret created by kubectl for service-to-service credentials.
- Use CiliumNetworkPolicy v2 with default-deny ingress and egress in every application namespace; never use standard NetworkPolicy resources.
- When using kubectl use `${workspaceFolder:root}/tofu/output/kube-config.yaml`.
- When using talosctl use `${workspaceFolder:root}/tofu/output/talos-config.yaml`.
</k8s_rules>
<k8s_network>
- Use Gateway API HTTPRoute for external access via external gateway 10.25.150.222.
- Use internal gateway for internal-only routes.
- Use Cilium 1.18+ for TCP Gateway listeners.
- Use Cloudflare DNS A record pointing to 10.25.150.222 for external routes.
- Avoid NodePort for external services.
- Avoid wildcard DNS certificates.
</k8s_network>
<k8s_backup>
- Use Velero with Kopia filesystem backups for proxmox-csi volumes.
- Use Velero restore before PV retain recovery; use PV retain recovery when Velero restore fails.
</k8s_backup>
<k8s_cnpg>
- Use ObjectStore CRD with barman-cloud plugin only.
- Store continuous WAL in MinIO with retentionPolicy 14d and weekly base backups in Backblaze B2 with retentionPolicy 30d.
- Set plugin isWALArchiver true.
- Use ScheduledBackup method plugin with pluginConfiguration name barman-cloud.cloudnative-pg.io.
</k8s_cnpg>
</k8s>

<k8s_ai>
- Request nvidia.com/gpu resources and schedule GPU workloads on gpu-node labeled nodes.
- Use qdrant.ai.svc.cluster.local:6333 for vector storage and litellm.ai.svc.cluster.local:4000 for provider access.
- Store AI models on PVCs labeled backup.velero.io/backup-tier=GFS; avoid emptyDir for model storage.
</k8s_ai>

<k8s_litellm>
- Enable JWT auth with roles_jwt_field and jwt_litellm_role_map; avoid user_roles_jwt_field with jwt_litellm_role_map.
- Set JWT_PUBLIC_KEY_URL to the Authentik JWKS endpoint and GENERIC_SCOPE to include roles.
- Include proxy_admin in user_allowed_roles for admin UI access.
</k8s_litellm>

<k8s_automation>
- Keep MQTT internal-only; use Cilium TCP route for MQTT on Cilium 1.18+.
- Run Zigbee coordinator on a separate VM; connect Zigbee2MQTT to the coordinator over network only.
- Use HA_SEED_ON_STARTUP true to overwrite Home Assistant seed files; false to preserve Home Assistant-managed files.
</k8s_automation>

<k8s_media>
- Use NFS PV with server truenas.peekoff.com path /mnt/media; mount via subPath for app-specific folders.
- Avoid Longhorn for new media workloads.
- Avoid Kubernetes backups for large NFS media libraries.
</k8s_media>

<k8s_games>
- Use configMapGenerator with double underscore path keys to map into /data/plugins.
- Project all plugin ConfigMaps into one projected volume; use a sync init container to copy configs into /data/plugins.
- Avoid mounting ConfigMaps directly over /data.
- Avoid modifying volumeClaimTemplates after creation.
</k8s_games>

<authentik>
- Set blueprint schema reference and version 1 in each blueprint file.
- Use identifiers for lookup and attrs for updates.
- Use blueprint states present, created, must_created, and absent as intended.
- Use !KeyOf and !Find for intra-blueprint references; !Env for secrets sourced from ExternalSecrets.
- Use authentik_providers_oauth2.scopemapping for OAuth property mappings.
</authentik>

<controllers>
- Deploy Cert Manager before External Secrets, CNPG, and Argo CD.
- Use Argo CD Helm chart version 9.2.3 with ApplicationSet Git generator for discovery.
- Use Velero defaultVolumesToFsBackup true; avoid CSI snapshots for Proxmox CSI.
</controllers>

<storage>
- Use StorageClass proxmox-csi on every PVC; reclaimPolicy Retain, cacheMode writethrough, filesystem ext4, mount option noatime.
- Use Deployment strategy type replace for workloads using proxmox-csi PVCs; proxmox-csi supports RWO (ReadWriteOnce) only, preventing rolling updates.
- Manage Proxmox CSI permissions with tofu/bootstrap/proxmox-csi-plugin using Proxmox user kubernetes-csi@pve.
</storage>

<database>
- Use at least two CNPG instances for HA.
- Avoid shared databases across applications.
</database>

<network>
- Use Cilium kubeProxyReplacement enabled.
</network>

<tofu>
- Run tofu fmt and tofu validate before commit; produce tofu plan output for review.
- Avoid tofu apply without explicit human approval; avoid --auto-approve, manual state file edits, and targeted apply unless explicitly approved.
</tofu>

<website>
- Run npm run typecheck and npm run lint:all before commit.
- Update sidebars.ts when adding new docs pages.
- Avoid referencing AGENTS.md from documentation.
- Avoid code blocks in documentation; link to source files by absolute path.
- Avoid first-person plural and temporal language.
</website>
