---
title: 'OpenWebUI Pipelines'
---

Pipelines run alongside OpenWebUI to handle OpenAI-compatible traffic on port `9099`. The Deployment mounts a PersistentVolumeClaim at `/app/pipelines` where pipeline files are downloaded on startup from the URLs specified in the `PIPELINES_URLS` environment variable.

## Configuration

- **Storage**: A PersistentVolumeClaim (`pipelines-pvc`) with 5Gi of Longhorn storage is mounted at `/app/pipelines` to persist downloaded pipeline files across pod restarts. An emptyDir volume is mounted at `/tmp` for temporary files.
- **Secrets**: The ExternalSecret `app-openwebui-pipelines-api-key` sources `PIPELINES_API_KEY` from Bitwarden and injects it into the container.
- **Service**: The `pipelines` `ClusterIP` Service exposes port `9099` inside the `open-webui` namespace.
- **Access**: OpenWebUI is automatically configured to connect to the pipelines service via the `PIPELINES_URL` and `PIPELINES_API_KEY` environment variables. The API key is sourced from the ExternalSecret `app-openwebui-pipelines-api-key`. Pipelines should appear automatically in the OpenWebUI admin panel.
- **Upstream provider**: Configure pipeline valves in the OpenWebUI UI to call LiteLLM at `http://litellm.litellm.svc.cluster.local:4000/v1` with the existing LiteLLM API key.

## Available Pipelines

The deployment includes several pipelines that are automatically loaded via the `PIPELINES_URLS` environment variable:

### General Tools Pipeline

Provides utility functions for LLM interactions:

- **get_user_name_and_email_and_id**: Retrieves current user session information
- **get_current_time**: Returns human-readable date and time
- **calculator**: Evaluates mathematical equations (with security warnings)
- **get_current_weather**: Fetches weather data from OpenWeather API

**Configuration**: Set `OPENWEATHER_API_KEY` valve parameter in OpenWebUI to enable weather functionality.

### Document Search Pipeline

Enables document retrieval from Qdrant vector store with hybrid search and RAG capabilities:

- Supports semantic and keyword-based search
- Optional reranking using Ollama or DeepInfra
- Configurable result limits and filtering

**Configuration**: The pipeline defaults are pre-configured for cluster services:
- Qdrant: `http://qdrant.qdrant.svc.cluster.local:6333`
- Embeddings: `nomic-embed-text:latest` via LiteLLM
- All settings adjustable via valve parameters in OpenWebUI

### Wikipedia Pipeline

Retrieves Wikipedia article summaries with automatic disambiguation and related topic suggestions.

### Memory Filter

Long-term memory filter using mem0 framework with Qdrant and Ollama for context-aware conversations.
