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