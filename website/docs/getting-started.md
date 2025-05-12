---
title: Getting started
---

Spin up the lab, bootstrap GitOps, and watch apps deploy—all in about one hour.

## About the getting‑started workflow

These steps provision the cluster (optional if you already have one), install ArgoCD, and let the Git repository take over.

:::info
Prefer a minimal demo? See the [quick‑start](./quick-start.md).
:::

## Prerequisites

- Proxmox access and an SSH key on the hypervisor.
- Packages: `opentofu`, `talosctl`, `kubectl`, `argocd`.

## Overview of steps

1. Clone repository.
2. Provision VMs + Talos (optional).
3. Install ArgoCD.
4. Let ApplicationSets sync.
5. Verify health.

## Step‑by‑step guide

1. **Clone the repo:**

   ```bash
   git clone https://github.com/theepicsaxguy/homelab.git
   cd homelab
````

2. **Provision the cluster (skip if you have one):**

   ```bash
   cd website/tofu
   opentofu init && opentofu apply
   ```

3. **Bootstrap ArgoCD:**

   ```bash
   kubectl apply -f k8s/bootstrap/argocd-install.yaml
   ```

4. **Watch ArgoCD reconcile:**

   ```bash
   argocd app list
   ```

## Verify the setup

* **Nodes healthy?**

  ```bash
  talosctl health --talosconfig talosconfig --nodes <control-plane-IP>
  ```

* **Apps synced?** ArgoCD UI should show *Synced / Healthy* for every application.
