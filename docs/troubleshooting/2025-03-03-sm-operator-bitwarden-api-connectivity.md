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

## Root Cause Investigation

Current findings:

1. Initial network connectivity issues resolved:

   - Leader election now working after fixing Cilium policies
   - sm-operator successfully acquires lease
   - Internal cluster communication restored

2. Bitwarden API connectivity still failing:

   - Successfully connects to identity.bitwarden.eu
   - TLS handshake succeeding
   - Authentication request fails with connection error

3. Token distribution verified:
   - bw-auth-token present in necessary namespaces
   - RBAC permissions configured correctly
   - Operator can access tokens across namespaces

## Detection

Latest error logs from sm-operator show:

```
ERROR Failed to authenticate {"error": "API error: error sending request for url (https://identity.bitwarden.eu/connect/token)"}
ERROR Error pulling Secret Manager secrets from API => API: https://api.bitwarden.eu -- Identity: https://identity.bitwarden.eu
```

## Investigation Steps Taken

1. Network Policy Resolution:

   - Removed default deny policy that was blocking API access
   - Added explicit allow rules for Bitwarden endpoints
   - Confirmed DNS resolution and TLS handshake working
   - Leader election and internal communication restored

2. Token Distribution:

   - Verified token presence in sm-operator-system
   - Extended token access to needed namespaces (argocd, dns)
   - Confirmed operator can access tokens

3. Current State:
   - Operator successfully starts and acquires leadership
   - Can connect to Bitwarden endpoints (DNS resolves, TLS works)
   - Authentication request fails despite token access

## Next Steps

1. API Connectivity:

   - Validate token format and content
   - Check for any proxy requirements in API request
   - Monitor full network path of API requests
   - Test direct API access from operator pod

2. Token Verification:

   - Verify token permissions in Bitwarden
   - Test token directly against API endpoints
   - Check token format matches API requirements

3. Debug Enhancement:
   - Enable verbose logging if available
   - Add network path monitoring
   - Consider packet capture for API requests

## Current Understanding

1. Network Layer:

   - Basic connectivity working (DNS, TLS)
   - No obvious network policy blocks
   - Possible deeper network path issue

2. Authentication Layer:

   - Token physically accessible
   - Format or permission issue possible
   - API request failing during auth step

3. Infrastructure State:
   - Cluster networking functional
   - Cross-namespace access working
   - External connectivity partial

## Questions to Investigate

1. Is the token content valid and properly formatted?
2. Are there hidden API dependencies beyond the main endpoints?
3. Could there be TLS/cert issues not visible in basic testing?
4. Are there required headers or parameters missing in the API request?

## Notes

- Leader election and internal communication now working
- API connectivity issue isolated from network policy problems
- Token distribution working but possible content/format issues
- Need to focus on API request specifics
