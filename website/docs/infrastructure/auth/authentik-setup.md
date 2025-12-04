---
sidebar_position: 1
title: Authentik Setup Guide
description: Comprehensive guide for Authentik SSO configuration and integration
---

# Authentik SSO Integration Guide

This guide covers the setup and management of Authentik Single Sign-On (SSO) in my Kubernetes cluster.

## Architecture Overview

Authentik is deployed with two main components:

1. **Authentik Server**
   - Core authentication service
   - User management interface
   - Policy configuration
   - Accessible at https://sso.your.domain.tld

2. **Proxy Outpost**
   - Authentication proxy (ports 9000/9443)
   - Handles SSO for protected applications
   - Integrated with Cilium Gateway API

## Proxy Architecture

```mermaid
graph LR
    A[External User] --> B[Gateway API]
    B --> C[Authentik Proxy]
    C --> D[Auth Flow]
    D --> E[Internal Service]
    C -.-> F[Authentik Server]
```

## Kubernetes API Authentication

Cluster logins go through Authentik using a dedicated OAuth 2.0 provider:

```yaml
apiServer:
  extraArgs:
    oidc-issuer-url: https://sso.your.domain.tld/application/o/kubectl/
    oidc-client-id: kubectl
    oidc-username-claim: preferred_username
    oidc-groups-claim: groups
```

Add your users to the **Kubectl Users** group in Authentik to grant access.

## Blueprint Users

Two sample accounts are bootstrapped via Authentik blueprints to show how group membership controls access:

- **admin-user**: belongs to every user group and sits in the ArgoCD and Grafana admin groups.
- **standard-user**: a regular account added to the same user groups without admin privileges.

Passwords and emails come from ExternalSecrets entries referenced in `authentik-blueprint-secrets`.

## Database Backups

The database backups upload to MinIO with credentials managed by an ExternalSecret:

```yaml
# k8s/infrastructure/auth/authentik/minio-externalsecret.yaml
spec:
  target:
    name: longhorn-minio-credentials
```

## Configuration Guide

### 1. Protecting a New Application

#### Step 1: Authentik Configuration

1. Access Authentik admin interface (https://sso.your.domain.tld)
2. Create a new Proxy Provider:
   ```yaml
   name: my-application
   external_host: app.your.domain.tld
   internal_host: http://my-service.namespace.svc:8080
   mode: forward_single
   ```
3. Create an Application:
   ```yaml
   name: My Application
   slug: my-application
   provider: my-application-proxy
   policy_engine_mode: any
   ```

#### Step 2: Gateway Configuration

Create an HTTPRoute:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-application
  namespace: my-namespace
spec:
  parentRefs:
    - name: external  # or internal based on access needs
      namespace: gateway
  hostnames:
    - "app.your.domain.tld"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: ak-outpost-authentik-embedded-outpost
          namespace: auth
          port: 9000
```

### 2. Security Best Practices

#### Network Policies

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-ak-outpost-authentik-embedded-outpost
  namespace: my-namespace
spec:
  endpointSelector:
    matchLabels:
      app: my-service
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: ak-outpost-authentik-embedded-outpost
            io.kubernetes.pod.namespace: auth
```

#### TLS Configuration

- Always use HTTPS for external access
- Certificates managed by cert-manager
- Internal communication can use HTTP

## Maintenance Guide

### 1. Regular Tasks

- Monitor Authentik logs for security events
- Review access policies quarterly
- Update Authentik version when available
- Rotate API tokens annually

### 2. Troubleshooting

#### Authentication Issues

1. Check Proxy Status:
```shell
kubectl -n auth logs -l app=ak-outpost-authentik-embedded-outpost
```

2. Verify Network Policies:
```shell
kubectl -n auth get ciliumnetworkpolicies
```

3. Test Authentication Flow:
```shell
curl -v "https://app.your.domain.tld"
# Should redirect to SSO
```

#### Common Issues

1. **503 Service Unavailable**
   - Check Proxy deployment status
   <!-- vale off -->
   - Verify backend service health
   <!-- vale on -->
   - Review network policies

2. **Authentication Loop**
   - Clear browser cookies
   - Check Provider configuration
   - Verify cookie domains

<!-- vale off -->
3. **Backend Unreachable**
   - Verify service DNS resolution
   - Check network policy rules
   - Validate service ports
<!-- vale on -->

## Integration Examples

### Basic Web Application

```yaml
# HTTPRoute for a basic web app
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: webapp
  namespace: apps
spec:
  parentRefs:
    - name: external
      namespace: gateway
  hostnames:
    - "webapp.your.domain.tld"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: ak-outpost-authentik-embedded-outpost
          namespace: auth
          port: 9000
```

### API Service

```yaml
# HTTPRoute for an API service
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api
  namespace: services
spec:
  parentRefs:
    - name: internal
      namespace: gateway
  hostnames:
    - "api.internal.your.domain.tld"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: ak-outpost-authentik-embedded-outpost
          namespace: auth
          port: 9000
```

## Performance Optimization

1. **Caching Configuration**
   - Enable Redis caching
   - Configure appropriate TTLs
   - Monitor cache hit rates

2. **Resource Allocation**
   ```yaml
   resources:
     requests:
       cpu: 500m
       memory: 512Mi
     limits:
       cpu: 1000m
       memory: 1Gi
   ```

## Monitoring

### Key Metrics

- Authentication success/failure rates
- Response times
- Session counts
- Token validity

### Alert Rules

```yaml
alerts:
  - auth_failure_rate > 10%
  - response_time_95th > 2s
  - proxy_5xx_rate > 1%
```
