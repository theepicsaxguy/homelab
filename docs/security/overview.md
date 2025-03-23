# Security Architecture

## Overview

Multi-layered security architecture implementing zero-trust principles across infrastructure, network, and application
layers.

## Core Components

### Authentication (Authelia)

```yaml
authelia:
  access_control:
    default_policy: deny
    rules:
      - domain: '*.kube.pc-tips.se'
        policy: two_factor
        networks:
          - 10.0.0.0/8
      - domain: 'grafana.kube.pc-tips.se'
        policy: two_factor
      - domain: 'argocd.kube.pc-tips.se'
        policy: two_factor

  authentication_backend:
    password_reset:
      disable: false
    refresh_interval: 5m

  session:
    expiration: 4h
    inactivity: 30m
    remember_me_duration: 30d
```

### Network Security (Cilium)

```yaml
network_policies:
  default:
    ingress: deny
    egress: deny

  monitoring:
    ingress:
      - from: monitoring
        ports: [9090, 9091, 9093]
    egress:
      - to: all-namespaces
        ports: [9090, 9100]

  authentication:
    ingress:
      - from: gateway-system
        ports: [9091]
    egress:
      - to: ldap
        ports: [636]
```

### Secret Management

```yaml
bitwarden_operator:
  sync_interval: 5m
  namespaces:
    - argocd
    - cert-manager
    - monitoring
    - gateway-system

  access_control:
    collections:
      - id: 'production'
        namespaces: ['prod-*']
      - id: 'staging'
        namespaces: ['staging-*']
```

## Infrastructure Security

### Node Security (Talos)

```yaml
talos:
  kubernetes:
    allowSchedulingOnControlPlanes: false

  network:
    interfaces:
      - interface: eth0
        dhcp: true
        vip:
          ip: 10.25.150.10

  sysctls:
    net.ipv4.ip_forward: '0'
    net.ipv6.conf.all.forwarding: '0'
    kernel.unprivileged_bpf_disabled: '1'
```

### Container Security

```yaml
pod_security_standards:
  enforce:
    - restricted
  audit:
    - restricted
  warn:
    - restricted

seccomp_profiles:
  default:
    defaultAction: SCMP_ACT_ERRNO
    architectures:
      - SCMP_ARCH_X86_64
      - SCMP_ARCH_ARM64
```

## Monitoring & Compliance

### Security Monitoring

```yaml
falco:
  rules:
    custom_rules:
      - macro: admin_namespaces
        items: [kube-system, argocd]

      - rule: Unauthorized Pod Namespace Change
        desc: Detect attempts to create/modify pods in admin namespaces
        condition: >-
          kevt.category=create and kevt.type=pod and ka.target.namespace in (admin_namespaces)
        output: 'Pod creation in admin namespace (user=%ka.user.name ns=%ka.target.namespace)'
        priority: CRITICAL
```

### Audit Logging

```yaml
audit_policy:
  rules:
    - level: RequestResponse
      resources:
        - group: ''
          resources: ['secrets', 'configmaps']

    - level: Metadata
      resources:
        - group: 'apps'
          resources: ['deployments', 'statefulsets']

    - level: None
      users: ['system:kube-proxy']
      resources:
        - group: '' # core
          resources: ['endpoints', 'services', 'services/status']
```

## Access Control

### RBAC Configuration

```yaml
roles:
  developer:
    rules:
      - apiGroups: ['', 'apps']
        resources: ['pods', 'deployments']
        verbs: ['get', 'list', 'watch']
      - apiGroups: ['monitoring.coreos.com']
        resources: ['servicemonitors']
        verbs: ['get', 'list', 'watch']

  operator:
    rules:
      - apiGroups: ['', 'apps']
        resources: ['*']
        verbs: ['*']
      - apiGroups: ['monitoring.coreos.com']
        resources: ['*']
        verbs: ['*']
```

### Service Accounts

```yaml
service_accounts:
  monitoring:
    name: prometheus-k8s
    namespace: monitoring
    roles:
      - monitoring-reader

  deployment:
    name: argocd-application-controller
    namespace: argocd
    roles:
      - application-controller
```

## Certificate Management

### Cert-Manager Configuration

```yaml
cert_manager:
  issuers:
    letsencrypt-prod:
      server: https://acme-v02.api.letsencrypt.org/directory
      email: admin@pc-tips.se
      privateKeySecretRef:
        name: letsencrypt-prod
      solvers:
        - dns01:
            cloudflare:
              email: admin@pc-tips.se
              apiTokenSecretRef:
                name: cloudflare-api-token
                key: api-token
```

## Environment-Specific Security

### Development

```yaml
security_config:
  authentication:
    mode: relaxed
  network_policies:
    default: allow
  monitoring:
    audit: minimal
```

### Production

```yaml
security_config:
  authentication:
    mode: strict
    session_timeout: 4h
  network_policies:
    default: deny
  monitoring:
    audit: complete
    retention: 90d
```

## Incident Response

### Detection

- Real-time threat monitoring
- Behavioral analysis
- Anomaly detection
- Alert correlation

### Response Procedures

1. Incident Classification
2. Containment Strategy
3. Evidence Collection
4. Root Cause Analysis
5. Recovery Process

### Recovery Plans

- System Restoration
- Data Recovery
- Service Continuity
- Post-Incident Review
