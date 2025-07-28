---
title: Deploy and Manage Applications
---

This guide explains how applications are deployed and managed on the Kubernetes cluster using GitOps with ArgoCD.

## Quick start

Applications live in `/k8s/applications/` organized by function:

- `ai/` - AI tools like Open WebUI, KaraKeep
- `automation/` - Home automation (Frigate, MQTT)
- `media/` - Media servers and tools (Jellyfin, *arr stack)
- `network/` - Network apps (AdGuard, Omada)
- `tools/` - Utility apps (IT-Tools, Whoami, Unrar)
- `web/` - Web applications (BabyBuddy, Pedrobot)
- `external/` - Services outside Kubernetes but referenced internally

## How Application Deployment Works

ArgoCD ApplicationSet automatically deploys apps from Git The process is:

1. Add your app files to a category folder (e.g., `/k8s/applications/media/myapp/`)
2. For most applications, ensure they're discoverable by the main ApplicationSet in
   `/k8s/applications/application-set.yaml` (which scans subdirectories).
3. For applications in the `external/` category (for example, Home Assistant Operating System (HAOS), Proxmox, TrueNAS), a separate
   ApplicationSet manages them. This ApplicationSet is located at `/k8s/applications/external/application-set.yaml` and specifically scans
   paths like `k8s/apps/external/*`.
4. ArgoCD detects the change and deploys automatically.

### Key Files

- `kustomization.yaml` - Groups apps in each category
- `project.yaml` - Sets ArgoCD permissions and controls
- `application-set.yaml` - Main deployment configuration (additional ApplicationSets exist for specific categories
  like `external`)

## Application Structure

Each app folder should contain:

```shell
myapp/
├── kustomization.yaml    # App configuration
├── namespace.yaml        # Kubernetes namespace
├── deployment.yaml      # Container settings
├── service.yaml         # Network exposure
├── pvc.yaml            # Storage for Deployments (optional)
├── statefulset.yaml     # Stateful workloads with volumeClaimTemplates
├── http-route.yaml     # External access
└── values.yaml         # Helm values (only if the app uses a Helm chart)
```

### Example: KaraKeep Configuration

Here's how KaraKeep (`/k8s/applications/ai/karakeep/`) is structured:

1. **Basic Setup**

   - Uses namespace: `karakeep`
   - Configures non-sensitive settings via ConfigMap
   - Manages versions through Kustomize

2. **Security**

   - Runs as non-root
   - Drops unnecessary privileges
   - Uses default security profiles
   - Helm charts explicitly set `runAsUser`, `runAsGroup`, and `fsGroup` to `1000`
     with `seccompProfile: RuntimeDefault` and `allowPrivilegeEscalation: false`.
   - Default UID and GID for Meilisearch are set to `1000`. Adjust `runAsUser` and `runAsGroup` in
     `meilisearch-deployment.yaml` if those IDs conflict with your environment.

3. **Storage**

   - Uses Longhorn for app data via PersistentVolumeClaims (e.g., `data-pvc`, `meilisearch-pvc`), which use the default
     StorageClass (Longhorn).
   - While a shared NFS media store exists for other media applications, KaraKeep primarily uses its dedicated PVCs for
     its operational data.

4. **Network Access**

   - The primary web interface is exposed via a `LoadBalancer` service (e.g., `karakeep-web-svc` with IP
     `10.25.150.230`). Internal components like Meilisearch or Chrome use `ClusterIP` services.
   - External access through Gateway API
   - Custom IPs via Cilium

5. **Secrets**
   - Managed by ExternalSecrets
   - Stored in Bitwarden
   - Automatically synced to Kubernetes

## Shared Resources

### Media Storage

I use NFS for shared media files:

- Location: `172.20.20.103:/mnt/wd1/media_share`
- Access: ReadWriteMany
- Retention: Persistent
- Used by: All media apps

## Best Practices

1. Use Kustomize for configuration
2. Store secrets in Bitwarden
3. Set resource limits
4. Configure security contexts and keep the root filesystem read-only when possible. s6-overlay containers like Frigate must run as root (`runAsUser: 0`), mount `/run` as an emptyDir so writes stay ephemeral, and require the `CHOWN`, `FOWNER`, `SETGID`, and `SETUID` capabilities so startup scripts can change permissions. If the container needs to write to `/etc` during startup, disable `readOnlyRootFilesystem` for that pod
5. Use automated sync with ArgoCD
6. Use the `Recreate` strategy for any Deployment that mounts a PVC.
7. Be aware that `Recreate` causes downtime during updates, so plan a short maintenance window.
8. Pin container images to explicit versions and set `imagePullPolicy: IfNotPresent`.

## OpenWebUI Notes

OpenWebUI provides a chat interface backed by local AI models. The deployment integrates with Authentik using OIDC and merges accounts by email so users can sign in with any provider. The `OLLAMA_BASE_URL` variable is intentionally omitted because the Ollama stack isn't managed in this repository.

Chrome and Ollama define both liveness and readiness probes so Kubernetes can restart them if they crash and only route traffic when each pod is ready.
Mosquitto and Unrar use similar probes. Pedro Bot relies on PersistentVolumeClaims for logs and data, and Jellyfin and Unrar can run on any available node.

## Karakeep Notes

Karakeep authenticates through Authentik using OIDC. The client ID and secret live in Bitwarden and sync to a Kubernetes secret via ExternalSecrets. Password logins are disabled so users sign in only with Authentik.
The container keeps its root filesystem read-only. Temporary paths like `/run` and `/tmp` come from `emptyDir` volumes so s6-overlay can write runtime files.

## BabyBuddy Notes

BabyBuddy runs on port `3000` and is deployed purely with Kustomize manifests. The deployment doesn't include a `values.yaml` file, avoiding confusion. Update your service and readiness probes to point to this port if you override the default configuration.

## Home Assistant Notes

Home Assistant runs as a StatefulSet. Configuration, media, and data paths each
use their own persistent volume created through `volumeClaimTemplates`. It
connects to the shared `mosquitto` service in the `mqtt` namespace - configure the
integration to use `mosquitto.mqtt.svc.cluster.local` and your Bitwarden
credentials. A ConfigMap provides `configuration.yaml` so the cluster gateway can
proxy requests using the `X-Forwarded-For` header. The main container starts as
`root` so its init system can run, but Kubernetes sets the volume group to `1000`
so Home Assistant can drop privileges. The BlueZ sidecar now drops all
capabilities and runs unprivileged, reducing risk.
## Zigbee2MQTT Notes

Zigbee2MQTT manages the Zigbee adapter without privileged mode. The
`zigbee2mqtt` namespace is labeled `pod-security.kubernetes.io/enforce=baseline` so
it adheres to the cluster's standard policies.


Need help? Check the application examples in `/k8s/applications/` for reference implementations.
