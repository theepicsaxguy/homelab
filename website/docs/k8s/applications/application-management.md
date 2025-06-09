---
title: Deploy and Manage Applications
---

This guide explains how to deploy and manage applications on our Kubernetes cluster using GitOps with ArgoCD.

## Quick Start

Applications live in `/k8s/applications/` organized by function:

- `ai/` - AI tools like OpenWebUI, KaraKeep
- `automation/` - Home automation (Frigate, MQTT)
- `media/` - Media servers and tools (Jellyfin, \*arr stack)
- `network/` - Network apps (AdGuard Home, Omada)
- `tools/` - Utility apps (IT-Tools, Whoami, Unrar)
- `web/` - Web applications (BabyBuddy, Pedrobot)
- `external/` - Services outside Kubernetes but referenced internally

## How Application Deployment Works

We use ArgoCD ApplicationSet to automatically deploy apps from Git. Here's the process:

1. Add your app files to a category folder (e.g., `/k8s/applications/media/myapp/`)
2. For most applications, ensure they are discoverable by the main ApplicationSet in
   `/k8s/applications/application-set.yaml` (which scans subdirectories).
3. For applications in the `external/` category (like HAOS, Proxmox, TrueNAS), these are managed by a separate
   ApplicationSet located at `/k8s/applications/external/application-set.yaml`. This ApplicationSet specifically scans
   paths like `k8s/apps/external/*`.
4. ArgoCD detects the change and deploys automatically.

### Key Files

- `kustomization.yaml` - Groups apps in each category
- `project.yaml` - Sets ArgoCD permissions and controls
- `application-set.yaml` - Main deployment configuration (additional ApplicationSets may exist for specific categories
  like `external`)

## Application Structure

Each app folder should contain:

```
myapp/
├── kustomization.yaml    # App configuration
├── namespace.yaml        # Kubernetes namespace
├── deployment.yaml      # Container settings
├── service.yaml         # Network exposure
├── pvc.yaml            # Storage (if needed)
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
   - Default UID and GID for Meilisearch are set to `1000`. Adjust `runAsUser` and `runAsGroup` in
     `meilisearch-deployment.yaml` if those IDs conflict with your environment.

3. **Storage**

   - Uses Longhorn for app data via PersistentVolumeClaims (e.g., `data-pvc`, `meilisearch-pvc`), which use the default
     StorageClass (Longhorn).
   - While a shared NFS media store exists for other media applications, KaraKeep primarily uses its dedicated PVCs for
     its operational data.

4. **Network Access**

   - The primary web interface is exposed via a `LoadBalancer` service (e.g., `karakeep-web-svc` with IP
     `10.25.150.230`). Internal components like Meilisearch or Chrome might use `ClusterIP` services.
   - External access through Gateway API
   - Custom IPs via Cilium

5. **Secrets**
   - Managed by ExternalSecrets
   - Stored in Bitwarden
   - Automatically synced to Kubernetes

## Shared Resources

### Media Storage

We use NFS for shared media files:

- Location: `172.20.20.103:/mnt/wd1/media_share`
- Access: ReadWriteMany
- Retention: Persistent
- Used by: All media apps

## Best Practices

1. Use Kustomize for configuration
2. Store secrets in Bitwarden
3. Set resource limits
4. Configure security contexts
5. Use automated sync with ArgoCD
6. Use the `Recreate` strategy for any Deployment that mounts a PVC.
7. Be aware that `Recreate` causes downtime during updates, so plan a short maintenance window.

## OpenWebUI Notes

OpenWebUI provides a chat interface backed by local AI models. The deployment integrates with Authentik using OIDC. The
`OLLAMA_BASE_URL` variable is intentionally omitted because the Ollama stack is not managed in this repository.

Chrome and Ollama now define both liveness and readiness probes so Kubernetes can restart them if they crash and only route traffic when each pod is ready.
Mosquitto and Unrar use similar probes. Pedro Bot now relies on PersistentVolumeClaims for logs and data, and Jellyfin and Unrar are free to run on any available node.

## BabyBuddy Notes

BabyBuddy runs on port `3000` and is deployed purely with Kustomize manifests. We removed an unused `values.yaml` file to avoid confusion. Update your service and readiness probes to point to this port if you override the default configuration.

Need help? Check the application examples in `/k8s/applications/` for reference implementations.
