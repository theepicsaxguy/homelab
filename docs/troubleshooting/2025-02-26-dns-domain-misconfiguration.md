# DNS Domain Misconfiguration

## Date

2025-02-26

## Category

- DNS
- Networking
- Configuration

## Status

Solved

## Impact

- Worker nodes unable to reach API server
- DNS resolution failures for internal services
- Cilium pods not functioning correctly on worker nodes
- Inconsistent domain usage across services

## Root Cause

1. Inconsistent domain usage between internal services:

   - Some services using `pc-tips.se` directly
   - Others using `kube.pc-tips.se` subdomain
   - Mixed DNS configurations leading to resolution issues

2. AdGuard DNS configuration issues:
   - Incorrect IP mapping for API server endpoint
   - Public domain exposure risk for internal services
   - Wildcard DNS entries potentially causing conflicts

## Detection

- Worker nodes (work-01, work-02) entered NotReady state
- Talos logs showed DNS resolution failures
- Cilium pods unable to establish connectivity
- Network policy enforcement issues

## Resolution

1. Standardize domain structure:

   - Use `kube.pc-tips.se` as the base domain for all Kubernetes services
   - Move all internal services under appropriate subdomains of `kube.pc-tips.se`
   - Update AdGuard DNS configuration to reflect the new structure

2. DNS Configuration Updates:

   - Configure correct IP mappings for API server and services
   - Implement proper DNS resolution hierarchy
   - Update service configurations to use new domain structure

3. Security Improvements:
   - Separate internal and external DNS zones
   - Implement proper access controls for internal domains
   - Review and update network policies

## Prevention

1. Documentation:

   - Create clear DNS naming conventions
   - Document required DNS records for new services
   - Maintain DNS record inventory

2. Automation:

   - Implement DNS validation in CI/CD
   - Add automated checks for DNS configuration
   - Create DNS configuration templates

3. Monitoring:
   - Add DNS resolution monitoring
   - Set up alerts for DNS-related issues
   - Monitor DNS query patterns

## Related Issues

- Node connectivity issues
- Cilium networking problems
- Service discovery failures

## Notes

- DNS is a critical infrastructure component
- Changes must be carefully planned and tested
- Consider implementing DNS automation tools
- Regular DNS audits should be scheduled
