# Authentication Configuration

## Overview

Authentication in the cluster is handled primarily by Authelia, providing SSO and MFA capabilities for all exposed
services.

## Components

### Authelia

- URL: authelia.kube.pc-tips.se
- Features:
  - Single Sign-On
  - Multi-factor authentication
  - User directory integration
  - Session management

## Configuration

### Integration with Ingress

```yaml
# Standard ingress annotations for authentication
annotations:
  nginx.ingress.kubernetes.io/auth-url: 'https://authelia.kube.pc-tips.se/api/verify'
  nginx.ingress.kubernetes.io/auth-signin: 'https://authelia.kube.pc-tips.se'
  nginx.ingress.kubernetes.io/auth-response-headers: 'Remote-User,Remote-Groups,Remote-Name,Remote-Email'
```

### Access Control Rules

```yaml
access_control:
  default_policy: deny
  rules:
    - domain: '*.kube.pc-tips.se'
      policy: two_factor
      subject:
        - ['group:admin']
    - domain: 'grafana.kube.pc-tips.se'
      policy: two_factor
      subject:
        - ['group:monitoring']
```

## User Management

- LDAP integration
- Local user database
- Group-based access control
- Password policies

## Security Considerations

- Session timeouts
- IP-based rate limiting
- Failed authentication monitoring
- Audit logging
