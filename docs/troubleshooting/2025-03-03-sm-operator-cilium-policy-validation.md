# SM Operator Cilium Policy Validation

## Date

2025-03-03

## Category

- Networking
- Security
- Configuration

## Status

Resolved

## Impact

- Network policies not enforcing correctly
- External connectivity issues for sm-operator
- Unable to reach Bitwarden API endpoints
- Potential security implications due to invalid policy state

## Root Cause

1. Cilium network policy was marked as invalid due to:

   - FQDN regex compilation LRU not initialized
   - Wildcarded FQDN patterns not properly supported
   - DNS-based policy rules not properly configured

2. Policy validation failures preventing proper enforcement of:
   - External API access
   - DNS resolution
   - TLS connections

## Detection

- Cilium policy status showed VALID: False
- Error message: "FQDN regex compilation LRU not yet initialized"
- Network connectivity failures to external endpoints

## Resolution

1. Restructured network policy to use explicit CIDR rules instead of FQDN patterns:

   - Added specific IP ranges for Bitwarden API endpoints (199.232.193.91/32, 199.232.197.91/32)
   - Configured explicit DNS resolution rules
   - Defined port-specific access rules

2. Updated policy configuration:

```yaml
spec:
  egress:
    - toCIDRSet:
        - cidr: '199.232.193.91/32'
        - cidr: '199.232.197.91/32'
      toPorts:
        - ports:
            - port: '443'
              protocol: TCP
```

## Prevention

1. Policy Validation:

   - Implement policy validation in CI/CD pipeline
   - Create policy templates for common use cases
   - Document policy requirements for external services

2. DNS Configuration:
   - Document DNS resolution requirements
   - Maintain list of required external endpoints
   - Regular policy audits

## Related Issues

- Leader election timeout
- External API connectivity
- DNS resolution problems

## Notes

- FQDN-based policies require careful configuration
- Consider maintaining IP allowlist for critical external services
- Regular validation of network policies is essential
- Document external service dependencies
