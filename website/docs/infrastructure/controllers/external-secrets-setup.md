---
sidebar_position: 2
title: External Secrets Setup
description: Configuration and usage guide for External Secrets Operator with Bitwarden
---

# External Secrets Configuration

This guide covers the setup and usage of External Secrets Operator (ESO) for managing Kubernetes secrets using Bitwarden as the backend.

## Initial Setup

### Certificate Trust Configuration

First, ensure proper certificate trust for external services:

```bash
# Download Let's Encrypt Root certificate
curl -Lo isrgrootx1.pem https://letsencrypt.org/certs/isrgrootx1.pem

# Create certificate trust secret
kubectl create secret generic letsencrypt-ca \
  --namespace external-secrets \
  --from-file=ca.crt=isrgrootx1.pem
```

### Bitwarden Integration

Create the Bitwarden access token secret:

```bash
kubectl create secret generic bitwarden-access-token \
  --namespace external-secrets \
  --from-literal=token=<your-token>
```

## ClusterSecretStore Configuration

Define the Bitwarden backend configuration:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: bitwarden
spec:
  provider:
    bitwarden:
      auth:
        secretRef:
          key: token
          name: bitwarden-access-token
          namespace: external-secrets
      url: https://bitwarden.pc-tips.se
```

## Usage Examples

### Basic Secret

Create a secret from a Bitwarden entry:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-application-secret
  namespace: apps
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: bitwarden
  target:
    name: app-secret
    template:
      engineVersion: v2
      data:
        username: "{{ .username }}"
        password: "{{ .password }}"
  data:
    - secretKey: username
      remoteRef:
        key: my-app-credentials
        property: username
    - secretKey: password
      remoteRef:
        key: my-app-credentials
        property: password
```

### TLS Certificate

Store and retrieve TLS certificates:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: tls-secret
  namespace: network
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: bitwarden
  target:
    name: tls-cert
    template:
      type: kubernetes.io/tls
      data:
        tls.crt: "{{ .certificate }}"
        tls.key: "{{ .private_key }}"
  data:
    - secretKey: certificate
      remoteRef:
        key: domain-tls
        property: certificate
    - secretKey: private_key
      remoteRef:
        key: domain-tls
        property: key
```

## Secret Templates

### Environment Variables

Template for application environment variables:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-env
  namespace: apps
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: bitwarden
  target:
    name: app-env-secret
    template:
      engineVersion: v2
      data:
        .env: |
          DB_USER={{ .database.username }}
          DB_PASSWORD={{ .database.password }}
          API_KEY={{ .api.key }}
  data:
    - secretKey: database
      remoteRef:
        key: app-database
    - secretKey: api
      remoteRef:
        key: app-api-credentials
```

## Security Considerations

### Access Control

- Use namespace-specific ServiceAccounts
- Implement minimal RBAC permissions
- Regularly rotate access tokens
- Monitor secret access events

### Network Policies

Restrict ESO network access:

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: external-secrets
  namespace: external-secrets
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: external-secrets
  egress:
    - toFQDNs:
        - matchName: bitwarden.pc-tips.se
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
```

## Monitoring

### Metrics Collection

ESO exposes Prometheus metrics:

```yaml
serviceMonitor:
  enabled: true
  interval: 30s
  scrapeTimeout: 10s
  namespace: external-secrets
```

### Alert Rules

Important metrics to monitor:

```yaml
alerts:
  - sync_errors_total
  - secret_refresh_failures
  - provider_errors
```

## Troubleshooting

### Common Issues

1. **Secret Sync Failures**
   - Check Bitwarden connectivity
   - Verify token permissions
   - Review ESO logs

2. **Certificate Issues**
   - Verify certificate trust
   - Check SSL/TLS versions
   - Validate certificate chain

3. **Permission Problems**
   - Review RBAC settings
   - Check ServiceAccount
   - Verify namespace access

### Debug Commands

```bash
# Check ESO logs
kubectl -n external-secrets logs -l app.kubernetes.io/name=external-secrets

# Verify secret status
kubectl get externalsecret -A

# Test Bitwarden access
kubectl -n external-secrets exec -it \
  $(kubectl -n external-secrets get pod -l app.kubernetes.io/name=external-secrets -o name) \
  -- curl -v https://bitwarden.pc-tips.se
```
