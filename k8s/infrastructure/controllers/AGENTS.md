# Infrastructure Controllers - Component Guidelines

SCOPE: Cluster operators and controllers
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: Argo CD, Velero, External Secrets, Cert Manager, CNPG, Kubechecks, Node Feature Discovery, GPU Operator

## COMPONENT CONTEXT

Purpose: Deploy and manage cluster-wide operators that handle authentication, backups, certificates, secrets, DNS, and deployment automation.

Architecture:
- `argocd/` - GitOps continuous delivery controller
- `velero/` - Backup and disaster recovery
- `external-secrets/` - Secret synchronization from Bitwarden
- `cert-manager/` - Certificate management (Cloudflare DNS, internal CA)
- `nvidia-gpu-operator/` - GPU driver management for AI workloads
- `node-feature-discovery/` - Hardware feature detection
- `kubechecks/` - Kubernetes manifest validation

## QUICK-START COMMANDS

```bash
# Build all controllers
kustomize build --enable-helm k8s/infrastructure/controllers

# Build specific controller
kustomize build --enable-helm k8s/infrastructure/controllers/<controller>

# Validate manifests
kustomize build --enable-helm k8s/infrastructure/controllers | yq eval -P -
```

## CONTROLLER PATTERNS

### Argo CD (GitOps Controller)
- Helm chart version 9.2.3 from argoproj repository
- Exposes UI via Gateway API (HTTPRoute)
- Uses ExternalSecrets for admin credentials
- Uses Git generator in ApplicationSet for auto-discovery

### Velero (Backup Controller)
- Cluster-wide backup using Kopia filesystem backups
- `defaultVolumesToFsBackup: true` for filesystem backup
- Excludes declarative workloads (can be recreated from Git)
- Excludes NFS/external storage volumes
- B2 credentials via separate Bitwarden entries

### External Secrets Operator
- Synchronizes secrets from Bitwarden Secrets Manager
- Uses secure API with separate entries per secret (no `property` field)
- Applications reference ExternalSecret resources instead of hardcoded secrets

### Cert Manager
- Automated TLS certificate management
- Cloudflare Issuer: DNS-01 challenge via Cloudflare API
- Internal CA Issuer: For internal services
- Auto-renewal via CRDs, network policy for security

### CNPG Database Operator
- PostgreSQL cluster management and backup automation
- High availability clusters, automatic failover, scheduled backups
- Auto-generated `<cluster-name>-app` secrets (do not use ExternalSecrets)
- See `/k8s/infrastructure/database/AGENTS.md` for complete patterns

### NVIDIA GPU Operator
- GPU driver management and device plugin for Kubernetes
- Automatic GPU driver installation
- Device plugin for Kubernetes scheduling
- Depends on Node Feature Discovery

### Node Feature Discovery
- Detects and labels hardware features on nodes
- Enables node-aware scheduling (GPU nodes, special hardware)

### Monitoring Setup Workflow

### Step 1: Enable Application Metrics
Add metrics endpoint to your application:
```yaml
# In your deployment container spec
env:
- name: METRICS_PORT
  value: "9090"
ports:
- name: metrics
  containerPort: 9090
  protocol: TCP
```

### Step 2: Create ServiceMonitor (Recommended)
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: <app>-monitor
  namespace: <namespace>
  labels:
    release: prometheus  # Important for Prometheus discovery
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: <app>
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### Step 3: Create PodMonitor (Alternative)
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: <app>-monitor
  namespace: <namespace>
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: <app>
  podMetricsEndpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### Step 4: CNPG Database Monitoring
```yaml
# In CNPG cluster spec
monitoring:
  enabled: true
```

### Step 5: Validation
```bash
# Check ServiceMonitor/PodMonitor
kubectl get servicemonitor -A
kubectl get podmonitor -A

# Check Prometheus targets
kubectl get prometheusrules -A

# Verify metrics collection
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# Browse to http://localhost:9090/targets
```

## Kubechecks
- Validates Kubernetes manifests in pull requests
- GitHub Actions workflow integration
- See `k8s/infrastructure/deployment/` for deployment

## CONTROLLER INTEGRATION

### Deployment Order
1. Cert Manager (certificates needed for ingress)
2. External Secrets Operator (secrets needed by other controllers)
3. CNPG (databases needed by applications)
4. Argo CD (GitOps sync depends on other operators)

### Authentication Flow
- Authentik (auth/) → Argo CD SSO login
- Bitwarden → External Secrets → All controller secrets
- Cloudflare API → Cert Manager

### Backup Flow
- Velero backs up all namespace resources
- CNPG backs up PostgreSQL databases independently
- Storage providers handle volume backups

## TESTING

### Pre-Deployment
- `kustomize build --enable-helm k8s/infrastructure/controllers/<controller>`
- Verify Helm chart versions in kustomization.yaml
- Check ExternalSecret references exist in Bitwarden

### Post-Deployment
- Verify controller pods: `kubectl get pods -n <namespace>`
- Check controller logs: `kubectl logs -n <namespace> -l app.kubernetes.io/name=<controller>`
- Verify CRDs: `kubectl get crd | grep <controller>`

### Controller-Specific Tests
**Argo CD**: Verify ApplicationSet auto-discovery, test sync with sample
**Velero**: `velero get schedules`, test backup creation
**External Secrets**: `kubectl get externalsecrets -A`, check secret existence
**Cert Manager**: `kubectl get clusterissuer`, test certificate request
**CNPG**: `kubectl get cluster -A`, check backup connectivity

## OPERATIONAL PATTERNS

### Controller Upgrades
1. Check release notes for breaking changes
2. Update Helm chart version in kustomization.yaml
3. Review values.yaml changes
4. Deploy via GitOps (commit and push)

### Controller Debugging
1. Check pod status: `kubectl get pods -n <namespace>`
2. Check logs: `kubectl logs -n <namespace> -l app.kubernetes.io/name=<controller> -f`
3. Check CRDs: `kubectl get <crd> -A`
4. Check events: `kubectl get events -n <namespace>`

## CONTROLLERS-DOMAIN ANTI-PATTERNS

### CRD & Operator Management
- Never modify CRD definitions manually - let operators manage their own CRDs
- Never deploy controllers without understanding dependencies
- Never use `latest` Helm chart versions - pin to specific versions
- Never disable controller RBAC - controllers need proper permissions

### Secrets & Security
- Never commit secrets to manifests - use ExternalSecrets
- Never give controllers excessive permissions - follow least privilege
- Never expose controller UIs to public internet without authentication
- Never use wildcard DNS certificates for production

### Configuration Management
- Never skip secret validation - verify ExternalSecret references exist
- Never create circular dependencies with ExternalSecrets for CNPG
- Never skip backup configuration - all stateful controllers need backups

## KNOWN ISSUES

### Cilium 1.17.x TCP Listener Issue
Cilium versions prior to 1.18 drop pure-TCP Gateway listeners. See `/k8s/infrastructure/network/AGENTS.md` for details.

### Velero CSI Snapshot Limitations
Proxmox CSI driver does not support CSI snapshots. See `/k8s/AGENTS.md` for complete backup strategy.

## REFERENCES

For Kubernetes patterns: /k8s/AGENTS.md
For certificate management: /k8s/infrastructure/network/AGENTS.md
For storage patterns: /k8s/infrastructure/storage/AGENTS.md
For database patterns: /k8s/infrastructure/database/AGENTS.md
For commit format: /AGENTS.md