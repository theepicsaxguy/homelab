# Network Policies

## Overview

Network policies implement a zero-trust security model using Cilium's network policy features and Gateway API
integration.

## Gateway Policies

### Gateway Access Control

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: gateway-access
spec:
  endpointSelector:
    matchLabels:
      io.cilium.k8s.policy.gateway: 'true'
  ingress:
    - fromEntities:
        - world
      toPorts:
        - ports:
            - port: '443'
              protocol: TCP
            - port: '80'
              protocol: TCP
    - fromEndpoints:
        - matchLabels:
            io.kubernetes.pod.namespace: kube-system
```

### Route-Specific Policies

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: route-policy
spec:
  endpointSelector:
    matchLabels:
      app: backend
  ingress:
    - fromEndpoints:
        - matchLabels:
            gateway.networking.k8s.io/gateway: 'true'
      toPorts:
        - ports:
            - port: '8080'
```

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
    - fromEndpoints:
        - matchLabels:
            gateway.networking.k8s.io/gateway: 'true'
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

### Authentication Flow

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: auth-flow
spec:
  endpointSelector:
    matchLabels:
      app: authelia
  ingress:
    - fromEndpoints:
        - matchLabels:
            gateway.networking.k8s.io/gateway: 'true'
      toPorts:
        - ports:
            - port: '9091'
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

### Gateway-Aware Database Access

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
            gateway.networking.k8s.io/route: 'true'
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

### Gateway Integration

1. **Gateway Classification**

   - Label gateways appropriately
   - Separate external/internal policies
   - TLS termination controls
   - Route-specific rules

2. **Route Security**
   - Authentication requirements
   - Rate limiting per route
   - Protocol enforcement
   - Header-based policies

### Policy Hierarchy

1. **Gateway Level**

   - External access controls
   - Protocol requirements
   - Global rate limits
   - TLS enforcement

2. **Route Level**

   - Service-specific rules
   - Authentication requirements
   - Custom rate limits
   - Header manipulation

3. **Service Level**
   - Backend access controls
   - Inter-service communication
   - Monitoring access
   - Database connections

## Monitoring and Observability

### Gateway Metrics

- Policy enforcement status
- Drop/accept statistics
- Rate limit breaches
- Authentication failures

### Traffic Analysis

- Hubble flow monitoring
- L7 protocol visibility
- Policy evaluation traces
- Gateway access patterns

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

### Secure Web Application

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: web-gateway-policy
spec:
  endpointSelector:
    matchLabels:
      app: web
  ingress:
    - fromEndpoints:
        - matchLabels:
            gateway.networking.k8s.io/gateway: 'true'
      toPorts:
        - ports:
            - port: '8080'
          rules:
            http:
              - method: 'GET'
                path: '/api/v1/.*'
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

### Policy Validation

- Gateway configuration testing
- Route attachment verification
- TLS certificate validation
- Authentication flow testing

### Emergency Procedures

- Gateway policy exceptions
- Temporary route bypasses
- Authentication overrides
- Recovery procedures

## Troubleshooting

### Common Issues

1. **Gateway Access Problems**

   ```bash
   # Check gateway policy status
   kubectl get cnp
   cilium policy get
   ```

2. **Route Authentication**

   ```bash
   # Verify auth flow
   kubectl logs -n auth -l app=authelia
   cilium monitor --type drop
   ```

3. **Policy Conflicts**
   ```bash
   # Debug policy resolution
   cilium policy trace
   kubectl describe cnp
   ```
