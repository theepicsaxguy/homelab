# Secrets Management

## Overview

This document describes how secrets are managed in the homelab infrastructure using Bitwarden Secrets Manager Operator (sm-operator).

## Core Components

### Bitwarden SM Operator

```yaml
components:
  sm_operator:
    version: latest
    features:
      - GitOps integration
      - Automatic secret rotation
      - Version control safety
      - Audit logging
```

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

## Security Model

### Access Control

```yaml
access_control:
  authentication:
    - Service account based
    - Token authentication
    - Time-limited access
    - Audit logging
  authorization:
    - RBAC integration
    - Namespace isolation
    - Minimal permissions
    - Regular review
```

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

## GitOps Integration

### Workflow

1. **Secret Creation**
   - Secret defined in Git (encrypted)
   - ArgoCD syncs configuration
   - Operator fetches from Bitwarden
   - Secret created in cluster

2. **Secret Updates**
   - Update in Bitwarden
   - Operator detects change
   - Automatic rotation
   - Version control

## Best Practices

### Secret Management

1. **Naming Convention**
   ```yaml
   secret_naming:
     format: "{app}-{environment}-{type}"
     example: "postgres-prod-credentials"
   ```

2. **Access Patterns**
   - Least privilege access
   - Temporary permissions
   - Regular rotation
   - Access logging

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

## Zero Trust Integration

### Authentication Chain

1. **Service Authentication**
   - Service account tokens
   - mTLS certificates
   - Limited scope access
   - Regular rotation

2. **User Authentication**
   - Multi-factor auth
   - SSO integration
   - Session management
   - Access auditing

### Security Controls

1. **Infrastructure**
   - Encrypted storage
   - Network isolation
   - Access logging
   - Change tracking

2. **Application**
   - Secret injection
   - Environment isolation
   - Version control
   - Rotation policies

## Implementation Details

### Setup Process

```yaml
installation:
  namespace: sm-operator-system
  components:
    - SM operator deployment
    - BitwardenSecret CRD
    - RBAC configuration
```

### Central Secret Configuration

1. **Main BitwardenSecret Resource**
   - Located in `sm-operator-system` namespace
   - Maps all secrets across the infrastructure

2. **Secret Distribution**
   - Applications reference secrets using the `bitwarden.com/source-secret: infrastructure-secrets` annotation
   - SM Operator automatically syncs secrets to appropriate namespaces
   - No need for manual secret copying between namespaces

### Application Integration

Example application secret configuration:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  namespace: app-namespace
  annotations:
    bitwarden.com/sync: 'true'
    bitwarden.com/source-secret: infrastructure-secrets # References the central secret
type: Opaque
stringData:
  # Uses the secretKeyName from the central BitwardenSecret mapping
  config.yaml: '{{ .app_config }}'
```

### Implementation Benefits

1. **Simplified Management**
   - Single point of configuration in BitwardenSecret
   - Clear mapping between Bitwarden and Kubernetes secrets
   - Easier secret rotation and auditing

2. **GitOps Friendly**
   - Secret templates can be version controlled
   - No sensitive data in Git
   - Automated secret distribution

3. **Scalability**
   - Easy to add new applications
   - Centralized management
   - Automated synchronization
