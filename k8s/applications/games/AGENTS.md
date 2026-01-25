# Games Domain - Repository Guidelines

**Domain Purpose**: Game servers and gaming infrastructure deployed on Kubernetes

## Scope

This domain manages game server deployments, including:
- Minecraft Java and Bedrock servers
- Game server management tools and utilities
- Game-specific networking and storage configurations
- Plugin configurations and mod management

## Architecture

### Directory Structure

```
k8s/applications/games/
├── AGENTS.md                    # This file
├── kustomization.yaml          # Domain-level Kustomize
└── minecraft/                  # Minecraft deployment
    ├── kustomization.yaml      # Main Minecraft Kustomize
    ├── base/                   # Core Kubernetes resources
    │   ├── kustomization.yaml  # Base resources Kustomize
    │   ├── namespace.yaml      # minecraft namespace
    │   ├── statefulset.yaml    # Minecraft server StatefulSet
    │   ├── service.yaml        # Minecraft service
    │   └── admin-external-secret.yaml  # Operator secrets
    ├── plugins/                # Plugin configurations
    │   ├── kustomization.yaml  # ConfigMap generators
    │   ├── plugins.txt         # Plugin download list
    │   ├── geyser-config.yml   # Geyser configuration
    │   └── essentialsx-config.yml  # EssentialsX configuration
    └── bedrockconnect/         # BedrockConnect service
        ├── kustomization.yaml  # BedrockConnect Kustomize
        ├── deployment.yaml     # BedrockConnect deployment
        ├── service.yaml        # BedrockConnect service
        ├── configmap.yaml      # BedrockConnect config
        └── pvc.yaml            # BedrockConnect storage
```

## Kustomize Organization

### Base Resources (`base/`)
Core Kubernetes manifests:
- StatefulSets, Deployments, Services
- Namespaces and RBAC
- Storage claims and networking
- External secrets

### Plugin Configurations (`plugins/`)
All ConfigMap generators for game configurations:
- Server properties and game settings
- Plugin configurations (Geyser, EssentialsX, etc.)
- Mod configurations and resource packs
- ConfigMap files are generated here to enable ConfigMap reloading

### Service Components (`bedrockconnect/`)
Supporting services that enable game functionality:
- BedrockConnect for cross-platform play
- Future: Game management interfaces
- Future: Backup and monitoring services

## Configuration Management

### ConfigMap Generator Strategy
- **Purpose**: Enable automatic ConfigMap reloading when configs change
- **Location**: All ConfigMaps in `plugins/` subfolder
- **Naming**: Use descriptive names indicating config purpose
- **Validation**: YAML configs validated during Kustomize build

### Plugin Management
- **plugins.txt**: Central list of plugins to download
- **Config files**: Individual plugin configs as separate files
- **Naming convention**: `<plugin>-config.yml` for clarity
- **Future scaling**: Easy to add 20+ plugins as separate ConfigMaps

## Deployment Patterns

### Game Server Lifecycle
1. **Base resources** provisioned first (namespace, storage)
2. **Plugin configs** generated and applied
3. **Supporting services** (BedrockConnect) started
4. **Main game server** deployed with all configurations

### Configuration Updates
- Plugin config changes trigger ConfigMap regeneration
- ConfigMap changes automatically trigger pod restarts
- Server restarts only when necessary (config hash changes)

## Integration Points

### Cross-Domain Dependencies
- **storage**: Uses proxmox-csi StorageClass
- **network**: Static IP allocation from network domain
- **auth**: External secrets from auth domain

### GitOps Integration
- All changes flow through Argo CD
- ConfigMap changes trigger automatic deployments
- Health checks ensure service availability

## Security Considerations

### Container Security
- Non-root user execution (UID 1000)
- Read-only filesystem where possible
- Resource limits and requests enforced
- Security context restrictions applied

### Network Security
- Dedicated game server namespaces
- Service mesh integration when applicable
- Network policies for inter-service communication

## Operational Excellence

### Monitoring Requirements
- Game server metrics collection
- Player count and performance monitoring
- Storage usage and backup status
- Service health and availability

### Backup Strategy
- World data backup to external storage
- Configuration backup to Git
- Plugin and mod version tracking

## Future Expansion

### Additional Games
- Structure supports adding new game types
- Follow same pattern: base/, plugins/, supporting services/
- Domain-level coordination for shared resources

### Advanced Features
- Game server clustering
- Dynamic scaling based on player load
- Automated backup and restore workflows
- Integration with game management platforms