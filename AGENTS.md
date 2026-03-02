
# Kubernetes Domain - Application Management Hub

SCOPE: Kubernetes manifests, operators, and application workflows
INHERITS FROM: /AGENTS.md
TECHNOLOGIES: Kubernetes, Kustomize, Helm, Argo CD, CNPG, Velero, Proxmox CSI

**PREREQUISITE: You must have read /AGENTS.md before working in this domain.**

## DOMAIN PATTERNS

### Storage Pattern
All PVCs use `storageClassName: proxmox-csi`. Always specify storage class. Volume expansion supported.

### Secret Management Pattern

#### Complete Secret Setup Workflow

**Step 1: Create Bitwarden Entry**
1. Login to Bitwarden
2. Create new Login item with meaningful name (e.g., "OpenAI API", "Database Credentials")
3. Add fields: username, password, API key, etc.
4. **Critical**: Do NOT use `property` field - create separate entries for each service

**Step 2: Create ExternalSecret**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: <app>-secrets
  namespace: <namespace>
spec:
  secretStoreRef:
    name: bitwarden-backend
    kind: ClusterSecretStore
  target:
    creationPolicy: Owner
    refreshInterval: 1h
  data:
  - secretKey: <k8s-secret-key>
    remoteRef:
      key: <bitwarden-item-name>
  - secretKey: api-key
    remoteRef:
      key: <bitwarden-item-name>
      property: password  # Only for password field
```

**Step 3: Use in Application**
```yaml
# Environment variable from secret
env:
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: <app>-secrets
      key: <k8s-secret-key>
```

**Step 4: Validation**
```bash
# Check ExternalSecret status
kubectl get externalsecret -n <namespace>

# Describe for errors
kubectl describe externalsecret -n <namespace> <name>

# Check generated secret
kubectl get secret -n <namespace> <app>-secrets -o yaml
```

#### Bitwarden Integration Rules

**Required Configuration:**
- `ClusterSecretStore: bitwarden-backend`
- `engineVersion: v2` in templates
- `refreshInterval: 1h` for secrets
- No `property` field in Bitwarden (create separate items)

**Naming Conventions:**
- Bitwarden items: Descriptive names (e.g., "App Database Credentials")
- ExternalSecrets: `app-<namespace>-purpose-type` pattern (e.g., `app-qdrant-api-key`, `app-vllm-embed-hf-token`)
- Secret keys: Environment variable style (`UPPER_CASE_WITH_UNDERSCORES`) or nested service format (`SERVICE__SECTION__KEY`)

#### Special Cases

**CNPG Databases:**
- Let CNPG auto-generate credentials (`<cluster-name>-app` secret)
- Do NOT create ExternalSecret for database passwords
- Use CNPG connection strings with auto-generated secrets

**Service to Service:**
- Use Kubernetes secrets (not ExternalSecrets)
- Create manually via `kubectl create secret`
- For internal service communication only

### GitOps Pattern
All changes via Git. Argo CD auto-syncs. Never `kubectl apply`. Validate with `kustomize build` before commit.

## COMPLETE WORKFLOWS

### Add New Application

#### Step 1: Choose Category
```
Primary Function → Directory
AI/ML → k8s/applications/ai/
Home Automation → k8s/applications/automation/
Media Management → k8s/applications/media/
Web Service → k8s/applications/web/
```

#### Step 2: Create Directory Structure
```bash
mkdir k8s/applications/<category>/<app-name>
cd k8s/applications/<category>/<app-name>
```

Create these files:
- `kustomization.yaml` - Required
- `deployment.yaml` - Application deployment
- `service.yaml` - Internal service discovery
- `http-route.yaml` - External access (if needed)
- `pvc.yaml` - Storage (if needed)
- `externalsecret.yaml` - Secrets (if needed)
- `podmonitor.yaml` - Monitoring (if needed)

#### Step 3: Configure Application

**Deployment Template:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <app-name>
  labels:
    app.kubernetes.io/name: <app-name>
    app.kubernetes.io/part-of: <category>
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: <app-name>
  template:
    metadata:
      labels:
        app.kubernetes.io/name: <app-name>
    spec:
      containers:
      - name: <app-name>
        image: <image>:<tag>  # Pin specific version
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

**Service Template:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: <app-name>
spec:
  selector:
    app.kubernetes.io/name: <app-name>
  ports:
  - port: 80
    targetPort: <app-port>
```

**HTTPRoute Template:**
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: <app-name>
spec:
  parentRefs:
  - name: external
    namespace: gateway
  - name: internal
    namespace: gateway
  hostnames:
  - "<app-name>.peekoff.com"
  rules:
  - matches:
    - path:
        type: Prefix
          value: /
    backendRefs:
    - name: <app-name>
      port: 80
```

**ExternalSecret Template:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-<namespace>-purpose-type
spec:
  secretStoreRef:
    name: bitwarden-backend
    kind: ClusterSecretStore
  target:
    creationPolicy: Owner
  data:
  - secretKey: <key-name>
    remoteRef:
      key: <bitwarden-item-name>
```

#### Step 4: Update Parent Kustomization
Add to `k8s/applications/<category>/kustomization.yaml`:
```yaml
resources:
- <app-name>
```

#### Step 5: Pre-Commit Validation Checklist

**Security:**
- [ ] No hardcoded secrets in manifests
- [ ] ExternalSecrets reference correct Bitwarden entries
- [ ] Container image pinned to specific version (no `latest`)
- [ ] Container runs as non-root user (if possible)

**Reliability:**
- [ ] Resource requests and limits set
- [ ] PVC backup label assigned (GFS/Daily/Weekly)
- [ ] Health checks configured (liveness/readiness)
- [ ] Appropriate replica count

**GitOps:**
- [ ] Kustomization builds: `kustomize build --enable-helm <path>`
- [ ] Parent kustomization includes new application
- [ ] All manifests follow naming conventions
- [ ] Commit message follows conventional format

### Update Existing Application

1. Make changes in application directory
2. Build and test: `kustomize build --enable-helm k8s/applications/<category>/<app>`
3. Run pre-commit validation checklist
4. Commit with conventional format: `feat(k8s): update <app-name>`
5. Monitor Argo CD deployment

### Remove Application

1. Remove from parent kustomization
2. Verify no other applications depend on it
3. Commit changes (Argo CD will handle deletion)
4. Verify PVC cleanup if storage was used

## QUICK-START COMMANDS

```bash
# Build specific application
kustomize build --enable-helm k8s/applications/<category>/<app>

# Build entire category
kustomize build --enable-helm k8s/applications/<category>

# Build all applications
kustomize build --enable-helm k8s/applications

# Build infrastructure
kustomize build --enable-helm k8s/infrastructure

# Validate YAML output
kustomize build <path> | yq eval -P -

# Check Argo CD status
kubectl get application -n argocd
kubectl describe application -n argocd <app-name>
```

## ANTI-PATTERNS

### Security
- Never hardcode secrets - use ExternalSecrets
- Never use `latest` tags - pin versions
- Never expose databases directly - keep internal
- Never skip TLS for external services

### Operations
- Never `kubectl apply` - use GitOps
- Never use `kubectl apply -f` - always use `kubectl apply -k` or `kustomize build` directly ( `-f` might miss some content )
- Never modify CRDs without understanding operators
- Never skip backup configuration for stateful workloads
- Never use Longhorn - deprecated

### Kustomize
- NEVER use `generatorOptions.disableNameSuffixHash: true` - hash suffixes prevent resource name conflicts and enable proper resource tracking
- NEVER modify generated resource names manually - use proper Kustomize naming patterns

### CNPG Databases
- Never use `property` field with Bitwarden
- Never use legacy barman object storage - use plugin architecture
- Always let CNPG auto-generate credentials (`<cluster-name>-app`)

#### Barman Cloud Plugin Rules
- **CRITICAL**: Remove ALL `spec.backup.barmanObjectStore` sections before enabling plugin
- **CRITICAL**: Remove ALL `spec.externalClusters[].barmanObjectStore` sections, replace with `spec.externalClusters[].plugin`
- **CRITICAL**: `spec.backup.retentionPolicy` moves to `ObjectStore.retentionPolicy`, not in Cluster spec
- Plugin requires: `plugins[0].isWALArchiver: true` + `parameters.barmanObjectName` pointing to ObjectStore
- ScheduledBackup must use: `method: plugin` + `pluginConfiguration.name: barman-cloud.cloudnative-pg.io`

## DOMAIN COMPONENTS

### Infrastructure
- `auth/`: Authentication (Authentik)
- `controllers/`: Operators (Argo CD, Velero, Cert Manager)
- `database/`: CloudNativePG clusters
- `network/`: Cilium, Gateway API, DNS
- `storage/`: Proxmox CSI

### Applications
- `ai/`: AI/ML workloads with GPU access
- `automation/`: Home automation systems
- `media/`: Content management and streaming
- `web/`: Web applications and services

## NETWORK POLICIES

### CiliumNetworkPolicy v2 Syntax (Cilium 1.14+)

CiliumNetworkPolicy v2 features stricter schema validation and restructured selectors compared to v1. Direct `ports` arrays under `ingress`/`egress` rules are no longer valid.

#### V1 vs V2 Ports Structure
**V1 (Deprecated - direct ports):**
```yaml
apiVersion: cilium.io/v1
kind: CiliumNetworkPolicy
metadata:
  name: v1-example
spec:
  endpointSelector:
    matchLabels:
      app: moltbot
  ingress:
  - fromEndpoints: [...]
    ports:                    # INVALID in v2
    - port: "8080"
      protocol: TCP
```

**V2 (Current - nested selectors):**
```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: v2-example
spec:
  endpointSelector:
    matchLabels:
      app: moltbot
  ingress:
  - fromEndpoints: [...]
    toPorts:                  # REQUIRED in v2
    - ports:
      - port: "8080"
        protocol: TCP
```

#### Complete V2 Example
```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: moltbot
spec:
  endpointSelector:
    matchLabels:
      app: moltbot
  ingress:
  - fromEntities:
    - world  # or specific namespaces/endpoints
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
  egress:
  - toEndpoints:
    - matchLabels:
        app.kubernetes.io/name: litellm
    toPorts:
    - ports:
      - port: "4000"
        protocol: TCP
```

#### Core V2 Changes
| Aspect | V1 | V2 |
|--------|----|----|
| **Ports Location** | Direct under `ingress[0].ports[]` | Nested `ingress[0].toPorts[0].ports[]` |
| **Rule Selectors** | `fromCIDR`, `toPorts` directly | Always via `toPorts`, `fromPorts`, `toEndpoints` |
| **Validation** | Loose (warnings) | Strict (rejects invalid fields) |
| **L7 Rules** | `toPorts.rules.http[]` | Same, but stricter nesting |

**Fix Command:** Replace `spec.egress[0].ports` → `spec.egress[0].toPorts[0].ports`

## SECURITY BASELINE

All applications follow a "Assume the pod is compromised" philosophy. Security controls extend beyond securityContext to include network policies, secrets management, image scanning, and RBAC - all of which materially affect blast radius.

### Network Policy Requirements

**CiliumNetworkPolicy v2 is required for all applications.** Use default-deny ingress and egress policies to contain compromised workloads.

#### Default-Deny Pattern
Every namespace should have a default-deny network policy applied. All application-specific policies then explicitly allow required traffic.

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  endpointSelector: {}
  ingress:
  - fromEntities:
    - kube-apiserver  # Allow kubelet API access
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: default-deny-egress
spec:
  endpointSelector: {}
  egress:
  - toEntities:
    - kube-apiserver  # Allow DNS and API access
```

#### Application Policy Template
```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: <app-name>
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: <app-name>
  ingress:
  - fromEndpoints:
    - matchLabels:
        app.kubernetes.io/name: <upstream-app>
    toPorts:
    - ports:
      - port: "<port>"
        protocol: TCP
  egress:
  - toEndpoints:
    - matchLabels:
        k8s:io.kubernetes.pod.namespace: kube-system
    toPorts:
    - ports:
      - port: "53"
        protocol: UDP
      - port: "53"
        protocol: TCP
```

### Pod Security Context Baseline

```yaml
spec:
  hostNetwork: false
  hostPID: false
  hostIPC: false
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
    fsGroup: 1000  # Only when needed
    supplementalGroups: []  # Only when needed
```

### Container Security Context Baseline

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  privileged: false
  capabilities:
    drop:
      - ALL
    add: []  # Or minimal required
  seccompProfile:
    type: RuntimeDefault
  readOnlyRootFilesystem: true
```

### Blast Radius Controls

| Layer | Control | Purpose |
|-------|---------|---------|
| **Pod** | Non-root user, seccomp RuntimeDefault | Limit container escape and host access |
| **Container** | Drop ALL caps, read-only filesystem | Minimize kernel attack surface |
| **Network** | Default-deny egress/ingress | Contain lateral movement |
| **Secrets** | ExternalSecrets (Bitwarden) | Rotate credentials, audit access |
| **Images** | Scan for CVEs, sign with Cosign | Verify supply chain integrity |
| **RBAC** | Least-privilege service accounts | Limit API access |

### Pod Security Admission

Enforce `restricted` PSA level for most namespaces:
```yaml
metadata:
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Admission Controls

Implement ValidatingAdmissionPolicy to block:
- Privileged containers
- hostPath mounts
- Missing required securityContext fields
- Images not scanned for critical CVEs

## DISASTER RECOVERY

### Recovery Priority Order
When recovering stateful workloads, use this priority:
1. **Velero restore** (preferred) — Full namespace restore with PodVolumeRestores.
2. **Kopia direct access** — Check Kopia repository browser for snapshots.
3. **Old PV with Retain policy** (fallback) — All PVCs use `proxmox-csi` with `Retain` reclaim policy. Old PVs persist on Proxmox after PVC/namespace deletion.

### PV Retain Recovery Procedure
All `proxmox-csi` PVs use `Retain` reclaim policy. When a PVC or namespace is deleted, the PV transitions to `Released` state but data remains on Proxmox.

```bash
# 1. Find old Released PVs
kubectl get pv | grep Released

# 2. Identify the correct PV (check creation date, capacity, volume handle)
kubectl get pv <pv-name> -o yaml

# 3. Clear claimRef to make PV Available
kubectl patch pv <pv-name> --type json -p '[{"op":"remove","path":"/spec/claimRef"}]'

# 4. Create PVC bound to the old PV
# Set spec.volumeName to the PV name, match storageClassName and accessModes
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: <new-pvc-name>
  namespace: <namespace>
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: proxmox-csi
  volumeName: <pv-name>
  resources:
    requests:
      storage: <size>
EOF

# 5. Copy data from old PV to current PVC using a temporary pod
# Use UID/GID matching the application's securityContext
```

### Velero Known Issues
- **Server instability**: Velero server crashes/restarts during long restore operations, marking in-progress restores as `Failed`
- **PVR stuck in Prepared**: PodVolumeRestores may get stuck in `Prepared` state and never execute when server restarts mid-restore
- **Error message**: `found a restore with status InProgress during server starting, mark it as Failed`
- **Fallback**: If Velero restores fail repeatedly, use PV Retain recovery as an alternative

### PodSecurity Policy
Namespaces enforce `restricted` PodSecurity policy. Temporary debug/recovery pods must:
- Run as non-root (UID 1000+ recommended)
- Set `securityContext.allowPrivilegeEscalation: false`
- Set `securityContext.seccompProfile.type: RuntimeDefault`
- Set `securityContext.capabilities.drop: ["ALL"]`
- Match the application's UID/GID for filesystem access (check StatefulSet securityContext)

## SPECIALIZED PATTERNS

For domain-specific patterns, see:
- AI GPU patterns: `k8s/applications/ai/AGENTS.md`
- Media NFS patterns: `k8s/applications/media/AGENTS.md`
- External access setup: `k8s/infrastructure/network/AGENTS.md`
- Database configuration: `k8s/infrastructure/database/AGENTS.md`
- Storage configuration: `k8s/infrastructure/storage/AGENTS.md`

## REFERENCES

For commit format: `/AGENTS.md`
For infrastructure: `/tofu/AGENTS.md`
For containers: `/images/AGENTS.md`

// applications/ai/AGENTS.md

# AI Applications - Specialized Patterns

SCOPE: AI/ML applications with GPU access and vector databases
INHERITS FROM: /k8s/AGENTS.md

## AI-SPECIFIC PATTERNS

### GPU Access Pattern
```yaml
# Add to deployment spec.template.spec.containers
resources:
  requests:
    nvidia.com/gpu: 1
  limits:
    nvidia.com/gpu: 1

# Add to deployment spec.template.spec
nodeSelector:
  gpu-node: "true"
tolerations:
- key: "nvidia.com/gpu"
  operator: "Exists"
  effect: "NoSchedule"
```

**Requirements:**
- Use `nvidia.com/gpu` resource name (not standard `gpu`)
- Schedule on GPU nodes with node affinity
- Check GPU capacity: `kubectl describe nodes | grep gpu`
- Monitor GPU memory usage

### Qdrant Integration Pattern
```yaml
# Service connection
apiVersion: v1
kind: Service
metadata:
  name: qdrant
  namespace: ai
spec:
  selector:
    app.kubernetes.io/name: qdrant
  ports:
  - port: 6333
    targetPort: 6333
```

**Application Config:**
- Connect to: `qdrant.ai.svc.cluster.local:6333`
- Use shared Qdrant cluster for all AI applications
- Qdrant PVCs use GFS backup tier (critical data)
- Monitor collection sizes for performance

### LiteLLM API Gateway Pattern
```yaml
# ExternalSecret for API keys
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: litellm-keys
spec:
  secretStoreRef:
    name: bitwarden-backend
    kind: ClusterSecretStore
  target:
    creationPolicy: Owner
  data:
  - secretKey: openai-api-key
    remoteRef:
      key: OpenAI API
  - secretKey: anthropic-api-key
    remoteRef:
      key: Anthropic Claude API
```

**Application Usage:**
- Connect to LiteLLM: `http://litellm.ai.svc.cluster.local:4000`
- Applications use LiteLLM, not direct provider APIs
- LiteLLM manages API keys and rate limiting
- Restart LiteLLM after configuration changes

### Model Storage Pattern
```yaml
# Model storage PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: <app>-models
  labels:
    backup.velero.io/backup-tier: GFS  # For critical models
    # backup.velero.io/backup-tier: Daily  # For caches
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-csi
  resources:
    requests:
      storage: 100Gi  # Adjust based on model size
```

**Requirements:**
- Use `proxmox-csi` StorageClass
- GFS backup tier for critical models, Daily for caches
- Monitor PVC usage for storage quotas
- Large models may need dedicated PVCs

### Network Policy Pattern
```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: <app>-network-policy
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: <app>
  egress:
  - toEndpoints:
    - matchLabels:
        app.kubernetes.io/name: qdrant
    ports:
    - port: "6333"
  - toEndpoints:
    - matchLabels:
        app.kubernetes.io/name: litellm
    ports:
    - port: "4000"
  - toFQDNs:
    - matchName: "api.openai.com"
    - matchName: "api.anthropic.com"
  ingress:
  - fromEndpoints:
    - matchLabels:
        k8s:io.kubernetes.pod.namespace: gateway
```

### OpenWebUI Patterns

**Deployment**: StatefulSet in `open-webui` namespace, deployed via `kubectl apply -k k8s/applications/ai/openwebui/`.

**Database**: SQLite at `/app/backend/data/webui.db` inside the PVC. The database contains ALL application data (users, chats, settings, RAG). This is not a cache — losing the database means losing all data.

**Schema Migrations**: OpenWebUI uses alembic for database migrations. Migrations run automatically on startup.
- Check current version: `sqlite3 /app/backend/data/webui.db "SELECT version_num FROM alembic_version;"`
- Major version upgrades (e.g., 0.5→0.8) involve significant schema changes including new tables and columns
- If a migration fails mid-way (e.g., "table already exists"), inspect which migrations already applied and stamp alembic_version to skip them: `sqlite3 webui.db "UPDATE alembic_version SET version_num='<target_revision>';"`
- Migration source code is in the container at `/app/backend/open_webui/migrations/versions/`

**Storage**: PVC `openwebui-data-open-webui-0` (StatefulSet volumeClaimTemplate). Contains:
- `webui.db` — SQLite database (critical, can be 1GB+)
- `uploads/` — User-uploaded files
- `vector_db/` — ChromaDB vector embeddings for RAG

**Recovery**: Follow PV Retain recovery in `k8s/AGENTS.md`. The application runs as UID 1000/GID 1000 — any data copy operations must preserve these permissions.

**Startup Behavior**: Large database migrations on version upgrades can take significant time. The StatefulSet has extended startup/readiness probes to accommodate this. Do not reduce probe timeouts without understanding migration duration.

## AI-DOMAIN ANTI-PATTERNS

### Resource Management
- Never request `gpu` - use `nvidia.com/gpu`
- Never skip GPU node affinity for GPU workloads
- Never use Daily backup tier for critical model data - use GFS
- Never underestimate GPU memory requirements for LLM inference

### Configuration
- Never connect applications directly to LLM providers - use LiteLLM
- Never create separate Qdrant instances - use shared cluster
- Store models in PVCs - never use emptyDir or ephemeral storage

## VALIDATION COMMANDS

```bash
# Check GPU availability
kubectl describe nodes | grep -A 10 "Allocated resources"
kubectl get nodes -l gpu-node=true

# Validate GPU allocation
kubectl describe pod -n ai <gpu-pod>

# Check Qdrant connectivity
kubectl exec -it -n ai <app-pod> -- \
  curl http://qdrant.ai.svc.cluster.local:6333/health

# Test LiteLLM connection
kubectl exec -it -n ai <app-pod> -- \
  curl http://litellm.ai.svc.cluster.local:4000/v1/models

# Monitor model storage
kubectl get pvc -n ai -l backup.velero.io/backup-tier=GFS
kubectl exec -it -n ai <app-pod> -- df -h /models
```

## PERFORMANCE TIPS

### GPU Optimization
- Monitor GPU memory usage: `nvidia-smi` on GPU nodes
- Batch model inference requests to reduce GPU context switching
- Consider model quantization for memory efficiency

### Model Storage
- Pre-download models to PVCs to avoid runtime download timeouts
- Use separate PVCs for different model types if access patterns differ
- Monitor storage usage and cleanup unused model caches

### Vector Database
- Monitor Qdrant collection sizes - consider sharding for large datasets
- Use appropriate vector dimensions for your use case
- Backup Qdrant PVCs regularly with GFS tier

## REFERENCES

For general Kubernetes patterns: `k8s/AGENTS.md`
For external access: `k8s/infrastructure/network/AGENTS.md`
For LiteLLM: https://docs.litellm.ai
For Qdrant: https://qdrant.tech/documentation

// applications/ai/litellm/AGENTS.md

# LiteLLM - Agent Guidelines

## Purpose

AI model proxy with enterprise SSO integration, role-based access control, and team management.

## Configuration Architecture

### Authentication Methods

1. **JWT Authentication** (Primary) - Uses JWT role mapping from Authentik groups
2. **OAuth SSO** (Fallback) - Direct authentication via environment variables
3. **Header-based** (Fallback) - Custom SSO proxy integration

### Required Files

- `proxy_server_config.yaml` - Main LiteLLM configuration
- `deployment.yaml` - Environment variables and container settings
- `AGENTS.md` - This file (agent guidelines)

## Configuration Rules

### JWT Authentication Setup

When `enable_jwt_auth: true`, must have:

```yaml
general_settings:
  enable_jwt_auth: true

litellm_jwtauth:
  roles_jwt_field: 'roles' # ✅ Required for jwt_litellm_role_map (IDP role synchronization)
  sync_user_role_and_teams: true
  user_allowed_roles:
    - proxy_admin # Required for admin_only UI access
    - internal_user
    - internal_user_viewer # Fallback role
    - customer
  jwt_litellm_role_map:
    - jwt_role: 'Litellm Admins' # Authentik group
      litellm_role: 'proxy_admin' # Mapped role
    - jwt_role: 'Litellm Users'
      litellm_role: 'internal_user'
```

**Field Usage Clarification:**

- **`roles_jwt_field`**: Used with `jwt_litellm_role_map` for IDP role synchronization. The
  `map_jwt_role_to_litellm_role()` method reads from this field.
- **`user_roles_jwt_field`**: Used with `user_allowed_roles` for simple role validation (whitelist approach). Do NOT use
  with `jwt_litellm_role_map`.

**Required environment variables:**

```yaml
env:
  - name: JWT_PUBLIC_KEY_URL
    value: 'https://sso.peekoff.com/.well-known/openid-configuration/jwks'
  - name: GENERIC_SCOPE
    value: 'openid profile email roles' # Must include roles
```

### OAuth Fallback Setup

When JWT authentication is disabled:

```yaml
generic_oauth:
  scope: 'openid profile email roles'
  user_role_field: 'roles' # Must contain direct LiteLLM role values
```

## Agent Guidelines

### When Working with SSO Issues

1. **ALWAYS verify authentication method precedence** - JWT vs OAuth vs headers
2. **Check `enable_jwt_auth` status** - Required for JWT role mapping
3. **Verify correct JWT field usage** - Use `roles_jwt_field` with `jwt_litellm_role_map`, NOT `user_roles_jwt_field`
4. **Validate scopes include `roles`** - Required for role information
5. **Ensure `user_allowed_roles` includes all fallback roles**
6. **Test JWT token payload** to verify roles claims are present

### Common Failure Patterns

- `internal_user_viewer` despite admin group → Missing `enable_jwt_auth: true` OR using `user_roles_jwt_field` instead
  of `roles_jwt_field` with `jwt_litellm_role_map`
- Role mapping ignored → JWT auth not enabled, OAuth active, OR incorrect field (`user_roles_jwt_field` used with
  `jwt_litellm_role_map`)
- Access denied with `admin_only` → User lacks `proxy_admin` role

### Testing Requirements

Before marking SSO issues as resolved:

- [ ] JWT authentication is enabled
- [ ] `roles_jwt_field` is set (NOT `user_roles_jwt_field`) when using `jwt_litellm_role_map`
- [ ] Roles scope is included in OAuth request
- [ ] Authentik user is in correct group
- [ ] JWT token contains roles claim
- [ ] Role mapping is applied correctly (verify `get_jwt_role()` reads from `roles_jwt_field`)
- [ ] User receives expected `proxy_admin` role
- [ ] Admin UI access works

### Implementation Checklist

- [ ] All authentication methods configured (JWT + OAuth fallback)
- [ ] Role mappings include all expected groups
- [ ] Environment variables set for JWT validation
- [ ] Fallback roles allowed in configuration
- [ ] UI access mode matches allowed roles

## DO NOT

- Commit historical fixes to AGENTS.md
- Remove working configurations for "simplification"
- Assume role mapping works without testing
- Change authentication methods without understanding precedence

## REQUIRED VERIFICATION

Any changes to authentication or role mapping MUST:

1. Verify JWT token contents with debug endpoint
2. Test with actual Authentik admin user
3. Confirm admin UI access with `proxy_admin` role
4. Validate fallback behavior for non-admin users

## Security Requirements

- All SSO configurations must use HTTPS endpoints
- Roles claim must be validated before role assignment
- Default roles should be most restrictive possible
- Admin access should require explicit role assignment


// applications/automation/AGENTS.md

# Automation Applications - Category Guidelines

SCOPE: Home automation, IoT, and workflow automation applications
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: Home Assistant, Frigate, MQTT, Zigbee2MQTT, N8N, Hass.io

## CATEGORY CONTEXT

Purpose: Deploy and manage home automation applications including smart home control, IoT device management, video surveillance, and workflow automation.

## INHERITED PATTERNS

For general Kubernetes patterns, see k8s/AGENTS.md:
- Storage: proxmox-csi (new), longhorn (legacy)
- Network: Gateway API for external access
- Authentication: Authentik SSO where supported
- Database: CNPG for PostgreSQL, auto-generated credentials
- Backup: Velero for proxmox-csi, Longhorn labels for legacy

## AUTOMATION-SPECIFIC PATTERNS

### MQTT Pattern
- Internal-only message broker for IoT communication
- All automation apps communicate via MQTT topics
- No external access required
- TCP route with Cilium 1.18+ required for full protocol support

### Zigbee2MQTT Pattern
- Zigbee coordinator (USB device) runs in separate VM (not Kubernetes)
- Kubernetes Zigbee2MQTT app connects to coordinator over network interface only
- Publishes to MQTT broker

### RTSP Stream Pattern
- Frigate ingests camera feeds via RTSP
- RTSP credentials managed via ExternalSecrets
- No public RTSP exposure

### Workflow Orchestration Pattern
- N8N orchestrates cross-system workflows via MQTT and HTTP APIs
- Uses CNPG PostgreSQL database with auto-generated credentials

## APPLICATION-SPECIFIC GUIDANCE

### Home Assistant
**Purpose**: Central smart home automation hub

**Deployment**:
- Hass.io add-on (not standard container)
- PVC for Home Assistant configuration and database
- Gateway API route for external access
- OAuth2 via Authentik for SSO
- ConfigMap for additional configuration

**Architecture**:
- Main Container: Home Assistant application
- ConfigMount: ConfigMap for customization
- Database: SQLite embedded in PVC
- Authentication: Authentik OpenID Connect
- Seed Configuration: InitContainer conditionally copies automations, scripts, scenes, lovelace from ConfigMap

**Seed Configuration**:
The initContainer manages HA-managed configuration files via the `HA_SEED_ON_STARTUP` environment variable:
- `"true"`: Always overwrite files from ConfigMap (useful for force-reset)
- `"false"` or unset: Only copy if files don't exist, allowing Home Assistant to manage its own files

**Resources**: CPU: 2 cores, Memory: 2Gi, Storage: 10Gi PVC

**External Secrets**: `ha_oidc_client_id`, `ha_oidc_client_secret` (Authentik OAuth2)

### Frigate
**Purpose**: Video surveillance with AI object detection

**Deployment**:
- Helm chart deployment (BlakeBlackshear fork)
- PVC for recordings and database
- Gateway API route for web UI
- RTSP stream access for camera ingestion
- Optional GPU support for faster inference

**Hardware Acceleration**:
- NVIDIA GPU: GPU passthrough for faster inference (optional)
- CPU-only: Default mode, slower inference

**Resources**: CPU: 4+ cores, Memory: 4-8Gi, Storage: 50Gi+ PVC, GPU: Optional 1 GPU

**External Secrets**: `frigate-rtsp-credentials` (RTSP username/password)

**Storage Labels**: Daily tier for recordings (no backup for video)

### MQTT
**Purpose**: Message broker for IoT communication

**Deployment**:
- StatefulSet with single replica
- PVC for persistent data
- Gateway API route for external access (optional)
- ExternalSecrets for authentication
- TCP route for MQTT protocol (Cilium 1.18+ required)
- Internal-only communication preferred

**Resources**: CPU: 1 core, Memory: 512Mi, Storage: 1Gi PVC

**Cilium TCP Listener Issue**: See `/k8s/infrastructure/network/AGENTS.md` for details

### Device Passthrough
- No USB device passthrough in Kubernetes
- Zigbee2MQTT coordinator (USB device) runs in separate VM
- Kubernetes Zigbee2MQTT application connects to coordinator over network interface only

### IoT Device Management
**Zigbee2MQTT Device Discovery**:
1. Edit `config/devices.yaml` to add new devices
2. Apply ConfigMap update via GitOps
3. Restart Zigbee2MQTT pod to load new configuration
4. Verify device joins network

**Frigate Camera Configuration**:
1. Edit Helm values file for camera RTSP credentials
2. Update ExternalSecret for RTSP authentication
3. Apply via GitOps
4. Verify camera ingestion in Frigate UI

**Frigate Live View "Low quality mode"**:
- Frigate tries MSE first; on timeout, buffering, or decode errors it falls back to jsmpeg (detect stream = "low bandwidth mode"). When MSE fails it may try WebRTC next (still high quality if WebRTC works).
- To keep high-quality stream: (1) Camera: H.264, AAC, I-frame interval = frame rate so MSE starts quickly. (2) go2rtc `webrtc.candidates` set and port 8555 TCP+UDP exposed (e.g. at frigate hostname) so WebRTC fallback works externally. (3) In Frigate UI Settings, increase the live view timeout if streams often fall back. (4) Browser console: "Max error count exceeded", "Media playback has stalled", "Safari reported decoding errors" indicate the trigger.

## AUTOMATION-DOMAIN ANTI-PATTERNS

### Security & Access
- Never expose MQTT to public internet without authentication - use Authentik SSO or restrict to internal only
- Never expose Frigate RTSP streams to public internet - keep internal-only or restrict to trusted networks
- Never skip USB device passthrough for Zigbee coordinator - device cannot function without access to `/dev/ttyUSB0`

### Storage & Data Management
- Never backup video recordings from Frigate - recordings can be regenerated and consume significant storage
- Never use Longhorn for new automation applications - use proxmox-csi for better performance and automatic backups
- Never skip database backup configuration for N8N - configure CNPG backups for workflow data

## REFERENCES

For Kubernetes domain patterns: k8s/AGENTS.md
For network patterns (Gateway API): k8s/infrastructure/network/AGENTS.md
For storage patterns: k8s/infrastructure/storage/AGENTS.md
For authentication patterns (Authentik): k8s/infrastructure/auth/authentik/AGENTS.md
For CNPG database patterns: k8s/infrastructure/database/AGENTS.md
For commit format: /AGENTS.md

// applications/games/AGENTS.md

# Games Domain - Repository Guidelines

**Domain Purpose**: Game servers and gaming infrastructure deployed on Kubernetes

## Scope

This domain manages game server deployments, including:
- Minecraft Java and Bedrock servers
- Game server management tools and utilities
- Game-specific networking and storage configurations
- Plugin configurations and mod management

## Architecture

### Directory Structure

```
k8s/applications/games/
├── AGENTS.md                    # This file
├── kustomization.yaml          # Domain-level Kustomize
└── minecraft/                  # Minecraft deployment
    ├── kustomization.yaml      # Main Minecraft Kustomize
    ├── base/                   # Core Kubernetes resources
    │   ├── kustomization.yaml  # Base resources Kustomize
    │   ├── namespace.yaml      # minecraft namespace
    │   ├── statefulset.yaml    # Minecraft server StatefulSet
    │   ├── service.yaml        # Minecraft service
    │   └── admin-external-secret.yaml  # Operator secrets
    ├── plugins/                # Plugin configurations
    │   ├── kustomization.yaml  # ConfigMap generators
    │   ├── plugins.txt         # Plugin download list
    │   ├── geyser-config.yml   # Geyser configuration
    │   └── essentialsx-config.yml  # EssentialsX configuration
    └── bedrockconnect/         # BedrockConnect service
        ├── kustomization.yaml  # BedrockConnect Kustomize
        ├── deployment.yaml     # BedrockConnect deployment
        ├── service.yaml        # BedrockConnect service
        ├── configmap.yaml      # BedrockConnect config
        └── pvc.yaml            # BedrockConnect storage
```

## Kustomize Organization

### Base Resources (`base/`)
Core Kubernetes manifests:
- StatefulSets, Deployments, Services
- Namespaces and RBAC
- Storage claims and networking
- External secrets

### Plugin Configurations (`plugins/`)
All ConfigMap generators for game configurations:
- Server properties and game settings
- Plugin configurations (Geyser, EssentialsX, etc.)
- Mod configurations and resource packs
- ConfigMap files are generated here to enable ConfigMap reloading

### Service Components (`bedrockconnect/`)
Supporting services that enable game functionality:
- BedrockConnect for cross-platform play
- Future: Game management interfaces
- Future: Backup and monitoring services

## Configuration Management

### ConfigMap Generator Strategy
- **Purpose**: Enable automatic ConfigMap reloading when configs change
- **Location**: All ConfigMaps in `plugins/` subfolder
- **Naming**: Use descriptive names indicating config purpose
- **Validation**: YAML configs validated during Kustomize build

### Plugin Management
- **plugins.txt**: Central list of plugins to download
- **Config files**: Individual plugin configs as separate files
- **Naming convention**: `<plugin>-config.yml` for clarity
- **Future scaling**: Easy to add 20+ plugins as separate ConfigMaps

## Deployment Patterns

### Game Server Lifecycle
1. **Base resources** provisioned first (namespace, storage)
2. **Plugin configs** generated and applied
3. **Supporting services** (BedrockConnect) started
4. **Main game server** deployed with all configurations

### Configuration Updates
- Plugin config changes trigger ConfigMap regeneration
- ConfigMap changes automatically trigger pod restarts
- Server restarts only when necessary (config hash changes)

## Integration Points

### Cross-Domain Dependencies
- **storage**: Uses proxmox-csi StorageClass
- **network**: Static IP allocation from network domain
- **auth**: External secrets from auth domain

### GitOps Integration
- All changes flow through Argo CD
- ConfigMap changes trigger automatic deployments
- Health checks ensure service availability

## Security Considerations

### Container Security
- Non-root user execution (UID 1000)
- Read-only filesystem where possible
- Resource limits and requests enforced
- Security context restrictions applied

### Network Security
- Dedicated game server namespaces
- Service mesh integration when applicable
- Network policies for inter-service communication

## Operational Excellence

### Monitoring Requirements
- Game server metrics collection
- Player count and performance monitoring
- Storage usage and backup status
- Service health and availability

### Backup Strategy
- World data backup to external storage
- Configuration backup to Git
- Plugin and mod version tracking

## Future Expansion

### Additional Games
- Structure supports adding new game types
- Follow same pattern: base/, plugins/, supporting services/
- Domain-level coordination for shared resources

### Advanced Features
- Game server clustering
- Dynamic scaling based on player load
- Automated backup and restore workflows
- Integration with game management platforms

// applications/games/minecraft/AGENTS.md

# Minecraft Component - Repository Guidelines

**Component Purpose**: Minecraft Java and Bedrock cross-platform server deployment with enterprise-grade Kubernetes patterns. This component serves as a reference implementation for game server deployments in the games domain.

## Scope

This component manages:
- Minecraft Java server (PaperMC) with cross-platform support
- BedrockConnect service for zero-click Bedrock player access
- Plugin management and configuration
- Game data persistence and backup integration
- Cross-platform authentication via Geyser + Floodgate

## Architecture

### Configuration Management

#### ConfigMap Generator Strategy

All game configurations use Kustomize configMapGenerator for automatic ConfigMap reloading:

```yaml
configMapGenerator:
  - name: minecraft-bedrock
    literals:
      - TYPE=PAPER
      - VERSION=1.21.11
    files:
      - PLUGINS=plugins.txt
  # Plugin configs: key = path under /data/plugins (__ = /)
  - name: geyser-config
    files:
      - Geyser-Spigot__config.yml=geyser-config.yml
```

**Why this pattern:**
- Enables automatic pod restarts when configs change
- Separates simple properties (literals) from complex configs (files)
- Validates YAML during Kustomize build
- Supports ConfigMap hashing for proper rollouts

#### Plugin configs: one mechanism for all plugins

Every plugin’s config comes from ConfigMaps. No per-plugin mounts or init logic.

- **Path-style keys**: ConfigMap keys use double underscore as path separator. Example: `Essentials__config.yml` → `/data/plugins/Essentials/config.yml`; `LuckPerms__yaml-storage__groups__admin.yml` → `/data/plugins/LuckPerms/yaml-storage/groups/admin.yml`.
- **Single projected volume**: All plugin ConfigMaps are combined in one `plugin-configs` projected volume.
- **Generic init container** (`sync-plugin-configs`): On every pod start, copies each file from the projected volume into `/data/plugins/`, translating `__` to `/`. Plugins then read from `/data/plugins/<PluginFolder>/...` as usual. Git-backed config always wins after a sync/restart; works for 2 or 600 plugins without changing the StatefulSet’s volume or init logic.
- **Adding a plugin**: (1) Add a configMapGenerator in `plugins/kustomization.yaml` with path-style keys (`PluginFolder__path__to__file`). (2) Add one entry to the `plugin-configs` projected volume `sources` in `base/statefulset.yaml`.

**Data volume**: `/data` holds world data, plugin JARs (downloaded by the server), and the config files written by the init container. Never mount a ConfigMap directly over `/data`.

#### Secret Management

**External Secrets**: Use ExternalSecret for sensitive data:
- Operator credentials via Bitwarden integration
- Never commit secrets to Git
- Use ClusterSecretStore for external secret backend

```yaml
envFrom:
  - secretRef:
      name: minecraft-server-ops
```

## Kustomize Organization

### Directory Structure

```
k8s/applications/games/minecraft/
├── kustomization.yaml          # Main Kustomize (combines subfolders)
├── base/                       # Core Kubernetes resources
│   ├── kustomization.yaml      # Base resources
│   ├── namespace.yaml          # minecraft namespace
│   ├── statefulset.yaml        # Minecraft server
│   ├── service.yaml            # LoadBalancer services
│   └── admin-external-secret.yaml  # External secrets
├── plugins/                    # Plugin configurations
│   ├── kustomization.yaml      # ConfigMap generators
│   ├── plugins.txt             # Plugin download list
│   ├── geyser-config.yml       # Geyser configuration
│   └── essentialsx-config.yml   # EssentialsX configuration
└── bedrockconnect/             # Supporting service
    ├── kustomization.yaml      # BedrockConnect resources
    ├── deployment.yaml         # BedrockConnect deployment
    ├── service.yaml            # BedrockConnect service
    ├── configmap.yaml          # BedrockConnect config
    └── pvc.yaml                # BedrockConnect storage
```

### Base Resources (`base/`)

**Purpose**: Core Kubernetes manifests that define the game server infrastructure.

**Contents**:
- StatefulSet with proper security context
- Services with static IP annotations
- ExternalSecret for credentials
- Namespace definition

**Rules**:
- StatefulSet uses volumeClaimTemplates for data persistence
- Never modify volumeClaimTemplates after creation (immutable)
- Use proper labels: `app.kubernetes.io/name` and `app.kubernetes.io/part-of: games`

### Plugin Configurations (`plugins/`)

**Purpose**: All game configuration files managed via ConfigMap generators.

**Pattern**:
- One ConfigMap per configuration type
- Simple properties as literals
- Complex configs as files
- Plugin list in `plugins.txt` for automated downloads

**Adding a plugin (with config)**:
1. Add plugin to `plugins.txt`.
2. In `plugins/kustomization.yaml`, add a configMapGenerator with path-style keys: key = `PluginFolder__path__to__file` (double underscore = `/` under `/data/plugins`), value = your config file.
3. In `base/statefulset.yaml`, add one entry under `volumes[plugin-configs].projected.sources` referencing the new ConfigMap name.
4. Run `kustomize build k8s/applications/games/minecraft` to verify.

**Scaling**: Same pattern for any number of plugins; no changes to init container or main container mounts.

### Supporting Services (`bedrockconnect/`)

**Purpose**: Services that enable game functionality but aren't the main game server.

**BedrockConnect**:
- Auto-redirects Bedrock players to Minecraft server
- Zero-click experience for Bedrock users
- Lightweight deployment (50m CPU, 128Mi memory)
- Separate PVC for player data persistence

## Configuration Rules

### What to Do

✅ **Use ConfigMap Generators**: For all game configurations
✅ **Separate Concerns**: Base resources vs plugin configs vs supporting services
✅ **Proper Labeling**: `app.kubernetes.io/part-of: games` for all resources
✅ **Namespace Isolation**: Use `minecraft` namespace for all Minecraft resources
✅ **Resource Requests**: Set proper CPU/memory limits and requests
✅ **Security Context**: Non-root user, dropped capabilities, seccomp profiles
✅ **Static IPs**: Use annotations for LoadBalancer services
✅ **External Secrets**: For all credentials and sensitive data

### Anti-Patterns

❌ **Don't**: Hardcode configuration in StatefulSet spec
❌ **Don't**: Mix plugin configs with server properties
❌ **Don't**: Mount ConfigMaps to `/data` directory (conflicts with game server)
❌ **Don't**: Use default namespace (must be `minecraft`)
❌ **Don't**: Commit secrets to Git (use ExternalSecret)
❌ **Don't**: Modify volumeClaimTemplates after creation
❌ **Don't**: Use root user in containers
❌ **Don't**: Skip resource limits (Minecraft needs proper CPU allocation)

## Plugin Management

### Plugin Downloads

**plugins.txt**: Central list of plugins to download:
```
https://papermc.io/ci/job/Paper-1.21.11/lastSuccessfulBuild/artifact/build/libs/paper-1.21.11.jar
https://download.geysermc.org/v2/projects/geyser/latest/downloads/spigot
https://download.geysermc.org/v2/projects/floodgate/latest/downloads/spigot
https://ci.ender.zone/job/EssentialsX/lastSuccessfulBuild/artifact/target/EssentialsX-2.21.2.jar
```

**Pattern**:
- One plugin per line
- Direct download URLs
- Game server downloads automatically on startup

### Plugin configuration (ConfigMaps for all)

Each plugin with config gets a ConfigMap whose keys use the path convention (`__` → `/` under `/data/plugins`). Example for one file per plugin, and for multiple files (e.g. LuckPerms groups):

```yaml
# One file: PluginFolder__config.yml = path Essentials/config.yml under /data/plugins
- name: essentialsx-config
  files:
    - Essentials__config.yml=essentialsx-config.yml

# Multiple files: nested paths
- name: luckperms-groups
  files:
    - LuckPerms__yaml-storage__groups__default.yml=luckperms-group-default.yml
    - LuckPerms__yaml-storage__groups__admin.yml=luckperms-group-admin.yml
```

All such ConfigMaps are projected into one volume and synced by the generic init container. No plugin-specific mounts or init logic.

### Chest and inventory sorting (CoreChestSort)

CoreChestSort provides lightweight chest and inventory sorting with a category-based system, GUI controls and configurable hotkeys. It respects protection plugins (Lands, WorldGuard, etc.).

- **Chest/container sorting**: `/sort` or `/chestsort` (settings GUI), `/sort on|off|toggle` for auto chest sorting, `/sort hotkeys` for hotkey GUI.
- **Inventory sorting**: `/invsort` or `/isort` (inventory only; hotbar untouched), `/invsort hotbar` (hotbar only), `/invsort on|off|toggle` for auto inventory sorting.
- **Reload**: `/sort reload` (admin).

Permissions are wired in LuckPerms: `chestsort.use` and `chestsort.use.inventory` for default group; `chestsort.reload` for admin. JAR is in `plugins.txt` via [SpiGet API](https://api.spiget.org/v2/resources/132579/download) (Spigot’s direct download URL returns 403 for non-browser requests). An init container removes any existing `QuickSort*.jar` from `/data/plugins` before startup when migrating from QuickSort.

## Operational Considerations

### Cross-Platform Setup

**Geyser + Floodgate**: Enables Java and Bedrock players to join same server:
- Geyser: Translates Bedrock protocol to Java
- Floodgate: Handles authentication for Bedrock players
- Both configured via ConfigMap generators

**Configuration**:
```yaml
GEYSER_ENABLED=true
FLOODGATE=true
GEYSER_AUTH_TYPE=floodgate
```

### Zero-Click Bedrock Access

**BedrockConnect**: Provides auto-redirect for Bedrock players:
- Listens on port 19132
- Auto-redirects to actual Minecraft server
- Custom server list entry for easy access
- Lightweight deployment (separate from main server)

### Resource Requirements

**Minecraft Server**:
- CPU: 2-8 cores (depending on player count)
- Memory: 2-6Gi (depending on plugins and world size)
- Storage: 5Gi+ for world data

**BedrockConnect**:
- CPU: 50m-500m
- Memory: 128Mi-256Mi
- Storage: 1Gi for player data

### Networking

**Ports**:
- Java: 25565/TCP (main game port)
- Bedrock: 19132/UDP (Bedrock protocol)
- BedrockConnect: 19132/UDP (auto-redirect)

**Static IPs**:
```yaml
annotations:
  io.cilium/lb-ipam-ips: 10.25.150.254  # Minecraft server
  io.cilium/lb-ipam-ips: 10.25.150.253  # BedrockConnect
```

## Development Workflow

### Local Testing

**Validate Changes**:
```bash
cd k8s/applications/games/minecraft
kustomize build .
```

**Test Diff**:
```bash
kustomize build . | kubectl diff -f - --server-side
```

### Configuration Updates

**Update Plugin Config**:
1. Edit plugin config file (e.g., `essentialsx-config.yml`)
2. Run `kustomize build .` to validate
3. Apply changes via Argo CD
4. Pod restarts automatically with new config

**Add New Plugin**:
1. Add to `plugins.txt`
2. Create ConfigMap generator if needed
3. Update `plugins/kustomization.yaml`
4. Test with `kustomize build .`
5. Apply via Argo CD

### Version Updates

**Update Minecraft Version**:
1. Change literals in `plugins/kustomization.yaml`:
   ```yaml
   - VERSION=1.21.11
   - PAPER_BUILD=99
   ```
2. Update `plugins.txt` if needed
3. Test build and apply

**Update Plugins**:
1. Update URLs in `plugins.txt`
2. Test by checking plugin download works
3. Apply via Argo CD

## Troubleshooting

### Common Issues

**Pod Not Starting**:
- Check resource allocation (CPU/memory)
- Verify PVC is bound
- Check logs for plugin download errors

**ConfigMap Not Applied**:
- Ensure ConfigMap name matches in StatefulSet
- Check that ConfigMap has proper labels
- Verify no syntax errors in YAML

**Plugin Not Working**:
- Check plugin URL in `plugins.txt`
- Verify plugin config file exists and is valid
- Check server logs for plugin errors

### Debugging Commands

**Check Pod Logs**:
```bash
kubectl logs minecraft-bedrock-0 -n minecraft
```

**Check ConfigMap**:
```bash
kubectl get configmap minecraft-bedrock -n minecraft -o yaml
```

**Check PVC**:
```bash
kubectl get pvc data-minecraft-bedrock-0 -n minecraft
```

**Check Resources**:
```bash
kubectl top pods -n minecraft
```

## Best Practices

### Configuration Management
- Keep configuration files in `plugins/` directory
- Use descriptive names for ConfigMaps
- Validate YAML before committing
- Test changes locally with `kustomize build`

### Security
- Always use ExternalSecret for credentials
- Never commit secrets to Git
- Use proper security context (non-root, dropped capabilities)
- Set resource limits to prevent resource exhaustion

### Scalability
- Structure supports 20+ plugins
- Each plugin gets dedicated ConfigMap
- Clear separation between components
- Easy to add new game types following same pattern

### Documentation
- Update this AGENTS.md when adding new plugins
- Document configuration changes
- Note breaking changes in commit messages
- Keep plugin documentation up to date

## Future Enhancements

### Potential Improvements
- Automated backup integration
- Horizontal scaling for multi-world setups
- Dynamic resource allocation based on player count
- Plugin version pinning for stability
- Health checks for plugin availability

### Migration Paths
- Version upgrades via ConfigMap changes
- Plugin additions without downtime
- Storage expansion via PVC resizing
- Network policy updates for security hardening

// applications/media/AGENTS.md

# Media Applications - Specialized Patterns

SCOPE: Media management, streaming, and content automation
INHERITS FROM: /k8s/AGENTS.md

## MEDIA-SPECIFIC PATTERNS

### NFS Media Library Pattern
```yaml
# Shared media mount for arr-stack
apiVersion: v1
kind: PersistentVolume
metadata:
  name: media-nfs
spec:
  capacity:
    storage: 10Ti
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: truenas.peekoff.com
    path: /mnt/media
---
# PVC for application access
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: media
  namespace: media
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Ti
  volumeName: media-nfs
```

**Mount Pattern:**
```yaml
volumeMounts:
- name: media
  mountPath: /media
  subPath: <app-specific-path>  # e.g., movies, tv, music
```

**SubPath Structure:**
- `/media/movies/` - Radarr
- `/media/tv/` - Sonarr
- `/media/music/` - Lidarr (if added)
- `/media/downloads/` - Sabnzbd
- `/media/audiobooks/` - Audiobookshelf

### arr-stack Service Pattern
```yaml
# Common service configuration for arr-stack
apiVersion: v1
kind: Service
metadata:
  name: <arr-app>
  namespace: media
spec:
  selector:
    app.kubernetes.io/name: <arr-app>
  ports:
  - port: 80
    targetPort: 8983  # Adjust per app
---
# HTTPRoute for external access
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: <arr-app>
  namespace: media
spec:
  parentRefs:
  - name: external
    namespace: gateway
  hostnames:
  - "<arr-app>.peekoff.com"
  rules:
  - matches:
    - path:
        type: Prefix
        value: /
    backendRefs:
    - name: <arr-app>
      port: 80
```

**arr-stack Services:**
- **Sonarr**: Port 8983, manages TV series
- **Radarr**: Port 7878, manages movies
- **Prowlarr**: Port 9696, manages indexers
- **Bazarr**: Port 6767, manages subtitles

### Immich Multi-Service Pattern
```yaml
# Immich services connection pattern
# Database: immich-postgresql.media.svc.cluster.local
# Redis: immich-redis.media.svc.cluster.local
# ML Service: immich-machine-learning.media.svc.cluster.local

# Environment variables pattern
env:
- name: DB_HOSTNAME
  value: immich-postgresql.media.svc.cluster.local
- name: DB_USERNAME
  valueFrom:
    secretKeyRef:
      name: immich-postgresql-app
      key: username
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: immich-postgresql-app
      key: password
- name: REDIS_HOSTNAME
  value: immich-redis.media.svc.cluster.local
```

**Storage Configuration:**
- Photos/videos: Large PVC with GFS backup tier
- Library: Use proxmox-csi StorageClass
- ML models: Separate PVC for ML service

### Download Manager Pattern (Sabnzbd)
```yaml
# Sabnzbd ExternalSecret
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: sabnzbd-credentials
  namespace: media
spec:
  secretStoreRef:
    name: bitwarden-backend
    kind: ClusterSecretStore
  target:
    creationPolicy: Owner
  data:
  - secretKey: nzb-server-host
    remoteRef:
      key: Usenet Server
  - secretKey: nzb-server-username
    remoteRef:
      key: Usenet Server
  - secretKey: nzb-server-password
    remoteRef:
      key: Usenet Server
  - secretKey: nzb-server-api-key
    remoteRef:
      key: Usenet Server
```

**Storage Pattern:**
```yaml
# Download storage PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sabnzbd-downloads
  namespace: media
  labels:
    backup.velero.io/backup-tier: Daily
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-csi
  resources:
    requests:
      storage: 500Gi
```

### Audiobookshelf Pattern
```yaml
# Audiobookshelf storage
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: audiobookshelf-library
  namespace: media
  labels:
    backup.velero.io/backup-tier: GFS  # Critical audiobook data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-csi
  resources:
    requests:
      storage: 200Gi
```

**Configuration:**
- Mount audiobooks from NFS or dedicated PVC
- Optional Authentik SSO integration
- Gateway API external access

## MEDIA-DOMAIN ANTI-PATTERNS

### Storage Management
- Never backup media libraries via Kubernetes - backed up separately via TrueNAS
- Never use Longhorn for new media applications - use proxmox-csi
- Never skip NFS mounts for arr-stack - required for shared media access
- Never use Daily backup tier for irreplaceable content - use GFS

### Service Configuration
- Never expose WhisperASR externally - internal service only
- Never use SQLite for production databases - use CNPG (Immich pattern)
- Never skip ExternalSecrets for credential management

## VALIDATION COMMANDS

```bash
# Check NFS mount status
kubectl exec -it -n media <arr-pod> -- df -h /media

# Test media file access
kubectl exec -it -n media <arr-pod> -- ls -la /media/movies

# Check arr-stack connectivity
kubectl exec -it -n media <arr-pod> -- curl http://localhost:8983

# Validate ExternalSecrets
kubectl get externalsecret -n media
kubectl describe secret -n media <secret-name>

# Check Immich services
kubectl get pods -n media -l app.kubernetes.io/part-of=immich
kubectl exec -it -n media immich-server-0 -- curl http://immich-postgresql.media.svc.cluster.local:5432
```

## PERFORMANCE TIPS

### Storage Optimization
- Use proxmox-csi for better performance than Longhorn
- Separate PVCs for different workloads (downloads vs library vs config)
- Monitor disk space on media NFS share

### Network Optimization
- arr-stack services communicate with each other via internal DNS
- Use HTTPRoute for external access with proper TLS termination
- Consider bandwidth management for large file transfers

## REFERENCES

For general patterns: `k8s/AGENTS.md`
For external access: `k8s/infrastructure/network/AGENTS.md`
For storage: `k8s/infrastructure/storage/AGENTS.md`
For databases (Immich): `k8s/infrastructure/database/AGENTS.md`

// applications/web/AGENTS.md

# Web Applications - Category Guidelines

SCOPE: Web-based productivity and utility applications
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: BabyBuddy, Pinepods, HeadlessX, Kiwix, Pedrobot

## CATEGORY CONTEXT

Purpose: Deploy and manage web-based applications for personal productivity, podcast management, offline content access, and bot services.

## INHERITED PATTERNS

For general Kubernetes patterns, see k8s/AGENTS.md:
- Storage: proxmox-csi (all new web applications)
- Network: Gateway API for external access
- Authentication: Authentik SSO where supported
- Database: CNPG for PostgreSQL with auto-generated credentials
- Backup: Velero automatic backups for proxmox-csi PVCs
- Large Storage: Exclude from backups if re-downloadable (Kiwix)

## WEB-SPECIFIC PATTERNS

### Browser Automation Pattern
- HeadlessX runs headless browser tasks with network policy restrictions for security
- Requires OAuth2 via Authentik
- Isolated namespace for security

### Podcast Management Pattern
- Pinepods uses CNPG PostgreSQL with Valkey (Redis-compatible) for caching
- Supports OAuth2 via Authentik
- Large PVC for podcast data with dual backup to MinIO and Backblaze B2

### Offline Content Pattern
- Kiwix stores large offline content (Wikipedia ZIM files, 200GB+)
- Exclude from Velero backups via pod annotation
- Content can be re-downloaded

### Bot Service Pattern
- Pedrobot uses MongoDB StatefulSet (not CNPG)
- External secrets for bot API credentials
- No OAuth2 support

## COMPONENTS

### BabyBuddy
Baby tracking application for infant care logging. Uses StatefulSet with PVC for application data and SQLite database. OAuth2 via Authentik for SSO.

### Pinepods
Self-hosted podcast management and synchronization. Uses CNPG PostgreSQL cluster (2 instances) with Valkey for caching. Large PVC for podcast data. Optional OAuth2 via Authentik. Dual backup to MinIO and Backblaze B2.

### HeadlessX
Browser automation service for headless browser tasks. Uses Deployment with PVC for browser profile and data. Network policy restricts egress to required domains only. OAuth2 via Authentik for SSO. Isolated namespace for security.

### Kiwix
Offline Wikipedia and content reader. Uses Deployment with large PVC for offline content (200GB+ Wikipedia). No external authentication required. Exclude from Velero backups due to size. Content can be re-downloaded.

### Pedrobot
Bot service for Discord. Uses MongoDB StatefulSet for backend. External secrets for bot API credentials. No OAuth2 support.

## WEB-DOMAIN ANTI-PATTERNS

### Storage & Data Management
- Never backup Kiwix content via Velero - exclude via annotation as content can be re-downloaded
- Never use Longhorn for new web applications - use proxmox-csi for automatic backups

### Security & Access
- Never skip network policy for HeadlessX - restrict egress to required domains only
- Never expose Pedrobot to public internet without rate limiting

## REFERENCES

For Kubernetes domain patterns: k8s/AGENTS.md
For network patterns (Gateway API): k8s/infrastructure/network/AGENTS.md
For storage patterns: k8s/infrastructure/storage/AGENTS.md
For CNPG database patterns (Pinepods): k8s/infrastructure/database/AGENTS.md
For commit format: /AGENTS.md

// infrastructure/auth/authentik/AGENTS.md

# Authentik Identity Provider - Component Guidelines

SCOPE: Authentik identity provider (SSO) and authentication flows
INHERITS FROM: /k8s/AGENTS.md

## COMPONENT CONTEXT

Purpose: Provide centralized authentication and authorization (SSO) for all homelab applications using Authentik as identity provider with GitOps-managed blueprints.

Architecture:
- `k8s/infrastructure/auth/authentik/` - Authentik deployment manifests
- `extra/blueprints/` - Declarative GitOps configuration (users, groups, apps, flows, providers)
- PostgreSQL database: Stores all Authentik data (managed by CNPG)
- Outposts: External auth instances for proxied applications

## INTEGRATION POINTS

### External Services
- **Proxied applications**: Home Assistant, Grafana, Argo CD, media services (use Authentik via OAuth/OIDC)
- **Email provider**: SMTP service for password recovery and notifications
- **User directories**: LDAP/AD integration (optional)

### Internal Services
- **PostgreSQL database**: CNPG-managed database for Authentik data
- **MinIO object storage**: Stores backups and attachments
- **Kubernetes secrets**: Database credentials and API tokens

## COMPONENT PATTERNS

### Blueprint GitOps Pattern
- **Purpose**: Declarative configuration for Authentik
- **Discovery**: YAML files mounted at `/blueprints`, auto-discovered when created/modified
- **Application**: Applied every 60 minutes or on-demand via UI/API
- **Properties**: Idempotent (safe to apply multiple times), atomic (all entries succeed or fail together)

### Blueprint File Structure
- **Version**: Always `1`
- **Metadata**: Name, labels, description
- **Entries**: List of objects to create/update (model, identifiers, attrs, state)
- **Custom YAML tags**: `!KeyOf`, `!Find`, `!Env`, `!File`, `!Context` for dynamic values

### Blueprint Entry States
- `present` (default): Creates if missing, updates `attrs` if exists
- `created`: Creates if missing, never updates (preserves manual changes)
- `must_created`: Creates only if missing, fails if exists (strict validation)
- `absent`: Deletes object (may cascade to related objects)

### Identifiers vs Attrs Pattern
- **`identifiers`**: Used to find existing objects (merged with attrs on creation, used for lookup on update, NOT applied on update)
- **`attrs`**: Used to set attributes on object (merged with identifiers on creation, only these fields modified on update)

### OAuth2 Application Pattern
Create OAuth2 provider in blueprint with:
- Name and client type (confidential/public)
- Redirect URIs with matching mode (strict/regex)
- Client ID and secret from `!Env` tags (ExternalSecrets)
- Token validity settings (access_code, access_token, refresh_token)
- Authorization and invalidation flows (use `!Find` to reference default flows)
- Signing key (use `!Find` to reference self-signed certificate)

### Flow and Stage Pattern
Authentication flows consist of stages (login, MFA, password recovery, consent). Stages reference each other via `!KeyOf` tags. Flows reference stages via `!KeyOf`. Default flows created by Authentik can be referenced with `!Find`.

## DATA MODELS

### Blueprint Models
- `authentik_core.user` - User accounts
- `authentik_core.group` - User groups
- `authentik_flows.flow` - Authentication flows
- `authentik_flows.flowstagebinding` - Flow-to-stage relationships
- `authentik_stages_authenticator.*.stage` - Authenticator stages (TOTP, WebAuthn, etc.)
- `authentik_providers_oauth2.oauth2provider` - OAuth2 providers
- `authentik_providers_saml.samlprovider` - SAML providers
- `authentik_core.application` - Application definitions
- `authentik_blueprints.blueprint` - Blueprint definitions

## WORKFLOWS

### Development
1. Create blueprint file: `k8s/infrastructure/auth/authentik/extra/blueprints/<name>.yaml`
2. Add schema reference: `# yaml-language-server: $schema=https://goauthentik.io/blueprints/schema.json`
3. Define entries with models, identifiers, attrs, and state
4. Use `!KeyOf` to reference entries within same blueprint
5. Use `!Find` to lookup existing Authentik objects
6. Use `!Env` for secrets (from ExternalSecrets)
7. Test blueprint syntax: `kustomize build --enable-helm k8s/infrastructure/auth/authentik`
8. Commit changes (GitOps applies blueprints automatically)

### Testing
- Validate blueprint YAML syntax: `yamllint extra/blueprints/*.yaml`
- Build kustomization: `kustomize build --enable-helm k8s/infrastructure/auth/authentik`
- Check blueprint logs: `kubectl logs -n auth -l app.kubernetes.io/name=authentik --tail=100 | grep -i blueprint`
- Monitor blueprint application in Authentik UI (System → Blueprints)

## CONFIGURATION

### Required
- PostgreSQL database (CNPG cluster) with external secret
- Blueprint files in `extra/blueprints/` directory
- External secrets for SMTP credentials, application client secrets
- Self-signed certificate key for OAuth signing

### Optional
- LDAP/AD integration for user directory
- External identity providers (Google, GitHub) for OAuth
- Custom authentication flows and stages
- Email provider for notifications
- Outposts for proxied applications

## BREAKING CHANGES

### Authentik 2024.8 Property Mapping Model Changes
- **Issue**: Removed `authentik_core.propertymapping` for OAuth2 property mappings
- **Fix**: Update OAuth2 property mapping references to use `authentik_providers_oauth2.scopemapping` with `[scope_name, "..."]`
- **Example**:
  ```yaml
  # OLD (fails in 2024.8+)
  property_mappings:
    - !Find [authentik_core.propertymapping, [name, "authentik default OAuth Mapping: OpenID 'openid'"]]

  # NEW (works in 2024.8+)
  property_mappings:
    - !Find [authentik_providers_oauth2.scopemapping, [scope_name, "openid"]]
  ```

## YAML CUSTOM TAGS REFERENCE

### Core Tags
- `!KeyOf` - Reference primary key of entry defined earlier in same blueprint
- `!Find` - Lookup existing object in database by model and fields
- `!FindObject` - Lookup with full data (v2025.8+), returns serialized object
- `!Env` - Read from environment variables, supports default values
- `!File` - Read file contents, supports default values
- `!Context` - Access blueprint context variables (built-in or user-defined)

### String Manipulation
- `!Format` - Python-style string formatting with `%` operator

### Conditional Tags
- `!If` - Evaluates condition and returns one of two values
- `!Condition` - Combines multiple conditions with boolean operators

### Iteration Tags
- `!Enumerate` - Loop over sequences or mappings to generate multiple entries
- `!Index <depth>` - Returns index (sequence) or key (mapping) at specified depth
- `!Value <depth>` - Returns value at specified depth
- `!AtIndex` - Access specific index in sequence or mapping (v2024.12+)

## AUTHENTIK-DOMAIN ANTI-PATTERNS

### Blueprint Management
- Never create blueprints without proper schema reference
- Never use incorrect model references (check breaking changes)
- Never create circular dependencies between blueprints
- Never assume blueprint application is instant - check logs and UI

### Configuration & Security
- Never commit secrets to blueprint files - use `!Env` tags with ExternalSecrets
- Never share ExternalSecret entries across applications
- Never create OAuth providers without proper redirect URIs
- Never skip testing blueprint syntax before committing

## GOTCHAS

- Blueprint auto-generated fields (like OAuth client secrets) are NOT overwritten on update if state is `present`
- Blueprint identifiers use OR logic if multiple fields specified; attrs use AND logic
- Blueprint `!Find` fails if no matching object found - use with `!If` for conditional lookups
- Blueprint `!KeyOf` references must match an `id` field defined earlier in same blueprint
- Multiple blueprints can conflict if they modify same objects

## REFERENCES

For general Kubernetes patterns: k8s/AGENTS.md
For commit format: /AGENTS.md
For CNPG database patterns: k8s/AGENTS.md
For Authentik documentation: https://goauthentik.io/docs/
For blueprint schema: https://goauthentik.io/blueprints/schema.json

// infrastructure/controllers/AGENTS.md

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

// infrastructure/database/AGENTS.md

# Database Infrastructure - Component Guidelines

SCOPE: PostgreSQL database management with CloudNativePG operator
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: CloudNativePG (CNPG), PostgreSQL, MinIO, Backblaze B2, S3-compatible storage

## COMPONENT CONTEXT

Purpose: Deploy and manage PostgreSQL database clusters using CloudNativePG operator, including high availability, backup, and disaster recovery.

## QUICK-START COMMANDS

```bash
# Build database infrastructure
kustomize build --enable-helm k8s/infrastructure/database

# Check CNPG clusters
kubectl get cluster -A

# Check database pods
kubectl get pods -n <namespace> -l cnpg.io/podRole=instance

# Describe cluster status
kubectl describe cluster <name> -n <namespace>

# Get auto-generated credentials
kubectl get secret <cluster-name>-app -n <namespace>

# Check backup status
kubectl get backup -n <namespace>
kubectl get scheduledbackup -n <namespace>

# Verify storage
kubectl get pvc -n <namespace>
```

## CLOUDNATIVEPG PATTERNS

### Cluster Configuration
- **Basic Structure**: Cluster manifest defines PostgreSQL configuration, instances, image version, storage allocation, WAL storage, PostgreSQL parameters, and monitoring settings
- **Storage Class**: Use `proxmox-csi` for new clusters
- **Minimum Requirements**: 2 instances for high availability, separate storage for data and WAL

### Auto-Generated Credentials (Preferred)
- **Pattern**: Let CNPG auto-generate credentials instead of using ExternalSecrets
- **How It Works**: CNPG automatically creates `<cluster-name>-app` secret containing username, password, dbname, host, port, and URI
- **Application Usage**: Applications reference this secret directly via environment variable with secretKeyRef
- **When to Use ExternalSecrets**: Only for backup credentials (Backblaze B2, MinIO), never for application database credentials

### Backup Configuration

**Backup Strategy**: Continuous WAL → MinIO (plugin), weekly base backups → B2 (backup section), both in externalClusters for recovery flexibility.

**Dual Backup Strategy**:

**1. Local MinIO (Fast Recovery)**:
- ObjectStore: S3-compatible endpoint (TrueNAS MinIO)
- Use case: Fast restores from local NAS
- Connection: `https://truenas.peekoff.com:9000`
- Bucket: `homelab-postgres-backups/<namespace>/<cluster>`

**2. Backblaze B2 (Disaster Recovery)**:
- ObjectStore: S3-compatible endpoint (Backblaze B2)
- Use case: Offsite disaster recovery
- Connection: `https://s3.us-west-002.backblazeb2.com`
- Bucket: `homelab-cnpg-b2/<namespace>/<cluster>`

**Key Configuration**:
- Retention Policy: Set `retentionPolicy: "14d"` on MinIO ObjectStores (local), `retentionPolicy: "30d"` on B2 ObjectStores (offsite DR)
- ExternalSecrets: Create separate Bitwarden entries for access-key-id and secret-access-key
- Backup Configuration: Use barmanObjectStore pointing to Backblaze B2 endpoint
- Scheduled Backups: Create ScheduledBackup resource with cron schedule (e.g., Sundays at 02:00)
- WAL Archiving: Configure barman-cloud.cloudnative-pg.io plugin with isWALArchiver enabled
- **Critical**: Only plugin architecture (ObjectStore CRD + barman-cloud plugin) is supported

### External Clusters (Recovery)
- **Purpose**: Enable recovery from either backup location
- **Configuration**: Configure externalClusters in spec with two entries (Backblaze B2 and MinIO)
- Each uses barmanObjectStore with destinationPath, endpointURL, and S3 credentials
- Enable gzip compression and AES256 encryption for WAL

## CLUSTER OPERATIONS

### Creating a New Cluster
**Steps**:
1. Create ExternalSecrets for backup credentials (2 separate Bitwarden entries)
2. Create ObjectStore resources for MinIO (`retentionPolicy: "14d"`) and Backblaze B2 (`retentionPolicy: "30d"`)
3. Create Cluster manifest with backup configuration
4. Create ScheduledBackup resource
5. Apply via GitOps

### Cluster Scaling
**Increase Instances**:
1. Update `spec.instances` in Cluster manifest
2. Apply via GitOps
3. Monitor pod rollout and verify health

**Increase Storage**:
1. Update `spec.storage.size` in Cluster manifest
2. Apply via GitOps
3. CNPG automatically expands PVCs
4. Verify expansion completed: `kubectl get pvc -n <namespace>`

### Cluster Upgrades
**PostgreSQL Version Upgrade**:
1. Update `spec.imageName` in Cluster manifest
2. Review breaking changes for PostgreSQL version
3. Apply via GitOps
4. Monitor upgrade logs and verify application compatibility

**CNPG Operator Upgrade**:
1. Update Helm chart version in `cloudnative-pg/kustomization.yaml`
2. Review release notes for breaking changes
3. Apply via GitOps
4. Monitor operator pods and verify cluster health

## DATABASE TUNING

### PostgreSQL Parameters
**Memory Configuration**:
- `shared_buffers`: 25% of RAM (shared memory for queries)
- `effective_cache_size`: 50% of RAM (operating system cache)
- `work_mem`: Memory per operation (default 4MB)
- `maintenance_work_mem`: Memory for maintenance operations (default 64MB)

**Performance Tuning**:
- `random_page_cost`: Cost for random page access (default 4.0, set 1.1 for SSD)
- `effective_io_concurrency`: Concurrent I/O operations (default 200)
- `default_statistics_target`: Statistics accuracy (default 100)

### Monitoring
- **PodMonitor**: Enable monitoring in cluster spec by setting enablePodMonitor to true
- **Metrics Exposed**: Connection counts, query performance, replication lag, storage usage, WAL metrics

## DISASTER RECOVERY

### Cluster Restoration
**From Backblaze B2**: List available backups to identify target backup ID. Create new Cluster manifest with bootstrap recovery configuration referencing externalClusterName and backupID.

**From MinIO (Local)**: List available backups. Create new Cluster manifest with bootstrap recovery configuration referencing minio-backup externalClusterName and backupID.

**Point-in-Time Recovery (PITR)**: Configure bootstrap recovery with targetTime parameter specifying precise recovery timestamp.

## TROUBLESHOOTING

### Cluster Not Starting
**Check Pods**:
```bash
kubectl get pods -n <namespace> -l cnpg.io/podRole=instance
kubectl logs -n <namespace> <instance-pod>
```

**Common Issues**: Storage not bound, resource limits, configuration error

### Backup Failures
**Check Backup Status**:
```bash
kubectl get backup -n <namespace>
kubectl describe backup <backup-name> -n <namespace>
```

**Common Issues**: S3 credentials invalid, network issue, insufficient storage

**After cluster rename**: Existing Backup CRs keep `spec.cluster.name` from when they were created. If the cluster was renamed (e.g. to `*-restored`), old Backup CRs reference the old name and report "Unknown cluster". ScheduledBackup in Git already points at the new cluster name. One-time cleanup: list and delete Backup CRs that reference the old cluster name (e.g. `kubectl get backup -n <namespace> -o json | jq -r '.items[] | select(.spec.cluster.name=="<old-cluster-name>") | .metadata.name' | xargs -r kubectl delete backup -n <namespace>`).

### Replication Issues
**Check Replication Status**:
```bash
kubectl get cluster <name> -n <namespace> -o yaml
kubectl describe cluster <name> -n <namespace>
```

**Common Issues**: Network latency, storage performance, resource exhaustion

## DATABASE-DOMAIN ANTI-PATTERNS

### Credentials Management
- Never use ExternalSecrets for application database credentials - let CNPG auto-generate `<cluster-name>-app` secret
- Never create separate Bitwarden entries for database credentials - CNPG generates credentials automatically
- Never commit database credentials to manifests - use CNPG auto-generated secrets or ExternalSecrets for backup credentials only
- Never share Bitwarden entries across applications - create separate entries for each secret value

### Configuration & Operations
- **NEVER use legacy barman object storage deployment - ONLY plugin architecture (ObjectStore CRD + barman-cloud plugin) is supported**
- Never skip backup configuration for production clusters - configure MinIO and Backblaze B2 backups
- Never use shared databases across applications - create separate CNPG clusters for each application
- Never skip WAL archiving for production workloads - enable WAL archiving to Backblaze B2 for point-in-time recovery
- Never use `latest` PostgreSQL version - pin to specific version for reproducibility
- Never delete old backups without archiving - maintain retention policy for disaster recovery

### Security
- Never use weak PostgreSQL passwords - let CNPG auto-generate strong passwords
- Never expose database pods to public internet - keep databases internal-only
- Never skip network policies for database access - restrict access to application namespaces only

## REFERENCES

For Kubernetes patterns: k8s/AGENTS.md
For storage patterns: k8s/infrastructure/storage/AGENTS.md
For Velero backup integration: k8s/infrastructure/controllers/velero/BACKUP_STRATEGY.md
For CNPG documentation: https://cloudnative-pg.io/documentation/
For Immich CNPG example: k8s/applications/media/immich/immich-server/database.yaml
For Pinepods CNPG example: k8s/applications/web/pinepods/database.yaml
For commit format: /AGENTS.md

// infrastructure/network/AGENTS.md

# Network Infrastructure - External Access Hub

SCOPE: Service exposure, DNS, and external access workflows
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: Gateway API, Cilium, CoreDNS, Cloudflared

## SERVICE EXPOSURE WORKFLOWS

### HTTPS Service Setup (Most Common)

#### Step 1: Create Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: <app-name>
  namespace: <app-namespace>
spec:
  selector:
    app.kubernetes.io/name: <app-name>
  ports:
  - port: 80
    targetPort: <app-port>
    protocol: TCP
```

#### Step 2: Create HTTPRoute
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: <app-name>
  namespace: <app-namespace>
spec:
  parentRefs:
  - name: external  # IP: 10.25.150.222
    namespace: gateway
    sectionName: https
  - name: internal  # Internal traffic only
    namespace: gateway
  hostnames:
  - "<app-name>.peekoff.com"
  - "<app-name>.goingdark.social"  # optional
  rules:
  - matches:
    - path:
        type: Prefix
        value: /
    backendRefs:
    - name: <app-name>
      port: 80
```

#### Step 3: DNS Configuration
1. Add A record in Cloudflare:
   - Name: `<app-name>.peekoff.com`
   - IP: `10.25.150.222`
   - TTL: Auto
   - Proxy: DNS only (not cloudflare proxy)

2. Certificate auto-provisioned by Cert Manager
3. Gateway routes HTTPS traffic to your service

#### Step 4: Validation
```bash
# Check HTTPRoute status
kubectl get httproute -n <app-namespace> <app-name>

# Test from external
curl -H "Host: <app-name>.peekoff.com" https://10.25.150.222

# Check certificate
kubectl get certificate -n <app-namespace>
```

### Internal Service Access

#### Step 1: Create Service (ClusterIP)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: <app-name>
  namespace: <app-namespace>
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: <app-name>
  ports:
  - port: <service-port>
    targetPort: <app-port>
```

#### Step 2: Access Pattern
Internal DNS: `<app-name>.<app-namespace>.svc.cluster.local`

### Cloudflare Tunnel Integration

#### Step 1: Install Cloudflared
Cloudflared runs as DaemonSet in `cloudflared` namespace.

#### Step 2: Configure Tunnel
Add to cloudflared ConfigMap:
```yaml
ingress:
  - hostname: <app-name>.peekoff.com
    service: http://<app-name>.<app-namespace>.svc.cluster.local:80
```

#### Step 3: DNS Configuration
1. Create CNAME record in Cloudflare:
   - Name: `<app-name>.peekoff.com`
   - Target: `<tunnel-id>.cfargotunnel.com`
   - Proxy: Cloudflare proxy (orange cloud)

## NETWORK COMPONENTS

### Cilium (CNI)
- Version: 1.18.5+ (1.17.x has TCP listener bug)
- Replaces kube-proxy with eBPF
- IP Pool for LoadBalancers: `10.25.150.220-10.25.150.255`

### Gateway API
- **External Gateway**: `gateway/external` (IP: 10.25.150.222)
- **Internal Gateway**: `gateway/internal`
- **TLS Passthrough**: `gateway/tls-passthrough`

### CoreDNS
- Cluster DNS resolution
- Resolves: `<service>.<namespace>.svc.cluster.local`

## TROUBLESHOOTING COMMANDS

### Service Issues
```bash
# Check service endpoints
kubectl get endpoints -n <namespace> <service-name>

# Test service connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://<service-name>.<namespace>.svc.cluster.local

# Check service logs
kubectl logs -n <namespace> -l app.kubernetes.io/name=<app-name>
```

### Gateway Issues
```bash
# Check gateway status
kubectl get gateway -n gateway
kubectl describe gateway -n gateway external

# Check HTTPRoute status
kubectl get httproute -A
kubectl describe httproute -n <namespace> <route-name>

# Test routing
curl -H "Host: <hostname>" https://10.25.150.222
```

### DNS Issues
```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test DNS resolution
kubectl run -it --rm dns-test --image=busybox --restart=Never -- \
  nslookup kubernetes.default.svc.cluster.local

# Test external DNS
kubectl run -it --rm dns-test --image=busybox --restart=Never -- \
  nslookup google.com
```

### Certificate Issues
```bash
# Check certificate status
kubectl get certificate -A
kubectl describe certificate -n <namespace> <cert-name>

# Check certificate requests
kubectl get certificaterequest -A
```

## NETWORK ANTI-PATTERNS

### Security
- Never expose databases directly - keep internal-only
- Never skip TLS certificates - always use HTTPS
- Never use NodePort for external access - use Gateway API
- Never open firewall ports - use Gateway API and Cloudflared

### Configuration
- Never bypass Gateway API - use HTTPRoutes
- Never disable Cilium kubeProxyReplacement
- Never manually configure CoreDNS
- Never use wildcard DNS certificates

## KNOWN ISSUES

### Cilium 1.17.x TCP Listener Bug
Version 1.17.x broke TCP Gateway listeners. Use 1.18+ for MQTT services.

## REFERENCES

For application patterns: `k8s/AGENTS.md`
For certificate management: `k8s/infrastructure/controllers/AGENTS.md`
For Cilium documentation: https://docs.cilium.io

// infrastructure/storage/AGENTS.md

# Infrastructure Storage - Component Guidelines

SCOPE: Cluster storage providers and volume management
INHERITS FROM: /k8s/AGENTS.md
TECHNOLOGIES: Proxmox CSI Driver, StorageClasses, PVCs, Volume Snapshots

## COMPONENT CONTEXT

Purpose: Manage persistent storage for Kubernetes workloads, including dynamic provisioning, volume backups, and storage class selection.

Architecture:
- `proxmox-csi/` - Proxmox CSI driver for dynamic provisioning from Proxmox ZFS

## QUICK-START COMMANDS

```bash
# Build all storage components
kustomize build --enable-helm k8s/infrastructure/storage

# Build specific storage provider
kustomize build --enable-helm k8s/infrastructure/storage/<provider>

# Check StorageClasses
kubectl get storageclass

# Check Proxmox CSI volumes
kubectl get pv -A
```

## STORAGE STRATEGY

### Primary Storage: Proxmox CSI

**Purpose**: Dynamic provisioning from Proxmox Nvme1 ZFS datastore.

**StorageClass**: `proxmox-csi`
- Cache Mode: `writethrough` - Balanced performance and integrity
- Filesystem: `ext4`
- Reclaim Policy: `Retain` - Persistent data preserved
- SSD: `true` - Optimized for SSD performance
- Mount Options: `noatime` - Reduce disk writes
- Default: `true` - Default StorageClass for new PVCs

**When to Use**:
- All new workloads
- Stateful applications requiring high performance
- Single-node storage (no replication needed)

**Backup Strategy**:
- Automatically backed up by Velero Kopia filesystem backups
- Velero schedules: Daily, hourly (GFS), weekly
- No annotations required

**Permissions**:
- Managed via Terraform at `tofu/bootstrap/proxmox-csi-plugin/`
- Proxmox user: `kubernetes-csi@pve`
- Minimal permissions: VM.Audit, VM.Config.Disk, Datastore.Allocate, Datastore.Audit

## STORAGE PATTERNS

### PVC Creation Pattern
Create PersistentVolumeClaim with ReadWriteOnce access mode. Set storageClassName to `proxmox-csi`. Specify requested storage size.

### Volume Expansion
- Resize PVC: Update `resources.requests.storage` in PVC spec
- K8s automatically expands volume (online expansion supported)
- Verify expansion: `kubectl describe pvc <name>`

### Volume Exclusion Pattern
Add annotation `backup.velero.io/backup-volumes-excludes: "cache-volume"` to exclude specific volume from backup.

## OPERATIONAL PATTERNS

### Storage Provider Upgrades

**Proxmox CSI Upgrade**:
1. Update Helm chart version in `proxmox-csi/kustomization.yaml`
2. Review values.yaml for breaking changes
3. Apply via GitOps
4. Monitor CSI pods: `kubectl get pods -n kube-system -l app=proxmox-csi`
5. Test PVC creation to verify provisioning works

### Storage Troubleshooting

**Proxmox CSI Issues**:
```bash
# Check CSI pods
kubectl get pods -n kube-system -l app=proxmox-csi

# Check CSI logs
kubectl logs -n kube-system -l app=proxmox-csi-plugin -c provisioner

# Check StorageClass
kubectl describe storageclass proxmox-csi

# Check PVC status
kubectl describe pvc <name> -n <namespace>

# Check PV details
kubectl describe pv <pv-name>
```

**Proxmox CSI Permission Errors**:
1. Verify Proxmox user permissions via Terraform
2. Check Terraform state: `tofu show module.proxmox-csi-plugin`
3. Update permissions: `tofu apply -target=module.proxmox-csi-plugin.proxmox_virtual_environment_role.csi`

**Volume Stuck in Terminating**:
```bash
# Remove finalizer from PVC (last resort)
kubectl patch pvc <name> -n <namespace> -p '{"metadata":{"finalizers":[]}}'
```

## TESTING

### Storage Validation
```bash
# Test Proxmox CSI provisioning
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-csi-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-csi
  resources:
    requests:
      storage: 1Gi
EOF

# Verify PVC bound
kubectl get pvc test-csi-pvc

# Test pod with PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-storage-pod
spec:
  containers:
    - name: test
      image: busybox
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: test-csi-pvc
EOF

# Verify pod can write to volume
kubectl exec test-storage-pod -- sh -c "echo 'test' > /data/test.txt && cat /data/test.txt"
```

### Backup Validation
```bash
# Verify Velero scheduled backups exist
velero get schedules -n velero

# Test backup
velero backup create test-backup --include-namespaces <namespace> --default-volumes-to-fs-backup --wait

# Verify PVC backed up
velero backup describe test-backup --details | grep -A 10 "Pod Volume Backups"
```

## STORAGE-DOMAIN ANTI-PATTERNS

### Storage Management
- Never use Longhorn - deprecated and removed. Use `proxmox-csi` for all workloads
- Never skip backup configuration - Proxmox CSI volumes automatically backed up by Velero
- Never delete PVCs without verifying backup status
- Never manually modify Proxmox storage volumes outside of Kubernetes
- Never assume Proxmox CSI permissions are correct - verify Terraform state if provisioning fails

### Security & Data Management
- Never grant excessive Proxmox permissions to CSI user - use minimal permissions
- Never store unencrypted secrets in volumes - use Kubernetes Secrets or ExternalSecrets
- Never use `Delete` reclaim policy for critical data - use `Retain` to preserve data

## MIGRATION NOTES

All workloads have been migrated from Longhorn to Proxmox CSI. See website/docs/breaking-changes/longhorn-removal.md for migration details.

## REFERENCES

For Kubernetes patterns: k8s/AGENTS.md
For Velero backup strategy: k8s/infrastructure/controllers/velero/BACKUP_STRATEGY.md
For Proxmox CSI permissions: tofu/bootstrap/proxmox-csi-plugin/
For CNPG database patterns: k8s/infrastructure/database/AGENTS.md
For commit format: /AGENTS.md
For Proxmox CSI documentation: https://github.com/sergelogvinov/proxmox-csi-plugin

// /home/develop/homelab/tofu/AGENTS.md

# OpenTofu Infrastructure - Domain Guidelines

SCOPE: Infrastructure provisioning, VM management, and cluster bootstrapping
INHERITS FROM: /AGENTS.md
TECHNOLOGIES: OpenTofu (Terraform fork), Proxmox API, Talos Linux, Cloud-init

**PREREQUISITE: You must have read /AGENTS.md before working in this domain.**

## DOMAIN CONTEXT

Purpose: Provision and manage all infrastructure resources including VMs, networking, load balancers, and Talos Linux cluster bootstrapping.

Architecture:
- `tofu/` - Main OpenTofu configuration with variables, providers, modules
- `tofu/talos/` - Talos Linux machine configuration and cluster bootstrap
- `tofu/lb/` - Load balancer configuration
- `tofu/bootstrap/` - Bootstrap modules for cluster infrastructure

## QUICK-START COMMANDS

```bash
cd tofu

# Format and validate
tofu fmt
tofu validate

# Plan and review
tofu plan -out=tfplan
tofu show -no-color tfplan

# Apply (only with explicit authorization)
tofu apply
```

## PATTERNS

### VM Provisioning Pattern
Define VMs in `tofu/virtual-machines.tf` with node types (control-plane, worker). Use Cloud-init for initial configuration.

### Talos Configuration Pattern
Generate Talos machine configs using `talos_config` data sources. Use `config-machine.tf` for node-specific configs. Inline manifests bootstrap cluster components.

### Network Pattern
Define network resources in tofu modules. Use static IPs for critical infrastructure (load balancer, control-plane nodes).

### Bootstrap Pattern
Use `tofu/bootstrap/` modules to create prerequisite infrastructure:
- Proxmox CSI plugin user, role, and API token
- Static persistent volumes for legacy workloads

## TESTING

- Static validation: `tofu fmt` and `tofu validate`
- Plan review: `tofu plan` output reviewed by humans
- Requirements: All files formatted, configuration validates, plans reviewed before applying

## WORKFLOWS

**Development:**
- Edit Terraform files in `tofu/` directory
- Run `tofu fmt` and `tofu validate`
- Generate plan with `tofu plan -out=tfplan`
- Review plan and create PR with plan output

**Deployment:**
- Infra changes require human authorization and review
- Apply with `tofu apply` only after plan approval
- Include rollback plan in PR description

## COMPONENTS

### Main Configuration
- `main.tf` - Root module and resource references
- `providers.tf` - Provider configurations
- `variables.tf` - Variable definitions
- `output.tf` - Output values

### Infrastructure Modules
- `talos/` - Talos Linux cluster configuration
  - `config-machine.tf` - Machine-specific configurations
  - `config-cluster.tf` - Cluster-wide configuration
  - `virtual-machines.tf` - VM definitions
- `lb/` - Load balancer configuration
- `bootstrap/` - Bootstrap modules

### Configuration Files
- `config.auto.tfvars` - Variable values (do not commit with secrets)
- `nodes.auto.tfvars` - Node definitions
- `defaults.tf` - Default variable values
- `backend.tf` - State backend configuration

## TOFU-DOMAIN ANTI-PATTERNS

### Security & Safety
- Never commit secrets to Terraform files - use variables and `.tfvars`
- Never modify state files manually - use Terraform commands
- Never run `tofu apply` without reviewing plan output
- Never apply infra changes without human authorization and review

### Configuration Management
- Never use `--auto-approve` flag - always require human confirmation
- Never use targeted apply (`-target=...`) unless explicitly approved
- Never delete resources without understanding dependencies
- Never hardcode values that should be variables
- Never skip `tofu fmt` or `tofu validate` before committing

## REFERENCES

## Enterprise Learning Philosophy

### Infrastructure as Learning
Proxmox + Talos + OpenTofu represents enterprise infrastructure patterns. VM lifecycle management, API-driven configuration, and immutable infrastructure are production skills.

### Production-Grade Decisions
- **Talos vs standard Linux**: Immutable OS teaches enterprise security patterns
- **OpenTofu vs manual**: IaC teaches enterprise scalability and audit requirements
- **API-driven vs GUI**: Automation teaches enterprise operational patterns

### Cross-Domain Integration
Infrastructure changes enable application deployment through:
1. VM provisioning → Kubernetes nodes
2. Network configuration → Application connectivity
3. Storage setup → Application persistence
4. Cluster bootstrapping → Argo CD GitOps pipeline activation

### Enterprise Recovery Patterns
- State backup/recovery teaches enterprise disaster recovery
- Configuration drift detection teaches enterprise compliance
- Version-controlled infrastructure teaches enterprise change management

## REFERENCES

For commit format: /AGENTS.md
For Kubernetes manifests: k8s/AGENTS.md
For Talos Linux: Talos documentation
For Proxmox API: Terraform Proxmox provider documentation

// /home/develop/homelab/images/AGENTS.md

# Container Images - Domain Guidelines

SCOPE: Custom container images and Dockerfiles
INHERITS FROM: /AGENTS.md
TECHNOLOGIES: Docker, Docker Compose, GitHub Actions

**PREREQUISITE: You must have read /AGENTS.md before working in this domain.**

## DOMAIN CONTEXT

Purpose: Define and build custom container images for homelab applications.

Architecture:
- `images/<image-name>/` - Directory per image with Dockerfile and supporting files
- `images/<image-name>/Dockerfile` - Multi-stage build definition
- `images/<image-name>/entrypoint.py` - Entry point scripts (Python images)
- `images/<image-name>/.dockerignore` - Build context exclusions

## QUICK-START COMMANDS

```bash
# Build locally
docker build -t local/<image-name>:dev images/<image-name>/

# Test container
docker run --rm -it local/<image-name>:dev /bin/bash
docker run --rm local/<image-name>:dev <test-command>

# Push to registry
docker tag local/<image-name>:dev <registry>/<image-name>:<version>
docker push <registry>/<image-name>:<version>
```

## PATTERNS

### Multi-Stage Build Pattern
Use multiple FROM statements to create layers and discard build dependencies. Final stage contains only runtime dependencies.

### Security Pattern
- Run as non-root user with `USER` directive
- Don't include secrets in Dockerfile
- Use `.dockerignore` to exclude sensitive files
- Keep base images updated with security patches
- Sign images with Cosign for supply chain verification
- Scan images for CVEs before deploying to cluster

### Optimization Pattern
- Use `.dockerignore` to reduce build context size
- Order Dockerfile instructions by change frequency
- Combine RUN commands to reduce layers
- Use build cache effectively

### CI/CD Pattern
GitHub Actions `image-build.yaml` builds images when:
- Files under `images/<name>/` change
- Git tag `image-<version>` is pushed
- Images are pushed to registry and deployed via Kubernetes manifests

## TESTING

- Local build test: Verify Dockerfile builds successfully
- Smoke test: Run container and verify basic functionality
- Requirements: Dockerfile builds, container runs cleanly, no secrets in Dockerfile, non-root user execution

## WORKFLOWS

**Development:**
- Create directory `images/<image-name>/`
- Write Dockerfile with multi-stage build
- Add `.dockerignore` and `README.md`
- Test locally: `docker build -t local/<image-name>:dev images/<image-name>/`
- Run smoke test: `docker run --rm local/<image-name>:dev <test-command>`

**Build & Deploy:**
- Commit Dockerfile and supporting files
- GitHub Actions workflow triggers on PR/merge
- CI builds and pushes image to registry
- Kubernetes manifests reference new image tag

## COMPONENTS

### Existing Images
- `headlessx/` - Headless browser automation
- `sabnzbd/` - Usenet download client with custom entrypoint
- `vllm-cpu/` - CPU-optimized LLM inference

### CI/CD
- `image-build.yaml` - GitHub Actions workflow for building images

## IMAGES-DOMAIN ANTI-PATTERNS

### Security & Safety
- Never commit secrets or credentials to Dockerfile or build context
- Never include sensitive data in images (passwords, API keys, certificates)
- Never run containers as root user - use `USER` directive

### Build & Tagging
- Never use `latest` tag for base images or production images - pin specific versions
- Never build large images - use multi-stage builds and slim base images
- Never skip local testing before committing - build and run smoke tests
- Never build images without `.dockerignore` file

## ADDING NEW IMAGES

1. Create directory: `images/<image-name>/`
2. Add `Dockerfile` with multi-stage build
3. Add `.dockerignore` file
4. Add `README.md` documenting purpose and usage
5. Add entry point script if needed
6. Test locally with `docker build` and `docker run`
7. Create PR (GitHub Actions will build and publish on merge)

## REFERENCES

## Container Security Philosophy

### Security as Learning
Container security patterns teach enterprise defense-in-depth:
- Multi-stage builds = enterprise build pipeline security
- Non-root containers = enterprise principle of least privilege
- Secret management = enterprise security operations

### Production Security Standards
Enterprise environments require:
- Security scanning at every build
- Immutable infrastructure patterns
- Zero-trust networking principles
- Comprehensive audit trails

### Integration with Cluster Security
Container security extends to cluster security:
- Image security → Pod security policies
- Build secrets → Runtime secret management
- CI/CD patterns → GitOps security pipelines

### Enterprise Compliance Patterns
- SBOM generation teaches enterprise software supply chain security
- Vulnerability scanning teaches enterprise compliance
- Signed images teach enterprise software trust

## REFERENCES

For commit format: /AGENTS.md
For Kubernetes deployment: k8s/AGENTS.md
For Docker best practices: Docker documentation

// /home/develop/homelab/website/AGENTS.md

# Documentation Website - Domain Guidelines

SCOPE: Docusaurus documentation site and build system
INHERITS FROM: /AGENTS.md
TECHNOLOGIES: Docusaurus 3.9.2, TypeScript 5.9, React 19, Node.js 20.18+, npm 10.0+

**PREREQUISITE: You must have read /AGENTS.md before working in this domain.**

## DOMAIN CONTEXT

Purpose: Build and maintain documentation website for homelab, including architecture documentation, operational guides, and troubleshooting procedures.

Architecture:
- `website/docs/` - Documentation content organized by category
- `website/src/` - Custom React components and CSS
- `website/static/` - Static assets
- `website/docusaurus.config.ts` - Site configuration
- `website/sidebars.ts` - Documentation navigation structure

## QUICK-START COMMANDS

```bash
cd website

# Install dependencies
npm install

# Development server (hot reload)
npm start

# Type check and linting
npm run typecheck
npm run lint:all

# Build for production
npm run build

# Serve production build
npm run serve
```

## PATTERNS

### Content Structure
- Documentation files in `website/docs/` with `.md` or `.mdx` extension
- Use kebab-case for file and directory names
- Include frontmatter with title, description, sidebar_position
- Use relative links for internal navigation: `[text](../other-page.md)`

### Frontmatter Pattern
All documentation files include frontmatter with title, description for SEO, and sidebar_position for navigation ordering.

### Navigation Pattern
Update `sidebars.ts` to add new documentation pages. Use sidebar_position to control ordering. Group related pages under category sections.

### Linking Pattern
- Use relative links for internal navigation
- Use absolute URLs for external resources
- Never reference AGENTS.md files in documentation
- Only link to files in `website/docs/` directory
- Verify relative paths are correct before committing

## TESTING

- Local preview: `npm start` to visually inspect changes
- Type checking: `npm run typecheck` to ensure TypeScript correctness
- Linting: `npm run lint:all` for markdown and prose validation
- Requirements: Site builds successfully, TypeScript type checks, markdown lints, internal links work

## WORKFLOWS

**Development:**
- Create documentation files in `website/docs/`
- Add frontmatter with title, description, sidebar_position
- Test locally with `npm start`
- Lint with `npm run lint:all`
- Type check with `npm run typecheck`
- Update `sidebars.ts` if adding new pages

**Build & Deploy:**
- `npm run build` generates static site in `website/build/`
- CI builds site via `website-build.yaml` workflow
- Deploy to production on merge to main

## COMPONENTS

### Site Structure
- `src/components/` - Custom React components
- `src/css/` - Custom styles
- `src/data/` - Data files
- `src/pages/` - Custom pages

### Configuration
- `docusaurus.config.ts` - Site configuration
- `sidebars.ts` - Navigation structure
- `tsconfig.json` - TypeScript configuration
- `package.json` - Dependencies and scripts

## WEBSITE-DOMAIN ANTI-PATTERNS

### Build & Asset Management
- Never commit build artifacts (`website/build/`, `node_modules/`)
- Never add large binary assets - use external storage and link by URL
- Never use deprecated Docusaurus config options - follow current Docusaurus v4 API

### Content & Navigation
- Never break existing navigation or internal links
- Never reference AGENTS.md files from documentation
- Never use unescaped special characters in MDX content
- Never skip linting and type checking before committing

## REFERENCES

For commit format: /AGENTS.md
## Documentation Philosophy

### Learning Through Documentation
Documentation isn't just reference - it's where learning happens. Clear explanations of enterprise patterns transform implementation into education.

### Production Documentation Standards
Enterprise environments require:
- Comprehensive change documentation
- Architecture decision records (ADRs)
- Operational runbooks
- Recovery procedures

### Cross-Domain Sync Triggers
Documentation updates required when:
- **tofu changes**: Infrastructure documentation must reflect new patterns
- **k8s changes**: Application documentation must capture new workflows
- **images changes**: Container security documentation must update

### Enterprise Content Standards
- Every complex pattern needs explanation of "why"
- Every anti-pattern needs production consequence explanation
- Every workflow needs learning objective context

## REFERENCES

For documentation writing: website/docs/AGENTS.md
For Kubernetes concepts: k8s/AGENTS.md
For infrastructure: tofu/AGENTS.md
For Docusaurus: https://docusaurus.io/docs

// /home/develop/homelab/website/docs/AGENTS.md

# Documentation Writing Guidelines

SCOPE: Writing documentation for the homelab
INHERITS FROM: /AGENTS.md, website/AGENTS.md

## DOMAIN CONTEXT

Purpose:
Write and maintain user-facing documentation in the homelab repository.

Boundaries:
- Handles: Documentation content in website/docs/
- Does NOT handle: Website build system (see website/AGENTS.md), code implementation (see k8s/, tofu/)
- Integrates with: All domain directories for source file references

## PATTERNS

### Documentation Pattern
Write technical documentation in imperative voice with present tense facts. No first-person plural ("we"), no temporal language ("now uses"), no narrative storytelling. State what exists and how it works.

### Code Block Pattern
Avoid code blocks in documentation. They become outdated quickly. Describe concepts in prose, or link to source files with absolute paths. If code examples are unavoidable, verify they work and flag them for review.

Example of linking to source:
```
The storage configuration is defined in `/k8s/infrastructure/storage/proxmox-csi/kustomization.yaml`.
```

### Linking Pattern
- Internal links: Use relative paths within website/docs/
- Source file links: Use absolute paths from repository root
- External links: Use full URLs

## DOCUMENTATION STYLE

### Voice and Tense
- Use imperative voice for instructions: "Configure the setting", "Run the command"
- Use present tense for facts: "The system uses X", "Kopia uploads data to S3"
- State what exists and how it works, not how it was created

### What to Avoid
- No first-person plural: "We use", "We investigated"
- No temporal language: "Now uses", "Has been updated"
- No narrative storytelling: "We explored X and found that..."
- No status updates: "The system now supports..."
- No code blocks (link to source files instead)

### Comments in Code Files
State what the setting does, not why you chose it:
- Bad: `# We use Kopia because snapshots didn't work`
- Good: `# Kopia filesystem backup to S3`
- When comparison is relevant: Good: `# instead of CSI snapshots`

## ANTI-PATTERNS

Never use first-person plural ("we", "our") in documentation.

Never use temporal language ("now", "recently", "has been updated") in documentation.

Never break existing links without updating all references.

Never include code blocks in documentation. Link to source files by absolute path or explain concepts in prose.

Never commit untested code examples without running them.

## CRITICAL BOUNDARIES

Never add secrets or credentials to documentation files.

Never include configuration values that may change. Link to source manifests instead.

After making changes, verify relevant documentation doesn't contain outdated information. Update or flag stale docs.

## DOCUMENTATION CATEGORIES

- `getting-started/` - Onboarding and setup guides
- `k8s/` - Kubernetes documentation (applications, infrastructure)
- `tofu/` - OpenTofu infrastructure documentation
- `backup/` - Backup and recovery procedures
- `infrastructure/` - Infrastructure component documentation
- `troubleshooting/` - Common issues and solutions
- `contributing/` - Contribution guidelines

## REFERENCES

For documentation writing examples, see existing files in website/docs/

For Docusaurus features, see https://docusaurus.io/docs

For prose style, see root AGENTS.md


// /home/develop/homelab/AGENTS.md

# Homelab - Repository Guidelines

**You are working in an over-engineered GitOps homelab repository designed for enterprise learning.** This is not a typical homelab - every choice prioritizes production-grade patterns over simplicity to develop real-world skills.

SCOPE: GitOps-managed homelab built on Kubernetes (Talos Linux) with Argo CD for continuous deployment

## Repository Purpose

Infrastructure-as-Code repository managing a Kubernetes-based homelab cluster. Infrastructure is provisioned with OpenTofu, and all Kubernetes manifests use Kustomize with GitOps deployment via Argo CD.

## Architecture

### High-Level Structure

**Domain: k8s** - Kubernetes manifests, operators, and GitOps patterns → `/k8s/AGENTS.md`
**Domain: tofu** - Infrastructure provisioning, VM management, cluster bootstrapping → `/tofu/AGENTS.md`
**Domain: website** - Documentation site and build system → `/website/AGENTS.md`
**Domain: images** - Custom container images and Dockerfiles → `/images/AGENTS.md`

### Domain Communication

Changes flow: tofu → k8s (via cluster bootstrapping) → Argo CD GitOps sync

## Universal Standards

### Commits

Follow Conventional Commits format enforced by commitlint:
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`
Scopes: `k8s`, `infra`, `apps`, `docs`, `tofu`, `monitoring`, `network`, `storage`

Breaking changes require footer: `BREAKING CHANGE: <description>`

### Documentation

**Where to document:**
- `website/docs/` for user-facing documentation (matching structure)
- `AGENTS.md` files only for developer/AI guidance
- README.md for project overview
- Inline comments for non-obvious implementation details

**Rules:**
- User-facing markdown MUST be in `website/docs/`
- Never create markdown files in domain directories (k8s/, tofu/, images/)
- Use imperative voice, present tense, no first-person plural or temporal language

## Technology Stack

**k8s:** Kubernetes, Kustomize, Helm, Argo CD
**tofu:** OpenTofu, Proxmox API, Talos Linux
**website:** Docusaurus, TypeScript, React
**images:** Docker, GitHub Actions

## Code Style

- Directories/files: kebab-case
- TypeScript: camelCase variables, PascalCase classes/types
- YAML/HCL: snake_case resources
- YAML: 2-space indent, 120-char line length
- TypeScript: single quotes, es5 trailing commas, 120-char width

## Solution Standards

**Enterprise at Home** - Production-grade only, no homelab shortcuts.

Rank solutions from hardest/most-capable to simplest. Complexity is a feature, not a problem. Default to perfection - every change must hold up 10+ years without modifications.

## Core Philosophy

### Learning-First Approach
This repository serves as a learning sandbox for enterprise patterns. Every "over-engineered" choice is intentional - complexity develops skills that translate directly to production environments.

### Over-Engineering by Design
**Why complexity is a feature:** Homelab shortcuts don't teach enterprise resilience. Production systems require redundancy, observability, and automation - those patterns are learned here, not simplified away.

### Complete Auditable State
**Everything as Code rationale:** Full Git state representation enables instant rebuild capability and provides complete audit trails - exactly what enterprise environments require.

### Production Simulation
**Why no homelab shortcuts:** Enterprise environments can't take shortcuts. Learning proper patterns here prevents bad habits in professional environments.

### Domain Integration Philosophy
- **tofu → k8s**: Infrastructure bootstrapping enables application deployment
- **k8s → website**: Documentation captures implementation reality
- **images → k8s**: Container security patterns extend to cluster security
- **All → GitOps**: Changes flow through pipeline, never directly applied

## AGENTS.md Discovery

**MANDATORY: Read ALL AGENTS.md files from root to your working directory before any task.**

This is not optional. Every task requires understanding the cumulative context across all levels:
1. Root AGENTS.md (this file) - **Always read first**
2. Domain AGENTS.md (k8s/, tofu/, website/, images/) - Required for domain-specific work
3. Component AGENTS.md (if applicable) - Required for application/infrastructure work

**Keeping AGENTS.md Current:**
- AGENTS.md files MUST be updated whenever patterns, workflows, or conventions change
- Never complete a task without updating relevant AGENTS.md files if new information was learned
- The Self-Healing Rule applies: if you need information not in the closest AGENTS.md, that file is incomplete - update it immediately

**Self-Healing Rule:** If you need information not in the closest AGENTS.md, that file is incomplete - update it.

### Available AGENTS.md Files

**Domain-level:** k8s/, tofu/, website/, images/

**Component-level:**
- Applications: ai/, automation/, media/, web/
- Infrastructure: auth/authentik/, controllers/, database/, network/, storage/

## Universal Anti-Patterns

### Critical Security & Safety
- Never commit secrets or credentials to Git
- Never commit generated artifacts (build/, .tofu/, terraform.tfstate*)
- Never run `tofu apply` without explicit human authorization
- Never use `--auto-approve` in tofu commands
- Never use kubectl `--force`, `--grace-period=0`, or `--ignore-not-found` flags
- Never modify CRD definitions without understanding operator compatibility
 - Workload security: every workload spec must set `securityContext` at the pod and container level (including `initContainers`). Use `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, and `capabilities.drop: ["ALL"]`. Always explicitly set `hostNetwork: false`, `hostPID: false`, and `hostIPC: false` in pod specs. If an exception is explicitly required and approved, record the approval and justification as an inline comment in the manifest.

### Operational Excellence
- Never apply changes directly to cluster - use GitOps
- Never guess resource names, connection strings, or secret keys - query to verify
- Never skip validation steps before committing
- Never delete resources without evidence from logs/events
- Never ignore deprecation warnings - implement migration paths immediately
- Never leave documentation stale after completing tasks
- Never hallucinate YAML fields - use `kubectl explain` or official docs
- Never create summary documentation about work performed
- Never use git commands unless user asks for it

### Documentation Integrity
- Never create documentation from scratch for existing components - extend existing docs
- Never reference AGENTS.md files from user-facing documentation

## Quick-Start Reference

```bash
# Documentation validation (only applies to docs files)
pre-commit run --all-files
pre-commit run --files <file-path>

```

Note: Pre-commit hooks are configured only for documentation files in `website/docs/`. For code changes, ensure compliance with the code style guidelines manually.


## Philosophy

- GitOps is Law: All changes must go through Git
- Automate Everything: If it can be scripted or managed by a controller, it should be
- Security is Not an Afterthought: "Assume the pod is compromised" - non-root containers, default-deny network policies (Cilium v2), externalized secrets, image signing/scanning, and least-privilege RBAC by default

### CNPG Backup Strategy (Universal Reference)
**Continuous WAL → MinIO (plugin), weekly base backups → B2 (backup section), both in externalClusters for recovery flexibility.**

- **Only Plugin Architecture**: Use ObjectStore CRD + barman-cloud plugin (legacy barman deployment is deprecated)
- **Dual Destinations**: Configure in externalClusters - MinIO for fast local recovery, Backblaze B2 for disaster recovery
- **Recovery Flexibility**: Both destinations enable recovery if one location becomes unavailable

