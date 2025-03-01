# Gateway API Configuration

## Overview

The cluster uses Gateway API with Cilium as the gateway controller, providing a modern approach to service networking
and ingress management.

## Gateway Architecture

### Components

- Cilium Gateway Controller
- Gateway API CRDs
- Cert-manager for SSL
- External-DNS for DNS management
- Authelia for authentication

### Gateway Classes

The cluster uses a single GatewayClass `cilium` with three gateway types:

- External Gateway (Internet-facing services)
- Internal Gateway (Cluster-local services)
- TLS Passthrough Gateway (Direct TLS termination)

## Standard Configurations

### External Gateway

### Standard Configuration

```yaml
annotations:
  cert-manager.io/cluster-issuer: 'letsencrypt-prod'
  nginx.ingress.kubernetes.io/ssl-redirect: 'true'
  nginx.ingress.kubernetes.io/force-ssl-redirect: 'true'
  nginx.ingress.kubernetes.io/auth-url: 'https://authelia.kube.pc-tips.se/api/verify'
  nginx.ingress.kubernetes.io/auth-signin: 'https://authelia.kube.pc-tips.se/'
```

## SSL Management

- Automatic certificate provisioning
- Let's Encrypt integration
- Certificate renewal automation
- HTTPS enforcement

## Security Configuration

### TLS Settings

- TLS 1.3 only
- Strong cipher suites
- HSTS enabled
- HTTP redirect to HTTPS

### Authentication

- Authelia integration
- Session management
- 2FA where configured
- Access control rules

## Authentication Flow

1. Request hits ingress
2. Authelia verification
3. SSO if authenticated
4. Redirect to login if needed

## Rate Limiting

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: app-ingress
  annotations:
    # Standard security headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-XSS-Protection: 1; mode=block";
spec:
  rules:
    - host: app.kube.pc-tips.se
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-service
                port:
                  number: 80
  tls:
    - hosts:
        - app.kube.pc-tips.se
      secretName: app-tls
```
