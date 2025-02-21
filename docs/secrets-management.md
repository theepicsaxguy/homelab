# Secrets Management with Bitwarden SM Operator

This document describes how secrets are managed in our homelab infrastructure using Bitwarden Secrets Manager Operator (sm-operator).

## Architecture Overview

The secrets management system follows these principles:
1. Secrets are stored in Bitwarden Secrets Manager
2. The sm-operator syncs secrets from Bitwarden to Kubernetes
3. Applications reference these secrets using standard Kubernetes secrets

## Setup Process

### 1. Install SM Operator

```bash
# Apply the sm-operator configuration
kubectl kustomize --enable-helm infra/controllers/bitwarden | kubectl apply -f -

# Create the authentication token secret
kubectl create secret generic bw-auth-token \
  -n sm-operator-system \
  --from-literal=token="<Auth-Token-Here>"
```

### 2. Configure BitwardenSecret Resource

The `BitwardenSecret` resource maps Bitwarden secrets to Kubernetes secrets. Example:

```yaml
apiVersion: k8s.bitwarden.com/v1
kind: BitwardenSecret
metadata:
  name: bitwarden-secrets
  namespace: sm-operator-system
spec:
  organizationId: '<your-org-id>'
  secretName: infrastructure-secrets
  map:
    - bwSecretId: '<secret-uuid>'
      secretKeyName: 'friendly-name'
```

### 3. Using Secrets in Applications

To use a secret in your application:

1. Create a standard Kubernetes secret with Bitwarden annotations:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secret
  namespace: my-namespace
  annotations:
    bitwarden.com/sync: "true"
    bitwarden.com/source-secret: infrastructure-secrets
type: Opaque
stringData:
  config.json: "{{ .secret_key_name }}"
```

2. Reference the secret in your application:
```yaml
spec:
  template:
    spec:
      containers:
        - name: app
          volumeMounts:
            - name: config
              mountPath: /config
              readOnly: true
      volumes:
        - name: config
          secret:
            secretName: my-app-secret
```

## Best Practices

1. **Central Management**: Use a single `BitwardenSecret` resource to manage all secrets
2. **Namespace Organization**: Keep the sm-operator in its own namespace (sm-operator-system)
3. **Secret Mapping**: Use descriptive `secretKeyName` values in the BitwardenSecret mapping
4. **Refresh Interval**: Configure appropriate refresh interval in sm-operator-values.yaml
5. **Access Control**: Use RBAC to control access to secrets in different namespaces

## Troubleshooting

If secrets are not syncing:

1. Check sm-operator logs:
```bash
kubectl logs -n sm-operator-system -l app.kubernetes.io/name=sm-operator
```

2. Verify the auth token secret exists:
```bash
kubectl get secret bw-auth-token -n sm-operator-system
```

3. Check BitwardenSecret status:
```bash
kubectl get bitwardensecret -n sm-operator-system
```

## Infrastructure Secrets Organization

### Secret Types and Structure

The infrastructure uses these main categories of secrets:

1. **Authentication Secrets**
   - SMTP credentials
   - Crypto keys
   - OIDC client secrets
   - LLDAP credentials

2. **Network Secrets**
   - Cloudflared tunnel credentials
   - AdGuard user configurations
   - API tokens

3. **Controller Secrets**
   - Cloudflare API tokens
   - Service account credentials

### Secret Mapping Pattern

The BitwardenSecret resource follows this structure:
```yaml
spec:
  map:
    # Auth secrets
    - bwSecretId: '<uuid>'
      secretKeyName: 'smtp_password'
    - bwSecretId: '<uuid>'
      secretKeyName: 'crypto_key'

    # Network secrets
    - bwSecretId: '<uuid>'
      secretKeyName: 'tunnel_credentials'

    # Controller secrets
    - bwSecretId: '<uuid>'
      secretKeyName: 'cloudflare_api_token'
```

## GitOps Integration

1. **Bootstrap Process**:
   - SM Operator deployment is part of the manual bootstrap process
   - Must be installed before other components that depend on secrets

2. **Secret Template Pattern**:
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     annotations:
       bitwarden.com/sync: "true"
       bitwarden.com/source-secret: infrastructure-secrets
   type: Opaque
   stringData:
     key: "{{ .secret_key_name }}"
   ```

3. **ArgoCD Integration**:
   - Secrets are synced before application deployments
   - Applications use synced Kubernetes secrets
   - No direct Bitwarden access needed in application pods

## Security Considerations

1. **Access Control**:
   - SM Operator runs with minimal permissions
   - Secrets are namespace-scoped
   - Use RBAC to control secret access

2. **Secret Rotation**:
   - Automatic sync every 180 seconds (configurable)
   - No pod restart required for secret updates
   - Use checksum annotations when pod restart is needed

3. **Audit Trail**:
   - All secret access is logged by SM Operator
   - Changes are tracked in Bitwarden audit logs
   - Use Kubernetes events for troubleshooting

## Maintenance Tasks

### Adding New Secrets

1. Add secret to Bitwarden Secrets Manager
2. Note the UUID of the secret
3. Add mapping to BitwardenSecret resource
4. Create Kubernetes secret with appropriate annotations
5. Reference in application

### Rotating Secrets

1. Update secret in Bitwarden
2. Wait for sync interval or trigger manual sync
3. If needed, restart pods that use the secret

### Troubleshooting Steps

1. **Verify SM Operator Status**:
   ```bash
   kubectl get pods -n sm-operator-system
   kubectl logs -l app.kubernetes.io/name=sm-operator -n sm-operator-system
   ```

2. **Check Secret Sync Status**:
   ```bash
   kubectl get events -n <namespace> --field-selector involvedObject.name=<secret-name>
   ```

3. **Validate Secret Configuration**:
   ```bash
   kubectl get secret <secret-name> -n <namespace> -o yaml
   ```

## Homelab-Specific Pattern

### Centralized Secret Management

This homelab uses a centralized pattern where:

1. **Single Source of Truth**:
   - One main BitwardenSecret (`infrastructure-secrets`)
   - Located in `sm-operator-system` namespace
   - Maps all secrets across the infrastructure

2. **Secret Distribution**:
   - Applications reference secrets using the `bitwarden.com/source-secret: infrastructure-secrets` annotation
   - SM Operator automatically syncs secrets to appropriate namespaces
   - No need for manual secret copying between namespaces

### Example Application Secret

For a new application requiring secrets:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  namespace: app-namespace
  annotations:
    bitwarden.com/sync: "true"
    bitwarden.com/source-secret: infrastructure-secrets  # References the central secret
type: Opaque
stringData:
  # Uses the secretKeyName from the central BitwardenSecret mapping
  config.yaml: "{{ .app_config }}"
```

### Benefits of This Pattern

1. **Simplified Management**:
   - Single point of configuration in BitwardenSecret
   - Clear mapping between Bitwarden and Kubernetes secrets
   - Easier secret rotation and auditing

2. **GitOps Friendly**:
   - Secret templates can be version controlled
   - No sensitive data in Git
   - Automated secret distribution

3. **Scalability**:
   - Easy to add new applications
   - Consistent secret handling across namespaces
   - Reduced operational overhead

## Integration with Security Architecture

### Zero Trust Integration

The Bitwarden Secrets Manager integrates with the homelab's zero-trust architecture:

1. **Authentication Chain**:
   - SM Operator authenticates with Bitwarden using machine tokens
   - Applications authenticate to Kubernetes to access secrets
   - All secret access is audited and logged

2. **Security Zones**:
   ```mermaid
   graph TB
       Bitwarden[Bitwarden Secrets Manager]
       SMOperator[SM Operator]
       K8SSecrets[Kubernetes Secrets]
       Apps[Applications]

       Bitwarden -->|Machine Token| SMOperator
       SMOperator -->|Sync| K8SSecrets
       Apps -->|Mount| K8SSecrets
   ```

### Compliance with Security Standards

1. **Secret Lifecycle**:
   - Creation through Bitwarden UI/API
   - Distribution via SM Operator
   - Rotation through Bitwarden
   - Deletion with proper garbage collection

2. **Security Controls**:
   - No secrets in Git repositories
   - Encryption at rest in Kubernetes
   - Network policy restrictions
   - Regular access auditing

3. **Emergency Procedures**:
   - Token revocation process
   - Manual secret sync capabilities
   - Disaster recovery procedures

### Security Best Practices

1. **Access Control**:
   ```yaml
   security_controls:
     rbac:
       - Namespace-level secret access
       - Service account restrictions
       - Pod security context enforcement
     monitoring:
       - Access logging
       - Usage metrics
       - Anomaly detection
   ```

2. **Secret Distribution**:
   - Least privilege principle
   - Just-in-time access where possible
   - Regular access reviews
   - Automated rotation schedules

3. **Integration Points**:
   - Works alongside Cert-Manager for TLS
   - Integrates with authentication stack
   - Supports backup encryption
   - Enables GitOps workflows

## Component Integration Guide

### Infrastructure Dependencies

The sm-operator has the following key dependencies:

1. **Pre-requisites**:
   - Running Kubernetes cluster
   - Network access to Bitwarden API
   - Authentication token configured

2. **Co-requisites**:
   - Cilium for network policies
   - Cert-manager for TLS certificates
   - RBAC configuration

### Common Integration Patterns

1. **Database Credentials**:
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: db-creds
     namespace: database
     annotations:
       bitwarden.com/sync: "true"
       bitwarden.com/source-secret: infrastructure-secrets
   type: Opaque
   stringData:
     username: "{{ .db_user }}"
     password: "{{ .db_password }}"
   ```

2. **TLS Certificates**:
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: tls-auth
     namespace: cert-manager
     annotations:
       bitwarden.com/sync: "true"
       bitwarden.com/source-secret: infrastructure-secrets
   type: Opaque
   stringData:
     api-token: "{{ .cloudflare_api_token }}"
   ```

3. **Authentication Config**:
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: oidc-config
     namespace: auth
     annotations:
       bitwarden.com/sync: "true"
       bitwarden.com/source-secret: infrastructure-secrets
   type: Opaque
   stringData:
     config.yaml: "{{ .oidc_config }}"
   ```

### Bootstrap Order

For new cluster deployments:

1. **Phase 1 (Pre-requisites)**:
   - Deploy Kubernetes cluster
   - Configure network access
   - Apply CRDs

2. **Phase 2 (Core Security)**:
   - Deploy Cilium networking
   - Configure network policies
   - Deploy sm-operator

3. **Phase 3 (Secret Distribution)**:
   - Create auth token secret
   - Deploy BitwardenSecret resource
   - Verify secret sync

4. **Phase 4 (Dependencies)**:
   - Deploy cert-manager
   - Configure authentication
   - Deploy applications

### Dependent Components

Key components that depend on sm-operator:

1. **Authentication Stack**:
   - Authelia configurations
   - OIDC client secrets
   - LLDAP credentials

2. **Networking**:
   - Cloudflared tokens
   - API credentials
   - TLS certificates

3. **Storage**:
   - Database credentials
   - Backup encryption keys
   - CSI provider secrets
