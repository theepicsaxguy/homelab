# Cilium Network Policy Audit Mode Implementation

## Overview
This implementation deploys cluster-wide Cilium network policies in audit mode to observe traffic patterns before enforcement.

## Configuration Changes

### 1. Cilium Audit Mode
- **File**: `k8s/infrastructure/network/cilium/values.yaml`
- **Setting**: `policyAuditMode: true`
- **Effect**: Logs policy violations without blocking traffic

### 2. Policy Structure
```
k8s/infrastructure/network/policies/
├── clusterwide/           # Baseline policies for all namespaces
├── database/             # Database-specific policies
├── monitoring/           # Monitoring and metrics collection
├── auth/                 # Authentik identity provider
├── argocd/               # GitOps controller
├── cert-manager/         # Certificate management
└── applications/         # Application-specific policies
    ├── ai/              # AI workloads
    ├── automation/      # Home automation
    ├── media/           # Media services
    ├── web/             # Web applications
    ├── games/           # Game servers
    ├── tools/           # Utility services
    └── network/         # Network management
```

## Policy Templates

### Baseline Policies (Cluster-wide)
1. **Default Deny Audit**: Logs all traffic that would be blocked
2. **DNS + Kubernetes API**: Essential cluster communication
3. **Gateway HTTP**: Standard web application access pattern

### Namespace-Specific Policies
- **Database**: PostgreSQL access within namespace only
- **Auth**: Authentik identity provider with database access
- **ArgoCD**: GitOps controller with Redis access
- **MQTT**: IoT broker with external client access
- **UniFi**: Network management with multiple ports
- **Minecraft**: Game server with TCP/UDP access

## Monitoring Setup

### Hubble Commands
```bash
# Monitor all audit violations
hubble observe --verdict AUDITED --all-namespaces

# Filter specific namespace
hubble observe --verdict AUDITED --namespace database

# Last 24 hours summary
hubble observe --verdict AUDITED --since 24h --all-namespaces
```

### Expected Output
```
policy-verdict: EGRESS AUDITED → database/postgres:5432 (from litellm/app)
policy-verdict: INGRESS AUDITED → qdrant/server:6333 (from ai/opencode)
policy-verdict: EGRESS AUDITED → external/https:443 (from app/curl)
```

## Deployment Process

1. **GitOps Integration**: Policies added to network kustomization
2. **ArgoCD Sync**: Automatic deployment across all namespaces
3. **Audit Period**: 1-2 weeks of violation monitoring
4. **Policy Tuning**: Update policies based on observed traffic
5. **Enforcement**: Switch to enforcement mode after validation

## Validation Steps

1. **Check Cilium Status**: Verify audit mode is enabled
2. **Monitor Hubble**: Observe audit verdicts in real-time
3. **Review Violations**: Identify legitimate vs. suspicious traffic
4. **Update Policies**: Add missing allow rules as needed
5. **Test Applications**: Ensure all services function normally

## Next Steps

After 1-2 weeks of audit monitoring:
1. Analyze violation patterns
2. Update policies to allow legitimate traffic
3. Remove overly permissive rules
4. Switch to enforcement mode gradually
5. Establish ongoing policy management workflow

## Notes

- All policies use `CiliumNetworkPolicy` for enhanced features
- Audit mode logs violations without blocking traffic
- Policies follow existing GitOps patterns
- Monitoring setup provides comprehensive visibility
- Namespace isolation enforced where appropriate