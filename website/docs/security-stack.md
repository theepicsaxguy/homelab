# Enterprise Security Stack Deployment Guide

## Overview

Deploy a comprehensive enterprise-grade security stack for your GitOps homelab using the latest stable versions:

- **Gatekeeper v3.21.0** - OPA admission control with NSA/CISA templates
- **Kyverno v1.16.2** - Policy validation + mutation (with security patches)
- **Falco v4.4.0** - Runtime security monitoring with eBPF driver
- **KubeArmor v1.6.6** - Kernel-level security enforcement with LSM/BPF

## Prerequisites

1. **Bitwarden Entry**: Create a Login item named "Falco Slack Webhook URL" with your Slack webhook URL
2. **Namespace Capacity**: Ensure cluster can handle additional security namespaces
3. **Resource Availability**: Verify sufficient resources for security workloads

## Deployment Steps

### Step 1: Deploy Security Stack
```bash
# Commit to GitOps repository
git add k8s/applications/security/
git commit -m "feat(k8s): add enterprise security stack"

# Argo CD will automatically deploy all resources
```

### Step 2: Configure Slack Integration (Optional)
```bash
# Create Bitwarden entry for Slack alerts
# Item: "Falco Slack Webhook URL"
# Field: webhook URL (e.g., https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK)
```

### Step 3: Verify Deployment
```bash
# Check security system status
kubectl get pods -n security-system
kubectl get crd | grep -E '(gatekeeper|kyverno|kubearmor)'

# Verify policies are active
kubectl get constraints -A
kubectl get clusterpolicies -A
kubectl get kubearmorpolicies -A
```

## Security Features

### Admission Control (Gatekeeper + Kyverno)
- **NSA/CISA Compliance**: Built-in hardening policies
- **Image Validation**: No latest tags, signed images preferred
- **Resource Limits**: CPU/memory enforcement for all workloads
- **Security Contexts**: Non-root, read-only filesystem, dropped capabilities
- **Namespace Protection**: Wildcard policies for all namespaces

### Runtime Security (Falco)
- **eBPF Driver**: High-performance syscall monitoring
- **Application-Specific Rules**: Custom rules for Minecraft, AI, and media workloads
- **Slack Integration**: Real-time alerting via falcosidekick
- **Metrics Export**: Prometheus integration for observability

### Kernel Enforcement (KubeArmor)
- **LSM Protection**: AppArmor/BPF kernel-level security
- **File System Controls**: Sensitive path protection
- **Network Restrictions**: Egress/ingress filtering by application
- **Process Controls**: Block suspicious binaries

## Monitoring & Observability

### Prometheus Metrics
- **Falco Metrics**: Port 8765, ServiceMonitor `falco`
- **KubeArmor Metrics**: Port 8080, ServiceMonitor `kubearmor`
- **Resource Usage**: CPU/memory monitoring for all security tools

### Grafana Dashboards
- Security tool performance metrics
- Policy compliance status
- Alert trends and patterns
- Namespace security overview

## Configuration Details

### Resource Allocation
```yaml
Falco:
  requests: 200m CPU, 512Mi memory
  limits: 1000m CPU, 1024Mi memory
  
KubeArmor:
  requests: 100m CPU, 128Mi memory  
  limits: 500m CPU, 256Mi memory
```

### Namespace Strategy
- **security-system**: Main security tools namespace
- **gatekeeper-system**: Gatekeeper namespace
- **kyverno**: Kyverno namespace  
- **kubearmor**: KubeArmor namespace
- **Wildcard Protection**: All other namespaces protected by default

## Troubleshooting

### Common Issues
1. **Policy Conflicts**: Check for overlapping Gatekeeper/Kyverno rules
2. **Resource Constraints**: Monitor security tool resource usage
3. **Network Policies**: Ensure Cilium allows security tool traffic
4. **Slack Alerts**: Verify webhook URL configuration

### Health Checks
```bash
# Verify all components are running
kubectl get pods -n security-system -l app.kubernetes.io/part-of=security

# Check policy status
kubectl get constrainttemplates -A
kubectl get clusterpolicies -A  
kubectl get kubearmorpolicies -A

# View security events
kubectl logs -n security-system -l app.kubernetes.io/name=falco
```

## Security Policies Applied

### NSA/CISA Hardening Rules
- **Pod Security**: Non-root, read-only filesystem, no host namespace sharing
- **Capability Restrictions**: All capabilities dropped
- **Image Security**: No privileged containers, validated registries

### Application-Specific Rules
- **Minecraft**: Shell access detection, file system anomaly protection
- **AI Workloads**: Model file access monitoring, data exfiltration detection  
- **Media Services**: Privilege escalation detection, configuration file protection

### KubeArmor LSM Policies
- **Path Protection**: Critical system directories blocked
- **Process Controls**: Suspicious binaries blocked
- **Network Filtering**: Application-specific port restrictions

## Maintenance

### Policy Updates
- Review security alerts weekly
- Update threat patterns monthly
- Test new policies in staging first
- Monitor CVE databases for security tool updates

### Performance Optimization
- Monitor security tool impact on application latency
- Adjust resource limits based on usage
- Fine-tune policy evaluation performance