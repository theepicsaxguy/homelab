---
title: Open Web UI
sidebar_position: 7
description: Chat UI for local LLMs
---

# Open Web UI

Open Web UI provides a browser interface to local language models and relies on
Authentik for single sign-on. The service runs as a StatefulSet and stores its
data on a Longhorn volume.

## Health checks

Vectorizing large RAG documents can freeze the UI for several minutes. To avoid
unnecessary pod restarts, the liveness and readiness probes now allow up to five
minutes of failures. A startup probe with a ten minute threshold covers the
initial launch.
