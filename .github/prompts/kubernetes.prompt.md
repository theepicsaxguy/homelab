# Kubernetes Configuration Guidelines for GitHub Copilot

## Purpose
This prompt extends the main guidelines with Kubernetes-specific rules for our GitOps-only homelab infrastructure.

## Architecture Requirements

- **CNI**: Cilium with eBPF enabled (Talos' default CNI is prohibited)
- **Service Mesh**: Istio with strict mTLS enforcement
- **BGP Routing**: Enabled for external service access
- **Database**: CloudNative PG for all database operations
- **Ingress**: Managed via ArgoCD using predefined templates

## Security Standards

- **Secrets Management**: External Secrets Operator required for all secrets
- **RBAC**: Strictly implemented with least privilege principle
- **Network Policies**: Required for all namespaces and workloads
- **SecurityContexts**: Must be defined with appropriate restrictions
- **Pod Security Standards**: Enforce restricted PSA profiles

## Resource Organization

- **Namespace Strategy**: Functional grouping with consistent labeling
- **Resource Limits**: All deployments must have CPU/memory limits
- **Label Standards**: App, component, part-of, and managed-by required
- **Annotations**: ArgoCD annotations for sync waves required

## Storage Configuration

- **CSI Drivers**: TrueNAS + Proxmox CSI for persistence
- **StorageClasses**: Must be defined in the infrastructure layer
- **Backups**: Velero-based backup strategies for all persistent data
- **No In-Cluster Changes**: All storage must be declared in Git

## Usage Instructions

Import this prompt when working on Kubernetes resources:

```
#import:.github/prompts/kubernetes.prompt.md
```

Combine with specific task prompts:
- For Kustomize tasks: `#import:.github/prompts/kustomize/base.prompt.md`
- For ApplicationSet: `#import:.github/prompts/RefactorApplicationSet.prompt.md`

## References

- `#file:../../k8s/applications/README.md`
- `#file:../../k8s/infrastructure/README.md`
- `#file:../../docs/kubernetes/best-practices.md`
