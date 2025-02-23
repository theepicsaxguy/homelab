# Application Deployment Best Practices

## GitOps Principles

1. **No Direct Deployments**
   - All changes must go through Git
   - No manual kubectl apply or helm install
   - ArgoCD is the only deployment mechanism

2. **Kustomize Usage**
   - No raw manifests allowed
   - Use overlays for environment-specific changes
   - Pin Helm chart versions in kustomization files

3. **Resource Management**
   - Define explicit resource requests and limits
   - Use horizontal pod autoscaling where appropriate
   - Implement proper pod disruption budgets

## Environment Guidelines

### Development
- Fast iteration cycles
- Reduced resource requirements
-允许 empty applications for testing

### Staging
- Production-like configuration
- Full HA testing
- Security scanning enforced

### Production
- Strict validation requirements
- Zero-downtime deployments
- Full monitoring integration

## ApplicationSet Usage

1. **Sync Wave Order**
   - Wave 3: Development applications
   - Wave 4: Staging applications
   - Wave 5: Production applications

2. **Labels and Annotations**
   - Always include environment labels
   - Use proper app.kubernetes.io/* labels
   - Include necessary ArgoCD annotations

## Security Requirements

1. **Secret Management**
   - Use Bitwarden Secrets Manager exclusively
   - No direct secret volume mounts
   - Follow least privilege principle

2. **Container Security**
   - Use non-root users
   - Implement read-only root filesystem
   - Define SecurityContext

## High Availability

1. **Replica Requirements**
   - Dev: Single replica acceptable
   - Staging/Prod: Minimum 3 replicas
   - Use pod anti-affinity rules

2. **Update Strategy**
   - Use rolling updates
   - Set proper maxSurge/maxUnavailable
   - Implement readiness probes

## Validation Process

1. **Before Deployment**
   - Run validate_manifests.sh
   - Verify kustomize builds
   - Check security compliance

2. **Post Deployment**
   - Verify ArgoCD sync status
   - Check application health
   - Validate monitoring integration