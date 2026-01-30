# Kubernetes Security Domain - Enterprise Security Stack

SCOPE: Security policies, runtime protection, and compliance enforcement
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: Gatekeeper, Kyverno, Falco, KubeArmor, OPA, NSA/CISA, eBPF, LSM

## SECURITY STACK OVERVIEW

### Multi-Layer Security Architecture
**Gatekeeper v3.21.0** - OPA admission control with NSA/CISA templates
**Kyverno v1.16.2** - Policy validation + mutation with security patches
**Falco v4.4.0** - Runtime syscall detection with eBPF driver
**KubeArmor v1.6.6** - Kernel-level enforcement with LSM/BPF

### Namespace Strategy
- **security-system**: Primary security tools namespace
- **Wildcard Protection**: Policies apply to all namespaces except security namespaces
- **Future-Proof**: Automatically protects new namespaces without policy updates

## DOMAIN PATTERNS

### Security Policy Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                Application Layer                      │
│  ┌─────────────┐  ┌──────────────┐        │
│  │   Kyverno    │  │  Gatekeeper  │        │
│  │ Validation    │  │  Admission    │        │
│  │ Mutation      │  │  Control       │        │
│  └─────────────┘  └──────────────┘        │
│           ↓                 ↓                   │
│  ┌─────────────────────────────────────┐         │
│  │        Runtime Protection           │         │
│  │  ┌─────────┐  ┌──────────────┐  │         │
│  │  │  Falco  │  │  KubeArmor  │  │         │
│  │  │ eBPF    │  │  LSM/BPF     │  │         │
│  │  └─────────┘  └──────────────┘  │         │
│  └─────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
                      ↓
               Monitoring & Alerting
    Prometheus + Grafana + AlertManager
```

### Policy Enforcement Flow
1. **Admission Control** (Gatekeeper + Kyverno)
   - Block non-compliant workloads at deployment time
   - Apply NSA/CISA hardening policies automatically
   - Enforce security contexts and capabilities

2. **Runtime Detection** (Falco)
   - Monitor syscalls and process execution
   - Detect suspicious behavior in real-time
   - Alert on container escape attempts

3. **Kernel Enforcement** (KubeArmor)
   - Block malicious system calls at kernel level
   - Enforce file system and network restrictions
   - Provide least-privilege container execution

## WORKFLOW INTEGRATION

### GitOps Integration
- Follow existing kustomize hierarchy: `k8s/infrastucture/security/`
- Use same naming patterns as other applications
- Integrate with existing monitoring and alerting
- Compatible with current Argo CD ApplicationSets

### Namespace Management
```yaml
# Wildcard protection for current + future namespaces
match:
  namespaces: ["*"]
  excludedNamespaces: 
    - "security-system"
    - "gatekeeper-system" 
    - "kyverno"
    - "kubearmor"
    - "kube-system"
```

## SECURITY STANDARDS

### NSA/CISA Compliance
- **Pod Security**: Non-root containers, dropped capabilities
- **Image Security**: Signed images, no latest tags
- **Network Security**: Allowed traffic patterns only
- **File System**: Critical path protection
- **Runtime Security**: Process execution controls

### Enterprise Features
- **Policy as Code**: All security controls in Git
- **Audit Trail**: Complete security event logging
- **Compliance Reporting**: Automated policy compliance metrics
- **Zero Trust**: Never trust, always verify

## IMPLEMENTATION GUIDELINES

### Resource Management
- Security tools get dedicated resource allocation
- Monitor resource usage to prevent impact on applications
- Use priority classes for critical security components

### Alert Integration
- Security alerts route through existing AlertManager
- Grafana dashboards for security observability
- Slack integration via falcosidekick for critical alerts

### Policy Lifecycle
1. **Audit Mode**: Initial deployment in observation mode
2. **Validation**: Review alerts and fine-tune policies
3. **Enforcement**: Gradual enablement of blocking rules
4. **Monitoring**: Continuous compliance assessment

## ANTI-PATTERNS

### Security Anti-Patterns
- Never deploy security tools without proper resource limits
- Never skip audit phase before enforcement
- Never ignore security alerts during tuning
- Never hardcode credentials in security policies

### Integration Anti-Patterns
- Never bypass admission control for emergency fixes
- Never disable runtime monitoring for performance
- Never modify kernel security settings without testing

## MAINTENANCE

### Policy Updates
- Review and update policies regularly
- Test new policies in staging environment
- Monitor CVE databases for security tool updates
- Update security tools with latest patches

### Performance Monitoring
- Monitor security tool resource usage
- Track policy evaluation latency
- Alert on security system degradation