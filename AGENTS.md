Homelab GitOps monorepo for enterprise-grade learning, built on Talos Kubernetes with Argo CD, OpenTofu, custom images, and Docusaurus documentation.

<Global_rules>
- Use subagents when possible to save context.
- prefer to use skills when relevant.
- Apply all cluster changes through GitOps and Argo CD unless the user approves manual kustomzie and kubectl.
- ensure to always aim for best practices.
- Always explicitly set pod spec hostNetwork false, hostPID false, hostIPC false; pod securityContext runAsNonRoot true, runAsUser, runAsGroup, fsGroup, fsGroupChangePolicy OnRootMismatch; container securityContext allowPrivilegeEscalation false, readOnlyRootFilesystem true, capabilities.drop ["ALL"]; and container resources cpu/memory requests and limits, even with custom values.
- Workloads must specify limits for emptyDir and all resource volumes.
- Run kustomize build --enable-helm on the changed path before commit.
- Use Conventional Commits with type and scope.
- Keep user-facing documentation in website/docs only.
- Avoid new markdown files inside k8s, tofu, and images.
- Avoid git commands unless the user requests them.
- Avoid kubectl apply for cluster changes.
- Avoid kubectl --force, --grace-period=0, and --ignore-not-found.
- Avoid secrets and generated artifacts in Git.
</Global_rules>

<repo_paths>
- /k8s
- /tofu
- /images
- /website
</repo_paths>

<k8s>
Kubernetes manifests, operators, and GitOps workflows.
<k8s_paths>
- k8s/applications
- k8s/infrastructure
</k8s_paths>
<k8s_rules>
- Use storageClassName proxmox-csi on every PVC.
- Use ExternalSecret with ClusterSecretStore bitwarden-backend for non-database secrets.
- Create one Bitwarden item per secret value.
- Set ExternalSecret refreshInterval to 1h.
- Avoid ExternalSecret for CNPG application credentials.
- Use CNPG auto-generated <cluster-name>-app secrets for database credentials.
- Use Kubernetes Secret created by kubectl for service-to-service credentials.
- Pin container images to specific tags.
- Use CiliumNetworkPolicy v2 for every application namespace.
- Apply default-deny ingress and egress in each namespace.
</k8s_rules>
<k8s_network_rules>
- Use Gateway API HTTPRoute for external access.
- Use external gateway IP 10.25.150.222 for HTTPS routes.
- Use internal gateway for internal-only routes.
- Use Cilium 1.18+ for TCP Gateway listeners.
- Avoid NodePort for external services.
- Avoid wildcard DNS certificates.
</k8s_network_rules>
<k8s_backup_rules>
- Use Velero with Kopia filesystem backups for proxmox-csi volumes.
- Use proxmox-csi PV reclaim policy Retain.
- Use Velero restore before PV retain recovery.
- Use PV retain recovery when Velero restore fails.
</k8s_backup_rules>
<k8s_cnpg_rules>
- Use ObjectStore CRD with barman-cloud plugin only.
- Store continuous WAL in MinIO and weekly base backups in Backblaze B2.
- Set MinIO ObjectStore retentionPolicy to 14d.
- Set B2 ObjectStore retentionPolicy to 30d.
- Set plugin isWALArchiver true.
- Use ScheduledBackup method plugin with pluginConfiguration name barman-cloud.cloudnative-pg.io.
</k8s_cnpg_rules>
</k8s>

<k8s_ai>
AI applications with GPU access, LiteLLM, and Qdrant.
<k8s_ai_paths>
- k8s/applications/ai
</k8s_ai_paths>
<k8s_ai_rules>
- Request nvidia.com/gpu resources for GPU workloads.
- Schedule GPU workloads on gpu-node labeled nodes.
- Use Qdrant service qdrant.ai.svc.cluster.local:6333 for vector storage.
- Use LiteLLM service litellm.ai.svc.cluster.local:4000 for provider access.
- Store AI models on PVCs labeled backup.velero.io/backup-tier=GFS.
- Avoid emptyDir for model storage.
- Treat OpenWebUI SQLite database at /app/backend/data/webui.db as critical data.
- Preserve UID 1000 and GID 1000 during OpenWebUI recovery.
- Keep OpenWebUI readiness and startup probes aligned with migration duration.
</k8s_ai_rules>
</k8s_ai>

<k8s_litellm>
LiteLLM SSO configuration rules.
<k8s_litellm_rules>
- Set general_settings enable_jwt_auth true for JWT role mapping.
- Use roles_jwt_field with jwt_litellm_role_map.
- Avoid user_roles_jwt_field with jwt_litellm_role_map.
- Set JWT_PUBLIC_KEY_URL to the Authentik JWKS endpoint.
- Set GENERIC_SCOPE to include roles.
- Include proxy_admin in user_allowed_roles for admin UI access.
- Test JWT token roles and proxy_admin assignment before closing SSO changes.
</k8s_litellm_rules>
</k8s_litellm>

<k8s_automation>
Home automation applications and IoT workflows.
<k8s_automation_paths>
- k8s/applications/automation
</k8s_automation_paths>
<k8s_automation_rules>
- Keep MQTT internal-only and avoid public exposure.
- Use Cilium TCP route for MQTT on Cilium 1.18+.
- Run Zigbee coordinator on a separate VM.
- Connect Zigbee2MQTT to the coordinator over network only.
- Store RTSP credentials in ExternalSecrets.
- Avoid public RTSP exposure.
- Use HA_SEED_ON_STARTUP true to overwrite Home Assistant seed files.
- Use HA_SEED_ON_STARTUP false to preserve Home Assistant-managed files.
</k8s_automation_rules>
</k8s_automation>

<k8s_media>
Media applications and shared storage patterns.
<k8s_media_paths>
- k8s/applications/media
</k8s_media_paths>
<k8s_media_rules>
- Use NFS PV media-nfs with server truenas.peekoff.com and path /mnt/media.
- Mount media via subPath for app-specific folders.
- Use CNPG for Immich database with immich-postgresql-app secret.
- Use ExternalSecrets for Sabnzbd Usenet credentials.
- Avoid Longhorn for new media workloads.
- Avoid Kubernetes backups for large NFS media libraries.
</k8s_media_rules>
</k8s_media>

<k8s_web>
Web applications and productivity services.
<k8s_web_paths>
- k8s/applications/web
</k8s_web_paths>
<k8s_web_rules>
- Use CNPG and Valkey for Pinepods.
- Exclude Kiwix content from Velero backups.
- Restrict HeadlessX egress with NetworkPolicy.
- Use MongoDB StatefulSet for Pedrobot.
</k8s_web_rules>
</k8s_web>

<k8s_games>
Game servers and Minecraft deployment patterns.
<k8s_games_paths>
- k8s/applications/games
- k8s/applications/games/minecraft
</k8s_games_paths>
<k8s_games_rules>
- Use configMapGenerator for all plugin configs.
- Use double underscore path keys to map into /data/plugins.
- Project all plugin ConfigMaps into one projected volume.
- Use a sync init container to copy projected configs into /data/plugins.
- Avoid mounting ConfigMaps directly over /data.
- Avoid modifying volumeClaimTemplates after creation.
- Use ExternalSecrets for operator credentials.
</k8s_games_rules>
</k8s_games>

<authentik>
Authentik SSO and blueprint GitOps.
<authentik_paths>
- k8s/infrastructure/auth/authentik
- k8s/infrastructure/auth/authentik/extra/blueprints
</authentik_paths>
<authentik_rules>
- Set blueprint schema reference in each blueprint file.
- Use blueprint version 1.
- Use identifiers for lookup and attrs for updates.
- Use blueprint states present, created, must_created, and absent as intended.
- Use !KeyOf and !Find for intra-blueprint references.
- Use !Env for secrets sourced from ExternalSecrets.
- Use authentik_providers_oauth2.scopemapping for OAuth property mappings.
</authentik_rules>
</authentik>

<controllers>
Cluster operators and controllers.
<controllers_paths>
- k8s/infrastructure/controllers
</controllers_paths>
<controllers_rules>
- Deploy Cert Manager before External Secrets, CNPG, and Argo CD.
- Use Argo CD Helm chart version 9.2.3.
- Use ApplicationSet Git generator for Argo CD discovery.
- Use Velero defaultVolumesToFsBackup true.
- Avoid CSI snapshots for Proxmox CSI.
- Avoid latest chart versions.
</controllers_rules>
</controllers>

<storage>
Cluster storage and Proxmox CSI.
<storage_paths>
- k8s/infrastructure/storage
- tofu/bootstrap/proxmox-csi-plugin
</storage_paths>
<storage_rules>
- Use StorageClass proxmox-csi for new PVCs.
- Use reclaimPolicy Retain for proxmox-csi volumes.
- Use cacheMode writethrough and filesystem ext4 for proxmox-csi.
- Use mount option noatime for proxmox-csi.
- Manage Proxmox CSI permissions with tofu/bootstrap/proxmox-csi-plugin.
- Use Proxmox user kubernetes-csi@pve for CSI.
</storage_rules>
</storage>

<database>
CNPG database infrastructure.
<database_paths>
- k8s/infrastructure/database
</database_paths>
<database_rules>
- Use at least two CNPG instances for HA.
- Separate WAL storage from data storage.
- Avoid shared databases across applications.
- Avoid latest PostgreSQL versions and pin imageName.
</database_rules>
</database>

<network>
Cluster networking and external access.
<network_paths>
- k8s/infrastructure/network
</network_paths>
<network_rules>
- Use Gateway API external gateway for HTTPS services.
- Use Cloudflare DNS A record pointing to 10.25.150.222 for external routes.
- Use Cilium kubeProxyReplacement enabled.
</network_rules>
</network>

<tofu>
OpenTofu infrastructure provisioning and Talos bootstrap.
<tofu_paths>
- tofu
- tofu/talos
- tofu/bootstrap
</tofu_paths>
<tofu_rules>
- Run tofu fmt and tofu validate before commit.
- Produce tofu plan output for review.
- Avoid tofu apply without explicit human approval.
- Avoid --auto-approve in tofu commands.
- Avoid manual edits to state files.
- Avoid targeted apply unless explicitly approved.
</tofu_rules>
</tofu>

<images>
Custom container images and build pipelines.
<images_paths>
- images
- .github/workflows/image-build.yaml
</images_paths>
<images_rules>
- Use multi-stage Dockerfiles.
- Use USER non-root in runtime stages.
- Avoid secrets in Dockerfiles and build contexts.
- Use .dockerignore in every image directory.
- Pin base image tags to specific versions.
- Run local build and smoke test before commit.
</images_rules>
</images>

<website>
Docusaurus documentation site.
<website_paths>
- website
- website/docs
</website_paths>
<website_rules>
- Use imperative voice and present tense in documentation.
- Run npm run typecheck and npm run lint:all before commit.
- Update sidebars.ts when adding new docs pages.
- Avoid referencing AGENTS.md from documentation.
- Avoid build artifacts in Git.
- Avoid first-person plural and temporal language in documentation.
- Avoid code blocks in documentation and link to source files by absolute path.
</website_rules>
</website>
