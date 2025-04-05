# GitOps Practices for GitHub Copilot

## Purpose
This prompt provides specific GitOps guidelines for GitHub Copilot to ensure all code generation adheres to our GitOps-only infrastructure approach.

## ArgoCD Configuration Standards

### ApplicationSet Requirements
- Use repository-based generators for app discovery
- Implement matrix generators for complex deployment patterns
- Ensure proper sync wave annotations for dependency management
- Structure ApplicationSets by functionality, not by environment

### Sync & Deployment Strategies
- Enforce automatic pruning of resources
- Implement proper health checks for all resources
- Use progressive sync waves with appropriate delays
- Apply retry limits for failed deployments

### Resource Health Management
- Define custom health checks for specialized resources
- Implement readiness gates where appropriate
- Set appropriate termination grace periods
- Configure proper liveness and readiness probes

## Deployment Structure Guidelines

### Kustomize Best Practices
- Use bases for common configurations
- Apply overlays for environment-specific changes
- Implement patches for targeted modifications
- Maintain a clean hierarchy of resources

### Environment Segregation
- Segregate by folder structure, not by cluster
- Use consistent naming conventions across environments
- Implement clear promotion paths between environments
- Maintain consistency across deployments

### Dependency Management
- Use ArgoCD sync waves for deployment ordering
- Implement proper readiness checks between components
- Define explicit dependencies where required
- Document component relationships

## CI/CD Flow Requirements

### Validation Processes
- Run `kustomize build` validation in CI
- Implement policy checks using OPA/Conftest
- Validate YAML syntax and structure
- Test all generated manifests before deployment

### Deployment Safety
- Implement progressive delivery when possible
- Use canary deployments for critical services
- Configure proper rollback strategies
- Test disaster recovery procedures regularly

## Usage Instructions

Import this prompt when working on GitOps-related tasks:

```
#import:.github/prompts/gitops-optimization.prompt.md
```

Combine with other prompts as needed:
- For Kubernetes resources: `#import:.github/prompts/kubernetes.prompt.md`
- For Kustomize tasks: `#import:.github/prompts/kustomize/base.prompt.md`

## References

- `#file:../../k8s/argocd-bootstrap.tf`
- `#file:../../docs/best-practices/gitops.md`
- `#file:../../k8s/applications/application-set.yaml`
