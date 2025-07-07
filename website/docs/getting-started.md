---
title: 'Getting Started: Homelab Cluster and GitOps Onboarding'
description: Step-by-step guide to bootstrap the homelab cluster and deploy apps using GitOps.
---
This guide walks you through spinning up a Kubernetes homelab: provisioning VMs, bootstrapping the cluster, and deploying workloads using GitOps—all in under one hour.

:::info
For a minimal demo or test setup, see the [quick‑start version](./quick-start.md).
:::

## Prerequisites

- Proxmox access (with an SSH key configured on the hypervisor).
- The following tools installed locally:
  - [`opentofu`](https://opentofu.org/)
  - [`talosctl`](https://www.talos.dev/)
  - [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
  - [`argocd`](https://argo-cd.readthedocs.io/)
- **Information about your environment**, including the Proxmox API endpoint, node IP addresses, and desired domain names.
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

### 2. Configure Your Cluster

Your cluster's configuration is split into two files:

- `tofu/terraform.tfvars`: Holds **sensitive** provider credentials, like your Proxmox API token. You will create this from the example file, and it should **never be committed to version control**.
- `tofu/config.auto.tfvars`: Holds **non-sensitive** cluster definitions, like IP addresses, domain names, and software versions. You can commit this file to your fork.

**Step 1: Configure Proxmox Credentials**

Copy the example file and edit `tofu/terraform.tfvars` with your Proxmox details:

```bash
cp tofu/terraform.tfvars.example tofu/terraform.tfvars
```

**Step 2: Configure Cluster Settings**

Edit `tofu/config.auto.tfvars` to define your cluster's network, versions, and other settings. The provided file `tofu/config.auto.tfvars` serves as a direct example.

:::info
**Managing Secrets**
The `terraform.tfvars` file contains your Proxmox API token. To prevent accidentally committing it, ensure your project's `.gitignore` file includes the line `*.tfvars`.

For automated CI/CD pipelines, it is best practice to provide secrets via environment variables instead of files. For example, you can set the Proxmox token with an environment variable named `TF_VAR_proxmox_api_token`.
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

## Bootstrap the Cluster

Once the VMs are running, you must manually bootstrap the cluster's core services. This is a one-time process that solves the "chicken-and-egg" problem: we need to install Argo CD, but we want to manage Argo CD *with* Argo CD.

Apply these components in the following order to ensure dependencies are met.

**1. Apply Core Custom Resource Definitions (CRDs):**
These CRDs extend the Kubernetes API and are required by the services you are about to install.
```bash
kustomize build --enable-helm infrastructure/crds | kubectl apply -f -
```

**2. Install Networking and Core Controllers:**
This step deploys Cilium for networking, cert-manager for TLS certificates, and External Secrets for secret management.
```bash
# Apply Cilium CNI
kustomize build --enable-helm infrastructure/network | kubectl apply -f -
# Apply cert-manager and external-secrets
kustomize build --enable-helm infrastructure/controllers/cert-manager | kubectl apply -f -
kustomize build --enable-helm infrastructure/controllers/external-secrets | kubectl apply -f -
```

**3. Install Argo CD:**
With the core APIs and networking in place, you can now deploy the GitOps controller, Argo CD.
```bash
kustomize build infrastructure/controllers/argocd | kubectl apply -f -
```

**4. Deploy Argo CD Projects and ApplicationSets:**
These final resources configure Argo CD, telling it to automatically find and deploy all other applications from your Git repository.
```bash
kubectl apply -f applications/project.yaml
kubectl apply -f infrastructure/project.yaml
kubectl apply -f applications/application-set.yaml
kubectl apply -f infrastructure/application-set.yaml
```

Once these steps are complete, Argo CD will take over and reconcile the state of your cluster to match the Git repository.

## Verify the Setup

After bootstrapping, Argo CD will begin deploying the rest of the applications. You can monitor the progress to confirm everything is working correctly.

1.  **Check Kubernetes Node Status:**
    Ensure all your nodes are `Ready`.
    ```bash
    kubectl get nodes
    ```

2.  **Monitor Argo CD Synchronization:**
    List the applications that Argo CD is managing. Initially, they may show as `Progressing` or `Missing`. After a few minutes, they should all become `Healthy` and `Synced`.
    ```bash
    # Watch the applications sync in real-time
    argocd app list -w
    ```

Once all applications are synced, your GitOps homelab is fully operational.

## Pro tips and troubleshooting

- **To recreate a node (e.g., after resizing a disk):**

  ```bash
  tofu taint 'module.talos.proxmox_virtual_environment_vm.this["work-00"]'
  tofu apply
  ```

---
For further details on cluster architecture, networking, and recovery, see [Cluster Details](./architecture.md).
