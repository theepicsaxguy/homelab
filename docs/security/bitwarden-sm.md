## Bitwarden Secrets Manager Integration

### Configuration Guidelines

The Bitwarden Secrets Manager Operator is configured with:

- EU region endpoints
  - API: <https://api.bitwarden.eu>
  - Identity: <https://identity.bitwarden.eu>
- Refresh interval: 5 minutes (300s)
- Organization ID: 4a014e57-f197-4852-9831-b287013e47b6

### Security Considerations

1. **GitOps Integration**

   - All secret configurations are managed through GitOps
   - Actual secret values stay in Bitwarden, only references in Git
   - Authentication tokens managed as Kubernetes secrets

2. **Namespace Isolation**

   - Operator runs in dedicated `sm-operator-system` namespace
   - RBAC controls limit access to secret management

3. **Key Security Practices**
   - SeccompProfile set to RuntimeDefault
   - Non-root execution
   - Container security context with minimal privileges

### Implementation Structure

```yaml
components:
  - namespace: sm-operator-system
  - kustomization: manages operator deployment
  - BitwardenSecret: infrastructure level secret definitions
  - project.yaml: ArgoCD project with proper RBAC
```
