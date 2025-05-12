---
title: Quick start
---

One command to see the whole stack in action.

## About the quick‑start

The `Makefile` wraps provisioning and bootstrapping for a disposable test drive.

## Prerequisites

- Same toolchain as the [getting‑started guide](./getting-started.md).
- A clean Proxmox node with available resources.

## Overview of workflow

1. `make demo-cluster` → Creates Talos cluster.
2. `make demo-apps` → Installs ArgoCD and syncs all manifests.

## Run the demo

1. **Kick off everything:**

   ```bash
   make demo-cluster && make demo-apps

````

2. **Open ArgoCD:** Navigate to `https://argocd.<YOUR-DOMAIN>` and log in with the admin password printed by the script.

## Verify the demo cluster

* **Applications:** Expect green check marks in ArgoCD after \~10 minutes.
* **Services:** Test any endpoint such as `https://grafana.<YOUR-DOMAIN>` (see Gateway IPs in `k8s/infrastructure/network/gateway/`).

Tear down with `make demo-clean` when you’re done.
