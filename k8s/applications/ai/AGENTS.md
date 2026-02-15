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