# Minecraft Component - Repository Guidelines

**Component Purpose**: Minecraft Java and Bedrock cross-platform server deployment with enterprise-grade Kubernetes patterns. This component serves as a reference implementation for game server deployments in the games domain.

## Scope

This component manages:
- Minecraft Java server (PaperMC) with cross-platform support
- BedrockConnect service for zero-click Bedrock player access
- Plugin management and configuration
- Game data persistence and backup integration
- Cross-platform authentication via Geyser + Floodgate

## Architecture

### Configuration Management

#### ConfigMap Generator Strategy

All game configurations use Kustomize configMapGenerator for automatic ConfigMap reloading:

```yaml
configMapGenerator:
  - name: minecraft-bedrock
    literals:
      - TYPE=PAPER
      - VERSION=1.21.11
      - PAPER_BUILD=99
    files:
      - PLUGINS=plugins.txt
  - name: geyser-config
    files:
      - config.yml=geyser-config.yml
```

**Why this pattern:**
- Enables automatic pod restarts when configs change
- Separates simple properties (literals) from complex configs (files)
- Validates YAML during Kustomize build
- Supports ConfigMap hashing for proper rollouts

#### Mount Patterns

**Data Volume**: `/data` mount for:
- World data (`/data/world`, `/data/world_nether`, `/data/world_the_end`)
- Plugin installations (`/data/plugins`)
- Server properties (`/data/server.properties`)
- Logs (`/data/logs`)

**ConfigMap Mounts**: Individual files mounted from ConfigMaps:
```yaml
volumeMounts:
  - mountPath: /data/config/geyser/config.yml
    subPath: config.yml
    readOnly: true
```

**Never**: Mount entire ConfigMap as directory to `/data` - this conflicts with game server expectations.

#### Secret Management

**External Secrets**: Use ExternalSecret for sensitive data:
- Operator credentials via Bitwarden integration
- Never commit secrets to Git
- Use ClusterSecretStore for external secret backend

```yaml
envFrom:
  - secretRef:
      name: minecraft-server-ops
```

## Kustomize Organization

### Directory Structure

```
k8s/applications/games/minecraft/
├── kustomization.yaml          # Main Kustomize (combines subfolders)
├── base/                       # Core Kubernetes resources
│   ├── kustomization.yaml      # Base resources
│   ├── namespace.yaml          # minecraft namespace
│   ├── statefulset.yaml        # Minecraft server
│   ├── service.yaml            # LoadBalancer services
│   └── admin-external-secret.yaml  # External secrets
├── plugins/                    # Plugin configurations
│   ├── kustomization.yaml      # ConfigMap generators
│   ├── plugins.txt             # Plugin download list
│   ├── geyser-config.yml       # Geyser configuration
│   └── essentialsx-config.yml   # EssentialsX configuration
└── bedrockconnect/             # Supporting service
    ├── kustomization.yaml      # BedrockConnect resources
    ├── deployment.yaml         # BedrockConnect deployment
    ├── service.yaml            # BedrockConnect service
    ├── configmap.yaml          # BedrockConnect config
    └── pvc.yaml                # BedrockConnect storage
```

### Base Resources (`base/`)

**Purpose**: Core Kubernetes manifests that define the game server infrastructure.

**Contents**:
- StatefulSet with proper security context
- Services with static IP annotations
- ExternalSecret for credentials
- Namespace definition

**Rules**:
- StatefulSet uses volumeClaimTemplates for data persistence
- Never modify volumeClaimTemplates after creation (immutable)
- Use proper labels: `app.kubernetes.io/name` and `app.kubernetes.io/part-of: games`

### Plugin Configurations (`plugins/`)

**Purpose**: All game configuration files managed via ConfigMap generators.

**Pattern**:
- One ConfigMap per configuration type
- Simple properties as literals
- Complex configs as files
- Plugin list in `plugins.txt` for automated downloads

**Adding New Plugins**:
1. Add plugin to `plugins.txt`
2. Create ConfigMap generator if plugin needs custom config
3. Update `kustomization.yaml` to include new ConfigMap
4. Test with `kustomize build .`

**Scaling**: This structure supports 20+ plugins without conflicts.

### Supporting Services (`bedrockconnect/`)

**Purpose**: Services that enable game functionality but aren't the main game server.

**BedrockConnect**:
- Auto-redirects Bedrock players to Minecraft server
- Zero-click experience for Bedrock users
- Lightweight deployment (50m CPU, 128Mi memory)
- Separate PVC for player data persistence

## Configuration Rules

### What to Do

✅ **Use ConfigMap Generators**: For all game configurations
✅ **Separate Concerns**: Base resources vs plugin configs vs supporting services
✅ **Proper Labeling**: `app.kubernetes.io/part-of: games` for all resources
✅ **Namespace Isolation**: Use `minecraft` namespace for all Minecraft resources
✅ **Resource Requests**: Set proper CPU/memory limits and requests
✅ **Security Context**: Non-root user, dropped capabilities, seccomp profiles
✅ **Static IPs**: Use annotations for LoadBalancer services
✅ **External Secrets**: For all credentials and sensitive data

### Anti-Patterns

❌ **Don't**: Hardcode configuration in StatefulSet spec
❌ **Don't**: Mix plugin configs with server properties
❌ **Don't**: Mount ConfigMaps to `/data` directory (conflicts with game server)
❌ **Don't**: Use default namespace (must be `minecraft`)
❌ **Don't**: Commit secrets to Git (use ExternalSecret)
❌ **Don't**: Modify volumeClaimTemplates after creation
❌ **Don't**: Use root user in containers
❌ **Don't**: Skip resource limits (Minecraft needs proper CPU allocation)

## Plugin Management

### Plugin Downloads

**plugins.txt**: Central list of plugins to download:
```
https://papermc.io/ci/job/Paper-1.21.11/lastSuccessfulBuild/artifact/build/libs/paper-1.21.11.jar
https://download.geysermc.org/v2/projects/geyser/latest/downloads/spigot
https://download.geysermc.org/v2/projects/floodgate/latest/downloads/spigot
https://ci.ender.zone/job/EssentialsX/lastSuccessfulBuild/artifact/target/EssentialsX-2.21.2.jar
```

**Pattern**:
- One plugin per line
- Direct download URLs
- Game server downloads automatically on startup

### Plugin Configuration

**Individual Configs**: Each plugin gets dedicated ConfigMap:
```yaml
configMapGenerator:
  - name: essentialsx-config
    files:
      - config.yml=essentialsx-config.yml
```

**Benefits**:
- Easy to update individual plugin configs
- ConfigMap changes trigger automatic pod restarts
- Clear separation between plugins
- Scales to 20+ plugins

## Operational Considerations

### Cross-Platform Setup

**Geyser + Floodgate**: Enables Java and Bedrock players to join same server:
- Geyser: Translates Bedrock protocol to Java
- Floodgate: Handles authentication for Bedrock players
- Both configured via ConfigMap generators

**Configuration**:
```yaml
GEYSER_ENABLED=true
FLOODGATE=true
GEYSER_AUTH_TYPE=floodgate
```

### Zero-Click Bedrock Access

**BedrockConnect**: Provides auto-redirect for Bedrock players:
- Listens on port 19132
- Auto-redirects to actual Minecraft server
- Custom server list entry for easy access
- Lightweight deployment (separate from main server)

### Resource Requirements

**Minecraft Server**:
- CPU: 2-8 cores (depending on player count)
- Memory: 2-6Gi (depending on plugins and world size)
- Storage: 5Gi+ for world data

**BedrockConnect**:
- CPU: 50m-500m
- Memory: 128Mi-256Mi
- Storage: 1Gi for player data

### Networking

**Ports**:
- Java: 25565/TCP (main game port)
- Bedrock: 19132/UDP (Bedrock protocol)
- BedrockConnect: 19132/UDP (auto-redirect)

**Static IPs**:
```yaml
annotations:
  io.cilium/lb-ipam-ips: 10.25.150.254  # Minecraft server
  io.cilium/lb-ipam-ips: 10.25.150.253  # BedrockConnect
```

## Development Workflow

### Local Testing

**Validate Changes**:
```bash
cd k8s/applications/games/minecraft
kustomize build .
```

**Test Diff**:
```bash
kustomize build . | kubectl diff -f - --server-side
```

### Configuration Updates

**Update Plugin Config**:
1. Edit plugin config file (e.g., `essentialsx-config.yml`)
2. Run `kustomize build .` to validate
3. Apply changes via Argo CD
4. Pod restarts automatically with new config

**Add New Plugin**:
1. Add to `plugins.txt`
2. Create ConfigMap generator if needed
3. Update `plugins/kustomization.yaml`
4. Test with `kustomize build .`
5. Apply via Argo CD

### Version Updates

**Update Minecraft Version**:
1. Change literals in `plugins/kustomization.yaml`:
   ```yaml
   - VERSION=1.21.11
   - PAPER_BUILD=99
   ```
2. Update `plugins.txt` if needed
3. Test build and apply

**Update Plugins**:
1. Update URLs in `plugins.txt`
2. Test by checking plugin download works
3. Apply via Argo CD

## Troubleshooting

### Common Issues

**Pod Not Starting**:
- Check resource allocation (CPU/memory)
- Verify PVC is bound
- Check logs for plugin download errors

**ConfigMap Not Applied**:
- Ensure ConfigMap name matches in StatefulSet
- Check that ConfigMap has proper labels
- Verify no syntax errors in YAML

**Plugin Not Working**:
- Check plugin URL in `plugins.txt`
- Verify plugin config file exists and is valid
- Check server logs for plugin errors

### Debugging Commands

**Check Pod Logs**:
```bash
kubectl logs minecraft-bedrock-0 -n minecraft
```

**Check ConfigMap**:
```bash
kubectl get configmap minecraft-bedrock -n minecraft -o yaml
```

**Check PVC**:
```bash
kubectl get pvc data-minecraft-bedrock-0 -n minecraft
```

**Check Resources**:
```bash
kubectl top pods -n minecraft
```

## Best Practices

### Configuration Management
- Keep configuration files in `plugins/` directory
- Use descriptive names for ConfigMaps
- Validate YAML before committing
- Test changes locally with `kustomize build`

### Security
- Always use ExternalSecret for credentials
- Never commit secrets to Git
- Use proper security context (non-root, dropped capabilities)
- Set resource limits to prevent resource exhaustion

### Scalability
- Structure supports 20+ plugins
- Each plugin gets dedicated ConfigMap
- Clear separation between components
- Easy to add new game types following same pattern

### Documentation
- Update this AGENTS.md when adding new plugins
- Document configuration changes
- Note breaking changes in commit messages
- Keep plugin documentation up to date

## Future Enhancements

### Potential Improvements
- Automated backup integration
- Horizontal scaling for multi-world setups
- Dynamic resource allocation based on player count
- Plugin version pinning for stability
- Health checks for plugin availability

### Migration Paths
- Version upgrades via ConfigMap changes
- Plugin additions without downtime
- Storage expansion via PVC resizing
- Network policy updates for security hardening