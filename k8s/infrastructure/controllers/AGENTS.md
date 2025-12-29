# Infrastructure Controllers - Component Guidelines

SCOPE: Cluster operators and controllers
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: Argo CD, Velero, External Secrets, Cert Manager, CNPG, Crossplane, Kubechecks, Node Feature Discovery, GPU Operator

## COMPONENT CONTEXT

Purpose:
Deploy and manage cluster-wide operators that handle authentication, backups, certificates, secrets, DNS, and deployment automation.

Boundaries:
- Handles: Operator deployments, CRDs, controller configurations, and integration settings
- Does NOT handle: Application deployments (see applications/), network CNI (see network/), storage providers (see storage/)
- Integrates with: auth/ (for Authentik SSO), network/ (for Gateway API), storage/ (for CSI integration)

Architecture:
- `argocd/` - GitOps continuous delivery controller
- `velero/` - Backup and disaster recovery
- `external-secrets/` - Secret synchronization from Bitwarden
- `cert-manager/` - Certificate management (Cloudflare DNS, internal CA)
- `crossplane/` - Cloud provider integration (Cloudflare DNS)
- `nvidia-gpu-operator/` - GPU driver management for AI workloads
- `node-feature-discovery/` - Hardware feature detection
- `kubechecks/` - Kubernetes manifest validation

## QUICK-START COMMANDS

```bash
# Build all controllers
kustomize build --enable-helm k8s/infrastructure/controllers

# Build specific controller
kustomize build --enable-helm k8s/infrastructure/controllers/<controller>

# Validate controller manifests
kustomize build --enable-helm k8s/infrastructure/controllers | yq eval -P -
```

## CONTROLLER-SPECIFIC PATTERNS

### Argo CD (GitOps Controller)
- **Purpose**: Continuous deployment controller that syncs manifests from Git to cluster
- **Installation**: Helm chart at version 9.2.3 from argoproj repository
- **Key Configurations**:
  - Exposes UI via Gateway API (HTTPRoute)
  - Uses ExternalSecrets for admin credentials
  - Redis with network policy for security
  - Role-based access control for namespace operations
- **Integration**: Uses Git generator in ApplicationSet to auto-discover applications

### Velero (Backup Controller)
- **Purpose**: Cluster-wide backup and disaster recovery using Kopia filesystem backups
- **Storage Locations**: See /k8s/AGENTS.md for complete backup strategy
- **Key Configuration**: `defaultVolumesToFsBackup: true` for filesystem backup via Kopia
- **External Secrets**: B2 credentials via separate Bitwarden entries (see /k8s/AGENTS.md for pattern)

### External Secrets Operator
- **Purpose**: Synchronize secrets from Bitwarden Secrets Manager to Kubernetes
- **Secret Store**: Bitwarden Secrets Manager via secure API
- **Key Requirements**: See /k8s/AGENTS.md for Bitwarden and ExternalSecrets patterns
- **Integration**: Applications reference ExternalSecret resources instead of hardcoded secrets

### Cert Manager
- **Purpose**: Automated TLS certificate management
- **Cluster Issuers**:
  - **Cloudflare Issuer**: DNS-01 challenge via Cloudflare API (Bitwarden API token)
  - **Internal CA Issuer**: For internal services
- **Network Policy**: Restricts egress for security
- **Certificate Requests**: Auto-renewal via CRDs
- **External Secrets**: Cloudflare API token via Bitwarden (see /k8s/AGENTS.md for pattern)

### CloudNativePG Database Operator
- **Purpose**: PostgreSQL cluster management and backup automation
- **Location**: See /k8s/infrastructure/database/AGENTS.md for complete database patterns
- **Key Features**: High availability clusters, automatic failover, scheduled backups
- **Credentials**: Auto-generated `<cluster-name>-app` secret (do not use ExternalSecrets, see /k8s/AGENTS.md for pattern)

### Crossplane
- **Purpose**: Infrastructure as Code for cloud provider resources (DNS records)
- **Provider**: Cloudflare provider for DNS management
- **Resources**: DNS records managed via CRDs
- **External Secrets**: Cloudflare API token via Bitwarden (see /k8s/AGENTS.md for pattern)
- **Integration**: Automated DNS record creation for services

### NVIDIA GPU Operator
- **Purpose**: GPU driver management and device plugin for Kubernetes
- **Use Case**: AI/ML workloads requiring GPU access
- **Features**:
  - Automatic GPU driver installation
  - Device plugin for Kubernetes scheduling
  - Node feature detection for GPU nodes
- **Dependencies**: Node Feature Discovery

### Node Feature Discovery
- **Purpose**: Detect and label hardware features on nodes
- **Use Case**: Enable node-aware scheduling (GPU nodes, special hardware)
- **Labels Applied**: Hardware features, CPU flags, kernel versions

### Kubechecks
- **Purpose**: Validate Kubernetes manifests in pull requests
- **Deployment**: See `k8s/infrastructure/deployment/`
- **Integration**: GitHub Actions workflow hooks for pre-merge validation

## CONTROLLER INTEGRATION

### Dependencies Between Controllers

**Deployment Order**:
1. Cert Manager (certificates needed for ingress)
2. External Secrets Operator (secrets needed by other controllers)
3. CNPG (databases needed by applications)
4. Argo CD (GitOps sync depends on other operators)
5. Crossplane (DNS records for services)

**Authentication Flow**:
- Authentik (auth/) → Argo CD SSO login
- Bitwarden → External Secrets → All controller secrets
- Cloudflare API → Cert Manager + Crossplane

**Backup Flow**:
- Velero backs up all namespace resources
- CNPG backs up PostgreSQL databases independently
- Storage providers (storage/) handle volume backups

## TESTING

### Validation Strategy

**Pre-Deployment**:
- `kustomize build --enable-helm k8s/infrastructure/controllers/<controller>`
- Verify Helm chart versions match in kustomization.yaml
- Check ExternalSecret references exist in Bitwarden

**Post-Deployment**:
- Verify controller pods are running: `kubectl get pods -n <namespace>`
- Check controller logs: `kubectl logs -n <namespace> -l app.kubernetes.io/name=<controller>`
- Verify CRDs are registered: `kubectl get crd | grep <controller>`

**Controller-Specific Tests**:

**Argo CD**:
- Verify ApplicationSet auto-discovers applications
- Test sync with sample application

**Velero**:
- Verify backup schedule status: `velero get schedules`
- Test backup: `velero backup create test --default-volumes-to-fs-backup --wait`
- Check storage location connectivity

**External Secrets**:
- Verify secret sync: `kubectl get externalsecrets -A`
- Check secret exists: `kubectl get secret <name> -n <namespace>`

**Cert Manager**:
- Verify issuers ready: `kubectl get clusterissuer`
- Test certificate request: `kubectl get certificate -A`

**CNPG**:
- Verify cluster status: `kubectl get cluster -A`
- Check backup connectivity

**Crossplane**:
- Verify provider ready: `kubectl get provider`
- Test DNS record creation

## OPERATIONAL PATTERNS

### Controller Upgrades

**General Process**:
1. Check controller release notes for breaking changes
2. Update Helm chart version in kustomization.yaml
3. Review values.yaml changes in new chart version
4. Test in staging environment if available
5. Deploy via GitOps (commit and push)

**Argo CD Upgrade Notes**:
- ApplicationSet syntax changes require manifest updates
- Redis network policy may need adjustment

**Velero Upgrade Notes**:
- Verify Kopia data mover compatibility
- Test restore after upgrade

**Cert Manager Upgrade Notes**:
- Check for CRD changes
- Update certificate resources if needed

### Controller Debugging

**General Debugging**:
1. Check controller pod status: `kubectl get pods -n <namespace>`
2. Check controller logs: `kubectl logs -n <namespace> -l app.kubernetes.io/name=<controller> -f`
3. Check CRD status: `kubectl get <crd> -A`
4. Check controller events: `kubectl get events -n <namespace>`

**Argo CD Issues**:
- Application not syncing: Check ApplicationSet generator pattern
- Sync failed: Review resource diffs in Argo CD UI
- Secret access denied: Verify ExternalSecret exists

**Velero Issues**:
- Backup failed: Check storage location credentials
- PVC not backed up: Verify `defaultVolumesToFsBackup: true`
- Restore failed: Check storage location connectivity

**External Secrets Issues**:
- Secret not syncing: Check Bitwarden connectivity
- Secret missing: Verify secret key exists in Bitwarden
- Template error: Check `engineVersion: v2` under `spec.target.template`

**Cert Manager Issues**:
- Certificate not issued: Check DNS challenge propagation
- Issuer not ready: Verify API token credentials
- Challenge failed: Check Cloudflare DNS records

## ANTI-PATTERNS

Never modify CRD definitions manually. Let operators manage their own CRDs.

Never skip secret validation. Verify ExternalSecret references exist in Bitwarden before applying.

Never deploy controllers without understanding dependencies. Some controllers require Cert Manager or External Secrets.

Never use `latest` Helm chart versions. Pin to specific versions for reproducibility.

Never create circular dependencies with ExternalSecrets for CNPG. Let CNPG auto-generate credentials.

Never disable controller RBAC. Controllers need proper permissions to manage resources.

Never skip backup configuration. All stateful controllers (Velero, CNPG) require backup setup.

## SECURITY BOUNDARIES

Never commit secrets or credentials to controller manifests. Use ExternalSecrets for all sensitive data.

Never give controllers excessive permissions. Follow principle of least privilege for RBAC.

Never expose controller UIs to public internet without authentication. Use Authentik SSO where applicable.

Never use wildcard DNS certificates for production. Issue specific certificates per service.

## KNOWN ISSUES

### Cilium 1.17.x TCP Listener Issue
Cilium versions prior to 1.18 drop pure-TCP Gateway listeners. For details and workaround, see /k8s/infrastructure/network/AGENTS.md.

### Velero CSI Snapshot Limitations
Proxmox CSI driver does not support CSI snapshots due to experimental status and permission requirements. For complete backup strategy, see /k8s/AGENTS.md.

## REFERENCES

For Kubernetes domain patterns, see /k8s/AGENTS.md

For certificate management patterns, see /k8s/infrastructure/network/AGENTS.md

For storage patterns, see /k8s/infrastructure/storage/AGENTS.md

For complete backup strategy, see /k8s/AGENTS.md

For CNPG database patterns, see /k8s/infrastructure/database/AGENTS.md

For commit message format, see /AGENTS.md
