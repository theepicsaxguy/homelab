# SM Operator Bitwarden API Connectivity

## Date

2025-03-03

## Category

- Authentication
- Networking
- Configuration

## Status

In Progress

## Impact

- Unable to sync secrets from Bitwarden
- Authentication failures to Bitwarden API
- Applications depending on Bitwarden secrets potentially affected
- BitwardenSecret resources not reconciling

## Root Cause

1. Circular dependency in auth token configuration:

   - BitwardenSecret CRD attempting to use itself for bootstrapping
   - Auth token secret being managed by the operator that needs it
   - Configuration trying to pull auth token using the auth token itself

2. Network connectivity issues:
   - Unable to reach Bitwarden API endpoints (api.bitwarden.eu)
   - TLS handshake failures with identity service
   - DNS resolution problems for Bitwarden domains

## Detection

Error logs from sm-operator showed:

```
Error pulling Secret Manager secrets from API => API: https://api.bitwarden.eu -- Identity: https://identity.bitwarden.eu
API error: error sending request for url (https://identity.bitwarden.eu/connect/token)
```

## Resolution

In Progress:

1. Current approach:

   - Removed circular dependency in auth token configuration
   - Configured direct CIDR access to Bitwarden API endpoints
   - Updated network policies to allow external connectivity

2. Remaining issues:
   - Need to verify proper auth token bootstrapping process
   - Validate TLS configuration for API endpoints
   - Ensure proper secret management hierarchy

## Prevention

1. Configuration Management:

   - Create validation checks for circular dependencies
   - Implement secret hierarchy guidelines

2. Network Access:
   - Maintain documentation of required API endpoints
   - Regular connectivity testing
   - Monitoring of API access patterns

## Related Issues

- Leader election timeout
- Cilium policy validation
- Network policy enforcement

## Notes

- Bootstrap process needs careful consideration
- Avoid circular dependencies in operator configurations
- Consider implementing API connectivity monitoring
- Document proper secret management hierarchy
