# Ingress Configuration

## Overview

The cluster uses ingress-nginx as the primary ingress controller, with standardized configurations for SSL,
authentication, and routing.

## Ingress Architecture

### Components

- ingress-nginx controller
- Cert-manager for SSL
- External-DNS for DNS management
- Authelia for authentication

### Standard Configuration

```yaml
annotations:
  cert-manager.io/cluster-issuer: 'letsencrypt-prod'
  nginx.ingress.kubernetes.io/ssl-redirect: 'true'
  nginx.ingress.kubernetes.io/force-ssl-redirect: 'true'
  nginx.ingress.kubernetes.io/auth-url: 'https://authelia.pc-tips.se/api/verify'
  nginx.ingress.kubernetes.io/auth-signin: 'https://authelia.pc-tips.se/'
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
rate_limits:
  default:
    rate: 100r/s
    burst: 200
  authenticated:
    rate: 200r/s
    burst: 400
```

## Monitoring Integration

### Metrics

- Request rate
- Error rate
- Latency
- SSL handshake timing

### Alerts

- High error rate
- Certificate expiration
- Authentication failures
- Latency spikes

## Example Configuration

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
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
    - host: app.pc-tips.se
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
        - app.pc-tips.se
      secretName: app-tls
```
