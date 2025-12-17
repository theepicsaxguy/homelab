# AI Applications - Agent Guidelines

> **Note:** This category-level AGENTS.md covers AI and ML applications under `k8s/applications/ai/`. It inherits from `k8s/AGENTS.md` for general Kubernetes patterns and adds AI-specific conventions.

## Purpose & Scope

- **Scope:** `k8s/applications/ai/` (AI/ML applications: LiteLLM, OpenHands, Qdrant, VLLM, etc.)
- **Parent:** Inherits from `k8s/AGENTS.md` for general Kubernetes patterns
- **Goal:** Document AI-specific patterns like GPU access, API key management, vector databases, and model storage

## Category-Specific Quick-Start

```bash
# Build all AI applications
kustomize build --enable-helm k8s/applications/ai

# Build a specific AI application
kustomize build --enable-helm k8s/applications/ai/<app>

# Validate AI category kustomization
kustomize build k8s/applications/ai | kubeval --strict
```

## Category Structure & Conventions

### Common Patterns

AI applications in this category share these patterns:
- **API Keys:** External secrets for LLM provider keysthrough litellm
- **Vector Databases:** Qdrant as shared vector database for embeddings
- **Model Storage:** Persistent volumes for downloaded models and caches
- **Resource Requests:** High CPU/memory requests
- **Backup Tiers:** GFS for vector DBs and critical state, daily for standard apps
- **Network Policies:** Allow access to shared Qdrant and external LLM APIs

### Shared Resources

- **Qdrant:** Shared vector database cluster for embeddings and semantic search
- **Model Storage:** Shared PVCs or S3 buckets for model artifacts
- **API Keys:** Centralized external secrets for LLM providers

## Adding a New AI Application

1. Create directory: `k8s/applications/ai/<app>/`
2. Add manifests following AI conventions (GPU requests, external secrets)
3. Include `kustomization.yaml` that references all manifests
4. Add backup labels to PVCs: GFS for vector DBs, daily for others
5. Update `k8s/applications/ai/kustomization.yaml` to include new app
6. Test locally: `kustomize build --enable-helm k8s/applications/ai/<app>`
7. Create PR (do not apply directly to cluster)

## Operational Patterns

### Deployment Order

AI applications have these dependencies:
1. **Qdrant** (shared vector database)
2. **Model storage** infrastructure
3. **Core AI services** (LiteLLM, VLLM)
4. **Dependent applications** (OpenHands, OpenWebUI)

### Backup Strategy

- **GFS:** Qdrant PVCs (critical vector data), model storage
- **Daily:** Application configs, caches
- **None:** Ephemeral model caches, temp files

**Maintenance Note:** Keep this file updated when AI patterns change. Update in the same PR as architectural changes.
