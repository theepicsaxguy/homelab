# AI Applications - Component Guidelines

SCOPE: AI/ML applications and shared resources
INHERITS FROM: ../AGENTS.md (and ../../AGENTS.md)

## COMPONENT CONTEXT

Purpose:
Define patterns for AI and ML applications, including GPU access, vector databases, API key management, and model storage.

Boundaries:
- Handles: AI application deployments (LiteLLM, OpenHands, VLLM, etc.), shared vector database (Qdrant), model storage
- Does NOT handle: General Kubernetes patterns (see k8s/AGENTS.md), infrastructure components
- Delegates to: k8s/AGENTS.md for general Kubernetes patterns, tofu/AGENTS.md for infrastructure

Architecture:
- `k8s/applications/ai/` - AI application deployments
- `qdrant/` - Shared vector database for embeddings and semantic search
- Shared resources: Model storage PVCs, centralized API keys for LLM providers
- External integrations: LLM provider APIs (OpenAI, Anthropic, etc.), vector database queries

File Organization:
- Each AI app in subdirectory: `k8s/applications/ai/<app>/`
- Standard files: `kustomization.yaml`, `deployment.yaml`, `service.yaml`, `httproute.yaml`
- Shared resources: `qdrant/` subdirectory for vector database

## INTEGRATION POINTS

External Services:
- LLM Provider APIs (OpenAI, Anthropic, Cohere, etc.): Used by LiteLLM for model inference
- Model Hubs (Hugging Face, etc.): For downloading models and embeddings
- External AI services: OpenAI API, Anthropic Claude API, etc.

Internal Services:
- Qdrant vector database: Shared across AI applications for embeddings storage and retrieval
- Model storage PVCs: Shared or application-specific volumes for model artifacts
- Centralized secrets: External secrets for LLM provider API keys via LiteLLM

APIs Consumed:
- LLM provider APIs (OpenAI, Anthropic, etc.) for model inference
- Hugging Face API for model downloads
- Vector database APIs (Qdrant) for embeddings operations

APIs Provided:
- HTTP endpoints for AI model inference (via LiteLLM gateway)
- Vector database endpoints for semantic search and retrieval
- Internal service-to-service communication

## COMPONENT-SPECIFIC PATTERNS

### GPU Access Pattern
AI workloads requiring GPU access use node affinity to schedule on GPU nodes. Define resource requests with `nvidia.com/gpu: 1`. Use GPU device plugins if required. Check available GPU capacity before adding GPU workloads.

### Vector Database Pattern (Qdrant)
Qdrant is shared vector database for embeddings and semantic search. All AI applications use single Qdrant cluster. Applications connect via internal Kubernetes service. Qdrant PVCs use GFS backup tier (critical vector data).

### API Key Management Pattern
LiteLLM acts as gateway for multiple LLM providers. Provider API keys stored in ExternalSecrets (Bitwarden). LiteLLM rotates and manages keys centrally. Applications connect to LiteLLM, not directly to providers.

### Model Storage Pattern
Downloaded models stored in persistent volumes. Use `proxmox-csi` StorageClass for new model storage. Large model caches use dedicated PVCs. Backup tier: GFS for critical models, Daily for standard caches.

### Resource Requests Pattern
AI applications require high CPU/memory requests. Set appropriate limits to prevent resource starvation. LLM inference requires more memory than model size. Monitor resource usage and adjust requests/limits.

### Network Policies Pattern
Allow outbound traffic to LLM provider APIs. Allow internal traffic to Qdrant. Restrict inbound traffic to necessary services. Use specific port ranges when possible.

## DATA MODELS

### Qdrant Collections
- Collections store vector embeddings for semantic search
- Each application uses separate collection or prefix
- Vector dimensions depend on embedding model used
- Collections stored in Qdrant PVCs (GFS backup tier)

### LiteLLM Provider Configuration
- Providers configured in LiteLLM deployment
- Each provider has API key from ExternalSecret
- Provider-specific parameters (model, temperature, etc.)
- Provider list and routing rules in configuration

## WORKFLOWS

Development:
- Create AI app directory: `k8s/applications/ai/<app>/`
- Define manifests following AI conventions (GPU requests, external secrets)
- Add backup labels to PVCs: GFS for critical data, Daily for caches
- Update `k8s/applications/ai/kustomization.yaml` to include new app
- Test locally: `kustomize build --enable-helm k8s/applications/ai/<app>`
- Create PR (do not apply directly to cluster)

Testing:
- Validate kustomization builds: `kustomize build --enable-helm k8s/applications/ai/<app>`
- Check GPU requests are appropriate for workload
- Verify external secrets reference correct Bitwarden entries
- Ensure network policies allow required traffic
- Confirm backup labels match data criticality

Deployment:
- Argo CD syncs from Git when changes merge
- Verify application starts and connects to shared resources (Qdrant, LiteLLM)
- Check GPU allocation if applicable: `kubectl describe node <gpu-node>`
- Monitor application logs for integration errors

## CONFIGURATION

Required:
- External secrets for LLM provider API keys (via Bitwarden)
- PVCs for model storage (if application stores models)
- Service and HTTPRoute for external access (if needed)
- Resource requests and limits (CPU, memory, GPU)

Optional:
- GPU resource requests for model inference workloads
- Custom embedding models for Qdrant
- Model download and caching configuration
- API rate limiting and quotas

Environment Variables:
- LLM provider API keys (from ExternalSecrets)
- Model paths (pointing to PVCs)
- GPU configuration (device index, memory limits)
- Qdrant connection details (internal service URL)
- LiteLLM gateway URL (for applications using gateway)

## KNOWN ISSUES

Large model downloads may timeout or fail due to network limitations. Pre-download models or use persistent caches.

GPU memory fragmentation can occur when running multiple models. Schedule GPU workloads carefully or use GPU sharing if supported.

Qdrant performance degrades with high vector counts. Monitor collection sizes and consider sharding or dedicated Qdrant instances.

## GOTCHAS

GPU resource requests use special resource name `nvidia.com/gpu`, not standard `gpu`. Request integer number of GPUs, not fractional values.

Model files stored in PVCs count against storage quotas. Monitor PVC usage and clean up unused models.

LiteLLM requires restart to reload provider configuration changes. Update manifests and let Argo CD redeploy.

Vector embeddings are large and expensive to recompute. Backup Qdrant PVCs with GFS tier (hourly/daily/weekly).

Backup tier selection matters for AI data. Use GFS for Qdrant and model storage (critical data), Daily for caches.

## REFERENCES

For general Kubernetes patterns, see k8s/AGENTS.md

For commit message format, see root AGENTS.md

For storage classes and backups, see k8s/AGENTS.md

For LiteLLM documentation, see https://docs.litellm.ai

For Qdrant documentation, see https://qdrant.tech/documentation
