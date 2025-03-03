# Secrets Management

## Overview

This document describes how secrets are managed in the homelab infrastructure using Bitwarden Secrets Manager Operator
(sm-operator).

⚠️ **Important**: Direct volume mounting of secrets is strictly prohibited. All secrets must be managed through the
Bitwarden Secrets Manager Operator.

## Core Components

### Bitwarden SM Operator

The sm-operator provides:

- GitOps integration for secret management
- Automatic secret synchronization
- Version control safety
- Audit logging capabilities

### Secret Types

1. **Infrastructure Secrets**

   - Cluster certificates
   - API tokens
   - Service account keys
   - Infrastructure credentials

2. **Application Secrets**
   - Database credentials
   - API keys
   - OAuth credentials
   - Service tokens

## Implementation Details

### Prohibited Practices

The following secret management practices are explicitly forbidden:

- Direct volume mounting of secrets in pods
- Using local secret volumes
- Manual secret creation via kubectl
- Using legacy SealedSecrets
- Storing unencrypted secrets in Git

### Secret Management Process

1. **Initial Setup**

   - Create bw-auth-token secret in each namespace that needs secrets
   - Token must be created manually using kubectl create secret
   - Each namespace requires its own auth token

2. **Secret Configuration**
   - Create BitwardenSecret resources in each namespace
   - Use UUID mapping to create friendly secret names
   - Follow least privilege principle for token access

### BitwardenSecret Configuration

Example BitwardenSecret configuration:

```yaml
apiVersion: k8s.bitwarden.com/v1
kind: BitwardenSecret
metadata:
  name: app-secrets
  namespace: app-namespace
  labels:
    app.kubernetes.io/name: bitwardensecret
    app.kubernetes.io/instance: app-secrets
    app.kubernetes.io/part-of: sm-operator
    app.kubernetes.io/managed-by: kustomize
    app.kubernetes.io/created-by: sm-operator
spec:
  organizationId: '4a014e57-f197-4852-9831-b287013e47b6' # Your Bitwarden org ID
  secretName: app-generated-secret
  map:
    - bwSecretId: 'your-secret-uuid'
      secretKeyName: 'friendly-name'
  authToken:
    secretName: bw-auth-token
    secretKey: token
```

## Security Model

### Access Control

- Service account based authentication
- Token-based access
- Time-limited access tokens
- Audit logging enabled
- RBAC integration
- Namespace isolation
- Minimal permissions
- Regular access review

### Secret Storage

1. **Encryption**

   - At-rest encryption
   - In-transit encryption
   - Key rotation
   - Backup encryption

2. **Backup**
   - Regular backups
   - Encrypted storage
   - Version history
   - Recovery testing

## Best Practices

### Secret Management

1. **Naming Convention**

   ```yaml
   secret_naming:
     format: '{app}-{environment}-{type}'
     example: 'postgres-prod-credentials'
   ```

2. **Access Patterns**
   - Least privilege access
   - Regular token rotation
   - Access logging
   - Namespace isolation

### Security Controls

1. **Network Security**

   - Internal network only
   - mTLS enforcement
   - Network policies
   - Traffic encryption

2. **Monitoring**
   - Access auditing
   - Usage tracking
   - Error monitoring
   - Rotation status
