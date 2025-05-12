Here's a clearer, more organized rewrite:

# Deploy and Manage Applications

This guide explains how to deploy and manage applications on our Kubernetes cluster using GitOps with ArgoCD.

## Quick Start

Applications live in `/k8s/applications/` organized by function:

- `ai/` - AI tools like OpenWebUI, KaraKeep
- `automation/` - Home automation (Frigate, MQTT)
- `media/` - Media servers and tools (Jellyfin, *arr stack)
- `network/` - Network apps (AdGuard Home)
- `tools/` - Utility apps (IT-Tools, Whoami)
- `web/` - Web applications (BabyBuddy)
- `external/` - Services outside Kubernetes but referenced internally

## How Application Deployment Works

We use ArgoCD ApplicationSet to automatically deploy apps from Git. Here's the process:

1. Add your app files to a category folder (e.g., `/k8s/applications/media/myapp/`)
2. Include the path in `/k8s/applications/application-set.yaml`
3. ArgoCD detects the change and deploys automatically

### Key Files

- `kustomization.yaml` - Groups apps in each category
- `project.yaml` - Sets ArgoCD permissions and controls
- `application-set.yaml` - Main deployment configuration

## Application Structure

Each app folder should contain:

```
myapp/
├── kustomization.yaml    # App configuration
├── namespace.yaml        # Kubernetes namespace
├── deployment.yaml      # Container settings
├── service.yaml         # Network exposure
├── pvc.yaml            # Storage (if needed)
└── http-route.yaml     # External access
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

3. **Storage**
   - Uses Longhorn for app data
   - Connects to NFS for shared media

4. **Network Access**
   - Internal access via ClusterIP
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

Need help? Check the application examples in `/k8s/applications/` for reference implementations.
