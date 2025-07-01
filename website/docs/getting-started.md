---
title: 'Getting Started: Homelab Cluster and GitOps Onboarding'
---
This guide walks you through spinning up a Kubernetes homelab: provisioning VMs, bootstrapping the cluster, and deploying workloads using GitOps—all in under one hour.

:::info
For a minimal demo or test setup, see the [quick‑start version](./quick-start.md).
:::

## Prerequisites

- Proxmox access (with SSH key set up on the hypervisor).
- Installed tools:
  - [`opentofu`](https://opentofu.org/)
  - [`talosctl`](https://www.talos.dev/)
  - [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
  - [`argocd`](https://argo-cd.readthedocs.io/)
- `terraform.tfvars` file with your cluster's details (see below for example).
- Access to this Git repository.

:::info
This repository uses `orkestack.com` and `pc-tips.se` for example domains.
If you fork it, search for these domains and replace them with your own.
:::

## Overview of steps

1. Configure cluster variables.
2. Launch and provision VMs with Talos.
3. Retrieve cluster access configs.
4. Bootstrap and verify ArgoCD.
5. Confirm GitOps deployment and cluster health.

## Prepare the configuration

1. **Clone the repository:**
   Download the required files and move into the working directory.

   ```bash
   git clone https://github.com/theepicsaxguy/homelab.git
   cd homelab
   ```

2. **Configure cluster variables:**
   Edit or create the `config.auto.tfvars` file to define your cluster nodes:

   ```hcl
   // tofu/config.auto.tfvars example

   cluster_name   = "talos"
   cluster_domain = "kube.pc-tips.se"

   # Network settings
   # All nodes must be on the same L2 network
   network = {
     gateway     = "10.25.150.1"
     vip         = "10.25.150.10" # Control plane Virtual IP
     cidr_prefix = 24
     dns_servers = ["10.25.150.1"]
     bridge      = "vmbr0"
     vlan_id     = 150
   }

   # Proxmox settings
   proxmox_cluster = "host3"

   # Software versions
   versions = {
     talos      = "v1.10.3"
     kubernetes = "1.33.2"
   }

   # OIDC settings (optional)
   oidc = {
     issuer_url = "https://sso.pc-tips.se/application/o/kubectl/"
     client_id  = "kubectl"
   }
   ```

   :::info
   Use secure storage for secrets, like 1Password or Bitwarden, and avoid committing sensitive files. For more information, see the [Argo CD Secrets Management](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/).
   :::

## Apply and deploy the cluster

3. **Initialize SSH agent and OpenTofu:**
   Enable SSH access and initialize the environment.

   ```bash
   eval $(ssh-agent)
   ssh-add ~/.ssh/id_rsa
   tofu init
   ```

4. **Provision the VMs and Talos cluster:**
   This step creates and configures all control-plane and worker nodes.

   ```bash
   tofu apply
   ```

5. **Retrieve Talos and Kubernetes configs:**
   Fetch access configs and set secure permissions.

   ```bash
   tofu output -raw talos_config > ~/.talos/config
   tofu output -raw kube_config > ~/.kube/config
   chmod 600 ~/.talos/config ~/.kube/config
   ```

## Bootstrap and verify ArgoCD

6. **Check or install ArgoCD:**
   ArgoCD is usually installed automatically. To verify or re-apply manually:

   ```bash
   kubectl get pods -n argocd
   # If ArgoCD pods aren't running, install with:
   kubectl apply -k k8s/infrastructure/controllers/argocd
   ```

7. **Monitor ApplicationSet synchronization:**
   Use the ArgoCD CLI to confirm apps are recognized and syncing.

   ```bash
   argocd app list
   ```

## Verify the setup

1. **Check node and service health:**

   ```bash
   talosctl health --talosconfig ~/.talos/config --nodes <control-plane-IP>
   ```

   All checks should report `healthy`.

2. **Confirm apps are synced in ArgoCD UI:**
   All applications should show *Synced / Healthy* status.

3. **Inspect ArgoCD logs (optional troubleshooting):**

   ```bash
   kubectl logs -n argocd deployment/argocd-server
   ```

   Look for messages indicating healthy reconciliation.

---

## Pro tips and troubleshooting

- **To recreate a node (e.g., after resizing a disk):**

  ```bash
  tofu taint 'module.talos.proxmox_virtual_environment_vm.this["work-00"]'
  tofu apply
  ```

- **For common issues (API or etcd failures):**

  ```bash
  talosctl etcd members
  ```

- Back up your `talosconfig` and `kubeconfig` immediately after setup.
- Document and save your network layout for future troubleshooting.

---
For further details on cluster architecture, networking, and recovery, see [Cluster Details](./architecture.md).
