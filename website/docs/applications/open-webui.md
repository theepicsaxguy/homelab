---
title: Open WebUI
sidebar_position: 7
description: Chat UI for local LLMs
---

# Open WebUI

Open WebUI provides a browser interface to local language models and relies on
Authentik for single sign-on. The service runs as a StatefulSet and stores its
data on a Longhorn volume.

## Health checks

Vectorizing large RAG documents can freeze the UI for several minutes. To avoid
unnecessary pod restarts, the liveness and readiness probes now tolerate up to
five minutes of failures. A startup probe with a ten-minute threshold covers the
initial launch.

## Vector store

Open WebUI stores uploaded documents in Qdrant. The StatefulSet pins the
following environment variables so the app always targets the in-cluster
deployment:

- `VECTOR_DB=qdrant`
- `QDRANT_URI=http://qdrant.qdrant.svc.cluster.local:6333`
- `ENABLE_QDRANT_MULTITENANCY_MODE=true`
- `QDRANT_PREFER_GRPC=false`

The `app-openwebui-qdrant-api-key` ExternalSecret now mirrors the
`QDRANT__SERVICE__API_KEY` property from Bitwarden into a Kubernetes secret with
a `QDRANT_API_KEY` field. Open WebUI will not start without this secret, which
prevents it from silently falling back to the default Chroma store and ensures
all traffic to Qdrant is authenticated.

After switching stores or rotating the API key, re-index all documents from the
Admin Panel → Settings → Documents page so the new Qdrant collection is
populated.

## Embeddings

LiteLLM fronts the in-cluster vLLM embedding server. Open WebUI treats LiteLLM
as an OpenAI-compatible backend with these environment variables:

- `OPENAI_API_BASE_URL=http://litellm.litellm.svc.cluster.local:4000/v1`
- `OPENAI_API_KEY` from the `app-openwebui-litellm-api-key` ExternalSecret
- `RAG_EMBEDDING_ENGINE=openai`
- `RAG_EMBEDDING_MODEL=intfloat/e5-base-v2`

LiteLLM and vLLM expose the `intfloat/e5-base-v2` embedding model, so the RAG
pipeline now shares a single embedding cache across the cluster.

## Persistent settings

Open WebUI reads the embedding and vector settings from env vars only on the
first boot. Later updates must be applied in the Admin Panel → Settings →
Documents page or by wiping the persistent volume.
