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
   ```

2. **Provision the cluster (skip if you have one):**

   ```bash
   cd tofu
   opentofu init && opentofu apply
   ```

3. **Bootstrap ArgoCD:**

   ArgoCD is typically bootstrapped as part of the OpenTofu provisioning process (defined in `k8s/argocd-bootstrap.tf`) or by applying its Helm chart manifests (e.g., from `k8s/infrastructure/controllers/argocd/`). Once the cluster is up and OpenTofu has run, ArgoCD should be getting installed.
   You can monitor its installation. If manual application of core ArgoCD components is needed (e.g., if not fully handled by OpenTofu initial setup for some reason):

   ```bash
   # This step might be handled automatically by OpenTofu.
   # Verify ArgoCD installation after 'opentofu apply'
   # If needed, apply the ArgoCD manifests from your infrastructure definitions:
   # kubectl apply -k k8s/infrastructure/controllers/argocd
   ```

4. **Watch ArgoCD reconcile:**

   ```bash
   argocd app list
   ```

## Verify the setup

- **Nodes healthy?**

  ```bash
  talosctl health --talosconfig talosconfig --nodes <control-plane-IP>
  ```

- **Apps synced?** ArgoCD UI should show *Synced / Healthy* for every application.
