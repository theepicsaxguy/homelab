---
title: Quick start
---

This page previously described a Makefile-based quick start. However, the `Makefile` is not currently available in the repository.

## About the quick‑start

The intention was to provide a single command to wrap provisioning and bootstrapping for a disposable test drive. This is not functional at the moment.

## Prerequisites

For setting up the homelab, please refer to the [getting‑started guide](./getting-started.md) for the current recommended procedure and prerequisites.

## Overview of workflow

The original quick-start aimed to:
1. Create a Talos cluster.
2. Install ArgoCD and sync all manifests.

This automated process is not available via `make` commands.

## Run the demo

The `make demo-cluster && make demo-apps` commands are not available. Please follow the [getting‑started guide](./getting-started.md) for a step-by-step setup.

## Verify the setup

After following the [getting‑started guide](./getting-started.md):

*   **Applications:** Expect green check marks in ArgoCD after manifests are synced. You can access ArgoCD at `https://argocd.<YOUR-DOMAIN>` (e.g., `https://argocd.pc-tips.se`).
*   **Services:** Test any endpoint such as `https://grafana.<YOUR-DOMAIN>` (see Gateway IPs in `k8s/infrastructure/network/gateway/`).

To tear down a cluster provisioned with OpenTofu, you would typically use `opentofu destroy` in the `tofu` directory.
