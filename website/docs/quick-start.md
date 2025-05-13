---
title: Homelab Quick start
---
Get your Kubernetes homelab up and running fast. This guide covers the minimum steps to launch a cluster and deploy apps with GitOps.

:::info
For a deeper technical guide or troubleshooting steps, see [Getting Started](./getting-started.md).
:::

## Prerequisites

- Proxmox access with your SSH key added to the hypervisor.
- Tools installed: `opentofu`, `talosctl`, `kubectl`, and `argocd`.
- This repository cloned locally.

## Overview of steps

1. Configure cluster variables.
2. Launch the cluster with OpenTofu.
3. Retrieve access configs.

## Quick Start Steps

1. **Clone the repository and move into it:**

   ```bash
   git clone https://github.com/theepicsaxguy/homelab.git
   cd homelab
   ```

2. **Create your cluster variable file (`terraform.tfvars`):**

   ```hcl
   # terraform.tfvars
   cluster_name     = "homelab"
   controlplane_ips = ["10.25.150.10", "10.25.150.11", "10.25.150.12"]
   worker_ips       = ["10.25.150.20", "10.25.150.21"]
   ```

   :::info
   Customize IPs and hostnames as needed for your lab environment.
   :::

3. **Initialize SSH agent and OpenTofu:**

   ```bash
   eval $(ssh-agent)
   ssh-add ~/.ssh/id_rsa
   tofu init
   ```

4. **Provision the cluster (this may take a few minutes):**

   ```bash
   tofu apply
   ```

5. **Fetch your access configs:**

   ```bash
   tofu output -raw talos_config > ~/.talos/config
   tofu output -raw kube_config > ~/.kube/config
   chmod 600 ~/.talos/config ~/.kube/config
   ```

## Verify

1. **Check that Talos nodes are healthy:**

   ```bash
   talosctl health --talosconfig ~/.talos/config --nodes <control-plane-IP>
   ```

2. **Confirm apps are syncing (ArgoCD):**

   ```bash
   argocd app list
   ```

   All applications should be `Healthy` and `Synced`.
   For any issues, see [troubleshooting in the full guide](./getting-started.md).

---
That's it! Your cluster and GitOps stack are live.
