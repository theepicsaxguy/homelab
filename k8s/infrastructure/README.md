# Infrastructure Components

This directory contains all the core infrastructure components for our homelab Kubernetes cluster managed using GitOps
principles through ArgoCD.

## 🏗 Directory Structure

```
infrastructure/
├── application-set.yaml   # ArgoCD ApplicationSet for automated deployment
├── project.yaml          # ArgoCD Project definition with proper RBAC
├── kustomization.yaml    # Main kustomization file
├── common/               # Common components and metadata
│   ├── kustomization.yaml
│   └── components/       # Reusable Kustomize components
│       ├── resource-limits.yaml
│       ├── high-availability.yaml
│       └── pod-disruption-budget.yaml
├── overlays/             # Environment-specific configurations
│   ├── dev/
│   ├── staging/
│   └── prod/
├── auth/                 # Authentication components
├── cluster-components/   # Cluster-wide resources
├── controllers/          # Core controllers
├── crds/                 # Custom Resource Definitions
├── network/              # Networking components (Cilium, etc.)
├── storage/              # Storage provisioners and configurations
└── vpn/                  # VPN configurations
```

## 🚀 Core Components

### Common Resources

The `common/` directory contains shared metadata, labels, annotations, and reusable Kustomize components. These are used
across all environments to ensure consistency and reduce duplication.

### Overlays

The `overlays/` directory contains environment-specific configurations:

- **dev**: Development environment with minimal resource requirements
- **staging**: Pre-production environment with high availability
- **prod**: Production environment with high availability and additional safeguards

Each overlay inherits common metadata and can include specific components and patches.

### Infrastructure Components

- **auth/**: Authentication services (OIDC, OAuth2 proxies, etc.)
- **cluster-components/**: Essential cluster services
- **controllers/**: Core controllers like cert-manager
- **crds/**: Custom Resource Definitions for all components
- **network/**: Cilium network policies and configurations
- **storage/**: Storage classes and provisioners
- **vpn/**: VPN configurations for secure access

## 📝 Using These Components

### Adding a New Component

1. Create a directory in the appropriate section (e.g., `network/my-component/`)
2. Add Kustomization files and resources
3. Update the ApplicationSet if needed
4. Push changes to Git, ArgoCD will automatically deploy

### Environment-Specific Configurations

To add environment-specific configurations:

1. Add resources or patches to the appropriate overlay
2. Reference common components to ensure consistency
3. Use the component naming pattern to ensure proper loading

## 🔒 Security Considerations

- The infrastructure project has restricted RBAC permissions
- CRDs are deployed first (sync-wave -1)
- Components follow least-privilege principles
- Resources are namespaced to avoid conflicts

## 🛠 Maintenance and Operations

### Updating Components

1. Make changes in Git repository
2. Push changes to the main branch
3. ArgoCD will automatically sync the changes

### Troubleshooting

If you encounter issues:

1. Check ArgoCD UI for sync status and errors
2. Verify that resources match GitOps definitions
3. Check logs in respective namespaces
4. Never make manual changes - always update via Git

## 🔗 Related Components

- [ArgoCD Setup](/k8s/argocd/)
- [Application Workloads](/k8s/applications/)
- [Monitoring Stack](/k8s/monitoring/)

## ⚠️ Important Notes

- All infrastructure changes must follow GitOps principles
- Manual changes will be overwritten by ArgoCD
- Use appropriately sized resource requests/limits
- Follow the DRY principles using common components
