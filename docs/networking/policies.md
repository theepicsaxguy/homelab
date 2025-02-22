# Network Policies

## Overview

Network policies implement a zero-trust security model using Cilium's network policy features.

## Default Policies

### Namespace Isolation

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: deny-from-other-namespaces
spec:
  endpointSelector:
    matchLabels: {}
  ingress:
    - fromEndpoints:
        - matchLabels:
            io.kubernetes.pod.namespace: kube-system
    - fromEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: $NAMESPACE
```

### Monitoring Access

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-monitoring
spec:
  endpointSelector:
    matchLabels: {}
  ingress:
    - fromEndpoints:
        - matchLabels:
            io.kubernetes.pod.namespace: monitoring
      toPorts:
        - ports:
            - port: '9090'
              protocol: TCP
```

## Service-Specific Policies

### Database Access

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: database-policy
spec:
  endpointSelector:
    matchLabels:
      app: database
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: backend
      toPorts:
        - ports:
            - port: '5432'
```

## Policy Best Practices

### General Guidelines

1. **Default Deny**

   - Start with deny-all
   - Add explicit allows
   - Document exceptions
   - Regular review

2. **Least Privilege**
   - Minimal required access
   - Port-specific rules
   - Protocol enforcement
   - Service isolation

### Monitoring

1. **Policy Observability**

   - Hubble integration
   - Flow monitoring
   - Drop tracking
   - Policy audit logs

2. **Alert Configuration**
   - Policy violations
   - Unexpected drops
   - Access attempts
   - Pattern changes

## Implementation Examples

### Web Application Stack

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: web-policy
spec:
  endpointSelector:
    matchLabels:
      app: web
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: frontend
      toPorts:
        - ports:
            - port: '8080'
  egress:
    - toEndpoints:
        - matchLabels:
            app: backend
      toPorts:
        - ports:
            - port: '9000'
```

## Security Considerations

### Policy Validation

- Regular testing
- CI/CD integration
- Compliance checking
- Impact assessment

### Emergency Access

- Break-glass procedures
- Temporary exceptions
- Audit requirements
- Restoration process
