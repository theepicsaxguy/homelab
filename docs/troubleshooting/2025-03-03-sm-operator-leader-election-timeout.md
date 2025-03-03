# SM Operator Leader Election Timeout

## Date

2025-03-03

## Category

- Configuration
- Kubernetes
- Networking

## Status

Resolved

## Impact

- SM Operator unable to establish leader election
- Secrets synchronization failing
- Service disruption for applications depending on Bitwarden secrets

## Root Cause

The sm-operator pod was unable to reach the Kubernetes API server (10.96.0.1:443) due to:

1. Missing Cilium network policy for API server access
2. Network connectivity issues between the pod and API server
3. Leader election lease unable to be acquired due to network policy restrictions

## Detection

Error logs from sm-operator showed:

```
error retrieving resource lock sm-operator-system/479cde60.bitwarden.com: Get "https://10.96.0.1:443/apis/coordination.k8s.io/v1/namespaces/sm-operator-system/leases/479cde60.bitwarden.com": dial tcp 10.96.0.1:443: i/o timeout
```

## Resolution

1. Created a Cilium Network Policy to allow:
   - Access to kube-apiserver
   - DNS resolution via kube-dns
   - Required ports and protocols

Network policy configuration:

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-sm-operator-api-access
  namespace: sm-operator-system
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: sm-operator
      app.kubernetes.io/instance: sm-operator
  egress:
    - toEntities:
        - kube-apiserver
    - toEndpoints:
        - matchLabels:
            k8s:k8s-app: kube-dns
      toPorts:
        - ports:
            - port: '53'
              protocol: UDP
```

## Prevention

1. Network Configuration:

   - Document required network policies for new operators
   - Implement policy templates for common patterns
   - Add network policy validation in CI/CD

2. Monitoring:
   - Add alerts for leader election failures
   - Monitor API server connectivity
   - Track network policy enforcement

## Related Issues

- Cilium Network Policy Enforcement
- API Server Connectivity
- DNS Resolution

## Notes

- Leader election is critical for operator functionality
- Network policies should be defined before deploying operators
- Consider implementing network policy templates
