# Kubechecks Integration

## Overview

Kubechecks is integrated into our GitOps workflow to validate Kubernetes manifests before they're applied by ArgoCD. The
setup follows our GitOps principles with sm-operator for secret management.

## Components

1. **ArgoCD Application**

   - Located in `/k8s/infra/base/kubechecks`
   - Uses Helm chart from zapier/kubechecks
   - Managed via GitOps after initial bootstrap

2. **Secret Management**
   - GitHub token managed by sm-operator
   - BitwardenSecret in sm-operator-system namespace
   - Secret reference: `github/kubechecks/token`

## Bootstrap Process

Initial deployment requires temporary secret setup before GitOps takes over:

```bash
export GITHUB_TOKEN=your_github_token
./scripts/bootstrap-kubechecks.sh
```

After bootstrap:

1. ArgoCD manages the Kubechecks deployment
2. sm-operator manages the GitHub token
3. All configuration changes must be made through Git

## Configuration

Key settings:

- Monitors all ArgoCD applications automatically
- Validates manifests using kubeconform
- Performs pre-upgrade checks
- Follows strict security practices with panic on validation failures
- Resource limits enforced for stability

## Security Considerations

1. **Token Management**

   - GitHub token managed securely through Bitwarden
   - No direct volume mounts
   - Secret rotation handled by sm-operator

2. **Access Control**
   - Runs in dedicated namespace
   - Limited to required permissions
   - Integrates with ArgoCD RBAC

## Integration Points

1. **ArgoCD**

   - Validates manifests before sync
   - Integrated with ArgoCD repository server
   - Automatic application monitoring

2. **GitHub**
   - PR validation and comments
   - Automated manifest checks
   - Security vulnerability scanning

## Maintenance

All changes must follow GitOps principles:

1. Update configuration in Git
2. ArgoCD syncs changes
3. Validate through PR process
4. Monitor deployment status
