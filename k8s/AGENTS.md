# Kubernetes Domain - Application Management Hub

SCOPE: Kubernetes manifests, operators, and application workflows
INHERITS FROM: /AGENTS.md
TECHNOLOGIES: Kubernetes, Kustomize, Helm, Argo CD, CNPG, Velero, Proxmox CSI

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