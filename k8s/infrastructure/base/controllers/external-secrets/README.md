# External Secrets Operator with Bitwarden Integration

This directory contains the configuration for External Secrets Operator (ESO) integrated with Bitwarden Secrets Manager.

## Components

- External Secrets Operator (v0.9.9)
- Bitwarden SDK Server (included in ESO Helm chart)
- SecretStore configuration for Bitwarden integration
- Initial ExternalSecret for authentication

## Setup Process

1. ESO is deployed via Helm through ArgoCD using a HelmRelease CR
2. The Bitwarden SDK Server is enabled as part of the ESO deployment
3. A SecretStore is configured to connect to Bitwarden Secrets Manager
4. Authentication is handled via an initial ExternalSecret that manages the auth token

## Migration from BitwardenSecrets

When migrating existing BitwardenSecrets to ExternalSecrets:

1. Create a new ExternalSecret CR using this template:
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: <name>
  namespace: <namespace>
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: bitwarden-backend
    kind: SecretStore
  target:
    name: <target-secret-name>
    creationPolicy: Owner
  data:
  - secretKey: <key>
    remoteRef:
      key: "<uuid-from-bitwarden>"
```

2. Update any dependent resources to use the new secret name
3. Remove the old BitwardenSecret CR

## Security Considerations

- TLS is enabled for the Bitwarden SDK Server
- Secrets are refreshed every hour by default
- Access is controlled via Kubernetes RBAC
- All secret operations are logged and auditable

## Validation

Pre-commit hooks are available in `.github/hooks/pre-commit` to validate:
- Kubernetes manifests
- Helm values
- Kustomize configurations

## ArgoCD Sync Validation

The ApplicationSet configuration includes:
- Automated pruning of removed resources
- Self-healing capabilities
- Retry logic for failed syncs
- Proper sync wave ordering